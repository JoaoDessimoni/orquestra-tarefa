# Auditoria — Disparo de ações da Torre de Controle em 2026: régua, step e atraso real

**Card:** IAF-4953 (Alteração do disparo de ação & régua e broadcast de título por contrato) · relacionado: IAF-4893
**Data:** 28/07/2026
**Escopo:** produção (`idinihcyezkqfarztrdx`), schemas `org_blips` e `org_finza`, período 01/02/2026 – 28/07/2026
**Natureza:** auditoria técnica. Descreve o que o sistema faz, o que os dados mostram, e o que é e não é reconstruível retroativamente. Não emite juízo sobre acerto ou erro de especificação.
**Fonte de verdade:** definição das funções lidas direto do catálogo do Postgres em produção (`pg_get_functiondef`) + tabelas de produção. Nenhum número deste documento vem de `.md`, de código local ou de documentação — todos vêm de query no banco de produção. As queries estão no Apêndice B.

---

## 0. Sumário de achados

| # | Achado | Evidência |
|---|--------|-----------|
| 1 | O motor decide **por título**, não por contrato nem por CPF. A elegibilidade é por contato; a ação é por título. Isso está implementado assim em todas as versões do motor que rodaram em 2026. | §1.2, §1.4 |
| 2 | O casamento título↔step é de **dia exato** (`days_overdue = config.days_overdue`), não de faixa. As réguas em produção **não têm** `days_overdue_trigger` configurado — caem no formato legado de igualdade estrita. | §2.1, §2.2 |
| 3 | A régua vigente tem **20 degraus de cobrança pós-vencimento no WhatsApp** e **27 no e-mail**, e **termina em D+110**. Não existe step "110 ou mais". | §2.3 |
| 4 | Em 14/07/2026 havia **10.045 títulos vencidos abertos e cobráveis**. Apenas **659 (6,6%)** tinham atraso coincidindo com um degrau naquele dia. **5.259 (52,4%)** já estavam **acima do teto D+110**. | §4.4 |
| 5 | Dos **1.821 contatos** com título vencido em 14/07, apenas **113 (6,2%)** tinham o seu título de **maior atraso** num degrau. **1.351 (74,2%)** não tinham **nenhum** título vencido num degrau. | §4.4 |
| 6 | A deduplicação mantém o título de **maior atraso entre os que casaram um step** — não o de maior atraso do contato. Como só ~6% dos títulos vencidos estão num degrau num dia qualquer, o vencedor é quase sempre uma parcela recente. | §1.3, §4.5 |
| 7 | Reconstrução independente reproduz o apontamento do negócio: **172.544** ações de comunicação para clientes já vencidos usaram step ≠ maior atraso do contato (fev–jul), contra **171.572** relatadas no e-mail — **diferença de 0,6%**. | §4.6 |
| 8 | A deduplicação **funciona**: média de **1,45–1,93 ações por contato/dia** somando todos os canais; em julho o máximo de WhatsApp para o mesmo contato no mesmo dia foi **2**. | §3.5 |
| 9 | **Zero** ações criadas com `days_overdue > 110` em julho — confirma o teto por dados, não só por config. | §2.3 |
| 10 | Achado colateral: **27.251** ações (fev–jul) foram criadas para títulos cuja `payment_date` registrada é **anterior ou igual** à data da ação (dado defasado no momento do disparo). | §6.1 |
| 11 | A reconstrução retroativa **é possível** com alta confiança para atraso e elegibilidade, e **impossível** para transição de status antes de 28/06/2026 (quando `title_status_history` passou a existir). | §5 |

---

## 1. Como o disparo de uma ação funciona

### 1.1 As três peças e o que cada uma decide

| Peça | Tabela | Decide | Não decide |
|------|--------|--------|-----------|
| **Campanha** | `campaigns` | **QUANDO** o motor roda (`producer_cron_expression`), qual régua usar (`target_reguas`), a janela de envio (`start_time`/`end_time`/`active_days`), o cooldown (`contact_cooldown_hours`), a vazão (`actions_per_minute`) e qual motor usar (`use_pipeline_v2`) | nada sobre dias de atraso |
| **Régua** (workflow) | `workflows` + `workflow_steps` | **QUEM** entra (`assignment_filters` = filtros + carteiras + lógica AND/OR) e **O QUÊ** dispara (a escada de steps: um por dia de atraso, com canal, integração e mensagem) | quando roda |
| **Motor** | 6 RPCs SQL em `public` | **COMO** se decide: resolve contatos → expande em títulos → casa título×step → aplica regras → deduplica → cria as ações | a regra de negócio |

Configuração real das campanhas recorrentes de comunicação em produção (todas iguais):

```
producer_trigger_type   : scheduled
producer_cron_expression: 30 7 * * *      (07:30 BRT, TODOS os dias)
active_days             : [1,2,3,4,5]     (seg–sex)  ← vale para o ENVIO
start_time / end_time   : 08:00 / 18:00              ← vale para o ENVIO
contact_cooldown_hours  : 24
actions_per_minute      : 20
use_pipeline_v2         : true
```

O orquestrador roda todo dia, inclusive fim de semana, e cria as ações como `Pendente`. Quem respeita `active_days` e a janela é o **envio** (`scheduled-action-processor`), não a criação. Consequência medida: **8.860 ações de julho** foram enviadas em dia posterior ao da criação (§3.4).

### 1.2 O pipeline v2 — 6 RPCs em cadeia

Cada etapa marca uma `disposition` no candidato, que alimenta a próxima:

```
1. campaign_pipeline_resolve_contacts   grão: CONTATO          → disposition='pending'
   Resolve assignment_filters + carteiras via get_filter_contact_ids (AND/OR).
   Saída: 1 linha por contato elegível.

2. campaign_pipeline_fetch_titles       grão: TÍTULO           → disposition='fetched'
   Junta mv_titles_base por contact_id → puxa TODOS os títulos cobráveis de
   TODOS os contratos daquele contato (não só o contrato que casou o filtro).
   Filtro de cobrável: status IN ('Disponivel','Expirado','Recomprado')
                       AND removed_at IS NULL AND payment_date IS NULL
   Recalcula days_overdue = CURRENT_DATE - due_date  (aceita negativo).

3. campaign_pipeline_match_titles       grão: TÍTULO × STEP    → 'matched' → 'selected'
   3a. Casa days_overdue com o step (3 formatos — ver §2.1).
       Não casou nenhum step → disposition='no_step_match'.
   3b. Dedup por integração: mantém 1 por (contact_id, action_type, integration_id)
       [+ contract_id quando action_type IN ('negativation','notification')],
       ORDER BY days_overdue DESC, id.
   3c. Promove os sobreviventes a 'selected'.

4. campaign_pipeline_apply_rules        4 verificações
   Rule 1 Blocklist      : contato/contrato/título em blocklist_entries ativa → exclui
   Rule 2 Cooldown       : mesmo canal+integração já enviado ao contato dentro
                           do cooldown → exclui  (scoped por contrato só em neg/notif)
   Rule 3 Same step      : já existe ação do mesmo workflow_step_id hoje
                           (status ∉ Falhou/Falha Permanente) → exclui
   Rule 4 Higher priority: já existe ação HOJE, no mesmo canal, cujo
                           metadata.days_overdue > o do candidato → exclui o candidato

5. campaign_pipeline_cross_dedup        grão: CONTATO × canal
   1 por (contato, action_type, integração) entre TODAS as campanhas do run,
   mantendo o de maior days_overdue.

6. campaign_pipeline_create_actions     grão: AÇÃO
   INSERT em actions com status='Pendente', gravando title_id, contract_id,
   integration_id, workflow_step_id e metadata = {days_overdue, pipeline_v2:true}.
```

O `metadata.days_overdue` gravado aqui é **a prova documental de qual degrau casou** — é o que permite toda a auditoria retroativa deste documento.

### 1.3 O ponto exato onde "maior atraso" é aplicado — e o seu limite

Três etapas escolhem "o de maior atraso": a dedup 3b (§1.2), o `cross_dedup` (etapa 5) e a Rule 4 do `apply_rules`.

**Todas as três operam sobre candidatos que JÁ casaram um step.** Nenhuma delas consegue promover um título que nunca casou. Trecho literal do `match_titles` em produção:

