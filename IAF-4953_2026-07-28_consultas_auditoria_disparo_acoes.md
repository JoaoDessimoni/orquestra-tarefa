# IAF-4953 — Consultas da auditoria de disparo de ações (step × atraso real)

**Companheiro de:** `IAF-4953_2026-07-28_auditoria_disparo_acoes_2026_step_vs_atraso_real.md`
**Data:** 28/07/2026
**Ambiente:** produção `idinihcyezkqfarztrdx`, schemas `org_blips` e `org_finza`, via MCP `supabase-prod` (somente leitura)
**Período:** 01/02/2026 – 28/07/2026

## Como ler este arquivo

Cada bloco abaixo é uma etapa da apuração, na **ordem em que a investigação foi feita** — do entendimento do mecanismo (o que o código faz) até a medição do efeito (o que os dados mostram). Para cada consulta:

- **Objetivo** — a pergunta que a query responde.
- **Query** — o SQL.
- **Campos validados** — quais colunas/predicados sustentam o número.
- **Como foi apurado** — o raciocínio de contagem/junção.
- **Perspectiva** — o que o resultado permite (e não permite) concluir.

> **Procedência das queries.** As marcadas **[verbatim]** estão transcritas literalmente do Apêndice B da auditoria. As marcadas **[reconstruída]** foram remontadas a partir do método descrito no corpo do documento (a auditoria registra que "demais queries seguem o mesmo padrão de agregação direta sobre as tabelas citadas em cada seção"). O resultado numérico das reconstruídas é o que está publicado nas tabelas da auditoria; o SQL abaixo é a forma canônica desse padrão, não necessariamente o texto exato executado.

---

## Etapa 0 — Fonte de verdade: o que o motor faz de fato

### Q0.1 — Definição das RPCs do Pipeline v2 em produção **[verbatim — B.5]**

**Objetivo:** ler a lógica de decisão direto do catálogo do Postgres, não de `.md`/código local. É o que sustenta todo o §1 (as 6 RPCs) e o §2.1 (os 3 formatos de gatilho).

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

- **Campos validados:** `pg_proc.proname`, `pg_namespace.nspname='public'`, corpo retornado por `pg_get_functiondef`.
- **Como foi apurado:** roda a mesma consulta para `campaign_pipeline_match_titles`, `campaign_pipeline_apply_rules` e `campaign_pipeline_cross_dedup`, filtrando as linhas com as palavras-chave do matching e da dedup. Extrai literalmente o `PARTITION BY contact_id, action_type, COALESCE(integration_id,…), CASE WHEN action_type IN ('negativation','notification') THEN contract_id END ORDER BY days_overdue DESC, id` e a `Rule 4` (`metadata->>'days_overdue' > c.days_overdue`).
- **Perspectiva:** prova documental de que (a) o motor decide **por título**, (b) "maior atraso" é **desempate entre os que já casaram um step** (`WHERE disposition='matched'`), nunca critério de seleção, e (c) a dedup é por contato no canal e por contrato em neg/notif. É a base causal de toda a auditoria (§1.3, §8).

---

## Etapa 1 — A régua: qual é a escada real

### Q1.1 — Escada de cada régua, por canal **[verbatim — B.2]**

**Objetivo:** listar os degraus (`config.days_overdue`) de cada canal da régua vigente. Sustenta o §2.3 (24 degraus WA / 31 e-mail, teto D+110).

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

- **Campos validados:** `workflow_steps.step_type` (canal), `config->>'days_overdue'` (degrau), `is_active`, `config ? 'days_overdue'` (tem gatilho de dia exato).
- **Como foi apurado:** agrega degraus distintos por canal, ordenados. Repetido por `workflow_id` de cada régua (v4, v2, Locação v1, Venda v1) para montar a comparação de escadas do §2.3.
- **Perspectiva:** confirma que a escada é discreta e finita — termina em D+110 e não tem step "110 ou mais". É a régua contra a qual se mede a carteira depois (§4.4).

### Q1.2 — Formato de gatilho de cada step (dia exato vs faixa) **[reconstruída — §2.1]**

**Objetivo:** provar que 100% do matching de 2026 rodou em **igualdade estrita** (Formato 2), porque `days_overdue_trigger` é NULL em todos os steps.

```sql
SELECT s.workflow_id,
       count(*)                                                      AS steps,
       count(*) FILTER (WHERE s.config ? 'days_overdue_trigger')     AS com_faixa,
       count(*) FILTER (WHERE NOT (s.config ? 'days_overdue_trigger')
                          AND s.config ? 'days_overdue')             AS dia_exato_legado
FROM org_blips.workflow_steps s
WHERE s.is_active
GROUP BY 1;
```

