# Domínio · Atendimento em nível de mensagem (log, autor, tempo de resposta, áudio, CNPJ)

> **Validado no BQ em 2026-11-18** (janela 2026-08-20 → 2026-11-18). Demanda de origem: relatório de atendimento do CTO
> (buckets de tempo de resposta, rubrica LLM, assunto, IA × humano, ranking 0–100).
> Recorte decidido: **(A) FINZA inteiro** e **(B) BLIPS, chats que PASSARAM por depto de Cobrança** (`is_cobranca_dpto=1 AND is_ia_dpto=0`). Os dois ficam separados.
> As poucas afirmações que seguem sem validação estão marcadas "(não validado)".

---

## 1 · Veredito: existe log completo de mensagens no BQ?

| Recorte | Log completo | Melhor fonte no BQ | Cobertura (90 d) |
|---|---|---|---|
| **A · FINZA** | **NÃO EXISTE** | reconstrução a partir de `lastMessage` em `bigquery___finza.chat_events` | 100% dos protocolos; ~50% das mensagens (estimado pela captura medida no BLIPS) |
| **B · BLIPS Cobrança** | **PARCIAL** | `bronze_hyperflow.chat_history` (v2, completo) + `tb_chat_messages` (amostra) de fallback | completo em 34% dos protocolos (19.650 de 57.847); os demais 66% só com amostra |

Fora do BQ, o log completo vem da API `getChatMessages(protocol)` do Hyperflow, que é exatamente o que a `chat_history` v2 carrega. **Para ter FINZA completo, o caminho é estender a extração `chat_history` ao tenant FINZA** (time de dados). Nenhum SQL resolve isso.

## 2 · Catálogo de candidatas (busca em todo o projeto)

| Tabela | Grão | Tenant | Janela | Completude | Uso |
|---|---|---|---|---|---|
| ⭐ `blips-bigdata.bronze_hyperflow.chat_history` (v2) | 1 linha por mensagem por carga (`CHAVE_COMPOSTA` = requested_key\|message_id); partição `dia_carga` | **só BLIPS** (`empresa`) | mensagens de chats de 2025-02 → hoje | **completo** por protocolo extraído (é o `getChatMessages`) | log real. ⚠️ **Escopo = protocolos casados com deal do Pipedrive** (`vw_extracao_conversas_leads_escopo`, lead comercial), não um departamento |
| `blips-bigdata.bronze_external_hyperflow.tb_chat_messages` | 1 linha por mensagem reconstruída | **só BLIPS** | 2026-08-19 em diante, nesta checagem | **~50%**: in 57%, out 50%, info 39% contra `chat_history`, protocolos de 01–07/out/2026 | amostra; tem `conteudo_texto`, `evento_origem_tipo`, `agente_evento_id` |
| `blips-bigdata.bigquery___finza.chat_events` | evento; partição `timestamp`; ~437k linhas | FINZA | 2025-10-08 → hoje (streaming) | sem evento por mensagem; `metadata.chat.lastMessage` dá ~1 mensagem por evento de interação | **única fonte de texto FINZA** |
| `blips-bigdata.blips___desk.chat_events` | idem | BLIPS | 2025-10-08 → hoje | idem | ⚠️ caro: 90 dias de varredura = **31 GB** |
| `blips-bigdata.bronze_hyperflow_finza.chat_history` | 1 linha por chat (v1, snapshot `historical_info`) | FINZA | legado, 9.907 linhas | **não tem mensagem** | não usar |
| `blips-bigdata.silver_auditoria.atendimentos` | 1 linha por atendimento auditado (`_id`); ponte por **`protocol`** (sem chat_id) | **só BLIPS** (0 FINZA em 90 d) | carga desde 2026-11 (histórico migrado do Airbyte) | 63% dos protocolos BLIPS-Cobrança em 90 d | resumo, `sentiment`, `topics`, `flags` (resolved, critical_flag), `avg_evaluation_score` (JSON), `csat` (~7%). Benchmark da rubrica. Coluna `origem`: avaliacao_qualidade / analise_comercial / nulo |
| `blips-bigdata.silver_auditoria.avaliacoes` | avaliação de qualidade | BLIPS | — | — | notas por atendente (`atendimentos.evaluations` aponta para cá). Schema não lido |
| `blips-bigdata.silver_auditoria.helper_messages` | 1 linha por mídia do **cliente** (image/audio/file) | BLIPS | 2025-03 → hoje | 477 áudios transcritos em BLIPS-Cobrança 90 d, contra ~8,6k áudios do cliente só nos 34% completos | **única transcrição de áudio no lake**; `text` = transcrição/descrição; ponte `protocol` |
| `blips-bigdata.bronze_mongodb_IA.atendimentos_tratado` / `airbyte_*` | view legada sobre o Airbyte | — | — | — | o Airbyte foi desligado; usar `silver_auditoria.*` |
| `blips-bigdata.bronze_mongodb_IA.audit_blips` | 1 linha por auditoria de atendente | BLIPS | **sem uso desde dez/2025** | — | métricas: empathy, clarity, proactivity, agility, resolution (+ negotiation, persuasion…). Referência histórica de rubrica |
| `bronze_mongodb_IA.hyper_delta`, `IA_E_AUTOMACAO.TBL_HYPER_MESSAGES_DELTA`, `VIEWS_DASHES.hyper_mensagem` | 1 linha por protocolo (delta de resposta) | BLIPS | legado/pequeno | — | não é log |
| `finza-prod-481500.silver_torre.org_{finza,blips}_actions_interaction_logs` | 1 linha por **turno de IA** (`user_message` + `ai_response`) | os dois | FINZA desde 2026-06-21; BLIPS desde 2026-08 | só o trecho com IA; 3.668 protocolos FINZA em 90 d, **58% casam** com o desk FINZA | texto do lado IA, `sentiment`, `intent_detected`, `transferred_to_human`, `agent_id`, tokens |
| `finza-prod-481500.silver_torre.org_*_agent_messages` | — | — | FINZA 0 linhas, BLIPS 231 | — | irrelevante. `ai_messages` (Supabase) **não é replicada** no BQ |

