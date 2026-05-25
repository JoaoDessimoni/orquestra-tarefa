# Mapa de Navegação — OrquestrAI

> Sitemap + fluxos + sidebar agrupada (v2). Última atualização: 21/05/2026.

## Fontes

- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md)
- [COMPONENTES.md](../07-design-system/COMPONENTES.md) §2.1 sidebar
- `BOARD.html` v2

---

## 1 · Sitemap

```
/                              → redirect /dashboard
/dashboard                     → Produção & Gestão (hero-dark + KPIs + barchart + deadlines)
/executions                    → Lista de execuções
/executions/[id]               → Detalhe com stream
/agents                        → Agentes primários (is_subagent=false)
/agents/[slug]                 → Detalhe (modal) + tabs Prompt/Skills/Subagents/Execuções
/subagents                     → Subagentes (is_subagent=true)
/subagents/[slug]              → Detalhe modal
/skills                        → Lista (cards)
/skills/[slug]                 → Detalhe modal (markdown preview)
/commands                      → Read-only list dos slash commands
/analyses                      → Lista de análises (cards)
/analyses/[id]                 → Detalhe modal
/pendencias                    → Tabela densa
/pendencias/[id]               → Detalhe modal
/reunioes                      → Cards
/reunioes/[id]                 → Detalhe modal
/reports                       → Tabela
/reports/[id]                  → Detalhe modal
/roadmap                       → Kanban por frente
/roadmap/[id]                  → Detalhe modal
/ones                          → 1on1s (cards)
/ones/[id]                     → Detalhe modal
/settings                      → Configuração + reset bootstrap
```

> No protótipo (`BOARD.html`), tudo vive em hash navigation (`#dashboard`, `#pendencias`, etc.). No produto Next.js: rotas App Router.

---

## 2 · Sidebar v2 (agrupada)

```
◆ OrquestrAI                v2 proto
─────────────────────────────────────

TRABALHO
  ⌂  Dashboard              1
  ⚡ Execuções              2  (8)

CONHECIMENTO
  ◈  Agentes                3  (3)
  ◇  Subagentes             4  (6)
  ◆  Skills                 5  (3)
  ⌥  Commands               6  (10)

PRODUÇÃO
  🔍 Análises              7  (2)
  📤 Relatórios             8  (1)
  ▢  Pendências             9  (26)
  🗓 Reuniões                  (3)
  🛣 Roadmap                   (24)

SISTEMA
  👤 1on1s                     (0)
  ⚙  Settings              ,

─────────────────────────────────────
JV  João Vinícius
    Supervisor IAF              ⚙
```

**Decisão v2**: módulos de **gestão** (Pendências, Reuniões, 1on1s, Roadmap) **entram no produto** — não ficam mais como "legado". Convivem com módulos de **conhecimento** (Agentes/Skills) e **produção** (Análises/Relatórios). Spec completa em [§8.8 do plan](../../../.claude/plans/eu-quero-trasnformar-o-replicated-river.md).

---

## 3 · Topbar

```
┌────────────────────────────────────────────────────────────────────┐
│  Dashboard          ⌥  Buscar comandos, ações… ⌘K          ?      │
└────────────────────────────────────────────────────────────────────┘
```

- Breadcrumb (clicável)
- Spacer
- Botão Cmd+K (abre palette)
- Botão help (?)

---

## 4 · Fluxos críticos

### Fluxo 1 — Criar pendência rápida

```
1. /dashboard
   └─ Clica "+ Nova Pendência" (atalho rápido) → openForm('pendencia')

2. Modal abre com:
   - id auto-gerado (P37, P38, …)
   - status default: aberta
   - prioridade default: media
   - criada default: hoje
   - owner default: João Vinícius
   - tags (chipinput vazio)

3. Preenche título, deadline, body
   └─ Clica "Criar"

4. Modal fecha → toast "Pendência criada" → DB persiste em localStorage
   └─ Re-render: KPI atualiza, aparece no Dashboard "Deadlines próximas"
```

### Fluxo 2 — Análise → Relatório

```
1. /analyses → openForm('analise')
2. Cria análise com tags e relacionadas (P15, P20, P21, ...)
3. Após salvar, abre detalhe → clica "+ Relatório"
4. openForm('relatorio') com analise_id pré-preenchido
5. Preenche destinatário, classificação → salva
6. Relatório aparece em /reports
```

### Fluxo 3 — Editar pendência via Cmd+K

```
1. ⌘K abre palette
2. Digita "p15"
3. Lista filtra: "P15 · Valentina roteamento Rhino"
4. Enter → openModal detalhe
5. Clica "Editar" → openForm('pendencia', {id:'P15'})
6. Modifica deadline → salva
7. Lista re-renderiza, dashboard recalcula
```

### Fluxo 4 — Executar agente (mock stream)

```
1. /agents/researcher-finza (modal)
2. Clica "▶ Executar"
3. Modal fecha, navega para /executions, cria registro novo "running"
4. Render: stream viewer com tokens animados (fade-in 350ms cada)
5. Após ~3-4s, status vira "done" + métricas calculadas
6. Toast "Execução concluída"
```

---

## 5 · Atalhos globais

| Atalho | Ação |
|---|---|
| `⌘K` / `Ctrl+K` | Command Palette |
| `1`–`9` | Trocar view (1=Dashboard, 2=Execuções, …, 9=Pendências) |
| `,` | Settings |
| `N` | Criar novo na view atual (e.g. em /pendencias → abre form pendência) |
| `/` | Foca/abre busca |
| `?` | Overlay de ajuda |
| `Esc` | Fecha modal/palette/help |
| `g d` | Dashboard |
| `g p` | Pendências |
| `g a` | Agentes |
| `g e` | Execuções |
| `g s` | Skills |
| `g r` | Relatórios |
| `g m` | Reuniões |
| `g k` | Roadmap |
| `g n` | Análises |
| `g o` | 1on1s |

---

## 6 · Estados de view

Toda lista tem:
- **Loading**: skeleton de rows/cards.
- **Empty**: ilustração + CTA `+ Novo X`.
- **Erro**: ErrorState + retry.

Toda tela de detalhe (modal) tem:
- Loading (rare — em memória)
- 404 (id inválido) → close + toast
- OK

---

## 7 · Mobile / tablet

**MVP: desktop only**. Layout para ≥1280px. Viewports menores funcionam mas sem otimização — sidebar pode ficar collapsada futuramente.

---

## 8 · Histórico

| Versão | Data | Mudança |
|---|---|---|
| v1 | 2026-05-20 | Sidebar branca Linear-style, módulos de gestão como "legacy" |
| **v2** | **2026-05-21** | Sidebar dark canônica. Módulos de gestão **promovidos a produção**. Atalhos `g x` expandidos. |
