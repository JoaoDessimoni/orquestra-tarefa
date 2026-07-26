# Catálogo de Consultas BigQuery — Custo & Volume dos Agentes de IA (Esperanza / Valentina)

> **Squad:** IAF — Inteligência Artificial em Finanças (Finza)
> **Gerado em:** 24/07/2026
> **Projeto de billing usado na execução:** `finza-prod-481500` (as três leem dados em `blips-bigdata` via leitura cross-project)
> **Modo de execução:** `execute_sql_readonly` (somente SELECT)
> **Status dos retornos:** valores reais capturados em 24/07/2026 — reexecutar para atualizar.

Este documento cataloga três consultas que, juntas, formam uma visão de **custo + volume** dos agentes conversacionais Esperanza e Valentina nos ecossistemas Finza e Blips:

| #   | Slug                              | O que mede                                           | Unidade    | Fonte                                   |
| --- | --------------------------------- | ---------------------------------------------------- | ---------- | --------------------------------------- |
| 1   | `protocolos_disparo_vs_receptivo` | Volume de protocolos e split ativo (HSM) × receptivo | protocolos | `chat_events` + `*_ai_protocols`        |
| 2   | `custo_llm_usd_por_agente`        | Custo de inferência (tokens LLM) por agente          | USD        | `s1_custos_ia.v_custos_por_agente`      |
| 3   | `custo_hyperflow_rs_por_mes`      | Custo mensal da plataforma Hyperflow (plano)         | BRL        | `bronze_hyperflow_finza.LIST_ALL_BILLS` |

---

## Convenções e premissas comuns

- **Dedup de ingestão (Airbyte):** onde há `ROW_NUMBER() OVER (PARTITION BY <chave> ORDER BY <timestamp> DESC)` + `WHERE rn = 1`, a intenção é ficar apenas com o registro **mais recente** de cada entidade, descartando snapshots repetidos vindos da replicação. Chaves usadas: `protocol` (Q1) e `id` (Q3).
- **Janela de análise 09–23/jul/2026:** recorte recorrente nas queries. O corte em **09/jul** também separa os buckets `pré_telemetria` × `telemetria` da Q2 — ver observação sobre o significado desse marco na Q2.
- **Timezone:** os filtros usam `DATE(started_at)` / `SAFE_CAST(cost_date AS DATE)`. Se as colunas de origem estiverem em **UTC**, protocolos/custos na borda noturna (horário de Brasília) podem escorregar para o dia vizinho e distorcer as pontas das janelas fechadas. _A confirmar o fuso de cada coluna de origem._

---

## 1. `protocolos_disparo_vs_receptivo`

### Contexto e objetivo

Mede **quantos protocolos** cada instância de agente gerou na janela e classifica cada protocolo como **disparo HSM** (conversa iniciada de forma ativa / broadcast — template de WhatsApp) ou **receptivo** (cliente iniciou). Serve para entender o **mix ativo × receptivo** por instância e, de quebra, funciona como **termômetro da ponte de dados** entre as tabelas de protocolo e a base de eventos de chat.

Instâncias avaliadas:

- **Esperanza·Finza** — `agent_id = c2e3a30e-31ff-49fb-8243-456bbf761df0`
- **Valentina·Finza** — `agent_id = 9a952883-7d34-4959-8f20-979bbec2bb59`
- **Esperanza·Blips** — todos os protocolos de `org_blips_ai_protocols` (rótulo fixo, **sem** filtro por `agent_id`)

### Fontes de dados

- `blips-bigdata.bigquery___finza.chat_events` — eventos de chat (lado Finza), campo `metadata.chat.isBroadcast`.
- `blips-bigdata.blips___desk.chat_events` — eventos de chat (lado Blips).
- `finza-prod-481500.bronze.org_finza_ai_protocols` — protocolos dos agentes Finza.
- `finza-prod-481500.bronze.org_blips_ai_protocols` — protocolos dos agentes Blips.

### Query