## 3 · Regras validadas

### 3.1 Autor da mensagem

- **`chat_history` v2:** coluna `sender_kind` = `client` / `agent` / `bot`, regra do front do desk via `meta.agent`. É a regra oficial.
- **Reconstrução (`chat_events` / `tb_chat_messages`):** `lastMessage` **não traz `meta.agent`**. Regra: `in` = cliente; `out` vindo de evento `chat_user_interaction` = **humano** (`agent` do evento = id do agente); demais `out` = bot/IA; `info` = sistema.
  - Validação contra `sender_kind`, BLIPS, 01–07/out/2026: **precisão 96%**, **recall ~66%**. Um terço das mensagens humanas chega por outros eventos (`chat_interaction_finished`, `chat_read`, `chat_hold`…) e cai em "bot".
- **IA não é agente do desk.** Os 10 agentes de maior volume nos dois recortes são pessoas (`tb_agents_ref`). Mensagem de IA = `bot`. Para separar IA de URA ou automação: depto `is_ia_dpto=1` (ex.: "IA - Financeiro" BLIPS `6764392440b22f327e145e70`, FINZA `698480eb046eaf3f6da39adb`) e protocolo em `silver_torre.org_*_ai_protocols` / `actions_interaction_logs`.
- `historical_info.agents` não vazio **não prova** mensagem humana: inclui quem só foi atribuído. No BLIPS-Cobrança, 96% dos chats têm agente.

### 3.2 Departamento "Cobrança" BLIPS (`tb_departments_ref`, `categoria_dpto='cobranca'`)

20 deptos BLIPS com `is_cobranca_dpto=1 AND is_ia_dpto=0`: "Cobrança" (`67c75289ae3f8d2070129f38`), faixas "Cobrança - 01 a 07 / 08 a 30 / 31 a 60 / 61 a 90 / 91+ / 01 a 10 / 11 a 30", Adimplente Preventivo, Bitrix, Jurídico, Novos Originadores, RCS, Suprimentos (2 ids), Cobrança Automatizada, Cobrança Email, FIDC, FIDC Atraso Maior, Fallback Cobrança, **Liquidação Financeira**. Fora do filtro: "IA - Financeiro" (`is_ia_dpto=1`) e os "Financeiro Blips/Ideal" desativados (`nao_classificado`). Se o negócio quiser só o depto chamado "Cobrança", o filtro é `department_id = '67c75289ae3f8d2070129f38'`.