- **Campos validados:** presença/ausência da chave JSONB `days_overdue_trigger`; presença de `days_overdue`.
- **Como foi apurado:** conta, por régua, quantos steps têm faixa e quantos caem no legado de dia exato. Resultado: 55 steps por régua v4 e 51 por v2, **todos** com `days_overdue_trigger` NULL.
- **Perspectiva:** é o que fecha o §2.1 — um título em D+104 não casa D+102 nem D+110; ou o atraso bate o degrau no dia exato, ou nada acontece. Sem isso, a cobertura de 6,6% (§4.4) não teria explicação mecânica.

### Q1.3 — Estabilidade da escada no tempo **[reconstruída — §5.1]**

**Objetivo:** datar a última alteração de step para saber a partir de quando a escada é "exata" como referência retroativa (06/04/2026).

```sql
SELECT date_trunc('day', al.created_at) AS dia, al.action, count(*)
FROM org_blips.workflow_audit_logs al
WHERE al.action IN ('step_added','step_updated','step_deleted')
GROUP BY 1,2 ORDER BY 1;
```

- **Campos validados:** `workflow_audit_logs.action`, `created_at`; cruzado com `workflow_steps.created_at/updated_at`.
- **Como foi apurado:** localiza a data do último `step_*`. v4 criada 30–31/03, última mudança 06/04.
- **Perspectiva:** define o limite de confiança temporal do §4.3 — exato de 06/04 em diante, aproximado em fev–mar (régua v2 com 4 degraus diferentes).

---

## Etapa 2 — O universo: schemas e volume

### Q2.1 — Sobreposição entre `org_blips` e `org_finza` **[verbatim — B.6]**

**Objetivo:** medir quantas ações existem nos dois schemas (cópias da migração) para não duplicar contagem. Sustenta o §3.0.

```sql
SELECT to_char(f.created_at AT TIME ZONE 'America/Sao_Paulo','YYYY-MM') AS mes,
       count(*) AS total_finza, count(b.id) AS copiadas_de_blips,
       count(*) - count(b.id) AS exclusivas_finza
FROM org_finza.actions f
LEFT JOIN org_blips.actions b ON b.id = f.id
WHERE f.created_at >= '2026-01-01' AND f.created_at < '2026-08-01'
GROUP BY 1 ORDER BY 1;
```

- **Campos validados:** `actions.id` como chave de identidade entre schemas; `created_at` em BRT para o corte mensal.
- **Como foi apurado:** LEFT JOIN por `id`; o que casa nos dois é cópia da migração (`_migr_finza_id3783_audit`), o que não casa é ação nativa de `org_finza`. Resultado: 10.707 ações compartilhadas; fev–mai 100% cópia, jun misto, jul 100% nativo.
- **Perspectiva:** decisão metodológica-chave — **`org_blips` é o universo de §3.1–§4.6** (histórico completo e base dos números do e-mail); `org_finza` entra separado no §7 contando só exclusivas. Somar sem deduplicar por `id` inflaria fev–mai.

### Q2.2 — Volume geral por mês: criação, envio, falha, cancelamento, defasagem **[reconstruída — §3.1]**

**Objetivo:** o inventário-mestre (444.724 ações fev–jul; 69.742 enviadas em dia posterior).

```sql
SELECT to_char(a.created_at AT TIME ZONE 'America/Sao_Paulo','YYYY-MM')     AS mes,
       count(*)                                                             AS criadas,
       count(*) FILTER (WHERE a.status = 'Enviado')                         AS enviadas,
       count(*) FILTER (WHERE a.status IN ('Falhou','Falha Permanente'))    AS falhas,
       count(*) FILTER (WHERE a.status LIKE 'Cancelado%')                   AS canceladas,
       round(avg(EXTRACT(epoch FROM (a.sent_at - a.created_at))/3600)
             FILTER (WHERE a.sent_at IS NOT NULL), 2)                       AS horas_ate_envio,
       count(*) FILTER (WHERE a.sent_at IS NOT NULL
             AND (a.sent_at AT TIME ZONE 'America/Sao_Paulo')::date
               > (a.created_at AT TIME ZONE 'America/Sao_Paulo')::date)     AS enviadas_dia_posterior,
       max((a.sent_at AT TIME ZONE 'America/Sao_Paulo')::date
         - (a.created_at AT TIME ZONE 'America/Sao_Paulo')::date)           AS max_defasagem_dias
FROM org_blips.actions a
WHERE a.created_at >= '2026-02-01' AND a.created_at < '2026-08-01'
  AND coalesce(a.metadata->>'is_test','') <> 'true'
GROUP BY 1 ORDER BY 1;
```

