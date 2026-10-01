# Hyperflow no BigQuery — uso, cobrança e atendimento

Mapa das tabelas de Hyperflow em `blips-bigdata`, com foco em **uso × cobrado**. Levantado e validado em 2026-09-17 (reconciliação fatura × uso bateu à vírgula em 9 de 11 meses fechados).

> Para **integração via API** (GraphQL, webhook runtime, token) a fonte é a skill `hyperflow-blips` dentro do `N8N-AGENT/`. Aqui é só **dado/análise**.

---

## 1 · O que existe, por finalidade

### 1.1 Dinheiro — as tabelas que respondem "quanto pagamos e por quê"

Dataset **`bronze_hyperflow_finza`** (tenant FINZA) e **`bronze_hyperflow`** (tenant BLIPS) têm o mesmo catálogo, espelhado da API administrativa do Hyperflow.

| Tabela | Grão | Para quê |
|---|---|---|
| ⭐ `GET_USAGE_INFO` | 1 linha por (`date`, `type`) | **Consumo faturável diário por tipo de evento.** É a tabela-mãe da análise de custo. |
| ⭐ `LIST_ALL_BILLS` | 1 linha por fatura | **Faturas emitidas** — `value`, `referencemonth`, `status`, `dueat`. |
| `GET_WABA_MESSAGE_TEMPLATES` | 1 linha por (canal, template) | Templates WhatsApp aprovados e a **`category` da Meta** (MARKETING / UTILITY / AUTHENTICATION) — define o preço na régua da Meta. |
| `LIST_BROADCAST_SCHEDULE_LOGS` | 1 linha por contato por disparo | Disparo em massa: `template_name`, `department_name`, `sent_at`, `failed_at`. Permite **volume por template**. |
| `LIST_SCHEDULED_BROADCASTS` | 1 linha por agendamento | Cabeçalho das campanhas. |
| `LIST_CALLS`, `LIST_AGENTS_FULL`, `COUNT_ALL_CHATS`, `all_chats` | vários | Auxiliares/legado. |

### 1.2 Volume de atendimento

| Tabela | Cobertura | Observação |
|---|---|---|
| `bronze_external_hyperflow.list_all_chats` | **BLIPS + FINZA**, 2023-05-18 → hoje | Snapshot por chat, event-driven. Filtrar `tenant_name` (MAIÚSCULA). **É a fonte certa para FINZA.** |
| `bronze_external_hyperflow.tb_chat_*` | idem | Camada silver por Dataform (timeline, interactions, messages, summary, surveys). Leia a `description` de cada uma. |
| `gold_HYPERFLOW.service_chats` | ⚠️ **só BLIPS**, desde 2025-10-08 | Visão rica 1-linha-por-chat. **Não tem FINZA** — não caia nessa. |
| `bigquery___finza.chat_events` | FINZA, tempo real (Analytics Hub) | Event log cru do tenant Finza. `blips___desk.chat_events` é o equivalente BLIPS. |
| `bronze_hyperflow_finza.*` (legado) / `HYPERFLOW.*` (gold antigo) | — | Preferir as de cima. |

### 1.3 Rateio de custo por departamento

`VIEWS_DASHES.custo_hyperflow_rateio_depto` e `..._rateio_chats` — **cobrem FINZA e BLIPS** (coluna `empresa`). Rateiam a fatura do mês entre departamentos por participação de chats. Parametrização de grupos em `w_integracoes_lovable.01_custo_hyperflow_grupo_param` (grupos: cobranca, onboarding, cs, suporte, comercial, retirada, formalizacao, franquia, nao_classificado).

`VIEWS_DASHES.custo_hyperflow_uso_diario` / `custo_hyperflow_diario` — equivalente lado BLIPS, sem coluna de empresa.

---

## 2 · O modelo de cobrança (decodificado)

**`GET_USAGE_INFO` é o extrato.** Colunas que importam:

| Coluna | Significado |
|---|---|
| `date`, `type` | dia e tipo de evento — o grão da linha |
| `total_events` | eventos do dia |
| `non_billable_events` | eventos **absorvidos pela franquia** do plano |
| `billable_events` | eventos **excedentes** (cobrados à parte) |
| `billable_pricing` | R$ do dia para aquele tipo = `billable_events × preço unitário` |
| `additional_price` | preço unitário do excedente — ⚠️ **não confie**, vem `0` para `whatsapp\|connection` mesmo sendo cobrado |
| `totalcost`, `totalevents` | **totais do ciclo inteiro, repetidos em toda linha** — não somar; usar `ANY_VALUE()` agrupando por (`startdate`,`enddate`) |
| `startdate`, `enddate` | janela do ciclo de faturamento |

### Fórmula validada

```
Fatura do mês = R$ 749,00 (plano)  +  totalcost do ciclo (excedente)
```

