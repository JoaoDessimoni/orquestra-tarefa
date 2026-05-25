# Estrutura do Repositório — OrquestrAI

> Layout do monorepo: apps/, infra/, scripts/, docs/. Última atualização: 20/05/2026.

## Fontes

- [STACK_TECNICO.md](../02-arquitetura/STACK_TECNICO.md)
- [DOCKER_COMPOSE.md](DOCKER_COMPOSE.md)

---

## 1 · Layout proposto

```
orquestr-ai/                         ← repositório raiz (novo, ao lado de Repasse/)
├── .editorconfig
├── .gitignore
├── .env.example
├── .pre-commit-config.yaml
├── README.md
├── LICENSE                          ← MIT (uso pessoal)
├── docker-compose.yml
├── docker-compose.override.yml      ← dev overrides (opcional)
│
├── apps/
│   ├── web/                         ← Next.js
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── package-lock.json
│   │   ├── next.config.mjs
│   │   ├── tailwind.config.ts
│   │   ├── tsconfig.json
│   │   ├── .eslintrc.json
│   │   ├── .prettierrc
│   │   ├── public/
│   │   ├── app/
│   │   ├── components/
│   │   ├── lib/
│   │   └── styles/
│   │
│   └── api/                         ← FastAPI
│       ├── Dockerfile
│       ├── docker-entrypoint.sh
│       ├── pyproject.toml
│       ├── uv.lock
│       ├── alembic.ini
│       ├── ruff.toml
│       ├── mypy.ini
│       ├── src/
│       │   └── orquestr_ai/
│       │       ├── __init__.py
│       │       ├── main.py
│       │       ├── settings.py
│       │       ├── deps.py
│       │       ├── db/
│       │       ├── schemas/
│       │       ├── routes/
│       │       ├── services/
│       │       ├── runner/
│       │       └── utils/
│       ├── migrations/
│       │   ├── env.py
│       │   ├── script.py.mako
│       │   └── versions/
│       └── tests/
│           ├── conftest.py
│           ├── unit/
│           └── integration/
│
├── infra/
│   ├── README.md
│   └── postgres/
│       └── init.sql                 ← seed inicial (opcional, normalmente via Alembic)
│
├── scripts/
│   ├── bootstrap.sh                 ← clone → up → migrate → seed
│   ├── backup.sh
│   ├── restore.sh
│   └── gen-api.sh                   ← regenera tipos TS do OpenAPI
│
├── docs/                            ← link simbólico ou cópia para Docs/orquestrAi/
│   └── README.md                    ← aponta para Docs/orquestrAi/ do workspace pai
│
└── .github/                         ← (V1+) CI mínimo
    └── workflows/
        ├── lint.yml
        └── test.yml
```

> O repositório `orquestr-ai/` fica em `~/Documents/Finza/orquestr-ai/`, paralelo ao `Repasse/`. O bind do docker-compose sobe um nível pra ver `Repasse/` (`../Repasse:/workspace/Repasse:ro`).

---

## 2 · Convenções

### 2.1 Linguagem por área

| Área | Linguagem | Linter |
|---|---|---|
| `apps/web/` | TypeScript + JSX | eslint + prettier |
| `apps/api/` | Python 3.12+ | ruff + mypy |
| `scripts/` | Bash POSIX | shellcheck |
| Configs | YAML/JSON/TOML | yamllint (opcional) |

### 2.2 Naming

- Arquivos Python: `snake_case.py`
- Arquivos TypeScript: `kebab-case.ts` ou `PascalCase.tsx` para componentes
- Pastas: `kebab-case/` em tudo
- Migrations Alembic: `<timestamp>_<slug>.py`

### 2.3 Commits

Convencional commits:
- `feat(agents): adiciona endpoint de clonagem`
- `fix(runner): captura crash do subprocess`
- `chore(deps): atualiza fastapi 0.115 → 0.116`
- `docs(api): completa schema de execuções`

---

## 3 · Apps em detalhe

### 3.1 `apps/web/app/`

```
app/
├── layout.tsx                  ← root layout (Providers + Toaster + Cmd+K)
├── page.tsx                    ← redirect /dashboard
├── (dashboard)/
│   ├── layout.tsx              ← sidebar + topbar
│   ├── dashboard/
│   │   └── page.tsx
│   ├── agents/
│   │   ├── page.tsx            (list)
│   │   ├── new/page.tsx        (create)
│   │   └── [slug]/
│   │       ├── page.tsx        (detail)
│   │       └── edit/page.tsx
│   ├── subagents/...
│   ├── skills/...
│   ├── executions/...
│   ├── analyses/...
│   ├── reports/...
│   └── settings/page.tsx
└── api/                        ← (vazio, backend é FastAPI separado)
```

