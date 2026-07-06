---
name: torre-projeto
description: Mapa que o workspace orquestra-tarefa tem do subprojeto acoplado cobranca-finza (github.com/blips-ai/cobranca-finza) — a Torre de Controle v2, SaaS multi-tenant de cobrança da Finza. Carregue antes de qualquer operação via /torre ou pelo agente torre-bridge. Cobre stack, os 8 agentes, as 24 skills, invariantes críticas, guardrails (git/Supabase via CI/CD), docs/guias e o vínculo com a frente BTR. Escopo do parent = contexto + leitura; dev pesado entra no subprojeto. NÃO substitui o CLAUDE.md/ARCHITECTURE.md DENTRO do cobranca-finza — é índice + ponte.
---

# Skill — Torre de Controle / cobranca-finza (subprojeto acoplado)

`cobranca-finza/` é um **repositório git próprio** (`github.com/blips-ai/cobranca-finza.git`) acoplado dentro do orquestra-tarefa, em `C:\Users\João Vinicius\Documents\Finza\Projetos\orquestra-tarefa\cobranca-finza`. É a **Torre de Controle v2** — o sistema de cobrança da Finza: campanhas, ETL, filtros dinâmicos, multi-tenant.

Esta skill é o **mapa que o parent tem** do subprojeto, para o agente `torre-bridge` e o comando `/torre`. Escopo do parent: **contexto + leitura**. A fonte de verdade do domínio é o **`cobranca-finza/CLAUDE.md`, `ARCHITECTURE.md`, `docs/guides/` e as 24 skills locais** — leia de lá para detalhe.

## 3 camadas da Torre (não confundir)

- **Código** → `cobranca-finza/` — via `/torre` (esta skill / `torre-bridge`).
- **Frente de backlog BTR** → `Backlog/frentes/torre/` — via `/backlog` (estratégia/RICE, agente `po-backlog`).
- **Overview narrativo** → `Backlog/contexto/torre_de_controle_overview.md` — via `/contexto` (curadoria, `context-curator`).

## Stack

React 19 · TypeScript 5.9 · Vite 7 · Tailwind CSS 4 · shadcn/ui · React Router 7 · TanStack Query 5 · Supabase (PostgreSQL + ~49 Edge Functions Deno). Multi-tenant **schema por org** (`org_{slug}`). `npm run dev` → http://localhost:8080.

## Invariantes críticas (resumo — detalhe nas regras 1–21 do CLAUDE.md do subprojeto)

- **`vw_titles_live`** é a única fonte de verdade de contatos/títulos (passthrough de `mv_titles_base`, refresh 12h, ~20 campos pré-calculados). Nunca `vw_contacts_with_titles` (não existe) nem recálculo inline.
- **`days_overdue` suporta negativos** (cobrança preventiva D-7/D-1). Nunca `GREATEST(0, ...)`.
- **Title-centric:** o sistema avalia **títulos** individuais, não contatos, por `days_overdue`.
- **Campaign Pipeline v2** = 6 RPCs em cadeia: `resolve_contacts → fetch_titles → match_titles → apply_rules → cross_dedup → create_actions` (dispositions encadeados; `fetch_titles` usa `'fetched'`, não `'pending'`).
- **Dedup:** comunicação (WhatsApp/email) por **contato**; negativação/notificação por **contrato**.
- **Status canônicos** em português (títulos e ações); nunca legacy em inglês. Helpers em `_shared/action-status.ts` e `title-status-config.ts`.
- **Brasília time:** usar `_shared/brasilia-time.ts` (Intl.DateTimeFormat não funciona no Deno Deploy).

## Os 8 agentes do subprojeto (dev real — dentro do cobranca-finza)

| Domínio | Agente |
|---|---|
| Campanhas, workflows/réguas, ações | `campaign-agent` |
| ETL, pipelines, data sources | `etl-agent` |
| Filtros, portfólios | `filter-portfolio-agent` |
| DB, migrations, Edge Functions, RPCs | `supabase-agent` |
| UI, componentes, hooks, dashboard | `torre-frontend` |
| Bugs, erros, diagnóstico | `torre-debugger` |
| Testes E2E/unitários | `torre-tester` |
| Planejamento de feature | `project-planner` |

O subprojeto opera em modo **orquestrador**: classifica domínio → delega ao agente → valida com `torre-tester` → entrega.

## As 24 skills do subprojeto (deep dive — dentro do cobranca-finza)

- **Domínio:** `campaign-system`, `etl-system`, `filter-system`, `multi-tenant`, `maestro-agent`, `variables-system`, `contact-tags`, `dev-workflow`, `ia-metrics-funnel`.
- **Frontend:** `react-patterns`, `tailwind-patterns`, `tanstack-query`, `lovable-compatibility`.
- **Arquitetura/design:** `architecture`, `database-design`, `frontend-design`, `api-patterns`.
- **Práticas:** `clean-code`, `plan-writing`, `systematic-debugging`, `testing-patterns`, `documentation-templates`.
- **Utilitárias:** `bash-linux`, `brainstorming`.

## Docs (navegação — dentro do cobranca-finza)

- `ARCHITECTURE.md` — C4 + ADRs, estrutura de pastas.
- `docs/guides/` (13): visao-geral, fluxo-cobranca, campanhas-e-reguas, acoes-e-status, etl, filtros-e-portfolios, ia, variaveis-e-templates, integracoes, webhooks-pagamento, observabilidade, tags-e-selos, dashboard-e-metricas.
- `docs/edge-functions.md` (catálogo + contagens), `docs/funcoes-criticas.md` (mapa por fluxo, EFs load-bearing).

## Guardrails (iguais aos do subprojeto — valem também daqui)

- **Git é dos devs:** Claude/agentes **nunca** `git commit`/`push`/`gh pr create|merge`. Ler git é OK.
- **Supabase via CI/CD:** migrations são arquivos em `supabase/migrations/`; EFs deployam por GitHub Actions no merge. **Nunca** `db push`/`functions deploy` nem MCP write (`apply_migration`/`deploy_edge_function`/branch ops). Leitura (incl. `execute_sql` p/ SELECT) OK. Bloqueado por deny no `settings.json` do parent.
- **Lovable.dev:** nunca remover `lovable-tagger`, mover `src/components/ui/` ou `src/integrations/supabase/`, mexer em `.lovable/`; usar imports `@/`; sem cores hardcoded.

## Setup do Supabase MCP no parent (para `/torre db`)

O MCP Supabase **não** é herdado do subprojeto. Para consultar o banco read-only daqui:
1. Copiar `orquestra-tarefa/.mcp.json.example` → `.mcp.json` e preencher `supabase-prod`/`supabase-dev` com os `project_ref` reais (Supabase Dashboard, ou reaproveitar de `cobranca-finza/.env.local` + `src/integrations/supabase/client.ts`).
2. Reiniciar o Claude Code. Uso é **somente leitura** (escrita bloqueada por deny).

## Quando ENTRAR no subprojeto

Contexto, leitura de docs, explicação de arquitetura e `SELECT` ficam no `/torre`. Para **qualquer implementação** (campanha, ETL, filtro, migration, EF, UI, fix de bug, teste), abra o subprojeto: `cd cobranca-finza` e rode `claude` lá — onde vivem os 8 agentes e os guardrails de git/Supabase.