- **Campos validados:** `status` (Enviado / Falhou / Falha Permanente / Cancelado*), `created_at`, `sent_at`, exclusão de `is_test`. `Pendente = 0` em todos os meses (verificado no mesmo agrupamento).
- **Como foi apurado:** contagens condicionais (`FILTER`) sobre o mesmo universo; a defasagem compara a **data** de criação com a **data** de envio em BRT.
- **Perspectiva:** separa **criação** (cron `30 7 * * *`, todo dia) de **envio** (`active_days` seg–sex + janela 08–18h). As 69.742 (15,7%) enviadas em dia posterior e os cancelamentos majoritariamente `Cancelado (Pago)` mostram que a rede de proteção contra dado defasado está **no envio**, não na criação (§3.4).

### Q2.3 — Por canal, com contatos/contratos/títulos distintos **[reconstruída — §3.2]**

**Objetivo:** mostrar a assinatura do modelo por título (títulos tocados ≈ 2× contratos).

```sql
SELECT to_char(a.created_at AT TIME ZONE 'America/Sao_Paulo','YYYY-MM') AS mes,
       a.action_type,
       count(*)                        AS acoes,
       count(DISTINCT a.contact_id)    AS contatos,
       count(DISTINCT a.contract_id)   AS contratos,
       count(DISTINCT a.title_id)      AS titulos
FROM org_blips.actions a
WHERE a.created_at >= '2026-02-01' AND a.created_at < '2026-08-01'
  AND coalesce(a.metadata->>'is_test','') <> 'true'
GROUP BY 1,2 ORDER BY 1,3 DESC;
```

- **Campos validados:** `action_type` (canal), `count(DISTINCT …)` de contato/contrato/título.
- **Como foi apurado:** cardinalidade distinta por grão. ~4.400–5.000 contatos e ~5.300–5.900 contratos estáveis, mas ~9.500–12.700 títulos/mês.
- **Perspectiva:** confirma empiricamente que a unidade de decisão é o título — um contrato parcelado entra com várias parcelas no mês.

### Q2.4 — Por régua × campanha × mês **[reconstruída — §3.3]**

**Objetivo:** distribuir o volume entre réguas/campanhas (identifica coexistência de v1/v2/v4, broadcasts, neg/notif).

```sql
SELECT to_char(a.created_at AT TIME ZONE 'America/Sao_Paulo','YYYY-MM') AS mes,
       w.name  AS regua,
       cp.name AS campanha,
       count(*)                                                    AS acoes,
       count(*) FILTER (WHERE a.action_type='send_whatsapp')       AS wa,
       count(*) FILTER (WHERE a.action_type='send_email')          AS email,
       count(*) FILTER (WHERE a.action_type IN
                        ('negativation','notification'))           AS neg_notif,
       count(DISTINCT a.contact_id)  AS contatos,
       count(DISTINCT a.contract_id) AS contratos,
       count(DISTINCT a.title_id)    AS titulos
FROM org_blips.actions a
LEFT JOIN org_blips.workflow_steps ws ON ws.id = a.workflow_step_id
LEFT JOIN org_blips.workflows      w  ON w.id  = ws.workflow_id
LEFT JOIN org_blips.campaigns      cp ON cp.id = a.campaign_id
WHERE a.created_at >= '2026-02-01' AND a.created_at < '2026-08-01'
  AND coalesce(a.metadata->>'is_test','') <> 'true'
GROUP BY 1,2,3
HAVING count(*) >= 50
ORDER BY 1, 4 DESC;
```

- **Campos validados:** junção `actions.workflow_step_id → workflow_steps.workflow_id → workflows.name`; `actions.campaign_id → campaigns.name`. Integridade total das junções (§5.1).
- **Como foi apurado:** corte `≥ 50` para limpar ruído; steps sem `workflow_id` aparecem como "(step órfão)".
- **Perspectiva:** documenta a transição v2→v4 (mar), a entrada de neg/notif (mar–abr) e SMS (jun), e a saída da operação FINZA de `org_blips` (jul). Contexto para não atribuir a um só motor um comportamento de vários.

---

## Etapa 3 — Deduplicação e funil (o "cliente recebe 2, 3 mensagens?")

### Q3.1 — Ações por contato por dia **[reconstruída — §3.5]**

**Objetivo:** resposta direta à pergunta do e-mail — a dedup segura o volume por contato/dia?

