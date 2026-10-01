---
description: Consulta e analisa dados no BigQuery da Blips/Finza (projeto blips-bigdata) via agente bq-analyst. Subcomandos — <pergunta>, tabelas, schema, sql, mapear, dominios. Somente leitura. Mantém a skill bigquery-finza como mapa vivo das tabelas.
---

# /bq — análise de dados no BigQuery

`$ARGUMENTS` é a pergunta ou o subcomando. Se vazio, liste os domínios já mapeados (§ `dominios`) e pergunte o que o João quer analisar.

Todo trabalho roda no agente **`bq-analyst`**, que carrega a skill **`bigquery-finza`** antes de tocar em qualquer tabela. **Somente leitura** — nunca escrever no BigQuery.

## Subcomandos

| Forma | O que faz |
|---|---|
| `/bq <pergunta em português>` | Caso padrão. Traduz a pergunta em métrica, acha a fonte, roda o SQL, reconcilia e responde. Ex: `/bq quanto pagamos de Hyperflow nos últimos 6 meses` |
| `/bq tabelas <termo>` | Procura tabela por nome em todo o projeto (`INFORMATION_SCHEMA.TABLES`). |
| `/bq schema <dataset.tabela>` | `get_table_info` — schema, partição, clustering, descrição, nº de linhas. |
| `/bq sql <query>` | Roda SQL cru em modo read-only. Recusa qualquer DDL/DML. |
| `/bq mapear <domínio>` | Descobre e **documenta** um domínio novo: cria `.claude/skills/bigquery-finza/<dominio>.md` e indexa na SKILL. |
| `/bq dominios` | Lista os domínios já mapeados na skill. |

## Regras

- **Read-only estrito.** `execute_sql_readonly`. Se o pedido implicar escrita, recuse e explique — criação de tabela é do time de dados.
- **Schema antes de SQL** em tabela desconhecida. Não inventar coluna.
- **Filtrar partição** em tabela grande.
- **Reconciliar** todo número de dinheiro contra fonte independente; diferença residual entra explicada.
- **Citar a tabela-fonte qualificada** de cada número.
- **Multi-empresa:** o lake serve BLIPS e FINZA. Confirmar o recorte (`tenant_name` / `empresa`) antes de concluir "não tem dado".
- **Documentar o que durar.** Domínio ou armadilha nova → atualizar a skill `bigquery-finza` no mesmo turno.

## Encadeamento

- Análise que vira artefato → `/analise` (grava em `Backlog/analises/<dd-mm-aaaa>/`).
- Devolutiva para terceiro → `/relatorio from <análise>`.
- Ação estratégica derivada → `/backlog add`.

O `/bq` **não** mexe em `Backlog/`, Quimera, Jira, n8n nem Torre — nomeia o comando certo e para.