"Passou pelo depto" = `department_id` atual OU algum `historical_info.interactions[].department` na lista.

### 3.3 CNPJ via telefone

`tb_contacts_crm_ref` por telefone canônico (DDD + 8 últimos dígitos, tirando o `55`). Chats com CNPJ em 90 d: **FINZA 87,1%** (19.514/22.410) · **BLIPS-Cobrança 80,4%** (46.507/57.847). Ambíguos (1 telefone → N clientes): FINZA 4.330 chats, BLIPS 9.181. Para ambíguo use `clientes_crm[]`; `cliente_principal` é o cadastro mais recente.

## 4 · Armadilhas

1. **FINZA não tem log completo nem auditoria no BQ.** `chat_history` v2, `tb_chat_messages`, `tb_chat_timeline` e `silver_auditoria` têm **0 protocolos FINZA**.
2. **`chat_history` v2 não é por departamento**: é a fila de **leads do Pipedrive**. Cobertura de Cobrança é acidental (34%). Não presuma que um chat BLIPS está lá.
3. **Áudio e imagem na reconstrução FINZA vêm sem URL e sem texto** (`payload` vazio). O único texto de áudio no lake é o `helper_messages` do auditor, só BLIPS e só mídia do cliente.
4. **`payload` de `lastMessage` é JSON serializado em string**: `JSON_VALUE(SAFE.PARSE_JSON(JSON_VALUE(metadata,'$.chat.lastMessage.payload')),'$.text')`. Na `chat_history`, `payload` é STRING JSON: `SAFE.PARSE_JSON(payload)`.
5. **Datas da `chat_history` são STRING** (`created_at`, `chat_created_at`); use `SAFE_CAST(... AS TIMESTAMP)`. Particionada por `dia_carga` (data de carga, não do chat): filtrar por data do chat varre a tabela (~1–3 GB por consulta).
6. **`blips___desk.chat_events` custa caro**: 90 dias de varredura = 31 GB. Para BLIPS prefira `tb_chat_messages`, que é a mesma reconstrução já materializada.
7. **`userInteractions` / `systemInteractions` não contam mensagens**: no FINZA, 90 d somam 24,7k interações contra 56,6k mensagens in/out reconstruídas.
8. **Ponte IA (Torre) → desk FINZA**: 58% dos protocolos de `actions_interaction_logs` casam com `list_all_chats` FINZA.
9. **`silver_auditoria.atendimentos` não tem `chat_id`**: a ponte é `protocol`, que tem colisão de ~5,8%.

10. **`tb_departments_ref` usa `name`, não `department_name`** (em `list_all_chats` a coluna é `department_name`). As 20 filas de Cobrança BLIPS são **21 `department_id`**: "Cobrança - Suprimentos" tem 2 ids.
11. **`historical_info.interactions[]` é a linha do tempo de estágios do chat** (validado 2026-11-19, os dois tenants). Cada item = um estágio: `department`, `agent` (nulo enquanto na fila), `transferAt` = **início do estágio** (entrada no depto/atribuição), `queuedAt` = entrada na fila, `firstInteractionAt` = 1ª interação do agente, `finishedAt` = fim do estágio. O 1º item é o depto inicial sem agente e dura milissegundos. Serve para "depto vigente na hora da mensagem" e "tempo para assumir" sem varrer `chat_events`.
12. **Payload por tipo de mensagem** (`chat_history`, validado 2026-11-19):
    - `hsm` de bot **não tem `$.text`**: o conteúdo está em `$.template` / `$.fallback` / `$.parameters`. `hsm` enviado por agente tem `$.text`.
    - `audio`/`image`/`video`/`file` trazem só `$.fileType` + `$.url` (agente: `$.name` + `$.url`). Há muito `out/audio/bot`.
    - `postback` do cliente vem com payload vazio (clique em botão) ou `flow_token,q1..q4` (resposta de WhatsApp Flow).
    - `info/system`: `system_type` = `CHAT_TRANSFERED` (payload com `department` e/ou `agent`), `FINISH_CHAT`, `ACTIVE_CHAT`, `COMMENT_ADDED` (comentário interno, texto em `$.comment`), `TRIGGER`.
    - Na reconstrução FINZA (`lastMessage`), o tipo de sistema vem em `payload.$.type` com os mesmos valores.