```sql
WITH cd AS (
  SELECT a.contact_id,
         (a.created_at AT TIME ZONE 'America/Sao_Paulo')::date AS dia,
         count(*)                                                AS total,
         count(*) FILTER (WHERE a.action_type='send_whatsapp')   AS wa,
         count(*) FILTER (WHERE a.action_type='send_email')      AS email
  FROM org_blips.actions a
  WHERE a.created_at >= '2026-02-01' AND a.created_at < '2026-08-01'
    AND coalesce(a.metadata->>'is_test','') <> 'true'
  GROUP BY 1,2)
SELECT to_char(dia,'YYYY-MM')                          AS mes,
       count(*)                                        AS contato_dias,
       round(avg(total),2)                             AS media_acoes,
       max(total)                                      AS max_total,
       count(*) FILTER (WHERE wa >= 2)                 AS cd_2mais_wa,
       round(100.0*count(*) FILTER (WHERE wa>=2)/count(*),2) AS pct_2mais_wa,
       max(wa)                                         AS max_wa,
       max(email)                                      AS max_email
FROM cd GROUP BY 1 ORDER BY 1;
```

- **Campos validados:** grão `(contact_id, dia)`; contagem por canal.
- **Como foi apurado:** agrega ações por contato-dia, depois estatística mensal. Média ~1,5–1,9/dia = par WhatsApp+e-mail do mesmo degrau; máx WA no mesmo dia caiu de 5 (fev) para 2 (jul).
- **Perspectiva:** a dedup por `(contato × canal × integração)` **funciona**. Os poucos casos de ≥2 WhatsApp/dia são integrações ou campanhas distintas (a chave inclui `integration_id`), não múltiplas cobranças do mesmo canal. Tendência de queda consistente (9,49%→1,78%).

### Q3.2 — Funil do Pipeline v2 **[reconstruída — §3.6]**

**Objetivo:** medir onde o funil perde candidatos — quantos títulos casam step e quanto a dedup descarta.

```sql
SELECT to_char(r.created_at AT TIME ZONE 'America/Sao_Paulo','YYYY-MM') AS mes,
       count(*)                          AS runs,
       sum(r.eligible_contacts)          AS contatos_elegiveis,
       sum(r.titles_fetched)             AS titulos_expandidos,
       sum(r.matches_after_step)         AS casaram_step,
       round(100.0*sum(r.matches_after_step)/nullif(sum(r.titles_fetched),0),1) AS pct_casou,
       sum(r.matches_after_integration_dedup) AS apos_dedup_integracao,
       sum(r.matches_after_rules)        AS apos_regras,
       sum(r.matches_after_cross_dedup)  AS apos_cross_dedup,
       sum(r.actions_created)            AS acoes_criadas
FROM org_blips.campaign_execution_runs r
WHERE r.created_at >= '2026-03-01' AND r.created_at < '2026-08-01'
GROUP BY 1 ORDER BY 1;
```

- **Campos validados:** contadores agregados de `campaign_execution_runs`. `actions_created` reconciliado com a contagem real de `actions` (bate em todos os meses).
- **Como foi apurado:** soma por mês de cada estágio do funil.
- **Perspectiva:** **duas leituras centrais** — (1) só **16%–33% dos títulos casam algum step** (jul: 329.854→86.586 = 26,3%); os ~73% restantes recebem `no_step_match` porque o atraso não caiu em degrau; (2) a dedup por integração descarta ~32% dos que casaram — aqui o "maior atraso" funciona, mas só entre os que casaram. ⚠ Contadores `skipped_*` parcialmente zerados a partir de abr (limitação de **telemetria**, não de comportamento).

### Q3.3 — Bloqueios registrados (motor v1) **[reconstruída — §3.7]**

**Objetivo:** dimensionar dedup/cooldown antes do pipeline v2.

```sql
SELECT to_char(sl.created_at AT TIME ZONE 'America/Sao_Paulo','YYYY-MM') AS mes,
       sl.reason,
       count(*)                       AS ocorrencias,
       count(DISTINCT sl.contact_id)  AS contatos,
       count(DISTINCT sl.title_id)    AS titulos
FROM org_blips.skipped_actions_log sl
WHERE sl.created_at >= '2026-02-01' AND sl.created_at < '2026-08-01'
GROUP BY 1,2 ORDER BY 1, 3 DESC;
```

- **Campos validados:** `skipped_actions_log.reason` (`duplicate_step`, `cooldown_active`).
- **Como foi apurado:** total 1.890.611 avaliações barradas fev–mai. Queda abrupta a partir de abr = migração ao v2 (não escreve nesta tabela), **não** redução de dedup.
- **Perspectiva:** cuidado interpretativo — a "queda" é de telemetria. O v2 registra em `campaign_execution_candidates` (retenção ~3 dias, §5.3).