Confirmado à vírgula em out/25, nov/25, dez/25, jan/26, fev/26, mar/26, abr/26, mai/26 e jun/26.

### Franquia do plano de R$ 749 (eventos/mês não faturados)

| Tipo | Franquia | Preço do excedente |
|---|---:|---:|
| `whatsapp\|activation` (template/disparo ativo) | **500** | **R$ 0,55** |
| `whatsapp\|conversation` + `whatsapp\|connection` | **~1.000** (compartilhada) | R$ 0,45 |
| `webhook` | **~5.005** | R$ 0,025 |
| `rcs\|single` | 0 | R$ 0,18 |
| `rcs\|activation` | 0 | R$ 0,105 |
| `rcs\|conversation` / `rcs` | 0 | R$ 0,39 |
| **Total** | **≈ 6.505 eventos/mês** | — |

→ Preço médio **dentro** da franquia: `749 / 6.505` = **R$ 0,115/evento**.
→ Uma activation excedente a R$ 0,55 custa **4,8×** o preço médio da franquia. É aí que a conta estoura.

**Derive o preço unitário real** como `billable_pricing / billable_events`, nunca de `additional_price`.

---

## 2.1 · Segregação BLIPS × FINZA (validada 2026-09-17)

Três mecanismos diferentes — saiba qual se aplica antes de filtrar:

| Mecanismo | Onde | Como isolar FINZA |
|---|---|---|
| **Dataset exclusivo** | `bronze_hyperflow_finza` (FINZA) × `bronze_hyperflow` (BLIPS) | Nada a filtrar — 100% das linhas de cada dataset são de uma só empresa. |
| **Coluna de tenant** | `bronze_external_hyperflow.list_all_chats`, `VIEWS_DASHES.custo_hyperflow_rateio_*` | `tenant_name = 'FINZA'` (MAIÚSCULA) ou `empresa = 'FINZA'`. |
| **Sem cobertura** | `gold_HYPERFLOW.service_chats` | Só BLIPS. Devolve vazio e parece "sem dado" — **descarte**. |

⚠️ **Dois namespaces de `tenant_id` — não são intercambiáveis:**

| Contexto | FINZA | BLIPS | Tabelas |
|---|---|---|---|
| Faturamento/organização | `6887a3927e315c8ae5814f4c` | `642eb756871c80fe9f0e0da9` | `GET_USAGE_INFO`, `LIST_ALL_BILLS`, `GET_WABA_MESSAGE_TEMPLATES` |
| Desk/atendimento | `68af4fe6efea9d04eda67f0e` | `642eb86c0cd915bc8137a05d` | `LIST_BROADCAST_SCHEDULE_LOGS`, `list_all_chats` |

Juntar custo com atendimento pelo `tenant_id` **não casa**. Use `empresa`/`tenant_name` como chave de negócio.

**Escala (por que misturar invalida tudo):** FINZA 22.611 chats × BLIPS 1.374.203 — a BLIPS é ~60× maior. O `bronze_hyperflow.GET_USAGE_INFO` (BLIPS) ainda traz `totalcost` **negativo** em alguns ciclos (créditos) — contrato diferente, não comparável linha a linha com o da FINZA.

## 3 · Armadilhas conhecidas

1. **`totalcost` é do ciclo, não da linha.** Somar a coluna multiplica o valor por dezenas.
2. **O snapshot do BQ é tirado antes do ciclo fechar.** Em jul/26 o corte foi 31/07 15h42 e em ago/26 foi 29/08 12h15 (o dia 30/08 nem existe na tabela) — por isso o uso subestima a fatura em R$ 50–85 (1–2%) nesses dois meses. Nos demais, fecha exato.
3. **`referencemonth` de `LIST_ALL_BILLS` escorrega.** A fatura de R$ 846,70 vem rotulada `2025-11` mas carrega o consumo de dezembro; a `2025-12` (R$ 853,60) carrega janeiro. **Reconcilie pelo valor/`dueat`, não pelo rótulo.** Há dois registros com `referencemonth = 2025-11`.
4. **`gold_HYPERFLOW.service_chats` não tem FINZA.** Retorna vazio e parece "sem dado".
5. **`tenant_name` é MAIÚSCULA** (`FINZA`, `BLIPS`).
6. **`tb_chat_messages` é amostra enviesada** — reconstruída de snapshots `lastMessage`, não é log completo. Não serve para contar mensagens.
7. **Sem dimensão de template em `GET_USAGE_INFO`.** Para saber *qual* template gerou a activation, cruze com `LIST_BROADCAST_SCHEDULE_LOGS` — que cobre só **disparo em massa**, não activation 1:1 disparada por fluxo/API.

---

## 4 · SQL pronto

### 4.1 Fatura × uso, mês a mês