13. **`bq` CLI no Windows (Git Bash):** passe o SQL por **stdin** (`bq.cmd ... query ... < arquivo.sql`). SQL como argumento quebra no `cmd.exe` ("'C:\Program' não é reconhecido"). Use `PYTHONIOENCODING=utf-8 PYTHONUTF8=1` para não corromper acentos e `--quiet --headless` para o stdout sair só com o JSON. A mensagem "Error saving Application Default Credentials" vai para o stderr e não afeta a consulta.

14. **Na reconstrução, "out rotulado bot" NÃO pode virar sistema direto** (validado 2026-11-19). Com recall de 66%, um terço das falas humanas chega como `bot`; a última fala do atendente costuma vir pelo evento de encerramento. Tratar todo `bot` como automação deu **98,5% de "sem resposta" falso** na amostra BLIPS. Regra que corrigiu, só para `bot` em estágio com atendente atribuído (item 11) e fora de depto de IA:
    - mesmo texto no `chat_history` (gabarito `sender_kind`, ≥ 5 ocorrências) → segue a maioria;
    - texto raro (< 10 ocorrências no recorte) → humano; texto frequente → humano se ≥ 30% das ocorrências vieram como `agent`;
    - áudio, imagem e `hsm` → humano; arquivo → automação.
    - Gabarito (`chat_history`, estágio com atendente): `bot` é 87% texto repetido em 50+ chats; `agent` é 47% texto único, mas 41% também é texto repetido (respostas prontas). Depois da regra, "sem resposta" na amostra caiu para 26% (fonte completa: 17%) e red flag ficou em 39% (completa: 41%).
15. **`msgs` FINZA órfãs:** ~1% das mensagens reconstruídas de `chat_events` pertence a chats fora da janela de `created_at`. Junte por `chat_id` contra a base de chats e descarte o resto.

## 5 · Retrato 2026-08-20 → 2026-11-18 (`list_all_chats`)

> Fechamento da janela (consulta de 2026-11-19, `created_at` < 2026-11-19 00:00 BRT): **A FINZA = 22.416 chats / 4.219 telefones / 12.366 broadcast / 9.254 com agente** · **B BLIPS Cobrança = 57.885 chats / 9.988 telefones / 1.788 broadcast / 55.621 com agente**. A tabela abaixo é o retrato parcial de 18/11.


| Recorte | mês | chats (= protocolos) | clientes (tel.) | broadcast | com agente atribuído | sem agente |
|---|---|---:|---:|---:|---:|---:|
| A FINZA | ago (20–31) | 1.695 | 757 | 708 | 939 | 756 |
| | set | 7.324 | 2.195 | 3.583 | 3.403 | 3.921 |
| | out | 7.810 | 2.234 | 4.885 | 2.748 | 5.062 |
| | nov (1–18) | 5.581 | 1.800 | 3.190 | 2.162 | 3.419 |
| | **total** | **22.410** | **4.219** | **12.366** | **9.252** | **13.158** |
| B BLIPS Cobrança | ago (20–31) | 7.758 | 3.960 | 222 | 7.758 | 0 |
| | set | 19.862 | 6.702 | 648 | 19.851 | 11 |
| | out | 18.925 | 5.684 | 615 | 18.075 | 850 |
| | nov (1–18) | 11.302 | 4.038 | 303 | 9.879 | 1.423 |
| | **total** | **57.847** | **9.985** | **1.788** | **55.563** | **2.284** |