---

## Etapa 4 — Volume por degrau (a escada em uso)

### Q4.1 — Ações por degrau em julho **[reconstruída — §2.3]**

**Objetivo:** mostrar a distribuição real por degrau e provar o teto por dados (0 ações > D+110).

```sql
SELECT (a.metadata->>'days_overdue')::int                         AS degrau,
       count(*)                                                   AS acoes,
       count(*) FILTER (WHERE a.action_type='send_whatsapp')      AS wa,
       count(*) FILTER (WHERE a.action_type='send_email')         AS email
FROM org_blips.actions a
WHERE a.created_at >= '2026-07-01' AND a.created_at < '2026-08-01'
  AND a.action_type IN ('send_whatsapp','send_email')
  AND coalesce(a.metadata->>'is_test','') <> 'true'
GROUP BY 1 ORDER BY 1;
```

- **Campos validados:** `metadata->>'days_overdue'` (degrau que casou, gravado por `create_actions`).
- **Como foi apurado:** histograma por degrau. A linha `> D+110 = 0` é **medição**, não inferência.
- **Perspectiva:** confirma o teto por dados (§9 do sumário) e mostra a concentração em D0/D+3/D+5. Combina com o §6.3: o motor **suporta** faixa aberta (`max=null`) mas nenhuma régua a configura.

---

## Etapa 5 — O núcleo: a ação saiu no título mais atrasado?

### Q5.1 — Reconstrução retroativa do maior atraso **[verbatim — B.1]**

**Objetivo:** o coração do §4. Para cada ação, reconstruir o estado da carteira do contato **na data de criação** e comparar o atraso do título cobrado com o maior atraso real.

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

- **Campos validados:** o predicado de "aberto e vencido em `d_ref`" — `due_date <= d_ref` (vencido), `payment_date IS NULL OR > d_ref` (não pago então), `removed_at IS NULL OR > d_ref` (não removido então), `created_at <= d_ref` (linha já existia = o que o motor **podia ver**). `d_ref = created_at` em BRT.
- **Como foi apurado:** monta o universo do contato em cada data de ação (`base`), tira `max(atraso)` por contato-dia (`mx`) e por contrato-dia (`mxc`), e compara com o atraso do título que gerou a ação. Rodada mês a mês trocando `:ini`/`:fim`.
- **Perspectiva:** é o que produz o §4.2 (43,6% saíram no maior atraso do contato; 48,5% num título menos atrasado). O predicado `created_at <= d_ref` é a sutileza-chave: reconstrói **o que o motor via**, não a verdade absoluta de hoje. A coluna "sem universo" (§4.2¹) vem de `payment_date` retroativa (Etapa 7).

### Q5.2 — Quando houve gap, existia degrau no maior atraso? **[reconstruída — §4.3]**

**Objetivo:** o achado que muda a leitura do problema — em 96,4% dos gaps, **não havia step** no dia de atraso do pior título.

```sql
-- reaproveita `acts`, `base`, `mx` da Q5.1; escada v4 como referência
WITH ... (CTEs da Q5.1) ...,
gap AS (
  SELECT a.id, mx.max_ct,
         mx.max_ct = ANY(ARRAY[0,3,5,8,11,13,16,20,23,25,31,35,40,46,50,55,
                               61,65,70,75,80,85,87,91,96,99,102,110]) AS max_em_degrau
  FROM acts a
  JOIN org_blips.titles t ON t.id = a.title_id
  JOIN mx ON mx.contact_id=a.contact_id AND mx.d_ref=a.d_ref
  WHERE mx.max_ct > 0 AND (a.d_ref-t.due_date) < mx.max_ct)   -- só as com gap
SELECT count(*)                                            AS acoes_com_gap,
       count(*) FILTER (WHERE max_em_degrau)               AS maior_atraso_tinha_degrau,
       count(*) FILTER (WHERE NOT max_em_degrau)           AS maior_atraso_sem_degrau,
       round(100.0*count(*) FILTER (WHERE NOT max_em_degrau)/count(*),1) AS pct_sem_degrau
FROM gap;
```

- **Campos validados:** flag `= ANY(escada)` — testa se o maior atraso real coincide com algum degrau da régua daquele dia.
- **Como foi apurado:** filtra só ações com gap (`atraso do título < max do contato`) e pergunta se o `max` estava em degrau. Resultado total: 96,4% **não** estavam.
- **Perspectiva:** desloca a causa do "motor errado" para "escada não alcança o estoque". Mesmo que o motor sempre escolhesse o mais atrasado, em 96% desses casos **não haveria mensagem** para enviar. Ressalva: escada v4 aplicada como referência; fev–mar têm margem de alguns pontos (v2 difere em 4 degraus), abr–jul exatos.