```sql
WITH
fbc AS (SELECT protocol, MAX(JSON_VALUE(metadata,'$.chat.isBroadcast')) isbc
        FROM `blips-bigdata.bigquery___finza.chat_events` WHERE protocol IS NOT NULL GROUP BY protocol),
bbc AS (SELECT protocol, MAX(JSON_VALUE(metadata,'$.chat.isBroadcast')) isbc
        FROM `blips-bigdata.blips___desk.chat_events`      WHERE protocol IS NOT NULL GROUP BY protocol),
fp AS (SELECT protocol, agent_id FROM (
    SELECT protocol,agent_id,started_at,ROW_NUMBER() OVER(PARTITION BY protocol ORDER BY _airbyte_extracted_at DESC) rn
    FROM `finza-prod-481500.bronze.org_finza_ai_protocols`) WHERE rn=1 AND DATE(started_at) BETWEEN '2026-07-09' AND '2026-07-23'),
bp AS (SELECT protocol FROM (
    SELECT protocol,started_at,ROW_NUMBER() OVER(PARTITION BY protocol ORDER BY _airbyte_extracted_at DESC) rn
    FROM `finza-prod-481500.bronze.org_blips_ai_protocols`)  WHERE rn=1 AND DATE(started_at) BETWEEN '2026-07-09' AND '2026-07-23')
SELECT inst,
  COUNT(*) protocolos,
  COUNTIF(isbc='true')  AS disparo_hsm,
  COUNTIF(isbc='false') AS receptivo,
  COUNTIF(isbc IS NULL) AS sem_match
FROM (
  SELECT CASE agent_id WHEN 'c2e3a30e-31ff-49fb-8243-456bbf761df0' THEN 'Esperanza·Finza'
                       WHEN '9a952883-7d34-4959-8f20-979bbec2bb59' THEN 'Valentina·Finza' END inst, fbc.isbc
  FROM fp LEFT JOIN fbc USING(protocol)
  WHERE agent_id IN ('c2e3a30e-31ff-49fb-8243-456bbf761df0','9a952883-7d34-4959-8f20-979bbec2bb59')
  UNION ALL
  SELECT 'Esperanza·Blips', bbc.isbc FROM bp LEFT JOIN bbc USING(protocol)
)
GROUP BY inst ORDER BY protocolos DESC;
```

### Mecânica (como funciona)

- **`fbc` / `bbc`** reduzem os eventos a **uma classificação por protocolo** via `MAX(JSON_VALUE(...))`. Como `JSON_VALUE` retorna **string**, `'true' > 'false'` na ordenação lexicográfica — logo o `MAX` implementa a regra _"se qualquer evento do protocolo foi broadcast, o protocolo é broadcast"_. Resultado possível: `'true'`, `'false'` ou `NULL`.
- **`fp` / `bp`** deduplicam os protocolos (registro Airbyte mais recente) e aplicam a janela sobre `started_at`.
- O corpo faz `LEFT JOIN` protocolo→classificação. Protocolo **sem correspondência** cai em `isbc IS NULL` → coluna **`sem_match`**.

### Parâmetros

- Janela: `started_at` entre **2026-07-09** e **2026-07-23** (inclusive).
- `agent_id`: apenas Esperanza·Finza e Valentina·Finza no ramo Finza; ramo Blips sem filtro.

### Exemplo de output (formato)

Cinco colunas, uma linha por instância:

```
inst (STRING) | protocolos (INT) | disparo_hsm (INT) | receptivo (INT) | sem_match (INT)
```

### Retorno atual (24/07/2026)

| inst            | protocolos | disparo_hsm | receptivo | sem_match | match rate |
| --------------- | ---------: | ----------: | --------: | --------: | ---------: |
| Esperanza·Blips |      1.217 |         670 |       534 |        13 |      98,9% |
| Valentina·Finza |        442 |           0 |       359 |        83 |      81,2% |
| Esperanza·Finza |        161 |          45 |        13 |       103 |      36,0% |

_Custo de execução: ~137,5 MB processados._

### O que está nos dizendo agora

- **A ponte de dados do lado Finza está furada.** O join Blips (`blips___desk.chat_events`) é praticamente perfeito (13 órfãos em 1.217, ~1%). Já o lado Finza (`bigquery___finza.chat_events`) tem cobertura fraca: **Esperanza·Finza casa apenas 36%** dos protocolos (103 de 161 sem classificação). Consequência prática: **o split disparo × receptivo do Finza não é confiável hoje** — a maior parte dos protocolos Finza não é classificada.
- **Valentina·Finza tem 0 disparos**, consistente com um papel de **roteamento/atendimento receptivo N1** (não faz campanha HSM de saída). Ressalva: com 83 `sem_match`, esse `0` é um **piso, não um fato confirmado** — se algum órfão for broadcast, o número real sobe.
- **Esperanza·Blips é o retrato limpo** (55% disparo / 44% receptivo) e serve de baseline de qualidade para comparar o Finza.

