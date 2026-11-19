# 02 · Fontes de dados — BigQuery + API do Hyperflow (híbrido)

O levantamento foi validado em 2026-11-18. O mapa vivo deste domínio fica na skill `bigquery-finza/atendimento-mensagens.md`.
Toda consulta é **somente leitura** (`execute_sql_readonly`) no projeto `blips-bigdata`, mais `finza-prod-481500.silver_torre` para o lado da IA.

## 1. Veredito: o BigQuery não tem o log completo de mensagens

| Recorte | Log completo no BQ | Melhor fonte no BQ |
|---|---|---|
| A · FINZA | **Não existe** | Reconstrução via `lastMessage` em `bigquery___finza.chat_events`. Cobre 100% dos protocolos e ~50% das mensagens. Áudio e imagem vêm sem texto |
| B · BLIPS Cobrança | **Parcial** | `bronze_hyperflow.chat_history` (v2, = `getChatMessages` da API), completo em 34% dos chats (19.650 de 57.847). Os outros 66% só têm a amostra de `tb_chat_messages` |

**Decisão (João, 2026-11-19): fonte híbrida.**

1. **O BigQuery cobre 100% dos chats para o universo**: volumes, jornada, departamentos, agentes, CNPJ e telefone. As faixas de tempo saem da melhor fonte de mensagens disponível para cada chat, com a coluna `fonte` gravada e visível no artefato.
2. **A API do Hyperflow (`getChatMessages(protocol)`, query GraphQL, só leitura)** substitui a fonte do BQ em dois grupos:
   - todos os chats da **amostra do avaliador** (spec 04 §7), para o LLM ler a conversa completa;
   - os chats **FINZA com interação humana** (`historical_info.agents` não vazio e não broadcast-sem-resposta), onde a reconstrução mais distorce o tempo de resposta.
   - Pré-requisito: token da API do Hyperflow (header `tenant` do desk de cada empresa). Ele não está no `.env` do workspace e precisa ser fornecido pelo João.
   - Limites:
     - ritmo conservador (≤ 5 req/s);
     - retomável por `protocol`;
     - grava em `dados/brutos/api/<chat_id>.json`;
     - em caso de falha, mantém a fonte do BQ.
3. Ordem de preferência da fonte por chat: `api_getChatMessages` > `chat_history_completo` > `tb_chat_messages_amostra` / `reconstrucao_lastMessage`.

## 2. Recortes

| Recorte | Filtro |
|---|---|
| A · FINZA | `list_all_chats.tenant_name = 'FINZA'`, todos os departamentos |
| B · BLIPS Cobrança | `tenant_name = 'BLIPS'` e o chat **passou** por um dos **20 deptos** com `is_cobranca_dpto = 1 AND is_ia_dpto = 0` em `tb_departments_ref` |

Os 20 deptos de B são:
- "Cobrança" (`67c75289ae3f8d2070129f38`);
- as faixas 01–07 / 08–30 / 31–60 / 61–90 / 91+ / 01–10 / 11–30;
- Adimplente Preventivo, Bitrix, Jurídico, Novos Originadores, RCS, Suprimentos (2 ids);
- Cobrança Automatizada, Cobrança Email, FIDC, FIDC Atraso Maior, Fallback Cobrança, Liquidação Financeira.

"Passou" = `department_id` atual **ou** qualquer `historical_info.interactions[].department` na lista. "IA - Financeiro" fica fora porque é IA, não fila humana.

Janela: `created_at` ≥ 2026-08-20 00:00 e < 2026-11-19 00:00 (`America/Sao_Paulo`).

## 3. Catálogo de tabelas usadas

