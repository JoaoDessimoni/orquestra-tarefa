# Stack Técnico — OrquestrAI

> Tecnologias, versões e bibliotecas. Justificativas curtas. Última atualização: 20/05/2026.

## Fontes

- [VISAO_GERAL.md](VISAO_GERAL.md)
- [REQUISITOS_NAO_FUNCIONAIS.md](../01-requisitos/REQUISITOS_NAO_FUNCIONAIS.md)

---

## 1 · Frontend (`apps/web/`)

| Categoria | Lib | Versão | Por quê |
|---|---|---|---|
| Framework | **Next.js** | 14.2.x (App Router) | Padrão React moderno; suporta SSE; build-only no MVP, sem SSR pesado |
| Linguagem | **TypeScript** | 5.4+ | Tipagem forte; integra com OpenAPI gerado pelo backend |
| Estilo | **Tailwind CSS** | 3.4+ | Utility-first; matches Linear/Notion-like density; tokens via `tailwind.config.ts` |
| State client | **zustand** | 4.5+ | Store leve, sem boilerplate; usado para UI state (palette aberta, modais) |
| State server | **@tanstack/react-query** | 5.x | Cache + mutations + invalidations; padrão para CRUD |
| Forms | **react-hook-form** + **zod** | 7.x + 3.x | Performance + validação tipada compartilhada com backend |
| Markdown render | **react-markdown** + **rehype-highlight** + **remark-gfm** | latest | Renderiza body de Skills, Análises, Relatórios, e output de Execução |
| Code editor (prompt) | **@uiw/react-textarea-code-editor** | 3.x | Editor leve com syntax highlighting; suficiente pra MVP |
| Busca fuzzy | **fuse.js** | 7.x | Command Palette; indexa em memória |
| Atalhos teclado | **react-hotkeys-hook** | 4.x | Cmd+K, Esc, 1-9, etc. |
| Ícones | **lucide-react** | 0.4xx | Stroke icons leves, padrão Linear-like |
| Toasts | **sonner** | 1.x | Toast moderno, sem dependência de provider gigante |
| HTTP client | **fetch nativo** + tanstack-query | — | Sem axios; query gerencia |
| OpenAPI types | **openapi-typescript** | 7.x | Gera tipos do schema FastAPI; mantém front/back em sync |
| Lint | **eslint** + **prettier** | latest | Convenção do projeto |
| Test | **vitest** + **@testing-library/react** | latest | Componentes críticos (palette, stream UI) |

### Estrutura `apps/web/`

```
apps/web/
├── app/
│   ├── layout.tsx
│   ├── page.tsx                  → redirect to /dashboard
│   ├── (dashboard)/
│   │   ├── layout.tsx            → sidebar + topbar
│   │   ├── dashboard/page.tsx
│   │   ├── agents/
│   │   │   ├── page.tsx          → list
│   │   │   ├── new/page.tsx
│   │   │   └── [slug]/
│   │   │       ├── page.tsx      → detail
│   │   │       └── edit/page.tsx
│   │   ├── subagents/...
│   │   ├── skills/...
│   │   ├── executions/
│   │   │   ├── page.tsx
│   │   │   ├── new/page.tsx
│   │   │   └── [id]/page.tsx     → detail + stream
│   │   ├── analyses/...
│   │   ├── reports/...
│   │   └── settings/page.tsx
├── components/
│   ├── ui/                        → Button, Input, Table, Card, Modal, Toast
│   ├── command-palette/
│   ├── stream-viewer/
│   ├── markdown-editor/
│   └── markdown-viewer/
├── lib/
│   ├── api/                       → typed fetch wrappers
│   ├── hooks/
│   └── stores/
├── styles/globals.css
├── tailwind.config.ts
└── package.json
```

---

## 2 · Backend (`apps/api/`)

| Categoria | Lib | Versão | Por quê |
|---|---|---|---|
| Framework | **FastAPI** | 0.115+ | Async, OpenAPI nativo, pydantic-v2 |
| Servidor ASGI | **uvicorn** | 0.30+ | Padrão FastAPI; `--reload` em dev |
| Validação | **pydantic** | 2.7+ | Schemas tipados; gera OpenAPI |
| ORM | **SQLAlchemy** | 2.x (async) | Async + tipagem moderna |
| Migrations | **alembic** | 1.13+ | Versionamento de schema |
| Driver Postgres | **asyncpg** | 0.29+ | Performance async |
| Subprocess async | **asyncio.create_subprocess_exec** | stdlib | Spawna Claude Code; lê stdout linha-a-linha |
| SSE | **sse-starlette** | 2.x | Wrapper SSE para Starlette/FastAPI |
| Tasks | **fastapi-utils.cbv** ou nativo | — | Background tasks via `BackgroundTasks` |
| Logs | **structlog** | 24.x | JSON structured logs |
| Settings | **pydantic-settings** | 2.x | Lê `.env` tipado |
| Testes | **pytest** + **pytest-asyncio** + **httpx** | latest | Tests async; cliente HTTP de teste |
| Lint | **ruff** | latest | All-in-one (lint + format) |
| Type check | **mypy** | latest | Estrito em `src/runner/` |