### Limitações / pontos de atenção

- `sem_match` é **ambíguo**: mistura "protocolo ausente do `chat_events`" com "protocolo presente, mas sem o campo `isBroadcast`". Distinguir exige uma query de diagnóstico adicional.
- **Assimetria de método:** o ramo Finza filtra por `agent_id`; o Blips assume que _todo_ protocolo em `org_blips_ai_protocols` é Esperanza. Se a Blips rodar outro agente nessa tabela, o número Blips fica contaminado. _A confirmar._
- `MAX` sobre string funciona por acaso lexicográfico (`'true'`/`'false'` minúsculos). Se a origem mudar para boolean nativo ou casing diferente (`'True'`), quebra silencioso. Alternativa robusta: `LOGICAL_OR(JSON_VALUE(...) = 'true')`.
- Depende de **`protocol` ter o mesmo formato** entre os dois projetos. Descasamento de formato é a suspeita nº 1 para o `sem_match` alto no Finza.

---

## 2. `custo_llm_usd_por_agente`

### Contexto e objetivo

Consolida o **custo de inferência (tokens de LLM) em USD** por agente, quebrando em quatro janelas para comparar **junho × julho** e **pré × pós o marco de 09/jul** (buckets `pré_telemetria` / `telemetria`). Serve para monitorar gasto de LLM por agente e avaliar o efeito de mudanças ao longo do tempo.

### Fonte de dados

- `blips-bigdata.s1_custos_ia.v_custos_por_agente` — view de custos de IA por agente (`agent_area`, `cost_date`, `cost_usd`).

### Query

```sql
SELECT
  agent_area,
  ROUND(SUM(CASE WHEN SAFE_CAST(cost_date AS DATE) BETWEEN '2026-06-01' AND '2026-06-30'
                 THEN CAST(cost_usd AS FLOAT64) END), 2) AS usd_junho,
  ROUND(SUM(CASE WHEN SAFE_CAST(cost_date AS DATE) BETWEEN '2026-07-01' AND '2026-07-23'
                 THEN CAST(cost_usd AS FLOAT64) END), 2) AS usd_julho_ate23,
  ROUND(SUM(CASE WHEN SAFE_CAST(cost_date AS DATE) BETWEEN '2026-06-01' AND '2026-07-08'
                 THEN CAST(cost_usd AS FLOAT64) END), 2) AS usd_pre_telemetria,
  ROUND(SUM(CASE WHEN SAFE_CAST(cost_date AS DATE) BETWEEN '2026-07-09' AND '2026-07-23'
                 THEN CAST(cost_usd AS FLOAT64) END), 2) AS usd_telemetria
FROM `blips-bigdata.s1_custos_ia.v_custos_por_agente`
WHERE agent_area LIKE 'Esperanza%' OR agent_area LIKE 'Valentina%'
GROUP BY agent_area
ORDER BY usd_junho DESC;
```

### Mecânica

- Quatro `SUM(CASE WHEN ...)` fazem **pivô por janela de data** na mesma passada.
- `SAFE_CAST(cost_date AS DATE)` tolera valores de data malformados (retorna `NULL` em vez de quebrar); `CAST(cost_usd AS FLOAT64)` assume que o custo vem como string/numérico convertível.
- Filtro por prefixo em `agent_area` (`Esperanza%` / `Valentina%`).
- **Relação entre buckets:** as janelas foram desenhadas de forma consistente — `pré_telemetria` (01/jun–08/jul) + `telemetria` (09–23/jul) = `junho` + `julho_ate23`.

### Exemplo de output (formato)

```
agent_area (STRING) | usd_junho | usd_julho_ate23 | usd_pre_telemetria | usd_telemetria   (todos FLOAT)
```

### Retorno atual (24/07/2026)

| agent_area                    | usd_junho | usd_julho_ate23 | usd_pré_telemetria | usd_telemetria |
| ----------------------------- | --------: | --------------: | -----------------: | -------------: |
| Esperanza - Cobrança          |  3.189,77 |          649,88 |           3.602,26 |         237,39 |
| Valentina - iA Atendimento N1 |      0,14 |            0,42 |               0,15 |           0,41 |