```sql
-- Step 3b: Dedup by integration - keep 1 per (contact_id, action_type, integration_id)
--          with highest days_overdue
ROW_NUMBER() OVER (
    PARTITION BY contact_id, action_type,
        COALESCE(integration_id, '00000000-...'::UUID),
        CASE WHEN action_type IN ('negativation','notification') THEN contract_id END
    ORDER BY days_overdue DESC, id
)
...
FROM %1$I.campaign_execution_candidates
WHERE run_id = %2$L AND disposition = 'matched'   -- ← só quem casou step
```

E a Rule 4:

```sql
AND EXISTS ( ... FROM actions a
             WHERE ... a.created_at >= v_same_step_cutoff
               AND a.status IN ('Enviado','Interagiu','Respondido','Em Atendimento',...)
               AND (a.metadata->>'days_overdue')::INTEGER > c.days_overdue ... )
```

Ela **exclui o menor** quando o maior já gerou ação. Ela não faz o inverso: não cria ação para o maior quando ele não casou step.

Isto é o mecanismo causal central desta auditoria: **"maior atraso" é aplicado como critério de desempate entre os títulos que caíram num degrau naquele dia, não como critério de seleção do título a cobrar.**

### 1.4 Escopo de dedup: contato vs contrato

| Tipo de ação | Escopo da dedup | Efeito |
|---|---|---|
| `send_whatsapp`, `send_email`, `send_sms`, `send_voice`, `send_rcs` | por **CONTATO** | 1 mensagem por contato por canal por integração — independente de quantos contratos |
| `negativation`, `notification` | por **CONTRATO** | cada contrato gera a sua própria ação |

Implementado nas 3 RPCs via `CASE WHEN action_type IN ('negativation','notification') THEN contract_id END` na chave de partição/predicado.

### 1.5 Do "Pendente" ao envio

```
create_actions → actions(status='Pendente')
       ↓  pg_cron 1 min
scheduled-action-processor
  ├─ cleanup_stale_locks + claim_pending_actions (lock atômico)
  ├─ enriquece com dados da campanha (active_days, janela)
  ├─ checa janela de execução → fora da janela: fica Pendente
  ├─ checa pagamento (payment_check_url) → achou pago: Cancelado (Pago)
  ├─ checa rate limit por canal
  └─ send-message
        ├─ resolve as {{variáveis}} lendo vw_titles_live + a ação
        ├─ checa blocklist por endereço/canal (fail-closed)
        └─ POST no webhook da integração
```

**Nota relevante para leitura de payload:** as `{{variáveis}}` — inclusive `{{title.days_overdue}}` — são resolvidas **no envio**, não na criação. Uma ação criada no sábado como D+8 e enviada na segunda carrega `title_days_overdue = 10` no corpo do webhook, embora o step que casou tenha sido o D+8. Isso explica divergências aparentes ao comparar a mensagem recebida com o step configurado.

### 1.6 Três motores coexistiram em 2026

| Motor | Quando é usado | Período em produção |
|---|---|---|
| `campaign-executor` v1 (TypeScript, title-centric) | `producer_trigger_type='on_pipeline_complete'` ou `use_pipeline_v2=false` | fev–mai/2026 (réguas v2, Locação v1, Venda v1) |
| **Pipeline v2** (6 RPCs SQL) | recorrente `scheduled`/`manual` com `use_pipeline_v2=true` | mar/2026 → hoje (réguas v4) |
| `broadcast-processor` | `campaign_type='broadcast'` | disparos pontuais avulsos |

Os três decidem por título. O v1 e o v2 divergem em telemetria (§3.6), não na regra de decisão.

---

## 2. Os steps: o quê, para quem, quando, como e por quê

### 2.1 Como um step é configurado e como o motor o interpreta

Um step é uma linha em `workflow_steps` com `step_type` (canal) e um `config` JSONB. O motor aceita **três formatos** de gatilho, nesta ordem:

| Formato | Condição no `config` | Semântica |
|---|---|---|
| 1 — Faixa | `days_overdue_trigger = {min, max}` | `days_overdue >= min AND (max IS NULL OR days_overdue <= max)` — **faixa**, e com `max=null` vira "min ou mais" |
| 2 — Dia exato (legado) | `days_overdue_trigger` ausente **e** `config.days_overdue` presente | `days_overdue = config.days_overdue` — **igualdade estrita** |
| 3 — Broadcast | nenhum gatilho, mas tem `message`/`integration_id` | casa qualquer título |

**O que está em produção:** consultei os 55 steps de cada régua v4 e os 51 de cada v2. Em **todas**, `days_overdue_trigger` é **NULL** e `config.days_overdue` está preenchido (com `trigger_day` espelhando o mesmo valor). Logo, **100% do matching de régua em 2026 rodou no Formato 2 — dia exato.**

Consequência direta: um título em D+104 não casa o step D+102 nem o D+110. Ele simplesmente não gera ação naquele dia. E um título em D+394 nunca mais casa nada.

Chaves observadas num step real (`[BLIPS] v4`, WhatsApp D-7): `days_overdue`, `trigger_day`, `integration_id`, `message`, `template_content`, `meta_template_name`, `meta_components`, `template_variable_map`, `activation_template_id`.

### 2.2 Como um título caminha pela régua

```
        vencimento (D0)
             │
D-10  D-7  D-5  D-3  D-1  D0   D+3  D+5  D+8 ... D+102  D+110      D+111 ...
  ●    ●    ●    ●    ●    ●     ●    ●    ●        ●      ●          (nada)
  └──── preventivo ─────┘   └────────── cobrança ──────────┘        silêncio
```

Todo dia às 07:30 BRT o motor recalcula o atraso de **cada** título cobrável de **cada** contato elegível e pergunta: *existe step exatamente neste dia?* Se sim, aquele título é candidato. Se não, ele passa o dia invisível — e volta a ser avaliado amanhã, com atraso +1.

Um título com 121 dias de vida útil na régua (D-10 a D+110) é avaliado 121 vezes e pode disparar em, no máximo, 33 dias distintos (24 no WhatsApp, 31 no e-mail). Nos outros 88+ dias, nada acontece com ele.

### 2.3 A escada real em produção

**Régua vigente — `[BLIPS]/[IDEAL]/[FINZA] Régua de Comunicação v4` (55 steps, estável desde 06/04/2026):**

| Canal | Steps | Degraus |
|---|---|---|
| **WhatsApp** | 24 | `-7, -3, -1, 0, 3, 5, 8, 11, 16, 20, 25, 31, 40, 46, 50, 61, 70, 85, 87, 91, 96, 99, 102, 110` |
| **E-mail** | 31 | `-10, -5, -3, 0, 3, 5, 8, 11, 13, 16, 20, 23, 25, 31, 35, 40, 46, 50, 55, 61, 65, 70, 75, 80, 85, 87, 91, 96, 99, 102, 110` |

Degraus **pós-vencimento** (atraso > 0): **20 no WhatsApp**, **27 no e-mail**. Teto: **D+110**.

**Régua anterior — `Régua de Comunicação v2` (51 steps, ativa fev–mar/2026):** mesma estrutura, degraus ligeiramente diferentes (`15, 30, 45, 60` onde a v4 usa `13, 31, 46, 61`). Teto igual: D+110.

**Réguas de fevereiro com escada curta:** `[BLIPS] Régua geral - Locação v1` (18 steps, teto **D+25**) e `[IDEAL] Régua Geral - Venda v1` (26 steps, teto **D+55**).

**Volume real por degrau — julho/2026, `org_blips`, comunicação:**