### Q5.3 — Cobertura da escada contra a carteira (snapshot 14/07) **[verbatim — B.3]**

**Objetivo:** medir o motivo-raiz direto no estoque, sem depender de ações — a foto da carteira contra a escada.

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

- **Campos validados:** whitelist de status cobrável (`Disponivel/Expirado/Recomprado`, vigente desde 14/06); mesmo predicado de aberto/vencido da Q5.1.
- **Como foi apurado:** foto de 14/07 de todos os títulos vencidos abertos; flag por título e por contato (maior atraso em degrau?).
- **Perspectiva:** o número mais forte da auditoria — **10.045 títulos vencidos; só 6,6% em degrau; 52,4% acima de D+110**. Em contatos: **só 6,2%** têm o maior atraso em degrau; **74,2%** não têm **nenhum** vencido em degrau. É o teto estrutural quantificado: num dia típico, só ~6% dos inadimplentes poderiam ser cobrados no seu pior título.

### Q5.4 — Tabela cruzada step × maior atraso real (julho) **[reconstruída — §4.5]**

**Objetivo:** mostrar a direção do desvio — sempre subcobrar, quase nunca sobrecobrar.

```sql
-- reaproveita `acts`, `base`, `mx` da Q5.1 (julho), só contatos já vencidos
WITH ... (CTEs da Q5.1 p/ julho) ...
SELECT CASE WHEN (a.d_ref-t.due_date) <= 0 THEN 'preventivo'
            WHEN (a.d_ref-t.due_date) <= 15 THEN 'D+1-15'
            WHEN (a.d_ref-t.due_date) <= 30 THEN 'D+16-30'
            WHEN (a.d_ref-t.due_date) <= 60 THEN 'D+31-60'
            WHEN (a.d_ref-t.due_date) <= 90 THEN 'D+61-90'
            ELSE 'D+91+' END                                       AS step_faixa,
       CASE WHEN mx.max_ct <= 15 THEN '1-15'
            WHEN mx.max_ct <= 30 THEN '16-30'
            WHEN mx.max_ct <= 60 THEN '31-60'
            WHEN mx.max_ct <= 90 THEN '61-90'
            WHEN mx.max_ct <= 180 THEN '91-180'
            ELSE '180+' END                                        AS atraso_real_faixa,
       count(*) AS acoes
FROM acts a
JOIN org_blips.titles t ON t.id = a.title_id
JOIN mx ON mx.contact_id=a.contact_id AND mx.d_ref=a.d_ref
WHERE mx.max_ct > 0 AND a.action_type IN ('send_whatsapp','send_email')
GROUP BY 1,2 ORDER BY 1,2;
```

- **Campos validados:** faixa do step disparado × faixa do maior atraso real; universo de 40.600 ações (contato já vencido).
- **Como foi apurado:** matriz de contagem. Diagonal (step = atraso real) = 43,1%; acima (step mais brando) ≈ 55%; abaixo (step mais severo) = **0,08%** (34 ações).
- **Perspectiva:** confirma com dados de produção a **mesma assimetria** do anexo do e-mail — o desvio é **sempre subcobrar**, nunca sobrecobrar. As raras 34 ações "abaixo" são resíduo de `payment_date` defasada (Etapa 7).

### Q5.5 — Reconciliação com os números do e-mail **[reconstruída — §4.6]**

**Objetivo:** provar que a auditoria reproduz o apontamento do negócio de forma independente.

```sql
-- métrica: ações de comunicação criadas no mês, contato com >=1 título vencido,
-- e atraso do título da ação <> maior atraso do contato
WITH ... (CTEs da Q5.1) ...
SELECT to_char(a.d_ref,'YYYY-MM')                                  AS mes,
       count(*) FILTER (WHERE mx.max_ct > 0)                       AS acoes_contato_vencido,
       count(*) FILTER (WHERE mx.max_ct > 0
                          AND (a.d_ref-t.due_date) <> mx.max_ct)   AS step_dif_maior,
       round(100.0*count(*) FILTER (WHERE mx.max_ct>0
                          AND (a.d_ref-t.due_date)<>mx.max_ct)
             / nullif(count(*) FILTER (WHERE mx.max_ct>0),0),1)    AS pct
FROM acts a
JOIN org_blips.titles t ON t.id = a.title_id
LEFT JOIN mx ON mx.contact_id=a.contact_id AND mx.d_ref=a.d_ref
GROUP BY 1 ORDER BY 1;
```

