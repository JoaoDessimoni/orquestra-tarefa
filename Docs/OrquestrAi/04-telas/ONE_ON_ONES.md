# Tela: 1on1s

> Conversas individuais (1:1) com pessoas do squad. Última atualização: 21/05/2026.

## Fontes

- `Gestao/1on1s/` (atualmente vazio — 0 registros)
- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md) §RF-OO

## Rotas

- `/ones` — cards
- `/ones/[id]` — modal detalhe

---

## 1 · Listagem

```
┌──── Empty state (atual) ────────────────────────────┐
│   👤                                                 │
│   Nenhum 1on1 registrado                             │
│   Crie seu primeiro registro de conversa individual. │
│   [+ Novo 1on1]                                      │
└──────────────────────────────────────────────────────┘
```

Quando houver registros: grid de cards similar a Reuniões.

```
┌──── Card ───────────────────────────────┐
│ 👤 João Lucas                            │
│ Owner Esperanza · quinzenal · 21/05      │
│                                          │
│ Falamos sobre evolução do escopo da      │
│ renegociação, próximos passos da home-   │
│ logação...                               │
│ [esperanza] [evolucao]                   │
└──────────────────────────────────────────┘
```

### Filtros

- Busca por pessoa
- Recorrência: semanal / quinzenal / mensal / ad-hoc
- Período: 30d / 90d / custom

---

## 2 · Modal detalhe

```
┌──── Modal (dotted) ──────────────────────────────────┐
│ 👤 1on1 com João Lucas                                │
├──────────────────────────────────────────────────────┤
│ Owner Esperanza · quinzenal · 30min · 21/05/2026     │
│ ─────────────────────────────────                    │
│ Como ele está                                        │
│ ...                                                  │
│ Trabalho atual                                       │
│ ...                                                  │
│ Bloqueios                                            │
│ ...                                                  │
│ Próximas ações                                       │
│ ...                                                  │
└──────────────────────────────────────────────────────┘
```

---

## 3 · Form criar/editar

| Campo | Tipo | Default | Validação |
|---|---|---|---|
| id | text readonly | auto `O${N+1}` | seq |
| pessoa | text | — | required |
| papel | text | — | livre (ex: "Owner Esperanza", "Eng. fullstack") |
| data | date | hoje | required |
| duracao | text | `30min` | livre |
| recorrencia | select | `quinzenal` | enum {semanal, quinzenal, mensal, ad-hoc} |
| tags | chipinput | `[]` | max 10 |
| body_excerpt | textarea | — | max 2000 |

**body_excerpt** é livre. V1+: seções estruturadas (Como está / Trabalho atual / Bloqueios / Feedback / Próximas ações).

---

## 4 · API

| Método | Path |
|---|---|
| GET | `/api/ones` |
| GET | `/api/ones/{id}` |
| POST | `/api/ones` |
| PATCH | `/api/ones/{id}` |
| DELETE | `/api/ones/{id}` |
| POST | `/api/export/ones/{id}` |

---

## 5 · Privacidade

1on1s contêm informação sensível (feedback pessoal). MVP é single-user (sem multi-tenancy), então não há risco. V1+ multi-user: 1on1s sempre `classificacao=restrito` por default e visíveis só ao owner.

---

## 6 · Histórico

| Versão | Data | Mudança |
|---|---|---|
| **v2** | **2026-05-21** | Doc criado. 1on1s entra no MVP. |