| Degrau | Ações | WA | E-mail | | Degrau | Ações | WA | E-mail |
|---:|---:|---:|---:|---|---:|---:|---:|---:|
| D-10 | 2.525 | 0 | 2.525 | | D+25 | 883 | 447 | 436 |
| D-7 | 3.827 | 3.827 | 0 | | D+31 | 1.934 | 976 | 958 |
| D-5 | 1.017 | 0 | 1.017 | | D+35 | 400 | 0 | 400 |
| D-3 | 3.202 | 1.605 | 1.597 | | D+40 | 1.414 | 712 | 702 |
| D-1 | 4.069 | 4.069 | 0 | | D+46 | 686 | 347 | 339 |
| **D0** | **5.535** | 2.779 | 2.756 | | D+50 | 1.102 | 841 | 261 |
| D+3 | 4.297 | 2.172 | 2.125 | | D+55 | 233 | 0 | 233 |
| D+5 | 3.464 | 1.908 | 1.556 | | D+61 | 411 | 209 | 202 |
| D+8 | 3.117 | 1.655 | 1.462 | | D+65 | 665 | 0 | 665 |
| D+11 | 2.413 | 1.224 | 1.189 | | D+70 | 1.301 | 657 | 644 |
| D+13 | 1.388 | 0 | 1.388 | | D+75 | 300 | 0 | 300 |
| D+16 | 2.124 | 1.077 | 1.047 | | D+80 | 650 | 0 | 650 |
| D+20 | 2.089 | 1.059 | 1.030 | | D+85 | 1.467 | 734 | 733 |
| D+23 | 1.035 | 0 | 1.035 | | D+87 | 574 | 287 | 287 |
| | | | | | D+91 | 817 | 409 | 408 |
| | | | | | D+96 | 985 | 493 | 492 |
| | | | | | D+99 | 1.071 | 536 | 535 |
| | | | | | D+102 | 1.106 | 553 | 553 |
| | | | | | **D+110** | **1.006** | 503 | 503 |
| | | | | | **> D+110** | **0** | **0** | **0** |

A última linha é medição, não inferência: **nenhuma ação** foi criada acima de D+110 em julho.

---

## 3. Inventário mensal de ações — 2026

### 3.0 Universo auditado e a migração de schema

O banco de produção tem **dois** schemas de organização. Isso é essencial para não duplicar contagem:

| Org | Slug | Criada | Ações totais | Papel |
|---|---|---|---|---|
| Blips | `org_blips` | 15/01/2026 | 445.131 | operação histórica e atual, **multi-originador** ([BLIPS], [IDEAL], [FINZA]) |
| Finza | `org_finza` | **11/06/2026** | 18.956 | recebeu a fatia FINZA por migração (`_migr_finza_id3783_audit`) e segue própria |

Sobreposição medida por `action.id`: **10.707 ações existem nos dois schemas** — são as linhas copiadas na migração, não disparos distintos.

| Mês | `org_finza` total | copiadas de `org_blips` | exclusivas de `org_finza` |
|---|---:|---:|---:|
| fev | 693 | 693 | 0 |
| mar | 1.697 | 1.697 | 0 |
| abr | 2.453 | 2.453 | 0 |
| mai | 4.180 | 4.180 | 0 |
| **jun** | 4.662 | 1.684 | **2.978** |
| **jul** | 5.271 | 0 | **5.271** |

**Leitura:** fev–mai a operação Finza rodou 100% dentro de `org_blips`; o corte para `org_finza` aconteceu em **junho**; em julho já não há régua `[FINZA]` produzindo em `org_blips`.

Por isso **§3.1–§4.6 usam `org_blips` como universo** (é onde está o histórico completo fev–jul e é o universo dos números do e-mail) e **§7 trata `org_finza` separadamente**, contando só as ações exclusivas. Somar os dois sem deduplicar por `id` inflaria fev–mai.

### 3.1 Volume geral — `org_blips`

| Mês | Ações criadas | Enviadas | Falhas | Canceladas | Horas médias até envio | Enviadas em dia posterior | Máx. dias de defasagem |
|---|---:|---:|---:|---:|---:|---:|---:|
| fev/26 | 62.161 | 54.268 | 7.392 | 7.664 | 12,99 | 16.890 | 2 |
| mar/26 | 69.652 | 60.550 | 5.772 | 8.987 | 5,69 | 8.131 | 9 |
| abr/26 | 84.055 | 68.760 | 5.432 | 15.434 | 8,02 | 15.319 | 19 |
| mai/26 | 92.599 | 69.588 | 8.412 | 22.871 | 7,27 | 12.111 | 5 |
| jun/26 | 78.486 | 64.928 | 2.789 | 13.111 | 5,72 | 8.431 | 2 |
| jul/26 | 57.771 | 47.959 | 4.184 | 9.169 | 6,55 | 8.860 | 2 |
| **Total** | **444.724** | **366.053** | **33.981** | **77.236** | — | **69.742** | — |

(exclui `metadata.is_test='true'`; `Pendente = 0` em todos os meses)

### 3.2 Por canal, com contatos / contratos / títulos distintos

| Mês | Tipo | Ações | Contatos | Contratos | Títulos |
|---|---|---:|---:|---:|---:|
| fev | send_email | 33.907 | 4.751 | 5.529 | 9.406 |
| fev | send_whatsapp | 28.254 | 4.750 | 5.478 | 9.283 |
| mar | send_email | 38.342 | 4.887 | 5.640 | 10.693 |
| mar | send_whatsapp | 31.156 | 4.354 | 4.886 | 8.899 |
| mar | notification | 209 | 163 | 168 | 179 |
| mar | negativation | 15 | 14 | 14 | 5 |
| abr | send_email | 43.103 | 5.027 | 5.907 | 10.972 |
| abr | send_whatsapp | 38.152 | 4.963 | 5.859 | 10.391 |
| abr | negativation | 1.899 | 1.275 | 1.453 | 1.828 |
| abr | notification | 904 | 731 | 833 | 902 |
| mai | send_email | 47.015 | 4.947 | 5.809 | 12.750 |
| mai | send_whatsapp | 44.063 | 4.942 | 5.863 | 12.191 |
| mai | negativation | 1.468 | 1.124 | 1.203 | 1.239 |
| mai | notification | 53 | 50 | 53 | 53 |
| jun | send_email | 40.156 | 4.867 | 5.836 | 10.855 |
| jun | send_whatsapp | 35.488 | 4.774 | 5.740 | 10.038 |
| jun | send_sms | 2.445 | 2.329 | 2.333 | 2.335 |
| jun | negativation | 383 | 316 | 379 | 382 |
| jul | send_whatsapp | 29.079 | 4.443 | 5.293 | 9.581 |
| jul | send_email | 28.028 | 4.477 | 5.268 | 9.537 |
| jul | negativation | 477 | 417 | 470 | 476 |
| jul | notification | 187 | 172 | 185 | 187 |

Observação estrutural: a carteira ativa é estável (~4.400–5.000 contatos, ~5.300–5.900 contratos), mas o número de **títulos** tocados por mês (~9.500–12.700) é ~2x o de contratos. É a assinatura do modelo por título: um contrato parcelado contribui com várias parcelas ao longo do mês.

### 3.3 Por régua × campanha × mês (≥ 50 ações)

**fevereiro/2026 — motor v1, réguas v2 e "geral"**

| Régua | Campanha | Ações | WA | E-mail | Contatos | Contratos | Títulos |
|---|---|---:|---:|---:|---:|---:|---:|
| [BLIPS] Régua de Comunicação v2 | BLIPS v2 | 34.433 | 16.205 | 18.228 | 3.504 | 4.042 | 6.476 |
| [IDEAL] Régua de Comunicação v2 | IDEAL v2 | 13.815 | 6.244 | 7.571 | 1.411 | 1.703 | 2.921 |
| [BLIPS] Régua geral - Locação v1 | Carteira Blips v1 | 7.604 | 2.149 | 5.455 | 3.419 | 3.666 | 4.304 |
| [IDEAL] Régua Geral - Venda v1 | Carteira Ideal v1 | 3.262 | 1.179 | 2.083 | 1.075 | 1.230 | 1.710 |
| (step órfão) | BLIPS v2 | 1.058 | 1.058 | 0 | 871 | 885 | 893 |
| (step órfão) | IDEAL v2 | 915 | 915 | 0 | 687 | 705 | 706 |
| [FINZA] Régua de Comunicação v2 | FINZA v2 | 835 | 361 | 474 | 210 | 220 | 239 |

**março/2026 — transição v2 → v4 + entrada de notificação/negativação**

| Régua | Campanha | Ações | WA | E-mail | Contatos |
|---|---|---:|---:|---:|---:|
| [BLIPS] Régua de Comunicação v2 | BLIPS v2 | 37.100 | 15.468 | 21.632 | 3.937 |
| [IDEAL] Régua de Comunicação v2 | IDEAL v2 | 18.411 | 8.146 | 10.265 | 2.843 |
| [FINZA] Régua de Comunicação v2 | FINZA v2 | 5.207 | 2.357 | 2.850 | 2.147 |
| Notificação Extrajudicial - Blips | [BLIPS] Notif. Extrajudicial v1 | 3.082 | 1.541 | 1.541 | 1.541 |
| [BLIPS] Pré Negativação Serasa | — | 2.040 | 2.040 | 0 | 1.272 |
| Notificação Extrajudicial - Ideal | [IDEAL] Notif. Extrajudicial v1 | 1.350 | 675 | 675 | 675 |
| Notificação Extrajudicial - Blips | — | 905 | 0 | 905 | 905 |
| [IDEAL] Pré Negativação Serasa | — | 806 | 806 | 0 | 457 |
| Notificação - MRS Cartorário | Notificação - MRS Cartorário | 138 | 0 | 0 (138 notif) | 134 |

