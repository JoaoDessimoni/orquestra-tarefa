# Pendências — Squad IAF

Backlog vivo do supervisor. Cada arquivo é uma pendência com frontmatter padrão e histórico imutável.

> Mantido pelo agente `pendencia-tracker` via `/pendencia`. Edite manualmente apenas se souber o que está fazendo.

---

## Convenção

**Arquivo:** `<id>_<slug>.md`
- `P01`–`Pnn` — pendências mapeadas no diagnóstico inicial da Torre (de `Docs/BRIEFING.md`).
- `custom_<slug>` — pendências surgidas depois.

**Frontmatter:**
```yaml
---
id: P07
title: <título>
status: aberta            # aberta | em-curso | bloqueada | fechada
prioridade: alta          # alta | media | baixa
origem: <onde apareceu>
owner: João Vinícius
criada: YYYY-MM-DD
deadline: YYYY-MM-DD      # opcional
fechada: YYYY-MM-DD       # só quando status=fechada
tags: []
---
```

**Corpo:** Contexto, Proposta, Quem depende, Histórico, Próxima ação.

---

## Índice

> Este índice é regenerado pelo `pendencia-tracker` a cada CRUD. Não edite manualmente.

Last update: 2026-05-18

### Abertas (5)

#### Alta prioridade
| ID | Título | Status | Deadline | Owner |
|---|---|---|---|---|
| [P07](P07_validar_1785_marcos.md) | Validar conclusão do ticket 1785 com Marcos | aberta | 2026-05-20 | João Vinícius |
| [P08](P08_validar_1779_marcos.md) | Validar conclusão do ticket 1779 com Marcos | aberta | 2026-05-20 | João Vinícius |
| [P09](P09_falar_vinicius_cunha_1775.md) | Falar com Vinícius Cunha sobre 1775 (HyperFlow) | aberta | 2026-05-22 | João Vinícius |

#### Média
| ID | Título | Status | Deadline | Owner |
|---|---|---|---|---|
| [P10](P10_confirmar_1747_leandro.md) | Confirmar fechamento do 1747 com Leandro | aberta | 2026-05-21 | João Vinícius |
| [P11](P11_definir_raia_validacao_marcos.md) | Decidir com Marcos a raia das demandas em validação | aberta | 2026-05-22 | João Vinícius |

> P01–P06 (pendências do BRIEFING) ainda não foram criadas. Rode `/pendencia init` para popular.

### Fechadas recentemente
*(nenhuma)*

---

## Como usar

```
/pendencia                        # lista abertas
/pendencia add "<título>"         # abre nova
/pendencia list --atrasadas       # filtra
/pendencia update P02 status=em-curso
/pendencia close P02              # pergunta resultado
/pendencia reopen P02             # pergunta razão
/pendencia init                   # popula P01-P06 do BRIEFING
/pendencia show P02               # mostra arquivo completo
```
