---
name: bigquery-finza
description: Mapa canônico do BigQuery da Blips/Finza (projeto `blips-bigdata`) para análises de dados do supervisor IAF. Índice vivo dos datasets e tabelas relevantes, com um arquivo de referência por domínio. Carregue antes de qualquer consulta/análise em BigQuery — custo, volume, atendimento, faturamento de plataforma. Domínio coberto hoje: HYPERFLOW (uso vs cobrado, faturas, templates WhatsApp, rateio por departamento). Cresce sob demanda — cada novo domínio analisado vira um arquivo de referência aqui.
---

# BigQuery Finza — mapa de análise

Base de conhecimento do agente `bq-analyst` (comando `/bq`). É um **índice vivo**: começa com Hyperflow e cresce a cada domínio novo que o João pedir para analisar.

**Projeto único:** `blips-bigdata` (location **US**). Sempre qualificar tabela como `` `blips-bigdata.<dataset>.<tabela>` ``.
O MCP é `claude_ai_Google_Cloud_BigQuery`; `list_dataset_ids` **exige** `project_id="blips-bigdata"` (sem isso dá erro de project vazio).

---

## 1 · Lei de operação

- **Somente leitura.** Use `execute_sql_readonly`. Nunca `CREATE`, `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE`, `DROP`, nem tabela temporária materializada. Análise não escreve no data lake da empresa.
- **Filtre a partição.** Quase toda tabela grande é particionada por data. Sem filtro de partição a query varre GB à toa e custa dinheiro real.
- **Nunca invente coluna nem tabela.** Rode `get_table_info` antes de escrever SQL contra tabela que você não conhece. A descrição das tabelas do Dataform é rica — leia, ela avisa das armadilhas.
- **Reconcilie antes de concluir.** Toda análise de dinheiro tem que bater com uma fonte independente (fatura × uso, API × BQ). Se não bater, a diferença é parte do resultado — explique-a, não a esconda.
- **PII.** `conteudo_texto`, `telefone_cliente`, `contact_phone`, `csat_comentario`, `agent_email` são dados pessoais. Não jogue em relatório que circula fora do time.

## 2 · Descoberta (quando o domínio ainda não está mapeado aqui)

```sql
-- Busca tabela por nome em todo o projeto
SELECT table_schema, table_name, table_type
FROM `blips-bigdata.region-us.INFORMATION_SCHEMA.TABLES`
WHERE LOWER(table_name) LIKE '%<termo>%' OR LOWER(table_schema) LIKE '%<termo>%'
ORDER BY table_schema, table_name;

-- Busca coluna dentro de um dataset
SELECT table_name, column_name, data_type
FROM `blips-bigdata.<dataset>.INFORMATION_SCHEMA.COLUMNS`
WHERE LOWER(column_name) LIKE '%<termo>%';
```

Achou algo relevante e duradouro? **Documente aqui** (novo arquivo de domínio + linha no índice §4). É essa a regra de crescimento da skill.

## 3 · Convenção de camadas

| Prefixo | Camada | Confiança |
|---|---|---|
| `bronze_*` | ingestão crua (API/Mongo/SQL espelhados) | fiel à origem, schema feio, sujeito a defasagem |
| `silver_*`, `tb_*` dentro de bronze | reconstruído/normalizado por Dataform | bom, leia a `description` da tabela |
| `gold_*`, nomes em CAIXA ALTA | curado/agregado para consumo | pronto para relatório, pode ter recorte fixo (ex.: só um tenant) |
| `VIEWS_DASHES`, `HYPERDASH`, `POWER_BI_VIEWS` | camada de dashboard | já agregado, checar se cobre a empresa que você quer |
| `TEMPORARIAS`, `z_tabelas_legado`, `tmp_*` | descartável/legado | **não usar** em análise nova |

⚠️ **Multi-empresa é a pegadinha nº 1.** O lake serve **BLIPS** e **FINZA**. Muita tabela gold cobre só BLIPS (ex.: `gold_HYPERFLOW.service_chats` **não tem FINZA**). Sempre confirme com `GROUP BY tenant_name/empresa` antes de concluir "não tem dado".

## 4 · Índice de domínios

| Domínio | Arquivo | Cobre |
|---|---|---|
| **Hyperflow** (atendimento WhatsApp/RCS, uso × cobrança) | [`hyperflow.md`](./hyperflow.md) | faturas, uso faturável, franquia, preços unitários, templates WhatsApp e categoria Meta, rateio por departamento, volume de atendimento |
| **Agentes de IA** (Esperanza, Valentina) | [`agentes-ia.md`](./agentes-ia.md) | protocolos (`silver_torre`), canal proativo × receptivo, transferência no desk e departamento, custo LLM por agente (`s1_custos_ia`), câmbio |

<!-- Próximos domínios entram aqui conforme o João pedir: custos de IA (s1_custos_ia), Bitrix, Torre de Controle, Sankhya, etc. -->

## 5 · Como adicionar um domínio novo

1. Descubra as tabelas (§2) e leia `get_table_info` de cada candidata.
2. Valide com uma query de sanidade (contagem, janela temporal, quebra por empresa).
3. Crie `<dominio>.md` nesta pasta com: tabelas e grão, colunas que importam, **armadilhas**, e SQL pronto para as 3–5 perguntas mais comuns.
4. Acrescente a linha no índice §4.
5. Se mudou o escopo do agente, reflita em `.claude/agents/bq-analyst.md` e no `CLAUDE.md` (§0/§1).