```sql
WITH ciclo AS (
  SELECT startdate, enddate, ANY_VALUE(totalcost) excedente, ANY_VALUE(totalevents) eventos
  FROM `blips-bigdata.bronze_hyperflow_finza.GET_USAGE_INFO`
  GROUP BY startdate, enddate
)
SELECT SUBSTR(startdate,1,7) mes, ROUND(excedente,2) excedente,
       ROUND(749 + excedente,2) fatura_esperada, eventos
FROM ciclo ORDER BY mes;
```

### 4.2 Composição do excedente por tipo

```sql
SELECT FORMAT_DATE('%Y-%m', PARSE_DATE('%Y-%m-%d', date)) mes, type,
       SUM(total_events) ev, SUM(non_billable_events) franquia,
       SUM(billable_events) excedente,
       ROUND(SUM(billable_pricing),2) brl,
       ROUND(SAFE_DIVIDE(SUM(billable_pricing), SUM(billable_events)),4) preco_unit
FROM `blips-bigdata.bronze_hyperflow_finza.GET_USAGE_INFO`
WHERE date >= '2026-06-01'
GROUP BY mes, type ORDER BY mes, brl DESC;
```

### 4.3 Projeção do mês corrente (run-rate)

```sql
WITH d AS (
  SELECT PARSE_DATE('%Y-%m-%d', date) dia, billable_pricing brl
  FROM `blips-bigdata.bronze_hyperflow_finza.GET_USAGE_INFO`
  WHERE date >= FORMAT_DATE('%Y-%m-01', CURRENT_DATE())
)
SELECT COUNT(DISTINCT dia) dias, ROUND(SUM(brl),2) ate_agora,
       ROUND(SUM(brl)/COUNT(DISTINCT dia)*30,2) proj_excedente_mes,
       ROUND(749 + SUM(brl)/COUNT(DISTINCT dia)*30,2) proj_fatura
FROM d;
```

### 4.4 Disparo por template e categoria Meta

```sql
WITH cat AS (
  SELECT DISTINCT name, category
  FROM `blips-bigdata.bronze_hyperflow_finza.GET_WABA_MESSAGE_TEMPLATES`
)
SELECT SUBSTR(l.sent_at,1,7) mes, c.category, l.template_name, l.department_name,
       COUNT(*) enviados
FROM `blips-bigdata.bronze_hyperflow_finza.LIST_BROADCAST_SCHEDULE_LOGS` l
LEFT JOIN cat c ON c.name = l.template_name
WHERE l.sent_at IS NOT NULL AND SUBSTR(l.sent_at,1,7) >= '2026-06'
GROUP BY mes, c.category, l.template_name, l.department_name
ORDER BY mes, enviados DESC;
```

### 4.5 Volume de atendimento FINZA por mês

```sql
SELECT FORMAT_DATE('%Y-%m', DATE(created_at,'America/Sao_Paulo')) mes,
       COUNT(*) chats, COUNTIF(is_broadcast) broadcast,
       COUNT(DISTINCT contact_phone) contatos
FROM `blips-bigdata.bronze_external_hyperflow.list_all_chats`
WHERE tenant_name = 'FINZA' AND created_at >= TIMESTAMP('2026-01-01')
GROUP BY mes ORDER BY mes;
```

### 4.6 Rateio da fatura por departamento

```sql
SELECT ano_mes, departamento, eh_ia, qtd_chats, qtd_disparos_massa,
       ROUND(custo_rateado_departamento,2) custo, ROUND(custo_total_mes,2) fatura_mes
FROM `blips-bigdata.VIEWS_DASHES.custo_hyperflow_rateio_depto`
WHERE empresa = 'FINZA' AND ano_mes >= '2026-06'
ORDER BY ano_mes, custo DESC;
```

---

## 5 · Retrato em 2026-09-17 (para comparação futura)

- Faturas pagas desde ago/2025: **13**, somando **R$ 26.070,13**. Plano puro seria R$ 9.737 — **63% da conta foi excedente**.
- Últimos 3 meses fechados: jun R$ 2.514,80 · jul R$ 4.292,73 · ago R$ 5.905,23.
- Agosto: 39.781 eventos, 6.514 na franquia, **33.267 excedentes**. `whatsapp|activation` = **72% do excedente** (R$ 3.641 de R$ 5.071,70).
- Activations (total): jun 2.632 → jul 4.725 → ago 7.123 → set (17 dias) 7.073. Franquia é 500.
- Rateio ago: **cobrança 83,5%** (R$ 4.932), onboarding 9,2%, CS 2,4%.
- Templates aprovados: **63 MARKETING**, 30 UTILITY, 2 AUTHENTICATION. O template mais disparado é `ativacao_generica` (**MARKETING**, texto livre), usado em todas as faixas de cobrança.
