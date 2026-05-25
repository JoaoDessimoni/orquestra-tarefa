# Tela: Skills

> CRUD de Skills (blocos de conhecimento reutilizáveis em markdown). Última atualização: 20/05/2026.

## Fontes

- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md) §RF-SK
- [REGRAS_DE_NEGOCIO.md](../03-dominio/REGRAS_DE_NEGOCIO.md) §2

## Rotas

- `/skills`
- `/skills/new`
- `/skills/[slug]`
- `/skills/[slug]/edit`

---

## 1 · /skills — Lista

### Layout (lista em estilo Notion: cards verticais + tags)

```
┌──────────────────────────────────────────────────────────────────────┐
│  Skills                                          [⌘K]  [+ Nova Skill]│
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  [🔍 Buscar...]                                                      │
│  Tags: [finza×] [contexto×] [+ todas]                                │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ 📚 Contexto Finza                       [finza] [contexto] │    │
│  │ Resumo do negócio Finza, plataformas, IAF, Torre...        │    │
│  │ 4 KB · usada em 3 agentes · atualizada há 2 dias            │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ 📚 Design system Finza                  [finza] [design]   │    │
│  │ Paleta, tipografia, padrões visuais de slides Finza.       │    │
│  │ 8 KB · usada em 2 agentes · atualizada há 5 dias            │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Filtros
- Busca textual em nome + body
- Tags multi-select (chip + remover)

### API
- `GET /api/skills?q=...&tags=...&page=1&limit=20`

---

## 2 · /skills/new e /skills/[slug]/edit — Form

```
┌──────────────────────────────────────────────────────────────────────┐
│  Skills / Nova                                  [Cancelar] [Salvar]  │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Nome*           [Contexto Finza                            ]        │
│  Slug*           [contexto-finza                            ]        │
│  Descrição       [Resumo do negócio Finza...                ]        │
│  Tags            [finza×] [contexto×] [+]                            │
│                                                                      │
│  Conteúdo (markdown)*                                                │
│  ┌──── Editor ───────────────┬──── Preview ──────────────────┐     │
│  │  # Contexto Finza         │  # Contexto Finza             │     │
│  │                           │                               │     │
│  │  ## Identidade            │  ## Identidade                │     │
│  │  A Finza é fintech...     │  A Finza é fintech...         │     │
│  │  ...                      │                               │     │
│  └───────────────────────────┴───────────────────────────────┘     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Campos
| Campo | Tipo | Validação |
|---|---|---|
| nome* | text | required, max 100 |
| slug* | text | required, regex, único |
| descrição | text | max 500 |
| tags | array string | regex `^[a-z0-9-]{1,30}$`, max 10 |
| body_md* | markdown editor | required, max 20000 |

### Editor split: 50/50 Editor / Preview (toggle via prop `preview="side"` em `MarkdownEditor`).

---

## 3 · /skills/[slug] — Detalhe

```
┌──────────────────────────────────────────────────────────────────────┐
│  Skills / contexto-finza             [Editar] [⋮ Mais]               │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  📚 Contexto Finza                          [finza] [contexto]       │
│  Resumo do negócio Finza, plataformas, IAF, Torre.                   │
│                                                                      │
│  4 KB · atualizada 2026-05-18                                        │
│                                                                      │
│  ── Conteúdo ────────────────────────────────────────                │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  # Contexto Finza                                            │  │
│  │  ...                                                         │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ── Usada em (3 agentes) ────────────────────────────                │
│  ◆ researcher-finza  →                                               │
│  ◆ slide-writer      →                                               │
│  ◆ drafter           →                                               │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Ações
- Editar
- ⋮ Mais: Excluir (soft), Exportar `.md`

### API
- `GET /api/skills/{slug}`
- `GET /api/skills/{slug}/used-by` — agentes vinculados

---

## 4 · Estados

- **Loading**: skeleton cards
- **Empty**: ilustração + "Nenhuma skill ainda" + CTA
- **Erro**: ErrorState