Mensagens em 90 d: FINZA reconstruídas = 18.182 in + 38.429 out + 45.598 info. BLIPS-Cobrança = 333.859 completas (19.650 protocolos, ~17 por protocolo) + 280.449 da amostra (38.197 protocolos).

## 6 · SQL de extração validado

### 6.1 Base de chats por recorte (metadados + CNPJ)

```sql
WITH cob AS (SELECT ARRAY_AGG(department_id) ids FROM `blips-bigdata.bronze_external_hyperflow.tb_departments_ref`
             WHERE tenant_name='BLIPS' AND is_cobranca_dpto=1 AND is_ia_dpto=0),
l AS (
  SELECT IF(l.tenant_name='FINZA','A_FINZA','B_BLIPS_COB') recorte, l.tenant_name, l.protocol, l._id chat_id,
    l.created_at, l.finished_at, l.status, l.is_broadcast, l.channel, l.department_id, l.department_name,
    l.contact_phone, l.historical_info.interactions jornada, ARRAY(SELECT a.agent._id FROM UNNEST(l.historical_info.agents) a) agentes,
    REGEXP_REPLACE(REGEXP_REPLACE(l.contact_phone, r'\D', ''), r'^55(\d{10,11})$', r'\1') t,
    (l.department_id IN UNNEST(cob.ids) OR EXISTS (SELECT 1 FROM UNNEST(l.historical_info.interactions) i WHERE i.department IN UNNEST(cob.ids))) passou_cob
  FROM `blips-bigdata.bronze_external_hyperflow.list_all_chats` l CROSS JOIN cob
  WHERE l.created_at >= TIMESTAMP('2026-08-20 00:00:00','America/Sao_Paulo') AND l.tenant_name IN ('FINZA','BLIPS'))
SELECT l.* EXCEPT (t, passou_cob),
  x.cliente_principal.cnpj_cpf cnpj_principal, x.match_ambiguo, ARRAY(SELECT c.cnpj_cpf FROM UNNEST(x.clientes_crm) c) cnpjs
FROM l LEFT JOIN `blips-bigdata.bronze_external_hyperflow.tb_contacts_crm_ref` x
  ON x.telefone_canonico = IF(LENGTH(l.t) BETWEEN 10 AND 11, CONCAT(SUBSTR(l.t,1,2), RIGHT(l.t,8)), NULL)
WHERE l.tenant_name='FINZA' OR l.passou_cob;
```
`list_all_chats._id` = `chat_id` (54.572 de 54.572 pares batem com `tb_chat_messages.chat_id`, BLIPS, 10–18/nov/2026).

### 6.2 Mensagens A · FINZA (reconstrução, ~50% estimado)

```sql
WITH ev AS (
  SELECT protocol, chat AS chat_id, eventType, agent, department,
    JSON_VALUE(metadata,'$.chat.lastMessage.id') message_id,
    JSON_VALUE(metadata,'$.chat.lastMessage.direction') direction,
    JSON_VALUE(metadata,'$.chat.lastMessage.type') message_type,
    SAFE_CAST(JSON_VALUE(metadata,'$.chat.lastMessage.createdAt') AS TIMESTAMP) mensagem_em,
    SAFE.PARSE_JSON(JSON_VALUE(metadata,'$.chat.lastMessage.payload')) p
  FROM `blips-bigdata.bigquery___finza.chat_events`
  WHERE timestamp >= TIMESTAMP('2026-08-20 03:00:00'))
SELECT protocol, chat_id, message_id,
  ANY_VALUE(direction) direction, ANY_VALUE(message_type) message_type, MIN(mensagem_em) mensagem_em,
  ANY_VALUE(COALESCE(JSON_VALUE(p,'$.text'), JSON_VALUE(p,'$.comment'))) texto,
  ANY_VALUE(JSON_VALUE(p,'$.type')) system_type,            -- CHAT_TRANSFERED, FINISH_CHAT… quando direction='info'
  ANY_VALUE(department) department_id,
  CASE WHEN ANY_VALUE(direction)='in' THEN 'client'
       WHEN LOGICAL_OR(eventType='chat_user_interaction' AND direction='out') THEN 'agent'
       WHEN ANY_VALUE(direction)='out' THEN 'bot' ELSE 'system' END sender_kind,
  ANY_VALUE(IF(eventType='chat_user_interaction', agent, NULL)) agent_id,
  'reconstrucao_lastMessage' fonte
FROM ev WHERE message_id IS NOT NULL
GROUP BY 1,2,3;
```
Custo: ~65 MB. Lado IA (texto completo dos turnos com IA): `finza-prod-481500.silver_torre.org_finza_actions_interaction_logs` por `protocol`.