### Estrutura `apps/api/`

```
apps/api/
├── src/orquestr_ai/
│   ├── __init__.py
│   ├── main.py                    → FastAPI app + middlewares
│   ├── settings.py                → pydantic-settings (.env)
│   ├── deps.py                    → DI: db session, settings
│   ├── db/
│   │   ├── base.py                → declarative_base
│   │   ├── session.py             → async engine + session
│   │   └── models/
│   │       ├── agent.py
│   │       ├── skill.py
│   │       ├── execution.py
│   │       ├── analysis.py
│   │       ├── report.py
│   │       └── setting.py
│   ├── schemas/                   → pydantic v2 (request/response)
│   ├── routes/
│   │   ├── agents.py
│   │   ├── skills.py
│   │   ├── executions.py
│   │   ├── analyses.py
│   │   ├── reports.py
│   │   ├── export.py
│   │   ├── settings.py
│   │   ├── stream.py              → SSE endpoint
│   │   └── health.py
│   ├── services/                  → lógica de negócio (RN-XX)
│   │   ├── agents.py
│   │   ├── executions.py
│   │   ├── export.py
│   │   └── cycle_detection.py
│   ├── runner/
│   │   ├── claude_code.py         → ClaudeCodeRunner (subprocess + parser)
│   │   ├── events.py              → tipos de evento
│   │   └── parser.py              → parser do output do Claude Code CLI
│   └── utils/
│       ├── logging.py
│       └── slug.py
├── migrations/                    → alembic
│   ├── env.py
│   └── versions/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── conftest.py
├── pyproject.toml
└── Dockerfile
```

---

## 3 · Banco

| Item | Valor |
|---|---|
| **Engine** | Postgres 16 |
| **Imagem** | `postgres:16-alpine` |
| **Volume** | `pgdata` (nomeado, persistente) |
| **Port (host)** | `5432` |
| **Banco** | `orquestr` |
| **Usuário** | `orquestr` |
| **Senha** | de `.env` (`POSTGRES_PASSWORD`) |
| **Encoding** | `UTF8` |
| **Locale** | `pt_BR.UTF-8` ou `C.UTF-8` (preferência: C para ordering estável) |

---

## 4 · Infraestrutura

| Item | Valor |
|---|---|
| **Orquestração** | docker-compose v2 |
| **Imagens custom** | `Dockerfile` em `apps/web` e `apps/api` |
| **Networking** | rede `orquestr_net` interna; só `web` e `api` expõem porta no host |
| **Volumes** | `pgdata` (DB) + bind `../Repasse:/workspace/Repasse:ro` (workspace, somente leitura do `.claude/`) + bind `../Repasse/Gestao:/workspace/Repasse/Gestao:rw` (export) |
| **Healthchecks** | `web`: HTTP 200 em `/`; `api`: HTTP 200 em `/health`; `db`: `pg_isready` |
| **Restart policy** | `unless-stopped` |

Spec do compose em [06-infra/DOCKER_COMPOSE.md](../06-infra/DOCKER_COMPOSE.md).

---

## 5 · Claude Code CLI (no host)

| Item | Valor |
|---|---|
| **Binário** | Instalado pelo usuário, fora do container |
| **Versão mínima** | TBD — validar a partir da versão atual do João |
| **Estratégia de invocação** | Subprocess do `api` chama binário no host. Detalhes em [EXECUCAO_DE_AGENTES.md](EXECUCAO_DE_AGENTES.md) |

<!-- TODO: confirmar versão exata do Claude Code que João usa -->

---

## 6 · Versões pinadas (resumo)

Para evitar drift, todas versões serão pinadas em arquivos lock:

- `apps/web/package-lock.json` (npm)
- `apps/api/poetry.lock` ou `uv.lock`
- Imagens Docker com SHA digest, não tag móvel

Atualizações trimestrais (V1+).