**abril/2026 — réguas v4 em regime**

| Régua | Campanha | Ações | WA | E-mail | Neg/Notif | Contatos | Contratos | Títulos |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| [BLIPS] v4 Boleto Disponível | idem | 52.070 | 24.471 | 27.599 | 0 | 3.625 | 4.217 | 7.758 |
| [IDEAL] v4 Boleto Disponível | idem | 20.259 | 9.544 | 10.715 | 0 | 1.297 | 1.501 | 3.076 |
| Notificação - MRS Cartorário | idem | 2.275 | 0 | 0 | 2.275 | 1.156 | 1.334 | 2.275 |
| [FINZA] v4 Boleto Disponível | idem | 2.089 | 966 | 1.123 | 0 | 182 | 183 | 292 |
| [BLIPS] v4 PNP | idem | 2.077 | 978 | 1.099 | 0 | 394 | 461 | 995 |
| Broadcast Pontual 23/04 | idem | 1.750 | 875 | 875 | 0 | 875 | 875 | 875 |
| [IDEAL] v4 PNP | idem | 1.059 | 467 | 592 | 0 | 176 | 232 | 561 |
| [BLIPS] 31+ NEGATIVAÇÃO REPIQUE | idem | 774 | 258 | 258 | 258 | 258 | 258 | 258 |
| [BLIPS] Construção >=16 Negativação | idem | 347 | 111 | 111 | 125 | 112 | 118 | 120 |
| [FINZA] v4 PNP | idem | 299 | 149 | 150 | 0 | 67 | 67 | 110 |

**maio/2026**

| Régua | Ações | WA | E-mail | Neg/Notif | Contatos | Contratos | Títulos |
|---|---:|---:|---:|---:|---:|---:|---:|
| [BLIPS] v4 Boleto Disponível | 55.769 | 27.032 | 28.737 | 0 | 3.634 | 4.224 | 8.971 |
| [IDEAL] v4 Boleto Disponível | 23.530 | 11.220 | 12.310 | 0 | 1.238 | 1.430 | 3.419 |
| [FINZA] v4 Boleto Disponível | 3.623 | 1.733 | 1.890 | 0 | 274 | 285 | 489 |
| [BLIPS] Broadcast 30/05 | 1.920 | 960 | 960 | 0 | 960 | 960 | 960 |
| [BLIPS] Broadcast 21/05 | 1.218 | 406 | 406 | 406 | 406 | 406 | 407 |
| Notificação Extrajudicial - Blips | 1.176 | 588 | 588 | 0 | 588 | 588 | 588 |
| [IDEAL] Broadcast 19/05 | 1.143 | 381 | 381 | 381 | 381 | 381 | 381 |
| [IDEAL] Broadcast 30/05 | 984 | 492 | 492 | 0 | 492 | 492 | 492 |
| Notificação Extrajudicial - Ideal | 652 | 326 | 326 | 0 | 326 | 326 | 326 |
| Negativação Serasa ≤6 / 15 dias | 310 | 0 | 0 | 310 | 271 | 310 | 310 |
| (+ 8 broadcasts/notificações menores) | ~1.500 | | | | | | |

**junho/2026 — entrada de SMS; saída da operação FINZA**

| Régua | Ações | WA | E-mail | SMS | Neg/Notif | Contatos | Contratos | Títulos |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| [BLIPS] v4 Boleto Disponível | 53.184 | 25.223 | 27.961 | 0 | 0 | 3.576 | 4.242 | 7.785 |
| [IDEAL] v4 Boleto Disponível | 20.064 | 9.507 | 10.557 | 0 | 0 | 1.165 | 1.345 | 2.902 |
| [BLIPS] Broadcast 22/06 | 1.774 | 0 | 0 | 1.774 | 0 | 1.774 | 1.774 | 1.774 |
| [FINZA] v4 Boleto Disponível | 1.675 | 758 | 917 | 0 | 0 | 306 | 322 | 458 |
| [IDEAL] Broadcast 22/06 | 668 | 0 | 0 | 668 | 0 | 668 | 668 | 668 |
| [BLIPS] Broadcast 12/06 | 501 | 0 | 501 | 0 | 0 | 501 | 501 | 501 |
| Negativação Serasa ≤6 / 15 dias | 323 | 0 | 0 | 0 | 323 | 268 | 319 | 323 |
| [IDEAL] Broadcast 12/06 | 220 | 0 | 220 | 0 | 0 | 220 | 220 | 220 |
| Negativação Serasa >6 / 31 dias | 67 | 0 | 0 | 0 | 67 | 50 | 61 | 67 |

**julho/2026 — só [BLIPS] e [IDEAL] em `org_blips`**

| Régua | Ações | WA | E-mail | Neg | Contatos | Contratos | Títulos |
|---|---:|---:|---:|---:|---:|---:|---:|
| [BLIPS] v4 Boleto Disponível | 38.189 | 19.728 | 18.461 | 0 | 3.536 | 4.182 | 7.364 |
| [IDEAL] v4 Boleto Disponível | 13.454 | 6.747 | 6.707 | 0 | 1.091 | 1.254 | 2.543 |
| [BLIPS] v4 PNP | 3.524 | 1.670 | 1.854 | 0 | 307 | 356 | 962 |
| [IDEAL] v4 PNP | 1.940 | 934 | 1.006 | 0 | 138 | 187 | 579 |
| Negativação Serasa >6 / 31 dias | 531 | 0 | 0 | 531 | 335 | 370 | 531 |
| Negativação Serasa ≤6 / 15 dias | 133 | 0 | 0 | 133 | 117 | 133 | 133 |

### 3.4 Criação vs envio

Ver §3.1. Pontos de leitura:

- A criação roda **todos os dias** (cron `30 7 * * *`); o envio só em `active_days` (seg–sex) na janela 08:00–18:00. Daí as **69.742 ações** (15,7% do total) enviadas em dia posterior ao da criação.
- Abril tem defasagem máxima de **19 dias** e maio de **5** — outliers de retentativa/janela, não regra.
- Os 77.236 cancelamentos são majoritariamente `Cancelado (Pago)` — o `scheduled-action-processor` checa pagamento antes de enviar. É a rede de proteção que existe **no envio** (não na criação) contra dado defasado.

### 3.5 Deduplicação: quantas mensagens um contato recebe por dia

Esta é a resposta direta à pergunta levantada no e-mail ("*se disparamos por título, quando o cliente vence 2, 3 ou mais boletos ele recebe 2, 3 ou mais comunicações simultaneamente?*").

| Mês | Contato-dias | Média de ações por contato/dia | Máx. total | Contato-dias com ≥2 WhatsApp | % | Máx. WA no mesmo dia | Máx. e-mail no mesmo dia |
|---|---:|---:|---:|---:|---:|---:|---:|
| fev | 32.137 | 1,93 | 10 | 1.385 | 4,31% | 5 | 6 |
| mar | 39.145 | 1,78 | 7 | 3.716 | 9,49% | 4 | 4 |
| abr | 56.099 | 1,45 | 10 | 1.456 | 2,60% | 6 | 4 |
| mai | 50.150 | 1,82 | 10 | 2.006 | 4,00% | 5 | 5 |
| jun | 48.913 | 1,60 | 6 | 661 | 1,35% | 3 | 3 |
| **jul** | **34.323** | **1,66** | **4** | **610** | **1,78%** | **2** | **2** |

**Leitura:** a dedup por (contato × canal × integração) está efetiva. A média de ~1,5–1,9 ações/contato/dia corresponde ao par WhatsApp + e-mail do mesmo degrau, não a múltiplas cobranças do mesmo canal. Os casos de ≥2 WhatsApp no mesmo dia (1,35%–9,49%) ocorrem quando há **integrações distintas** ou **campanhas distintas** envolvidas — a chave de dedup inclui `integration_id`. A tendência é de queda consistente (9,49% em março → 1,78% em julho).