- **Campos validados:** mesmo predicado da Q5.1; recorte "contato vencido" = `max_ct > 0`.
- **Como foi apurado:** total auditoria 172.544 casos divergentes vs 171.572 do e-mail — **diferença de 0,6%**. Denominadores mensais divergem até 18% (definições diferentes de "cliente vencido"), o que redistribui os percentuais, mas o volume absoluto fecha.
- **Perspectiva:** a auditoria **não contesta** o número do negócio; confirma em magnitude, direção e ordem de grandeza — e adiciona o **mecanismo** que o produz (Q5.2, Q5.3).

---

## Etapa 6 — Reconstruibilidade retroativa

### Q6.1 — Integridade histórica dos títulos **[verbatim — B.4]**

**Objetivo:** provar que nenhum título referenciado por ação de 2026 foi perdido — pré-condição de toda reconstrução.

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

- **Campos validados:** `title_id` órfão (não existe mais em `titles`).
- **Como foi apurado:** LEFT JOIN; **0 órfãos** em 39.026 títulos distintos / 434.410 ações.
- **Perspectiva:** como `due_date` é imutável e nada se perdeu, o **atraso** de qualquer ação passada é reconstruível com confiança total. É o que legitima §4 e §5.1.

### Q6.2 — Existência e cobertura do `title_status_history` **[reconstruída — §5.2]**

**Objetivo:** delimitar o que **não** é reconstruível — a transição de status antes de 28/06/2026.

```sql
SELECT min(created_at) AS primeiro_registro, count(*) AS linhas,
       count(DISTINCT title_id) AS titulos
FROM org_blips.title_status_history;
-- resultado: 28/06/2026 09:00, 7.839 linhas
```

- **Campos validados:** `title_status_history.created_at`, cardinalidade.
- **Como foi apurado:** a tabela só nasce em 28/06 → não há como saber **quando** um título passou de `Disponivel`→`Expirado`→`Recomprado` antes disso.
- **Perspectiva:** impacto **baixo** para atraso (os 3 status são todos cobráveis, transição entre eles não muda elegibilidade); só afeta `Aguardando Cancelamento/Recompra` (255 títulos hoje).

---

## Etapa 7 — Achados colaterais

### Q7.1 — Ações para títulos com `payment_date` anterior à ação **[reconstruída — §6.1]**

**Objetivo:** dimensionar o dado defasado no disparo — a única fonte de ruído material da reconstrução (§4.2 "sem universo").

```sql
SELECT to_char(a.created_at AT TIME ZONE 'America/Sao_Paulo','YYYY-MM') AS mes,
       count(*)                                                      AS acoes,
       round(100.0*count(*) / (SELECT count(*) FROM org_blips.actions x
             WHERE x.created_at >= date_trunc('month', a.created_at)
               AND x.created_at <  date_trunc('month', a.created_at)+interval '1 month'
               AND x.action_type IN ('send_whatsapp','send_email')
               AND coalesce(x.metadata->>'is_test','')<>'true'),1)   AS pct_comunicacoes,
       count(*) FILTER (WHERE t.removed_at IS NOT NULL)              AS ja_removidos
FROM org_blips.actions a
JOIN org_blips.titles t ON t.id = a.title_id
WHERE a.created_at >= '2026-02-01' AND a.created_at < '2026-08-01'
  AND a.action_type IN ('send_whatsapp','send_email')
  AND coalesce(a.metadata->>'is_test','') <> 'true'
  AND t.payment_date IS NOT NULL
  AND t.payment_date <= (a.created_at AT TIME ZONE 'America/Sao_Paulo')::date
GROUP BY 1 ORDER BY 1;
```

- **Campos validados:** `titles.payment_date <= d_ref` (título hoje consta pago antes da ação).
- **Como foi apurado:** 27.251 ações fev–jul (6,4%). Duas causas indistinguíveis sem `title_status_history`: (a) base defasada no disparo, ou (b) pagamento lançado depois com data retroativa.
- **Perspectiva:** tendência de melhora clara (10,8%→2,5%). É **identificável linha a linha** — pode ser segregado em qualquer análise, não precisa ser tolerado como erro cego. Parte é cancelado no envio pelo `payment_check_url` (explica os 77.236 `Cancelado`).

### Q7.2 — Divergência `metadata.days_overdue` × atraso recalculado **[reconstruída — §6.2]**

