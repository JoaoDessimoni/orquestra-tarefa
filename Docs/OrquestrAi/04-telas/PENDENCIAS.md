# Tela: Pendências

> CRUD de pendências do supervisor IAF. Promovida a módulo de produção do MVP (v2). Última atualização: 21/05/2026.

## Fontes

- `Gestao/Pendencias/` (schema implícito, 26 pendências reais P07-P36)
- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md) §RF-PE
- [SCHEMA_POSTGRES.md](../03-dominio/SCHEMA_POSTGRES.md) §3.11 pendencias

## Rotas

- `/pendencias` — tabela
- `/pendencias/[id]` — modal detalhe

---

## 1 · Listagem

```
┌──────────────────────────────────────────────────────────────────┐
│  Pendências — backlog               + Nova Pendência (⌘N)         │
│  22 abertas · 3 fechadas · 17 alta prioridade                     │
├──────────────────────────────────────────────────────────────────┤
│  🔍 Buscar título, ID, tag…    [Status: todos] [Prio: todas]      │
├──────────────────────────────────────────────────────────────────┤
│  ID    TÍTULO                              STATUS    PRIO  DEAD  │
│  P21   Resgatar relatório pré-Torre        ●aberta   ALTA  22/05 │
│  P11   Decidir com Marcos a raia           ●em-curso MED   22/05 │
│  P09   Falar Vinícius Cunha 1775           ●em-curso ALTA  22/05 │
│  P15   Valentina roteamento Rhino (urg.)   ●aberta   ALTA  26/05 │
│  …                                                                │
│  P07   Validar 1785 com Marcos             ●fechada  ALTA   --   │
└──────────────────────────────────────────────────────────────────┘
```

### Colunas

| Coluna | Conteúdo | Largura |
|---|---|---|
| ID | mono `P21` | 60px |
| Título | weight 500 + tags (3 primeiras) | flex |
| Status | badge | 110px |
| Prioridade | badge | 90px |
| Deadline | mono `fmtDate` + badge `atraso` se < hoje | 110px |
| Owner | text-sm muted | 140px |
| Ações (hover) | ✎ / 🗑 | 100px |

### Ordenação

- Default: por deadline ascending (vence primeiro no topo)
- `fechada` sempre vai para o fim, independente do deadline
- Sortable: deadline, criada, prioridade, status

### Visual de atraso

```css
tbody tr.atrasada td:first-child { box-shadow: inset 3px 0 var(--danger); }
```

### Filtros

- Busca textual (título, id, tags)
- Status: aberta / em-curso / bloqueada / fechada
- Prioridade: alta / media / baixa
- Owner (V1)
- Tags multi-select (V1)

---

## 2 · Modal detalhe

```
┌──── Modal (dotted) ──────────────────────────────────┐
│ Pendência P21                                       ×│
├──────────────────────────────────────────────────────┤
│ [P21] [aberta] [alta] [22/05]                        │
│                                                      │
│ Resgatar relatório pré-Torre sobre redirecionamento  │
│ IA→humano                                            │
│                                                      │
│ Owner: João Vinícius · criada 19/05                  │
│ origem: Anotações caderno 15-18/05                   │
│                                                      │
│ [esperanza] [relatorio] [torre] [historico]          │
│ ──────────────────────────────────────────────       │
│ Antes da Torre existia relatório de redirecionamento │
│ IA→humano. Número estratégico para contextualizar    │
│ evolução pós-Torre. Precisa ser resgatado antes que  │
│ se perca.                                            │
│                                                      │
│ 📁 Gestao/Pendencias/19-05-2026/P21_resgatar_…md     │
├──────────────────────────────────────────────────────┤
│                              [Fechar] [Editar]       │
└──────────────────────────────────────────────────────┘
```

---

## 3 · Form criar/editar

| Campo | Tipo | Default | Validação |
|---|---|---|---|
| id | text readonly | auto `P${N+1}` | sequencial |
| title | text | — | required, max 200 |
| status | select | `aberta` | enum |
| prioridade | select | `media` | enum |
| owner | text | `João Vinícius` | — |
| criada | date | hoje | — |
| deadline | date | — | opcional, ≥ criada |
| origem | text | — | — |
| tags | chipinput | `[]` | max 10 |
| body_excerpt | textarea | — | max 500 |

Após salvar: `path` derivado: `Gestao/Pendencias/<dd-mm-aaaa>/<id>_<slug>.md`.

---

## 4 · API (produto)

| Método | Path | Descrição |
|---|---|---|
| GET | `/api/pendencias` | Lista com filtros (status, prio, owner, q, page) |
| GET | `/api/pendencias/{id}` | Detalhe |
| POST | `/api/pendencias` | Criar |
| PATCH | `/api/pendencias/{id}` | Atualizar |
| DELETE | `/api/pendencias/{id}` | Excluir (soft) |
| POST | `/api/export/pendencias/{id}` | Exporta `.md` para `Gestao/Pendencias/` |

---

## 5 · Atalhos

- `N` na view → abre form de criação
- `/` → foca busca
- Click em linha → abre modal detalhe
- Hover linha → mostra ✎ / 🗑

---

## 6 · Estados

- Loading: skeleton 10 rows.
- Empty: ilustração ▢ + "Nenhuma pendência. + Nova Pendência".
- Erro: ErrorState com retry.

---

## 7 · Histórico

| Versão | Data | Mudança |
|---|---|---|
| **v2** | **2026-05-21** | Doc criado. Pendências promovidas a módulo de produção (saiu do "legacy"). |