### 6.3 Mensagens B · BLIPS Cobrança (completo quando há, amostra no resto)

```sql
WITH cob AS (SELECT ARRAY_AGG(department_id) ids FROM `blips-bigdata.bronze_external_hyperflow.tb_departments_ref`
             WHERE tenant_name='BLIPS' AND is_cobranca_dpto=1 AND is_ia_dpto=0),
base AS (
  SELECT l.protocol FROM `blips-bigdata.bronze_external_hyperflow.list_all_chats` l CROSS JOIN cob
  WHERE l.tenant_name='BLIPS' AND l.created_at >= TIMESTAMP('2026-08-20 03:00:00')
    AND (l.department_id IN UNNEST(cob.ids) OR EXISTS (SELECT 1 FROM UNNEST(l.historical_info.interactions) i WHERE i.department IN UNNEST(cob.ids)))),
ch AS (
  SELECT protocol, ANY_VALUE(chat_id) chat_id, message_id, ANY_VALUE(direction) direction, ANY_VALUE(message_type) message_type,
    MIN(SAFE_CAST(created_at AS TIMESTAMP)) mensagem_em,
    ANY_VALUE(JSON_VALUE(SAFE.PARSE_JSON(payload),'$.text')) texto, ANY_VALUE(JSON_VALUE(SAFE.PARSE_JSON(payload),'$.url')) midia_url,
    ANY_VALUE(system_type) system_type, ANY_VALUE(sender_kind) sender_kind, ANY_VALUE(agent_id) agent_id
  FROM `blips-bigdata.bronze_hyperflow.chat_history`
  WHERE empresa='BLIPS' AND message_id IS NOT NULL AND chat_created_at >= '2026-08-19' AND protocol IN (SELECT protocol FROM base)
  GROUP BY protocol, message_id),
tm AS (
  SELECT protocol, ANY_VALUE(chat_id) chat_id, message_id, ANY_VALUE(direcao) direction, ANY_VALUE(tipo_mensagem) message_type,
    MIN(mensagem_em) mensagem_em, ANY_VALUE(conteudo_texto) texto, CAST(NULL AS STRING) midia_url, CAST(NULL AS STRING) system_type,
    CASE WHEN ANY_VALUE(direcao)='in' THEN 'client'
         WHEN LOGICAL_OR(evento_origem_tipo='chat_user_interaction' AND direcao='out') THEN 'agent'
         WHEN ANY_VALUE(direcao)='out' THEN 'bot' ELSE 'system' END sender_kind,
    ANY_VALUE(IF(evento_origem_tipo='chat_user_interaction', agente_evento_id, NULL)) agent_id
  FROM `blips-bigdata.bronze_external_hyperflow.tb_chat_messages`
  WHERE tenant_name='BLIPS' AND mensagem_em >= TIMESTAMP('2026-08-19')
    AND protocol IN (SELECT protocol FROM base) AND protocol NOT IN (SELECT DISTINCT protocol FROM ch)
  GROUP BY protocol, message_id)
SELECT *, 'chat_history_completo' fonte FROM ch
UNION ALL
SELECT *, 'tb_chat_messages_amostra' FROM tm;
```
Custo: ~3,2 GB por execução. No `chat_history`, `info` aparece com `sender_kind` = agent/bot; use `system_type` para identificar evento de sistema.

### 6.4 Enriquecimento opcional (BLIPS)

`silver_auditoria.atendimentos` (resumo, sentimento, tópicos, flags, `avg_evaluation_score`) e `silver_auditoria.helper_messages` (transcrição de áudio do cliente), ambos por `protocol`.