| Tabela | Uso | Cobertura |
|---|---|---|
| `blips-bigdata.bronze_external_hyperflow.list_all_chats` | **Base de chats**: `_id` = `chat_id`, `protocol`, `created_at`, `finished_at`, `status`, `is_broadcast`, `channel`, `department_id/name`, `contact_phone`, `historical_info.interactions[]` (jornada: fila, transferência, depto), `historical_info.agents[]` | BLIPS + FINZA, todo o histórico |
| `blips-bigdata.bronze_external_hyperflow.tb_departments_ref` | Nome do depto e flags `is_cobranca_dpto` / `is_ia_dpto` / `categoria_dpto` | BLIPS + FINZA |
| `blips-bigdata.bronze_external_hyperflow.tb_agents_ref` | Nome e e-mail do atendente | BLIPS + FINZA |
| `blips-bigdata.bronze_external_hyperflow.tb_contacts_crm_ref` | **CNPJ** pelo telefone canônico: `cliente_principal.cnpj_cpf`, `clientes_crm[]`, `match_ambiguo` | CRM BLIPS. Cobertura: FINZA 87,1%, BLIPS-Cob 80,4% |
| `blips-bigdata.bigquery___finza.chat_events` | Mensagens FINZA (reconstrução) e eventos `chat_transferred` / `chat_assigned` / `chat_finished` | FINZA, desde 2025-10-08 |
| `blips-bigdata.bronze_hyperflow.chat_history` | Mensagens BLIPS completas (`sender_kind`, `direction`, `message_type`, `payload`, `agent_id`, `system_type`) | só BLIPS, 34% dos chats de Cobrança |
| `blips-bigdata.bronze_external_hyperflow.tb_chat_messages` | Mensagens BLIPS amostradas (in 57%, out 50%) | só BLIPS |
| `blips-bigdata.silver_auditoria.helper_messages` | **Transcrição de áudio** do cliente (única no lake), por `protocol` | só BLIPS, 477 áudios em Cobrança |
| `blips-bigdata.silver_auditoria.atendimentos` | Auditoria Nascimento (resumo, sentimento, nota), por `protocol`. **Benchmark** do avaliador | só BLIPS, 63% de Cobrança |
| `finza-prod-481500.silver_torre.org_finza_actions_interaction_logs` | Turnos da IA FINZA (`user_message`, `ai_response`, `sentiment`, `transferred_to_human`) | FINZA desde 2026-06-21, 58% casam com o desk |
| `finza-prod-481500.silver_torre.org_*_ai_protocols` | Protocolo → agente de IA (`agent_id`) | as duas orgs |

**Não usar:**
- `gold_HYPERFLOW.service_chats` (só BLIPS);
- `blips___desk.chat_events` (31 GB em 90 dias; use `tb_chat_messages`);
- `bronze_mongodb_IA.*` (legado, Airbyte desligado);
- `userInteractions` / `systemInteractions` como contagem de mensagem.

## 4. Autoria da mensagem (cliente × humano × IA × sistema)

| Fonte | Regra |
|---|---|
| API e `chat_history` | `sender_kind`: `client` / `agent` (humano) / `bot`. `info` ou `system_type` preenchido = sistema |
| Reconstrução (FINZA e amostra BLIPS) | `in` = cliente. `out` vindo de evento `chat_user_interaction` = humano (`agent` = id do atendente). Demais `out` = bot. `info` = sistema. Contra o `sender_kind`: precisão 96%, **recall ~66%** |
| IA × URA/automação | `bot` vira **IA** quando o chat passou por depto `is_ia_dpto = 1` (BLIPS "IA - Financeiro" `6764392440b22f327e145e70`, FINZA `698480eb046eaf3f6da39adb`) **ou** quando o protocolo está em `silver_torre.org_*_ai_protocols` |

Ressalvas:
- A IA **não** é agente do desk. Ter agente atribuído não prova fala humana.
- Mensagens automáticas de fila (`bot` fora de depto IA) são `sistema` para a spec 03: não contam como resposta.

## 5. SQL de extração (validado em 2026-11-18)