_Custo de execução: ~5,0 MB processados._

### O que está nos dizendo agora

- **Esperanza concentra praticamente todo o custo de LLM.** No período 01/jun–23/jul, Esperanza somou **USD 3.839,65** contra **USD 0,56** da Valentina — uma diferença de ~5.000×. Coerente com Esperanza (Cobrança) sendo o agente conversacional pesado e Valentina (N1) um fluxo leve/quase determinístico. _Hipótese a confirmar: verificar se Valentina realmente usa LLM ou majoritariamente roteamento sem inferência._
- **Queda abrupta de custo em Esperanza após 09/jul.** Custo/dia no bucket `pré_telemetria` (38 dias): ~**USD 94,80/dia**. No bucket `telemetria` (15 dias): ~**USD 15,83/dia** — uma **redução de ~83% no custo diário**. O marco de 09/jul derrubou o gasto de forma expressiva.
- **O que é "telemetria" precisa ser confirmado.** O nome dos buckets sugere que em 09/jul entrou algo (instrumentação de telemetria, troca de modelo, mudança de prompt/arquitetura, ou queda de volume). A causa da queda de custo **não está provada por esta query** — é preciso cruzar com volume (Q1) e com o changelog do agente. _A confirmar._

### Limitações / pontos de atenção

- **Mapeamento de `agent_area` ↔ instâncias da Q1 não é 1:1.** "Esperanza - Cobrança" é um único `agent_area`, enquanto a Q1 separa Esperanza em Finza e Blips. Não dá para dividir custo por plataforma diretamente. _A confirmar como `agent_area` se relaciona com `agent_id`/instância._
- `CAST(cost_usd AS FLOAT64)` **não** é `SAFE_CAST`: se algum `cost_usd` vier malformado, a query **quebra** (diferente do tratamento dado a `cost_date`). Considerar `SAFE_CAST` por consistência.
- Buckets `junho`/`julho_ate23` e `pré`/`telemetria` **se sobrepõem em cobertura** (são dois recortes do mesmo período); somar as quatro colunas conta o período em dobro.

---

## 3. `custo_hyperflow_rs_por_mes`

### Contexto e objetivo

Extrai o **custo mensal real da plataforma Hyperflow em BRL**, considerando apenas as faturas de renovação de plano (`type = 'renew_plan'`) — segundo o comentário do autor, essa é a linha que representa o custo efetivo do Hyperflow. Serve para acompanhar a **evolução do gasto de plataforma** (distinto do custo de LLM da Q2).

### Fonte de dados

- `blips-bigdata.bronze_hyperflow_finza.LIST_ALL_BILLS` — faturas do Hyperflow (`id`, `value`, `referencemonth`, `type`, `data_hora`).

### Query

```sql
WITH b AS (
  SELECT id, value, referencemonth,
         ROW_NUMBER() OVER (PARTITION BY id ORDER BY data_hora DESC) AS rn  -- dedup snapshots
  FROM `blips-bigdata.bronze_hyperflow_finza.LIST_ALL_BILLS`
  WHERE type = 'renew_plan'          -- fatura mensal do plano (o custo real do Hyperflow)
)
SELECT SUBSTR(referencemonth, 1, 7) AS mes_consumo,
       ROUND(SUM(value), 2)         AS custo_hyperflow_rs
FROM b
WHERE rn = 1
GROUP BY 1
ORDER BY 1 DESC;
```

### Mecânica

- Filtra `type = 'renew_plan'` (fatura de renovação do plano).
- Deduplica por `id` de fatura, mantendo o snapshot mais recente (`data_hora DESC`, `rn = 1`) — evita somar o mesmo boleto replicado.
- Agrupa por `referencemonth` truncado a `YYYY-MM` (`SUBSTR(...,1,7)`) e soma `value`.

### Exemplo de output (formato)

```
mes_consumo (STRING, 'YYYY-MM') | custo_hyperflow_rs (FLOAT, BRL)
```

### Retorno atual (24/07/2026)