```sql
SELECT to_char(a.created_at AT TIME ZONE 'America/Sao_Paulo','YYYY-MM') AS mes,
       count(*) FILTER (WHERE (a.metadata->>'days_overdue')::int
             <> ((a.created_at AT TIME ZONE 'America/Sao_Paulo')::date - t.due_date)) AS divergentes,
       round(100.0*count(*) FILTER (WHERE (a.metadata->>'days_overdue')::int
             <> ((a.created_at AT TIME ZONE 'America/Sao_Paulo')::date - t.due_date))
             / count(*),2)                                          AS pct
FROM org_blips.actions a
JOIN org_blips.titles t ON t.id = a.title_id
WHERE a.created_at >= '2026-02-01' AND a.created_at < '2026-08-01'
  AND a.action_type IN ('send_whatsapp','send_email')
  AND coalesce(a.metadata->>'is_test','') <> 'true'
GROUP BY 1 ORDER BY 1;
```

- **Campos validados:** `metadata->>'days_overdue'` vs `created_at::date - due_date`.
- **Como foi apurado:** compatível com ações **diferidas** (`deferred_at`, `original_days_overdue`, `original_title_id`) e criações que atravessam meia-noite. Caiu para 0,09% em julho.
- **Perspectiva:** sugere que a causa foi endereçada; raiz não investigada (fora do escopo do card).

### Q7.3 — `org_finza`, ações exclusivas **[reconstruída — §7]**

**Objetivo:** medir a operação Finza pós-migração separadamente (excluindo as 10.707 cópias).

```sql
WITH acts AS (
  SELECT f.id, f.contact_id, f.contract_id, f.title_id, f.action_type,
         (f.created_at AT TIME ZONE 'America/Sao_Paulo')::date AS d_ref
  FROM org_finza.actions f
  LEFT JOIN org_blips.actions b ON b.id = f.id
  WHERE b.id IS NULL                                    -- só exclusivas de org_finza
    AND f.created_at >= '2026-06-01' AND f.created_at < '2026-08-01'
    AND f.title_id IS NOT NULL
    AND coalesce(f.metadata->>'is_test','') <> 'true'
    AND f.action_type IN ('send_whatsapp','send_email','send_sms'))
-- … + mesmo bloco `base`/`mx` da Q5.1 apontando para org_finza.contracts/titles …
SELECT ... (mesmas métricas da Q5.1) ...;
```

- **Campos validados:** `b.id IS NULL` (exclusiva); demais idênticos à Q5.1, no schema `org_finza`.
- **Como foi apurado:** aderência **melhor** (56%–63% no maior atraso do contato vs 41%–47% em `org_blips`).
- **Perspectiva:** carteira Finza menor e menos fragmentada (1,6–1,8 títulos vencidos/contato-ação vs 5,5) → maior chance de o pior título cair num degrau. **Mesma régua, mesmo motor, resultado melhor** — reforça que o driver é a **distribuição da carteira contra a escada**, não o motor.

---

## Mapa consulta → seção da auditoria

| Consulta | Seção | Achado que sustenta |
|---|---|---|
| Q0.1 | §1, §8 | motor decide por título; "maior atraso" é desempate entre os que casaram |
| Q1.1–Q1.3 | §2.1, §2.3, §5.1 | escada de dia exato, 20/27 degraus, teto D+110, estável desde 06/04 |
| Q2.1 | §3.0 | 10.707 cópias; `org_blips` = universo |
| Q2.2–Q2.4 | §3.1–§3.3 | 444.724 ações; assinatura por título; coexistência de motores |
| Q3.1 | §3.5 | dedup funciona: 1,5–1,9 ações/contato/dia |
| Q3.2 | §3.6 | só 16–33% casam step; dedup descarta ~32% |
| Q3.3 | §3.7 | queda de log = telemetria, não comportamento |
| Q4.1 | §2.3, §6.3 | 0 ações > D+110; sem step de cauda |
| Q5.1 | §4.2 | 43,6% no maior atraso; 48,5% em título menos atrasado |
| Q5.2 | §4.3 | 96,4% dos gaps: pior título sem degrau |
| Q5.3 | §4.4 | 6,6% dos títulos / 6,2% dos contatos em degrau em 14/07 |
| Q5.4 | §4.5 | desvio sempre subcobra (0,08% sobrecobra) |
| Q5.5 | §4.6 | reconcilia com e-mail: 0,6% de diferença |
| Q6.1–Q6.2 | §5.1–§5.2 | atraso reconstruível; status pré-28/06 não |
| Q7.1–Q7.3 | §6.1, §6.2, §7 | payment_date defasada (6,4%); org_finza melhor |

---

## Log de alterações
- 2026-07-28 — criado como companheiro da auditoria IAF-4953
