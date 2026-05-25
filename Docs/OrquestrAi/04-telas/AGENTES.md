# Tela: Agentes

> CRUD de Agentes + tela de detalhe rica. Mesma estrutura serve para Subagentes (com filtro `is_subagent=true`). Última atualização: 20/05/2026.

## Fontes

- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md) §RF-AG
- [REGRAS_DE_NEGOCIO.md](../03-dominio/REGRAS_DE_NEGOCIO.md) §1
- [SCHEMA_POSTGRES.md](../03-dominio/SCHEMA_POSTGRES.md) §3.1

## Rotas

- `/agents` — lista
- `/agents/new` — form criar
- `/agents/[slug]` — detalhe
- `/agents/[slug]/edit` — form editar

> Para Subagentes: trocar `/agents` por `/subagents` e API filtra `is_subagent=true`.

---

## 1 · /agents — Lista

### 1.1 Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  Agentes / Lista                              [⌘K]  [+ Novo Agente]  │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  [🔍 Buscar...] [Modelo: todos ▾] [Tags: todas ▾]                    │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  NOME ↕         SLUG              MODELO   TOOLS  SKILLS  EXEC  ││
│  ├─────────────────────────────────────────────────────────────────┤│
│  │  Researcher F.  researcher-finza  sonnet     4      2     17    ││
│  │  Drafter        drafter           sonnet     3      1      8    ││
│  │  Reviewer       reviewer          haiku      2      0      5    ││
│  │  Slide writer   slide-writer      sonnet     5      3     22    ││
│  └─────────────────────────────────────────────────────────────────┘│
│  Mostrando 1–20 de 12                            [‹ Prev]  [Next ›]  │
└──────────────────────────────────────────────────────────────────────┘
```

### 1.2 Colunas

| Coluna | Sortable | Conteúdo |
|---|---|---|
| Nome | ✓ | `name` |
| Slug | ✓ | `slug` em mono pequena |
| Modelo | ✓ | Badge (`opus`/`sonnet`/`haiku`) |
| Tools | — | Count (ex: "4") |
| Skills | — | Count |
| Execuções | ✓ | Count |
| Última exec. | ✓ | Tempo relativo (oculto em colunas estreitas) |

### 1.3 Filtros

- Busca textual: em `name` e `slug` (debounce 200ms)
- Filtro modelo: dropdown todos/opus/sonnet/haiku
- Filtro tags (V1+)
- Toggle "Incluir excluídos" (V1+)

### 1.4 Estados

- Loading: SkeletonTable 5×6
- Empty: ilustração + "Nenhum agente ainda" + CTA "+ Novo Agente"
- Erro: ErrorState com retry

### 1.5 API

- `GET /api/agents?q=...&model=...&page=1&limit=20&sort=name:asc`

---

## 2 · /agents/new e /agents/[slug]/edit — Form

### 2.1 Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  Agentes / Novo                                       [Cancelar][Salvar]
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Informação geral                                                    │
│  ────────────────────────────────────────────                        │
│  Nome*           [Researcher Finza                          ]        │
│  Slug*           [researcher-finza                          ] auto-gen
│  Descrição       [textarea curta...                         ]        │
│                                                                      │
│  Comportamento                                                       │
│  ────────────────────────────────────────────                        │
│  Modelo*         [Sonnet ▾]                                          │
│  Ferramentas     [☑ Read] [☑ Grep] [☑ Glob] [☐ Edit] [☐ Write]      │
│                  [☐ Bash] [☐ WebSearch] [☐ WebFetch]                 │
│                                                                      │
│  Prompt do sistema (markdown)*                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  # Researcher Finza                                          │  │
│  │                                                              │  │
│  │  Você é um agente especialista em fatos da Finza...          │  │
│  │  ...                                                         │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Conhecimento                                                        │
│  ────────────────────────────────────────────                        │
│  Skills vinculadas                                                   │
│  [☑ contexto-finza] [☑ glossario-tecnico] [☐ design-system]         │
│  [+ Adicionar skill]                                                 │
│                                                                      │
│  Subagentes invocáveis                                               │
│  [☐ slide-architect] [☐ folder-organizer]                            │
│  [+ Adicionar subagente]                                             │
│                                                                      │
│  Avançado                                                            │
│  ────────────────────────────────────────────                        │
│  ☐ Este é um Subagente (não chamado diretamente pelo usuário)        │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### 2.2 Campos

| Campo | Tipo | Validação |
|---|---|---|
| nome* | Input text | required, max 100 |
| slug* | Input text | required, regex `^[a-z0-9][a-z0-9-]*[a-z0-9]$`, único (check assíncrono) |
| descrição | Textarea | optional, max 500 |
| modelo* | Select | required, enum {opus, sonnet, haiku} |
| ferramentas | Checkboxes | mínimo 1 |
| system_prompt* | Markdown editor | required, max 50000 chars |
| skills | Multi-select com fuzzy | optional |
| subagentes | Multi-select com fuzzy | optional, valida ciclos (RN-03) |
| is_subagent | Checkbox | default false |

### 2.3 Comportamentos

- **Slug auto-gen**: ao digitar nome, slug é sugerido (kebab-case). Editável.
- **Slug uniqueness check**: ao perder foco, checa via `GET /api/agents/check-slug?slug=...`.
- **Salvar**:
  - Submit `POST /api/agents` (new) ou `PATCH /api/agents/{id}` (edit).
  - Sucesso: toast "Agente salvo" + navega para `/agents/[slug]`.
  - Erro de validação: highlight nos campos + mensagem.
  - Erro de ciclo de subagente: toast danger com mensagem da RN-03.
- **Cancelar**: navega para lista. Se há mudanças não salvas, confirma.

---

## 3 · /agents/[slug] — Detalhe

### 3.1 Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  Agentes / researcher-finza            [▶ Executar] [Editar] [⋮ Mais]│
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ◆ Researcher Finza               [sonnet]  [4 tools]  [17 execuções]│
│  Agente que pesquisa fatos no contexto Finza...                      │
│                                                                      │
│  [Prompt] [Skills (2)] [Subagentes (0)] [Execuções (17)]            │
│  ──────────────────────────────────────────────────────              │
│                                                                      │
│  ## Prompt                                                           │
│  ───────────────────                                                 │
│  (Renderiza system_prompt como markdown — preview legível)           │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  # Researcher Finza                                          │  │
│  │  Você é um agente especialista...                            │  │
│  │  ...                                                         │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Última execução: há 12s — done — 0:23 — 4 tool calls — 0.012 USD   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### 3.2 Header

- Nome (h1 `--text-2xl`)
- Slug em mono
- Descrição
- Badges: modelo + count de tools + count de execuções

### 3.3 Ações primárias

- **▶ Executar** → `/executions/new?agent={slug}`
- **Editar** → `/agents/{slug}/edit`
- **⋮ Mais** (dropdown):
  - Clonar
  - Exportar como `.md`
  - Excluir (com confirmação)

### 3.4 Tabs

| Tab | Conteúdo |
|---|---|
| Prompt | Markdown rendering do system_prompt + lista de tools habilitadas |
| Skills | Lista de skills vinculadas, com link para detalhe |
| Subagentes | Lista de subagentes invocáveis, com link |
| Execuções | Tabela de execuções (mesma da tela /executions, filtrada) |

### 3.5 API

- `GET /api/agents/{slug}` — detalhe completo (com skills/subagents expandidos)
- `GET /api/agents/{slug}/executions?limit=20` — execuções

---

## 4 · Subagentes (variação)

Rotas paralelas, mesmas telas. Diferenças:
- Lista filtra `is_subagent=true`
- Form: `is_subagent` checkbox pré-marcado e oculto
- Detalhe: aba "Invocado por" mostra agentes que têm este como subagente vinculado

---

## 5 · Validações cliente (zod)

```typescript
const agentSchema = z.object({
  name: z.string().min(1).max(100),
  slug: z.string().regex(/^[a-z0-9][a-z0-9-]*[a-z0-9]$/),
  description: z.string().max(500).default(''),
  model: z.enum(['opus','sonnet','haiku']),
  tools: z.array(z.enum(['Read','Edit','Write','Grep','Glob','Bash','WebSearch','WebFetch'])).min(1),
  system_prompt: z.string().min(1).max(50000),
  skills: z.array(z.string()),
  subagents: z.array(z.string()),
  is_subagent: z.boolean().default(false),
});
```

---

## 6 · Performance

- Lista paginada (20 por página default).
- Detalhe: tabs lazy (Execuções só carrega ao clicar).
- Markdown rendering memoizado.