### 3.2 `apps/web/components/`

```
components/
├── ui/                          ← primitivos (Button, Input, Table, ...)
├── layout/                      ← Sidebar, Topbar, Breadcrumb
├── command-palette/
├── stream-viewer/               ← componente custom de execução
├── markdown-editor/
├── markdown-viewer/
└── empty-states/
```

### 3.3 `apps/web/lib/`

```
lib/
├── api/
│   ├── client.ts                ← fetch wrapper tipado
│   ├── types.gen.ts             ← gerado de OpenAPI
│   ├── agents.ts                ← hooks (use queries/mutations)
│   ├── executions.ts
│   └── ...
├── hooks/
│   ├── use-execution-stream.ts  ← EventSource
│   ├── use-hotkeys-global.ts
│   └── ...
├── stores/
│   └── ui-store.ts              ← zustand (palette open, etc.)
└── utils/
```

### 3.4 `apps/api/src/orquestr_ai/`

Ver [STACK_TECNICO.md §2 Estrutura](../02-arquitetura/STACK_TECNICO.md).

---

## 4 · `.gitignore` essencial

```
# OS
.DS_Store
Thumbs.db

# IDEs
.vscode/
.idea/
*.swp

# Python
__pycache__/
*.py[cod]
.venv/
.pytest_cache/
.mypy_cache/
.ruff_cache/
*.egg-info/
.uv/

# Node
node_modules/
.next/
out/
dist/
.turbo/

# Env
.env
.env.local
.env.*.local
!.env.example

# Logs
*.log
logs/

# Backups
backups/*.sql
backups/*.dump

# Generated
apps/web/lib/api/types.gen.ts     ← ou versionar; preferir gerar

# Docker
.docker-cache/
```

---

## 5 · `.editorconfig`

```ini
root = true

[*]
end_of_line = lf
insert_final_newline = true
charset = utf-8
trim_trailing_whitespace = true
indent_style = space

[*.{py,toml}]
indent_size = 4

[*.{ts,tsx,js,jsx,json,yaml,yml,md,html,css}]
indent_size = 2

[Makefile]
indent_style = tab
```

---

## 6 · Pre-commit hooks (`.pre-commit-config.yaml`)

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.5.0
    hooks:
      - id: ruff
        args: [--fix]
        files: ^apps/api/
      - id: ruff-format
        files: ^apps/api/

  - repo: local
    hooks:
      - id: eslint
        name: eslint (web)
        entry: bash -c 'cd apps/web && npx eslint --fix'
        language: system
        files: ^apps/web/.*\.(ts|tsx|js|jsx)$
      - id: prettier
        name: prettier (web)
        entry: bash -c 'cd apps/web && npx prettier --write'
        language: system
        files: ^apps/web/.*\.(ts|tsx|js|jsx|json|md)$
```

---

## 7 · `README.md` raiz (esqueleto)

```markdown
# OrquestrAI

Sistema local de orquestração de agentes Claude Code + análises e relatórios.

## Setup

1. Instale Docker Desktop e Docker Compose v2.
2. Clone o repo.
3. Copie `.env.example` para `.env` e ajuste.
4. `docker compose up -d`
5. Aguarde healthchecks. Acesse `http://localhost:3000`.

Spec completa em [Docs/orquestrAi/](../Repasse/Docs/orquestrAi/).

## Scripts

- `./scripts/bootstrap.sh` — setup completo
- `./scripts/backup.sh` — dump SQL
- `./scripts/restore.sh <arquivo>` — restore

## Stack

- Next.js 14 + TypeScript + Tailwind
- FastAPI + SQLAlchemy 2 + Alembic + Postgres 16
- docker-compose
- Claude Code CLI (sidecar no container `api`)

## Licença

MIT (uso pessoal).
```

---

## 8 · Trade-offs

| Decisão | Justificativa |
|---|---|
| Monorepo (não 2 repos) | Single-user, lockstep deploy local, sem overhead de versionamento separado |
| `apps/` (não `packages/`) | Indica aplicação executável vs lib |
| Docs em `Repasse/Docs/orquestrAi/` (não no repo do produto) | Mantém doc viva no workspace gerencial; produto puxa via link |
| Sem `nx/turborepo` | Monorepo pequeno; npm scripts bastam |
| `uv` (não poetry) | Mais rápido, padrão moderno Python |
| Versionar `uv.lock` e `package-lock.json` | Reprodutibilidade |
| `.env` no `.gitignore`, `.env.example` versionado | Convenção 12-factor |

---

## 9 · Migração futura

Se o repo crescer:
- `packages/` para libs internas reusáveis (V1+ se compartilhar tipos entre web/api).
- `turborepo` se build paralelo importa.
- Repos separados se time crescer e cadência de release divergir.
