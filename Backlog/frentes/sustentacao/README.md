# Frente Sustentação · Operação

Criada em **2026-06-02** durante o espelhamento Quimera + Jira do backlog.

Abriga demandas **operacionais** importadas das fontes (bugs, incidentes, ajustes, tarefas de TI)
que **não** têm frente estratégica clara (Esperanza, Torre, Clara, Bitrix/Automações, Valentina,
Lívia, Estratégica). É o destino *default* do mapeamento de frente.

## Convenção de IDs (frente espelhada)

Diferente das frentes estratégicas (prefixos `BBT/BAU/BTR/BCL/BES/BVA/BLV/BST`), os itens aqui — e
os importados em geral — usam o **identificador da fonte** como ID:

- `IAF-###` — issue do Jira legado (projeto IAF).
- `QMR####` — ticket do Quimera (`ticket_number`). Quando há os dois, o Quimera (verdade) é o ID e o
  Jira fica no campo `jira:`.

## Campos de origem (em cada item)

- `fonte:` — `quimera+jira` | `jira` | `quimera` | `backlog`.
- `categoria:` — categoria da fonte (Cobrança, TI, Formalização, Recuperação, …), também como tag.
- `quimera:` / `jira:` — referências cruzadas.

> Fonte da verdade dos itens: os `.md`. Projeções (`backlog.html`, `mapa-mental.html`) são regeneradas
> a partir daqui — não editar o JSON à mão. Matriz de reconciliação completa em `Backlog/_recon/matriz.md`.