### 3.6 Funil do Pipeline v2 (`campaign_execution_runs`)

| Mês | Runs | Contatos elegíveis (Σ) | Títulos expandidos | Casaram step | % que casou | Após dedup por integração | Após regras | Após cross-dedup | Ações criadas |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| mar | 26 | 94.198 | 521.019 | 83.737 | **16,1%** | 55.327 | 56.980 ⚠ | 47.291 | 47.291 |
| abr | 59 | 188.554 | 486.479 | 137.241 | **28,2%** | 92.902 | 91.957 | 91.957 | 91.957 |
| mai | 36 | 135.772 | 356.215 | 111.988 | **31,4%** | 83.844 | 83.282 | 83.282 | 83.282 |
| jun | 30 | 119.748 | 321.205 | 104.640 | **32,6%** | 76.099 | 75.313 | 75.313 | 75.313 |
| jul | 28 | 96.627 | 329.854 | 86.586 | **26,3%** | 59.107 | 57.771 | 57.771 | 57.771 |

⚠ Em março `matches_after_rules` (56.980) > `matches_after_integration_dedup` (55.327) — inconsistência de contador no período de transição v1→v2. Os contadores de `skipped_*` também estão parcialmente zerados a partir de abril (o pipeline v2 não popula `skipped_blocklist_breakdown` e alguns contadores no mesmo grão do v1). **A limitação é de telemetria, não de comportamento**: `actions_created` fecha com a contagem real da tabela `actions` em todos os meses.

Duas leituras quantitativas importantes:

1. **Apenas 16%–33% dos títulos avaliados casam algum step.** Em julho: 329.854 títulos expandidos → 86.586 casaram (26,3%). Os ~73% restantes recebem `no_step_match` — o atraso deles não caiu em nenhum degrau naquele dia.
2. **A dedup por integração descarta ~32% dos que casaram.** Julho: 86.586 → 59.107 (−27.479). São títulos que casaram um degrau mas perderam para outro título **mais atrasado** do mesmo contato/canal. Aqui o "maior atraso" funciona — mas só entre os que casaram.

### 3.7 Deduplicação e bloqueios registrados (`skipped_actions_log`)

Log do motor v1 (o pipeline v2 registra em `campaign_execution_candidates`, com retenção de ~3 dias — ver §5.3):

| Mês | Motivo | Ocorrências | Contatos | Títulos |
|---|---|---:|---:|---:|
| fev | `duplicate_step` | 387.655 | 723 | 764 |
| fev | `cooldown_active` | 57.160 | 441 | 430 |
| mar | `cooldown_active` | 893.314 | 4.069 | 6.113 |
| mar | `duplicate_step` | 323.435 | 3.740 | 5.628 |
| abr | `cooldown_active` | 193.844 | 840 | 899 |
| abr | `duplicate_step` | 6.314 | 396 | 406 |
| mai | `cooldown_active` | 28.427 | 3.899 | 4.659 |
| mai | `duplicate_step` | 462 | 103 | 106 |

Total 1.890.611 avaliações barradas. A queda abrupta a partir de abril é a migração para o pipeline v2 (que não escreve nesta tabela) — não uma redução de dedup.

---

## 4. Validação cruzada: a ação saiu no título mais atrasado?

### 4.1 Método

Para cada ação de comunicação com `title_id` (excluindo `is_test`), reconstruí o estado da carteira **na data em que a ação foi criada** (`d_ref` = `created_at` em BRT):

```sql
-- universo do contato em d_ref: títulos já vencidos e abertos naquela data
WHERE t.due_date <= d_ref                                        -- já vencido
  AND (t.payment_date IS NULL OR t.payment_date  > d_ref)        -- não pago então
  AND (t.removed_at   IS NULL OR t.removed_at::date > d_ref)     -- não removido então
  AND t.created_at::date <= d_ref                                -- linha já existia
```

Deste universo derivei, por (contato, dia) e por (contrato, dia), o `max(d_ref - due_date)` = **maior atraso real**. Comparei com o atraso do título que efetivamente gerou a ação (`d_ref - due_date` do `title_id`) e com o degrau registrado em `metadata.days_overdue`.

Também classifiquei se o **maior atraso** do contato caía num degrau da régua daquele dia (`= ANY(escada)`).

### 4.2 Resultado mensal — `org_blips`, comunicação (WhatsApp/e-mail/SMS)

| Mês | Ações c/ título | Preventivas (atraso ≤ 0) | Vencidas (atraso > 0) | = maior atraso do **contato** | = maior atraso do **contrato** | < maior atraso do contato | Sem universo¹ |
|---|---:|---:|---:|---:|---:|---:|---:|
| fev | 60.068 | 23.973 | 36.095 | 14.535 (40,3%) | 15.085 (41,8%) | 15.898 (44,0%) | 5.306 |
| mar | 60.885 | 15.709 | 45.176 | 20.744 (45,9%) | 21.482 (47,6%) | 21.264 (47,1%) | 2.951 |
| abr | 81.255 | 29.082 | 52.173 | 21.860 (41,9%) | 22.749 (43,6%) | 27.787 (53,3%) | 2.200 |
| mai | 91.078 | 21.075 | 70.003 | 30.713 (43,9%) | 31.827 (45,5%) | 30.342 (43,3%) | 7.826 |
| jun | 78.096 | 32.790 | 45.306 | 21.300 (47,0%) | 22.427 (49,5%) | 22.322 (49,3%) | 1.466 |
| jul | 57.107 | 20.201 | 36.906 | 15.300 (41,5%) | 16.225 (44,0%) | 20.992 (56,9%) | 521 |
| **Total** | **428.489** | **142.830** | **285.659** | **124.452 (43,6%)** | **129.795 (45,4%)** | **138.605 (48,5%)** | **20.270** |

¹ *Sem universo* = o próprio título da ação não aparece no universo reconstruído (tipicamente porque hoje ele carrega `payment_date` **anterior** à data da ação — ver §6.1). Há também um resíduo pequeno (0,2%–1,6%/mês) em que o atraso do título da ação é **maior** que o máximo reconstruído, pela mesma causa.

### 4.3 Quando houve gap, existia degrau no maior atraso?

Recorte sobre as ações da coluna "< maior atraso do contato":

| Mês | Ações com gap | Maior atraso **tinha** degrau | % | Maior atraso **NÃO tinha** degrau | % | Gap médio (dias) | Gap mediano |
|---|---:|---:|---:|---:|---:|---:|---:|
| fev | 15.898 | 1.115 | 7,0% | **14.783** | **93,0%** | 97,4 | 62 |
| mar | 21.264 | 1.287 | 6,1% | **19.977** | **93,9%** | 95,8 | 61 |
| abr | 27.787 | 613 | 2,2% | **27.174** | **97,8%** | 102,7 | 61 |
| mai | 30.342 | 972 | 3,2% | **29.370** | **96,8%** | 107,2 | 62 |
| jun | 22.322 | 543 | 2,4% | **21.779** | **97,6%** | 123,2 | 75 |
| jul | 20.992 | 508 | 2,4% | **20.484** | **97,6%** | 121,7 | 80 |
| **Total** | **138.605** | **5.038** | **3,6%** | **133.567** | **96,4%** | — | — |

**Leitura:** em **96,4%** dos casos em que a ação saiu num título menos atrasado que o pior do cliente, **não existia step configurado no dia de atraso do pior título**. Ou seja: mesmo se o motor decidisse "cobre sempre o mais atrasado", em 96% desses casos ele não teria mensagem para enviar naquele dia — a régua não tem degrau ali.

*Ressalva metodológica:* a escada usada como referência é a **v4** (estável desde 06/04/2026). Para fev–mar a régua vigente era a **v2**, cuja escada difere em 4 degraus (`15/30/45/60` vs `13/31/46/61`), e havia réguas com teto D+25 e D+55. Os percentuais de fev–mar têm, portanto, margem de erro de alguns pontos; abr–jul são exatos.

### 4.4 O motivo raiz, medido na carteira: a escada não alcança o estoque

Snapshot de **14/07/2026** — todos os títulos vencidos, abertos e cobráveis (`status IN ('Disponivel','Expirado','Recomprado')`) em `org_blips`:

