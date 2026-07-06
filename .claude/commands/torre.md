---
description: Ponte contexto+leitura para o subprojeto cobranca-finza (Torre de Controle v2). Subcomandos — contexto, arquitetura, agentes, skills, db, guia, ef, entrar. Entende a Torre, consulta o Supabase read-only e navega os docs; dev pesado acontece DENTRO do subprojeto (8 agentes próprios). Não commita/push/PR, não escreve Supabase. Não confunde com a frente BTR do /backlog nem com /quimera, /jira, /n8n.
---

# /torre — entender e consultar a Torre de Controle (cobranca-finza)

Roteia para o agente **`torre-bridge`** (escopo **contexto + leitura**). Conhecimento do subprojeto na skill `torre-projeto`; o domínio profundo vive dentro de `cobranca-finza/` (CLAUDE.md, ARCHITECTURE.md, `docs/guides/`, 24 skills).

> **3 camadas da Torre — não confunda:** o **código** (`cobranca-finza/`, via `/torre`) ≠ a **frente de backlog BTR** (`Backlog/frentes/torre/`, via `/backlog`) ≠ o **overview narrativo** (`Backlog/contexto/torre_de_controle_overview.md`, via `/contexto`).

> **Daqui é contexto/leitura.** Implementação de código, migration, Edge Function, fix de bug = **entrar no subprojeto** (`/torre entrar`). Nada de commit/push/PR; nada de escrita no Supabase (tudo via CI/CD).

`$ARGUMENTS` define o subcomando:

| Forma | O que faz |
|---|---|
| `/torre` (vazio) | Snapshot: o que é a Torre, stack, e os pontos de entrada (docs, agentes, skills). |
| `/torre contexto` | Resumo executivo do sistema (multi-tenant, cobrança title-centric) ligando com a frente BTR e o overview em `Backlog/contexto/`. |
| `/torre arquitetura [assunto]` | Explica arquitetura/invariantes (vw_titles_live, Pipeline v2, dedup, schema-por-org). Lê `ARCHITECTURE.md`/CLAUDE.md do subprojeto. |
| `/torre agentes` | Lista os 8 agentes do subprojeto e quando usar cada um (tabela domínio→agente). |
| `/torre skills [busca]` | Lista/encontra as 24 skills do subprojeto (campaign-system, etl-system, multi-tenant, dev-workflow, ...). |
| `/torre db "<SELECT ...>"` | Consulta o banco em **somente leitura** via Supabase MCP (quando configurado). Diz ambiente + schema/org. |
| `/torre guia <assunto>` | Aponta/lê o guia certo em `docs/guides/` (etl, campanhas-e-reguas, filtros, ia, observabilidade, ...). |
| `/torre ef [busca]` | Navega o catálogo de Edge Functions (`docs/edge-functions.md`, `docs/funcoes-criticas.md`). |
| `/torre entrar [tarefa]` | Orienta abrir o subprojeto (`cd cobranca-finza` → `claude`) e nomeia o agente certo para a tarefa de dev. |

## Execução

Invoque `torre-bridge` passando o subcomando + args. Brief:
```
Subcomando: <contexto|arquitetura|agentes|skills|db|guia|ef|entrar>
Args: <args>
Escopo: contexto + leitura (dev pesado → entrar no subprojeto)
```

## Quando pedir input adicional (via AskUserQuestion)

- `db` sem indicação de ambiente (dev/prod) → pergunte qual antes de consultar.
- Pedido que é claramente **implementação** → não tente fazer daqui; ofereça `/torre entrar` nomeando o agente.
- `guia`/`ef` com assunto vago → liste os disponíveis e pergunte.

## Regras duras

- **Leitura/contexto livre** (`contexto`, `arquitetura`, `agentes`, `skills`, `guia`, `ef`, `db` com SELECT) — executa direto.
- **Proibido daqui:** `git commit`/`push`/`gh pr create|merge`, qualquer escrita Supabase (`db push`, `functions deploy`, `apply_migration`, `deploy_edge_function`, branch ops). Bloqueado por deny no `settings.json`.
- **Dev real entra no subprojeto** e delega aos 8 agentes (`campaign-agent`, `etl-agent`, `filter-portfolio-agent`, `supabase-agent`, `torre-frontend`, `torre-debugger`, `torre-tester`, `project-planner`).
- Respeita Lovable.dev (não mover `src/components/ui`, `src/integrations/supabase`, não mexer em `.lovable`/`lovable-tagger`).
- Se o Supabase MCP não responder, é provável `.mcp.json` não configurado (ver skill `torre-projeto`), não bug.