### 5.1 Base de chats por recorte (metadados + CNPJ)

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
  WHERE l.created_at >= TIMESTAMP('2026-08-20 00:00:00','America/Sao_Paulo')
    AND l.created_at <  TIMESTAMP('2026-11-19 00:00:00','America/Sao_Paulo')
    AND l.tenant_name IN ('FINZA','BLIPS'))
SELECT l.* EXCEPT (t, passou_cob),
  x.cliente_principal.cnpj_cpf cnpj_principal, x.match_ambiguo, ARRAY(SELECT c.cnpj_cpf FROM UNNEST(x.clientes_crm) c) cnpjs
FROM l LEFT JOIN `blips-bigdata.bronze_external_hyperflow.tb_contacts_crm_ref` x
  ON x.telefone_canonico = IF(LENGTH(l.t) BETWEEN 10 AND 11, CONCAT(SUBSTR(l.t,1,2), RIGHT(l.t,8)), NULL)
WHERE l.tenant_name='FINZA' OR l.passou_cob;
```

### 5.2 Mensagens A · FINZA (reconstrução; custo ~65 MB)

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

Lado da IA FINZA (texto completo dos turnos com IA): `finza-prod-481500.silver_torre.org_finza_actions_interaction_logs`, por `protocol`.

### 5.3 Mensagens B · BLIPS Cobrança (completo quando há, amostra no resto; custo ~3,2 GB)

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

No `chat_history`, `info` aparece com `sender_kind` = agent/bot. Use `system_type` para identificar evento de sistema.

### 5.4 Enriquecimento (BLIPS)

`silver_auditoria.helper_messages` traz a transcrição de áudio do cliente. Ela entra no `texto` da mensagem de áudio, casada por `protocol` e pelo timestamp mais próximo. `silver_auditoria.atendimentos` traz nota e sentimento do auditor Nascimento e serve como comparação na calibração (spec 09). A ponte é `protocol`, com colisão de ~5,8%.

## 6. Saída da extração (`dados/brutos/`, gitignored)

| Arquivo | Conteúdo |
|---|---|
| `chats.jsonl` | 1 linha por chat (SQL 5.1) |
| `mensagens_bq.jsonl` | SQL 5.2 + 5.3, com `fonte` |
| `api/<chat_id>.json` | `getChatMessages` bruto (§1.2) |
| `ia_turnos.jsonl` | `actions_interaction_logs` FINZA, para o lado da IA |
| `transcricoes.jsonl` | `helper_messages` BLIPS |

Normalizado em `dados/protocolos/<chat_id>.json`: metadados, mensagens unificadas e ordenadas, `fonte` e autor resolvido. Essa é a entrada das specs 03 e 04.

## 7. Retrato da janela (para reconciliação na spec 09)

| Recorte | Chats | Clientes | Broadcast | Com agente | Com CNPJ |
|---|---:|---:|---:|---:|---:|
| A · FINZA | 22.410 | 4.219 | 12.366 | 9.252 | 87,1% (4.330 ambíguos) |
| B · BLIPS Cobrança | 57.847 | 9.985 | 1.788 | 55.563 | 80,4% (9.181 ambíguos) |

Por mês (ago desde 20/08, set, out, nov até 18/11):
- FINZA: 1.695 · 7.324 · 7.810 · 5.581
- BLIPS Cobrança: 7.758 · 19.862 · 18.925 · 11.302

Os números de 18/11 cobrem até 18/11. A extração final vai até 18/11 23:59.

## 8. Limitações declaradas no artefato

- Chats sem API ficam com o tempo de resposta pela fonte do BQ, com selo **"fonte aproximada"** e filtro `fonte` disponível.
- Áudio sem transcrição (todo o FINZA fora da API e a maior parte da BLIPS) aparece como "áudio não transcrito".
- CNPJ vem pela ponte do CRM BLIPS por telefone. Telefone ambíguo mostra todos os CNPJs.