| Métrica | Valor |
|---|---:|
| Títulos vencidos abertos e cobráveis | **10.045** |
| … cujo atraso coincidia com um degrau da régua naquele dia | **659 (6,6%)** |
| … com atraso **acima do teto D+110** | **5.259 (52,4%)** |
| Contatos com pelo menos 1 título vencido | **1.821** |
| … cujo título de **maior atraso** estava num degrau | **113 (6,2%)** |
| … cujo maior atraso estava **acima de D+110** | **1.014 (55,7%)** |
| … que **não tinham nenhum** título vencido num degrau | **1.351 (74,2%)** |
| Média de títulos vencidos por contato | **5,5** |
| Máximo de títulos vencidos num contato | **166** |
| Maior atraso observado na carteira | **880 dias** |

Isto quantifica o teto estrutural: num dia típico, **6,2% dos clientes inadimplentes** poderiam receber uma mensagem casada com o seu maior atraso. Nos demais 93,8%, o maior atraso está num dia sem degrau ou além de D+110 — e a régua, como está configurada, não tem o que enviar para aquele atraso.

**Caso concreto** (contato real, 14/07/2026, 13 contratos parcelados): 166 títulos vencidos abertos, atrasos de **29 a 394 dias** — `394, 364, 333, 302, 272, 241, 211, 180, 149, 146, 121, 90, 60, 29`. **Nenhum** desses valores é degrau da régua (o mais próximo, 90, fica entre os degraus 87 e 91; e o teto é 110). Resultado: nenhum dos 166 títulos vencidos gerou ação naquele dia. A única comunicação que o contato recebeu foi disparada por um título **ainda a vencer**, num step **preventivo**.

Esse padrão aparece agregado na tabela cruzada abaixo: em julho, **4.252 ações preventivas** (step D-x/D0) foram para contatos que já tinham título vencido — incluindo **664** cujo maior atraso passava de 180 dias.

### 4.5 Tabela cruzada — step disparado × maior atraso real do contato (julho/2026)

`org_blips`, comunicação WhatsApp+e-mail, apenas ações cujo contato já tinha algum título vencido (**40.600 ações**):

| Step disparado ↓ / Maior atraso real → | 1–15 | 16–30 | 31–60 | 61–90 | 91–180 | 180+ | **Total** |
|---|---:|---:|---:|---:|---:|---:|---:|
| **preventivo (D-x / D0)** | 590 | 1.312 | 622 | 512 | 552 | 664 | **4.252** |
| **D+1–15** | **9.006** | 295 | 1.785 | 1.286 | 913 | 924 | **14.209** |
| **D+16–30** | 7 | **2.289** | 1.043 | 834 | 841 | 1.033 | **6.047** |
| **D+31–60** | 11 | — | **1.970** | 1.082 | 1.277 | 1.417 | **5.757** |
| **D+61–90** | — | 8 | 4 | **1.641** | 1.818 | 1.888 | **5.359** |
| **D+91+** | 2 | — | 2 | — | **2.589** | 2.383 | **4.976** |
| **Total** | **9.616** | **3.904** | **5.426** | **5.355** | **7.990** | **8.309** | **40.600** |

Diagonal (faixa do step = faixa do atraso real): **17.495 = 43,1%**. Acima da diagonal (step mais brando que o atraso real): **~55%**. Abaixo da diagonal (step mais severo que o atraso real): **34 ações = 0,08%** — praticamente inexistente, e explicável pelo resíduo de dado defasado (§6.1).

Isto reproduz, com dados de produção, a mesma assimetria mostrada na tabela anexada ao e-mail: o desvio é **sempre no sentido de subcobrar** (mensagem mais branda do que o atraso real), nunca de sobrecobrar.

### 4.6 Reconciliação com os números do e-mail

O e-mail de 28/07 apresenta, por mês, "ações para clientes vencidos" e quantas foram "indevidas" (step ≠ atraso real). Reproduzi a métrica com a definição mais próxima possível: ações de comunicação criadas no mês, cujo **contato** tinha ao menos um título vencido naquela data, e o atraso do título da ação ≠ maior atraso do contato.

| Mês | E-mail: ações p/ clientes vencidos | E-mail: indevidas | E-mail % | Auditoria: ações p/ contato vencido | Auditoria: step ≠ maior atraso | Auditoria % |
|---|---:|---:|---:|---:|---:|---:|
| fev | 39.689 | 20.111 | 50,7% | 37.627 | 23.092 | 61,4% |
| mar | 42.609 | 22.266 | 52,3% | 44.791 | 24.047 | 53,7% |
| abr | 50.024 | 30.981 | 61,9% | 56.597 | 34.737 | 61,4% |
| mai | 56.997 | 36.684 | 64,4% | 67.101 | 36.388 | 54,2% |
| jun | 53.228 | 35.184 | 66,1% | 50.280 | 28.980 | 57,6% |
| jul | 39.652 | 26.346 | 66,4% | 40.600 | 25.300 | 62,3% |
| **Total** | **282.199** | **171.572** | **60,8%** | **296.996** | **172.544** | **58,1%** |

**Conclusão da reconciliação:** o volume absoluto de casos divergentes fecha com **0,6% de diferença** (171.572 vs 172.544). Os denominadores mensais divergem em até 18% (definições diferentes de "cliente vencido" e do recorte por status/tipo de ação), o que redistribui os percentuais mês a mês, mas **o achado do e-mail está confirmado em magnitude, direção e ordem de grandeza**. A auditoria não contesta o número; ela identifica o mecanismo que o produz (§4.3, §4.4) e o que dele é configuração de régua versus comportamento de motor.

---

## 5. É possível saber, retroativamente, qual título "deveria" ter sido cobrado?

Resposta curta: **sim, para o atraso e a elegibilidade — com alta confiança. Não, para a transição de status antes de 28/06/2026.**

### 5.1 O que É reconstruível (e por quê)

| Dado | Por que é reconstruível | Verificação feita |
|---|---|---|
| **Atraso de qualquer título em qualquer data passada** | `titles.due_date` é imutável e nenhum título referenciado por ação de 2026 foi perdido | **0 títulos órfãos** entre os **39.026** `title_id` distintos referenciados por **434.410** ações de 2026 |
| **Se o título estava pago naquela data** | `payment_date` é uma **data**, não um flag: `payment_date > d_ref` ⇒ estava aberto | 28.843 títulos `Pago`, todos com `payment_date` preenchida |
| **Se o título estava removido naquela data** | `removed_at` é timestamp | 8.657 `Removido`, 8.649 com `removed_at` |
| **Se o título já existia na base** | `titles.created_at` (preservado no upsert do ETL: `row_min` = 28/01/2026 para todos os status, data da carga inicial) | permite reconstruir *o que o motor podia ver*, não só *o que era verdade* |
| **Qual degrau casou** | `actions.metadata.days_overdue`, gravado por `create_actions` | presente em 99,9% das ações (18.930 de 18.956 na amostra `org_finza`) |
| **Qual step/régua/campanha** | `actions.workflow_step_id` → `workflow_steps.workflow_id`; `actions.campaign_id` | integridade total nas junções usadas em §3.3 |
| **A escada vigente na data** | `workflow_audit_logs` (`step_added`/`step_updated`/`step_deleted`) + `workflow_steps.created_at`/`updated_at` | v4 criada 30–31/03, última alteração de step **06/04/2026** ⇒ escada **estável** de abr a jul |

Isso é exatamente o que sustenta §4.2–§4.5: para cada ação passada é possível dizer, com evidência, qual era o maior atraso do cliente e do contrato naquele dia, e se existia degrau para ele.

### 5.2 O que NÃO é reconstruível

