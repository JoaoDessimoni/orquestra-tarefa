# Domínio · Agentes de IA (volume, encaminhamento, custo LLM)

Mapeado em 2026-10-22 para o `Relatório Agentes Finza.html` (Esperanza e Valentina, jun–out/2026).
Execução com `projectId = finza-prod-481500` (lê `blips-bigdata` cross-project).

## Tabelas

| Tabela | Grão | Uso |
|---|---|---|
| `finza-prod-481500.silver_torre.org_blips_ai_protocols` / `org_finza_ai_protocols` | 1 linha por protocolo (já deduplicado) | volume por agente (`agent_id`, `started_at`) |
| `blips-bigdata.blips___desk.chat_events` / `bigquery___finza.chat_events` | evento de chat (partição `timestamp`, cluster `eventType`) | canal (`metadata.chat.isBroadcast`) e transferência (`eventType='chat_transferred'`, `metadata.transferredToDepartment` = **ID**) |
| `blips-bigdata.bronze_external_hyperflow.tb_departments_ref` | departamento | nome do departamento por `department_id` |
| `blips-bigdata.s1_custos_ia.v_custos_por_agente` | custo diário por SKU/projeto | custo LLM por `agent_area` (`cost_usd` NUMERIC, `cost_date` DATE, `tokens_*`) |
| `blips-bigdata.s1_custos_ia.v_fx_diario` | dia | câmbio USD→BRL (`usd_brl_rate`), taxa do billing GCP |

`agent_id` dos agentes: Esperanza·Blips `e9dbe911-3408-42f5-980a-3413d2becbc3` · Esperanza·Finza `c2e3a30e-31ff-49fb-8243-456bbf761df0` · Valentina·Finza `9a952883-7d34-4959-8f20-979bbec2bb59` · Clara·Blips `418fb5c2-…` · Clara·Finza `b9939d16-…` (nomes em `org_*.ai_agents` na Torre).

`agent_area` relevantes: `Esperanza - Cobrança`, `Valentina - iA Atendimento N1`, `Tageador Finza`.

## Armadilhas

- **`finza-prod-481500.bronze.org_*_ai_protocols` não existe mais** (out/2026). Use `silver_torre` (deduplicado; não precisa `ROW_NUMBER` por `_airbyte_extracted_at`).
- **Ponte de canal do Finza é fraca:** Esperanza·Finza só tem `isBroadcast` em ~34% dos protocolos. Não force split proativo/receptivo nesse caso sem declarar o `sem_match`.
- **`v_fx_diario` ≠ câmbio de mercado:** é a taxa mensal do billing GCP (~5,82–5,93 em 2026), e a Torre (`public.fx_rates`) usa outra (~5,0–5,2). Declare qual delas usou.
- **Gemini/Vertex caem em `nao_atribuido`** (ex.: projeto `blips-gastarcredito-temporario`). Não atribua a nenhum agente.
- **Ingestão de custo D-2:** os 2 últimos dias vêm zerados, e isso é ingestão pendente, não custo zero.
- **Reconciliação:** a Torre tem o mesmo custo em `public.cost_totals` (`cost_type_key='custom_openai'`, `dimensions->>'agent'`), a partir de 01/09/2026. Setembro bate centavo a centavo (Esperanza US$ 290,32).
- Encaminhamento do desk (`chat_transferred`) ≠ transbordo/transferência da Torre (`ai_funnel_events.transfer_type`). São medidas diferentes, não substitua uma pela outra.
- **Encaminhamento da Clara ≠ `chat_transferred` do desk.** Das conversas da Clara com `chat_transferred` (01/08–21/10: 414 de 903), 79% são a analista do time de formalização puxando a conversa, sem nota e sem o resumo da Clara. O que a IA mandou para humano é a interseção com o evento de transferência da Clara na Torre (`org_*.ai_funnel_events`, `transferred_to_human`, `agent_id` da Clara): 75 de 903. A Clara **tem** `ai_funnel_events`, mas `transfer_type` vem sempre nulo (sem split transbordo/transferência) e nem todo evento vira transferência no Hyperflow (75 de 129 protocolos). Motivo: `transfer_reason` "Motivo categorizado - <categoria>. Escolha IA - <justificativa>"; sem tag = categoria vazia ("."). Canal da conversa: `JSON_QUERY(metadata,'$.chat.isBroadcast')` em qualquer evento do protocolo. Custo: `agent_area = 'Clara V2 - Formalização'` (julho = testes; implantação 01/08/2026). "Clara - iA Onboarding" é outro agente, o v1. O funil de formalização (turma em `RESPONSIBLE_ADDRESS` × conversa no depto IA - Formalização × protocolo na Torre × "Formalizacao APROVADA por") segue as definições da skill `raio-x-clara`. Departamentos IA - Formalização: Blips `6a80917d9e841905d20806e0`, Finza `6a70b455e2304d735ed7477b`.

## SQL — custo diário por agente

```sql
SELECT cost_date,
  ROUND(SUM(IF(agent_area='Esperanza - Cobrança',cost_usd,0)),2) esp,
  ROUND(SUM(IF(agent_area='Valentina - iA Atendimento N1',cost_usd,0)),2) val,
  ROUND(SUM(IF(agent_area='Tageador Finza',cost_usd,0)),2) tag
FROM `blips-bigdata.s1_custos_ia.v_custos_por_agente`
WHERE cost_date BETWEEN @ini AND @fim
GROUP BY 1 ORDER BY 1;
```

## SQL — protocolos, canal e transferência no desk por dia

```sql
WITH p AS (
  SELECT 'esp-blips' k,'b' src, protocol, DATE(started_at) d FROM `finza-prod-481500.silver_torre.org_blips_ai_protocols`
  WHERE agent_id='e9dbe911-3408-42f5-980a-3413d2becbc3' AND DATE(started_at) BETWEEN @ini AND @fim),
ev AS (
  SELECT 'b' src, protocol, eventType, JSON_VALUE(metadata,'$.chat.isBroadcast') isbc
  FROM `blips-bigdata.blips___desk.chat_events` WHERE timestamp >= TIMESTAMP_SUB(TIMESTAMP(@ini), INTERVAL 7 DAY) AND protocol IS NOT NULL),
bc AS (SELECT src, protocol, MAX(isbc) isbc, LOGICAL_OR(eventType='chat_transferred') tr FROM ev GROUP BY 1,2)
SELECT k, d, COUNT(*) protocolos, COUNTIF(isbc='true') proativo, COUNTIF(isbc='false') receptivo,
       COUNTIF(isbc IS NULL) sem_match, COUNTIF(tr) transferidos_desk
FROM p LEFT JOIN bc USING (src, protocol) GROUP BY 1,2 ORDER BY 1,2;
```