| mes_consumo | custo_hyperflow_rs (R$) |
| ----------- | ----------------------: |
| 2026-06     |                2.514,80 |
| 2026-05     |                2.948,53 |
| 2026-04     |                2.203,05 |
| 2026-03     |                2.435,93 |
| 2026-02     |                  917,43 |
| 2025-12     |                  853,60 |
| 2025-11     |                1.691,73 |
| 2025-10     |                  809,10 |
| 2025-09     |                  749,00 |
| 2025-08     |                  749,00 |

_Custo de execução: ~2 KB processados (tabela pequena)._

### O que está nos dizendo agora

- **Tendência de alta com patamar-base migrando.** Começa em R$ 749,00 (ago/set 2025 — provável plano-base), escala ao longo de 2025/2026 e atinge o **pico de R$ 2.948,53 em maio/2026**, recuando levemente para R$ 2.514,80 em junho.
- **Ordem de grandeza distinta da Q2.** O Hyperflow (plataforma, R$ 2–3 mil/mês) e o LLM da Esperanza (Q2, milhares de USD/mês) são **naturezas de custo diferentes** — plataforma de atendimento vs. inferência de modelo. Somar os dois exige alinhar moeda e conceito.

### Limitações / pontos de atenção

- **Buraco na série: falta `2026-01` (janeiro/2026).** A sequência pula de dez/2025 para fev/2026. Pode ser (a) mês sem fatura `renew_plan`, (b) gap de ingestão, ou (c) `referencemonth` gravado fora do padrão nesse mês. **Investigar** — um mês faltante em série de custo é exatamente o tipo de ponta solta que enviesa análise de tendência.
- **Não há `2026-07`**, esperado se a fatura do mês corrente ainda não foi gerada/ingerida.
- Depende de `type = 'renew_plan'` capturar **todo** o custo relevante do Hyperflow. Se houver outros tipos de cobrança (add-ons, excedentes, mensagens avulsas), o custo total está **subestimado**. _A confirmar quais `type` existem na tabela._

---

## Leitura cruzada das três (visão consolidada)

Juntas, as queries montam um painel **volume → custo** dos agentes:

- **Q1 (volume)** diz _quanto_ cada instância atendeu e o mix ativo/receptivo.
- **Q2 (custo LLM, USD)** diz _quanto custou de inferência_ por agente.
- **Q3 (custo plataforma, BRL)** diz _quanto custou o Hyperflow_ como plataforma.

Cruzamento **ilustrativo** na janela 09–23/jul (mesma janela da Q1 e do bucket `telemetria` da Q2), tratando "Esperanza - Cobrança" como proxy do total Esperanza — **leitura tentativa, pendente de confirmar o mapeamento `agent_area` ↔ instância**:

- Esperanza: ~USD 237,39 de LLM para ~1.378 protocolos (161 Finza + 1.217 Blips) → **~USD 0,17/protocolo**.
- Valentina: ~USD 0,41 para 442 protocolos → **~USD 0,0009/protocolo** (praticamente nulo).

Ou seja: Esperanza é o centro de custo de LLM; Valentina é desprezível nesse eixo. Antes de tirar conclusão de eficiência, é preciso resolver os itens abertos abaixo.

## Pendências abertas (loose ends)

1. **Ponte Finza `chat_events`** — 64% de `sem_match` em Esperanza·Finza. Rodar query de diagnóstico separando "ausente" vs "sem campo `isBroadcast`" e verificar formato de `protocol` entre projetos. _(bloqueia confiança na Q1 lado Finza)_
2. **Significado do marco 09/jul ("telemetria")** — o que mudou que derrubou ~83% do custo diário de Esperanza? Cruzar com volume e changelog. _(bloqueia interpretação da Q2)_
3. **Mapeamento `agent_area` ↔ `agent_id`/instância** — necessário para dividir custo por plataforma (Finza vs Blips) e cruzar Q1×Q2 com rigor.
4. **Janeiro/2026 faltante na Q3** — determinar se é gap de dado ou ausência real de fatura.
5. **Cobertura de `type` na Q3** — confirmar se `renew_plan` captura 100% do custo Hyperflow ou se há tipos adicionais.
6. **Fuso horário** das colunas de data nas três queries — impacto nas bordas das janelas fechadas.
7. **`CAST` não-seguro** de `cost_usd` na Q2 — risco de quebra; avaliar `SAFE_CAST`.