| Limitação | Impacto | Magnitude |
|---|---|---|
| **`title_status_history` só existe desde 28/06/2026** (7.839 linhas, primeiro registro 28/06 09:00) | Não se sabe **quando** um título transitou entre `Disponivel` → `Expirado` → `Recomprado` → `Aguardando Cancelamento`. | **Baixo para o cálculo de atraso**: os 3 primeiros são todos cobráveis, então a transição entre eles não muda elegibilidade. **Não reconstruível** para `Aguardando Cancelamento`/`Aguardando Recompra` (255 títulos hoje). |
| **`payment_date` registrada retroativamente** | Um pagamento lançado depois, com data anterior à ação, faz o título parecer "já pago" na reconstrução — mas não se sabe se o ETL sabia disso na hora. | 27.251 ações fev–jul (§6.1). É a causa da coluna "Sem universo" da §4.2. |
| **Retenção de `campaign_execution_candidates` ≈ 3 dias** (5.362 linhas, 26–28/07, 3 runs) | Não existe o registro título-a-título de `no_step_match` / `dedup_integration` / `excluded_*` dos meses passados. | Contornado pelos **agregados** de `campaign_execution_runs`, que cobrem mar–jul (§3.6). |
| **Mudança da regra de status cobrável em 14/06/2026** (#3856: lista negra → lista branca `Disponivel/Expirado/Recomprado`) | Antes de 14/06 a elegibilidade era mais ampla (entrava tudo menos `Pago`/`Cancelado`/`Removido`). | Afeta o denominador de fev a 13/06 de forma marginal (os status extra somam 255 títulos hoje). |
| **Escada da régua v2 (fev–mar)** | Reconstruí a escada v2 (§2.3) mas apliquei a v4 como referência no flag "tinha degrau" das §4.3. | Margem de alguns pontos percentuais **só em fev–mar**. Abr–jul exatos. |
| **Texto exato da mensagem enviada** | `actions.content` guarda o corpo, mas templates Meta resolvem no provedor. | Não afeta nenhuma métrica deste documento. |

### 5.3 Conclusão operacional

Para responder "*este disparo de dois meses atrás deveria ter sido nesse título?*", o caminho é:

1. `actions.metadata.days_overdue` → o degrau que casou;
2. `titles.due_date` do `title_id` → confirma o atraso do título cobrado;
3. reconstrução do universo do contato/contrato com o predicado da §4.1 → maior atraso real na data;
4. escada da régua vigente (`workflow_steps` + `workflow_audit_logs`) → existia degrau naquele atraso?

Os passos 1–3 são exatos. O passo 4 é exato de **06/04/2026** em diante, e aproximado antes disso. A única fonte de ruído material é o item "payment_date retroativa" (§6.1), que afeta ~6,4% das ações do período e é **identificável linha a linha** — ou seja, pode ser segregada em qualquer análise, não precisa ser tolerada como erro cego.

---

## 6. Achados colaterais

### 6.1 Ações criadas para títulos cuja `payment_date` é anterior à ação

| Mês | Ações | % das comunicações | Títulos já removidos na data |
|---|---:|---:|---:|
| fev | 6.491 | 10,8% | 546 |
| mar | 3.335 | 5,5% | 671 |
| abr | 3.439 | 4,2% | 308 |
| mai | 10.024 | 11,0% | 1.304 |
| jun | 2.538 | 3,2% | 347 |
| jul | 1.424 | 2,5% | 229 |
| **Total** | **27.251** | **6,4%** | **3.405** |

Duas leituras possíveis, ambas compatíveis com os dados: (a) o título já estava pago e a base estava defasada no momento do disparo; (b) o pagamento foi registrado depois com data retroativa. As duas são indistinguíveis sem `title_status_history` (§5.2). A tendência é claramente de melhora (10,8% em fev → 2,5% em jul). Vale registrar que a rede de proteção do **envio** (`payment_check_url` + status no banco) cancela parte desses casos antes de sair — é o que explica os 77.236 `Cancelado` da §3.1.

### 6.2 Divergência entre `metadata.days_overdue` e o atraso recalculado

| Mês | Ações com divergência | % |
|---|---:|---:|
| fev | 7.838 | 13,0% |
| mar | 1.065 | 1,7% |
| abr | 3.732 | 4,6% |
| mai | 8.583 | 9,4% |
| jun | 3.339 | 4,3% |
| **jul** | **54** | **0,09%** |

Divergência = `metadata.days_overdue` ≠ (`created_at`::date − `due_date`). Compatível com ações **diferidas** (`deferred_at`, `original_days_overdue`, `original_title_id` existem na tabela) e com criações que atravessam a meia-noite. A queda para 0,09% em julho sugere que a causa foi endereçada; não investiguei a raiz porque está fora do escopo deste card.

### 6.3 Ausência de step de "cauda"

Não existe, em nenhuma régua de 2026, step com `days_overdue_trigger = {min: 110, max: null}` — ou seja, nenhum degrau do tipo "110 ou mais". Como **52,4%** do estoque vencido está acima de D+110 (§4.4), essa faixa da carteira não é endereçada por régua. O motor **suporta** esse formato (Formato 1 com `max=null`, §2.1); ele apenas não está configurado.

---

## 7. `org_finza` — a operação Finza desde a migração

Ações **exclusivas** de `org_finza` (excluindo as 10.707 copiadas de `org_blips` na migração), comunicação com `title_id`:

| Mês | Ações | Preventivas | Vencidas | Ações p/ contato vencido | Step ≠ maior atraso | % | = maior atraso contato | = maior atraso contrato | Contatos | Contratos | Títulos |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| jun/26 | 2.883 | 945 | 1.938 | 2.095 | 868 | **41,4%** | 1.227 (63,3%) | 1.246 (64,3%) | 368 | 392 | 553 |
| jul/26 | 5.180 | 1.828 | 3.352 | 3.662 | 1.768 | **48,3%** | 1.894 (56,5%) | 1.952 (58,2%) | 530 | 577 | 933 |

A aderência é **melhor** que em `org_blips` (56%–63% das ações vencidas casam o maior atraso do contato, contra 41%–47%). A explicação estrutural: a carteira Finza é menor e menos fragmentada (1,6–1,8 títulos vencidos por contato-ação contra 5,5 em `org_blips`), então a chance de o título mais atrasado cair num degrau é maior. Mesma régua, mesmo motor, resultado diferente — o que reforça que o driver do desvio é a **distribuição da carteira contra a escada**, não o motor.

---

## 8. Síntese: a cadeia causal completa

```
1. resolve_contacts   → elegibilidade é por CONTATO (filtro da régua)
                             │
2. fetch_titles       → expande TODOS os títulos cobráveis de TODOS os
                        contratos do contato  (grão vira TÍTULO)
                             │
3. match_titles 3a    → casa days_overdue com o step em DIA EXATO
                        escada: 20 degraus WA / 27 e-mail, teto D+110
                        ⇒ na carteira de 14/07: só 6,6% dos títulos
                          vencidos estavam num degrau; 52,4% acima do teto
                             │
   match_titles 3b    → dedup mantém o de MAIOR days_overdue
                        ENTRE OS QUE CASARAM  ← ponto crítico
                             │
4. apply_rules R4     → exclui o menor quando o maior JÁ gerou ação hoje.
                        Não promove o maior quando ele não casou step.
                             │
5. cross_dedup        → 1 por contato × canal × integração entre campanhas
                             │
6. create_actions     → grava metadata.days_overdue = o degrau que casou
```

**O resultado observado é a composição de (3) com (3b):** como a escada cobre ~6% dos atrasos presentes na carteira num dia qualquer, o "maior atraso" que a dedup elege é o maior **entre os poucos que caíram num degrau** — tipicamente uma parcela recente. O título de 394 dias nunca entra na disputa, porque nunca casa um step.

Em números fechados do período fev–jul/2026, `org_blips`, comunicação:

- **428.489** ações com título; **285.659** para títulos já vencidos
- **124.452 (43,6%)** dessas saíram no título de maior atraso do contato; **129.795 (45,4%)** no de maior atraso do contrato
- **138.605 (48,5%)** saíram num título menos atrasado que o pior do cliente
- dessas, **133.567 (96,4%)** tinham o pior título num dia **sem degrau** na régua
- desvio **sempre** no sentido de subcobrar: apenas **0,08%** das ações de julho usaram step mais severo que o atraso real

---

## Apêndice A — Glossário

| Termo | Definição operacional |
|---|---|
| **Régua** (`workflows`) | Coleção de steps + filtro de atribuição. Define *quem* entra e *o que* dispara. |
| **Step** (`workflow_steps`) | Uma ação configurada para um dia de atraso específico, com canal, integração e mensagem. |
| **Degrau** | O valor de `config.days_overdue` de um step. Sinônimo de "dia de disparo". |
| **Campanha** (`campaigns`) | Agendador: quando o motor roda, qual régua, janela de envio, cooldown. |
| **`days_overdue`** | `CURRENT_DATE − due_date`. Aceita negativo (cobrança preventiva). |
| **Cobrável** | `status IN ('Disponivel','Expirado','Recomprado')` **e** `removed_at IS NULL` **e** `payment_date IS NULL` (whitelist desde 14/06/2026). |
| **Cooldown** | Janela (24h nas campanhas de régua) em que o mesmo contato não recebe o mesmo canal+integração de novo. |
| **Dedup por integração** | `match_titles` 3b: 1 candidato por (contato, tipo, integração), o de maior atraso entre os que casaram step. |
| **Cross-dedup** | Etapa 5: mesma regra, mas entre **todas** as campanhas do run. |
| **Maior atraso real** | `max(d_ref − due_date)` entre os títulos do contato/contrato abertos e vencidos naquela data (reconstruído — §4.1). |
| **Gap** | `maior atraso real − atraso do título que gerou a ação`. |

## Apêndice B — Queries usadas

Todas executadas em produção, somente leitura, via MCP `supabase-prod`.

**B.1 Reconstrução retroativa do maior atraso (núcleo da §4)**

```sql
WITH acts AS (
  SELECT a.id, a.contact_id, a.contract_id, a.title_id, a.action_type,
         (a.created_at AT TIME ZONE 'America/Sao_Paulo')::date AS d_ref,
         (a.metadata->>'days_overdue')::int AS md
  FROM org_blips.actions a
  WHERE a.created_at >= :ini AND a.created_at < :fim
    AND a.title_id IS NOT NULL
    AND coalesce(a.metadata->>'is_test','') <> 'true'
    AND a.action_type IN ('send_whatsapp','send_email','send_sms','send_voice',
                          'send_rcs','whatsapp','email','sms')),
pares AS (SELECT DISTINCT contact_id, d_ref FROM acts),
base AS (
  SELECT p.contact_id, p.d_ref, t.contract_id, (p.d_ref - t.due_date) AS atraso
  FROM pares p
  JOIN org_blips.contracts c ON c.contact_id = p.contact_id
  JOIN org_blips.titles    t ON t.contract_id = c.id
  WHERE t.due_date <= p.d_ref
    AND (t.payment_date IS NULL OR t.payment_date > p.d_ref)
    AND (t.removed_at IS NULL
         OR (t.removed_at AT TIME ZONE 'America/Sao_Paulo')::date > p.d_ref)
    AND (t.created_at AT TIME ZONE 'America/Sao_Paulo')::date <= p.d_ref),
mx  AS (SELECT contact_id, d_ref,              max(atraso) AS max_ct FROM base GROUP BY 1,2),
mxc AS (SELECT contact_id, d_ref, contract_id, max(atraso) AS max_cc FROM base GROUP BY 1,2,3)
SELECT count(*)                                                        AS total,
       count(*) FILTER (WHERE (a.d_ref-t.due_date) <= 0)               AS preventivas,
       count(*) FILTER (WHERE (a.d_ref-t.due_date) >  0)               AS vencidas,
       count(*) FILTER (WHERE mx.max_ct > 0)                           AS acoes_contato_vencido,
       count(*) FILTER (WHERE mx.max_ct > 0
                          AND (a.d_ref-t.due_date) <> mx.max_ct)       AS step_dif_max,
       count(*) FILTER (WHERE (a.d_ref-t.due_date) = mx.max_ct)        AS eh_max_contato,
       count(*) FILTER (WHERE (a.d_ref-t.due_date) = mxc.max_cc)       AS eh_max_contrato
FROM acts a
JOIN org_blips.titles t ON t.id = a.title_id
LEFT JOIN mx  ON mx.contact_id=a.contact_id  AND mx.d_ref=a.d_ref
LEFT JOIN mxc ON mxc.contact_id=a.contact_id AND mxc.d_ref=a.d_ref
             AND mxc.contract_id=a.contract_id;
```

**B.2 Escada real da régua, por canal**

```sql
SELECT s.step_type,
       string_agg(DISTINCT (s.config->>'days_overdue'), ','
                  ORDER BY (s.config->>'days_overdue')) AS degraus,
       count(*) AS steps
FROM org_blips.workflow_steps s
WHERE s.workflow_id = 'a07e185c-40cc-4ccb-bf0e-ad47d3734a2f'
  AND s.is_active AND s.config ? 'days_overdue'
GROUP BY 1;
```

**B.3 Cobertura da escada contra a carteira (§4.4)**

```sql
WITH snap AS (
  SELECT c.contact_id, ('2026-07-14'::date - t.due_date) AS atraso
  FROM org_blips.contracts c JOIN org_blips.titles t ON t.contract_id = c.id
  WHERE t.status IN ('Disponivel','Expirado','Recomprado')
    AND t.due_date <= '2026-07-14'
    AND (t.payment_date IS NULL OR t.payment_date > '2026-07-14')
    AND (t.removed_at IS NULL
         OR (t.removed_at AT TIME ZONE 'America/Sao_Paulo')::date > '2026-07-14')
    AND (t.created_at AT TIME ZONE 'America/Sao_Paulo')::date <= '2026-07-14'),
flag AS (SELECT contact_id, atraso,
                atraso = ANY(ARRAY[0,3,5,8,11,13,16,20,23,25,31,35,40,46,50,55,
                                   61,65,70,75,80,85,87,91,96,99,102,110]) AS em_degrau
         FROM snap),
porc AS (SELECT contact_id, count(*) AS n, max(atraso) AS max_at,
                bool_or(em_degrau) AS tem_algum_em_degrau,
                max(atraso) = ANY(ARRAY[0,3,5,8,11,13,16,20,23,25,31,35,40,46,50,55,
                                        61,65,70,75,80,85,87,91,96,99,102,110]) AS max_em_degrau
         FROM flag GROUP BY 1)
SELECT (SELECT count(*) FROM flag)                                  AS titulos_vencidos_abertos,
       (SELECT count(*) FROM flag WHERE em_degrau)                  AS titulos_em_degrau,
       (SELECT count(*) FROM flag WHERE atraso > 110)               AS titulos_acima_teto,
       count(*)                                                     AS contatos_com_vencido,
       count(*) FILTER (WHERE max_em_degrau)                        AS contatos_max_em_degrau,
       count(*) FILTER (WHERE max_at > 110)                         AS contatos_max_acima_teto,
       count(*) FILTER (WHERE NOT tem_algum_em_degrau)              AS contatos_sem_degrau,
       round(avg(n),1) AS media_titulos, max(n) AS max_titulos, max(max_at) AS max_atraso
FROM porc;
```

**B.4 Verificação de integridade histórica dos títulos (§5.1)**

```sql
SELECT count(DISTINCT a.title_id)                              AS titles_referenciados,
       count(DISTINCT a.title_id) FILTER (WHERE t.id IS NULL)  AS titles_orfaos,
       count(*)                                                AS acoes_com_title_id
FROM org_blips.actions a
LEFT JOIN org_blips.titles t ON t.id = a.title_id
WHERE a.created_at >= '2026-01-01' AND a.created_at < '2026-08-01'
  AND a.title_id IS NOT NULL;
-- resultado: 39.026 / 0 / 434.410
```

**B.5 Definição das RPCs em produção (fonte de verdade do §1)**

```sql
WITH f AS (SELECT pg_get_functiondef(p.oid) AS def
           FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public'
             AND p.proname = 'campaign_pipeline_match_titles'),  -- e apply_rules, cross_dedup
     l AS (SELECT row_number() OVER () AS ln, line
           FROM f, unnest(string_to_array(def, E'\n')) AS line)
SELECT ln, line FROM l
WHERE line ~* '(days_overdue_trigger|trigger_day|ORDER BY|PARTITION BY|Rule [0-9])'
ORDER BY ln;
```

**B.6 Sobreposição entre schemas (§3.0)**

```sql
SELECT to_char(f.created_at AT TIME ZONE 'America/Sao_Paulo','YYYY-MM') AS mes,
       count(*) AS total_finza, count(b.id) AS copiadas_de_blips,
       count(*) - count(b.id) AS exclusivas_finza
FROM org_finza.actions f
LEFT JOIN org_blips.actions b ON b.id = f.id
WHERE f.created_at >= '2026-01-01' AND f.created_at < '2026-08-01'
GROUP BY 1 ORDER BY 1;
```

Demais queries (funil `campaign_execution_runs`, volume por régua/campanha, ações por contato/dia, `skipped_actions_log`, volume por degrau, `workflow_audit_logs`) seguem o mesmo padrão de agregação direta sobre as tabelas citadas em cada seção.

---

## Log de alterações
- 2026-07-28 — criado
