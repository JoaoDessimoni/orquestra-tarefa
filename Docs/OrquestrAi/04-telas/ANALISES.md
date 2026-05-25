# Tela: Análises

> CRUD de Análises + vínculo de execuções como insumos + derivação para Relatórios. Última atualização: 20/05/2026.

## Fontes

- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md) §RF-AN
- [REGRAS_DE_NEGOCIO.md](../03-dominio/REGRAS_DE_NEGOCIO.md) §4
- [SCHEMA_POSTGRES.md](../03-dominio/SCHEMA_POSTGRES.md) §3.6

## Rotas

- `/analyses`
- `/analyses/new`
- `/analyses/[slug]`
- `/analyses/[slug]/edit`

---

## 1 · /analyses — Lista

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  Análises                                  [⌘K]  [+ Nova Análise]    │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  [🔍 Buscar...] [Tipo: todos ▾] [Status: todos ▾] [Tags ▾]           │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ 🔍 Demandas cobrança time negócio                          │    │
│  │    investigacao · rascunho · 2026-05-18                    │    │
│  │    Insumos: 2 execuções · Relatórios: 0                    │    │
│  │    [cobranca] [demandas] [time-negocio]                    │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ 🔍 Cruzamento roadmap × pendências IAF                     │    │
│  │    cruzamento · publicada · 2026-05-19                     │    │
│  │    Insumos: 4 execuções · Relatórios: 1                    │    │
│  │    [roadmap] [iaf] [estrategia]                            │    │
│  └────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
```

### Filtros

- Busca em título + pergunta
- Tipo: dropdown (investigacao, comparativo, rfc, postmortem, proposta, cruzamento)
- Status: multi-select (rascunho, revisao, publicada)
- Tags: chips multi-select

### API

`GET /api/analyses?q=...&kind=...&status=...&tags=...&page=1&limit=20`

---

## 2 · /analyses/new — Form criar

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  Análises / Nova                              [Cancelar] [Salvar]    │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Identificação                                                       │
│  ────────────────────────                                            │
│  Título*         [Demandas cobrança time negócio       ]             │
│  Slug*           [demandas-cobranca-time-negocio       ] auto         │
│  Tipo*           [investigacao ▾]                                    │
│  Tags            [cobranca×] [demandas×] [+]                         │
│                                                                      │
│  Pergunta de investigação*                                           │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Qual a fila atual de demandas do time de cobrança e quanto │  │
│  │  já está endereçado pelo squad IAF?                         │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Contexto / corpo                                                    │
│  ┌──── Editor ───────────────┬──── Preview ──────────────────┐     │
│  │  ## Contexto              │  ## Contexto                  │     │
│  │  ...                      │  ...                          │     │
│  └───────────────────────────┴───────────────────────────────┘     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Campos

| Campo | Tipo | Default | Validação |
|---|---|---|---|
| título* | text | — | required, max 200 |
| slug* | text | auto-gen | regex, único |
| tipo* | select | `investigacao` | enum |
| tags | array | `[]` | max 10 |
| pergunta* | textarea | — | required, max 1000 |
| body_md | markdown editor | "" | max 100000 |
| status (no edit) | select | `rascunho` | enum + transições válidas |

---

## 3 · /analyses/[slug] — Detalhe

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  Análises / demandas-cobranca           [Editar] [Publicar] [⋮ Mais] │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  🔍 Demandas cobrança time negócio                                   │
│  investigacao · rascunho · 2026-05-18 · João Vinícius                │
│  [cobranca] [demandas]                                               │
│                                                                      │
│  ── Pergunta de investigação ────────────────                        │
│  > Qual a fila atual de demandas...                                  │
│                                                                      │
│  ── Insumos (2 execuções) ──────────────────  [+ Anexar execução]    │
│  ◆ researcher-finza · há 2h · done · 0:23 · "Liste demandas..."  → │
│  ◆ researcher-finza · há 1h · done · 1:12 · "Cruze com IAF..."    → │
│                                                                      │
│  ── Conteúdo ──────────────────────────                              │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  ## Contexto                                                 │  │
│  │  O time de cobrança...                                       │  │
│  │  ...                                                         │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ── Relatórios derivados (1) ────────────────  [+ Novo Relatório]   │
│  📤 Relatório CTO · enviado · interno · 2026-05-19    →             │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Ações no header

- **Editar** → `/analyses/{slug}/edit`
- **Publicar** (se status=rascunho/revisao) → muda para `publicada` (validação RN-21)
- **⋮ Mais**:
  - Voltar para rascunho (se em revisão)
  - Exportar `.md` para Gestao/
  - Excluir (bloqueado se há relatórios — RN-23)

### Seções

| Seção | Componente |
|---|---|
| Header | Title + meta + tags + status badge |
| Pergunta de investigação | Blockquote destacado |
| Insumos | Lista de execuções com link + tool "Anexar" |
| Conteúdo | MarkdownViewer do `body_md` |
| Relatórios derivados | Lista de Relatórios com link + botão "+ Novo Relatório" |

### Modal "+ Anexar execução"

Lista execuções com status=done, filtros por agente, busca. Multi-select.

### API

- `GET /api/analyses/{slug}`
- `POST /api/analyses/{slug}/executions` body: `{execution_ids: [...]}`
- `DELETE /api/analyses/{slug}/executions/{exec_id}`
- `POST /api/analyses/{slug}/publish`
- `POST /api/export/analyses/{slug}` → exporta `.md`

---

## 4 · Estados de status

| Status atual | Transições permitidas | Restrições |
|---|---|---|
| rascunho | → revisao | — |
| revisao | → rascunho, → publicada | — |
| publicada | (nenhuma) | published_at fixado |

UI esconde botão "Publicar" se já publicada. "Voltar para rascunho" só visível em revisao.

---

## 5 · Validações

- Não pode excluir se há relatórios não-deletados (RN-23) — modal alerta "Esta análise tem N relatórios. Exclua-os primeiro."
- Não pode vincular execução não-concluída (RN-22) — botão desabilitado, tooltip explicativo.

---

## 6 · Estados

- Loading: skeleton
- Empty (lista): "Nenhuma análise ainda" + CTA
- Erro: ErrorState
- 404 detalhe: NotFoundState
