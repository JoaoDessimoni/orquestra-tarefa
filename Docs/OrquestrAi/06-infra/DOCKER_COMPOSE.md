# docker-compose — OrquestrAI

> Especificação do `docker-compose.yml`: serviços, volumes, networks, healthchecks. Última atualização: 20/05/2026.

## Fontes

- [STACK_TECNICO.md](../02-arquitetura/STACK_TECNICO.md)
- [EXECUCAO_DE_AGENTES.md](../02-arquitetura/EXECUCAO_DE_AGENTES.md)
- [REQUISITOS_NAO_FUNCIONAIS.md](../01-requisitos/REQUISITOS_NAO_FUNCIONAIS.md)

---

## 1 · Arquivo `docker-compose.yml`

```yaml
name: orquestr-ai

services:

  db:
    image: postgres:16-alpine
    container_name: orquestr-db
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-orquestr}
      POSTGRES_USER: ${POSTGRES_USER:-orquestr}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      LANG: C.UTF-8
      LC_ALL: C.UTF-8
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "127.0.0.1:5432:5432"
    networks:
      - orquestr_net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-orquestr} -d ${POSTGRES_DB:-orquestr}"]
      interval: 5s
      timeout: 3s
      retries: 10
    restart: unless-stopped

  api:
    build:
      context: ./apps/api
      dockerfile: Dockerfile
    container_name: orquestr-api
    depends_on:
      db:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql+asyncpg://${POSTGRES_USER:-orquestr}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB:-orquestr}
      WORKSPACE_PATH: /workspace/Repasse
      EXPORT_PATH: /workspace/Repasse/Gestao
      MAX_CONCURRENT_EXECUTIONS: ${MAX_CONCURRENT:-3}
      EXECUTION_TIMEOUT_SECONDS: ${EXECUTION_TIMEOUT:-900}
      LOG_LEVEL: ${LOG_LEVEL:-INFO}
      CLAUDE_CONFIG_DIR: /home/orquestr/.claude
    volumes:
      - ../../Repasse:/workspace/Repasse:ro
      - ../../Repasse/Gestao:/workspace/Repasse/Gestao
      - claude_credentials:/home/orquestr/.claude
    ports:
      - "127.0.0.1:8000:8000"
    networks:
      - orquestr_net
    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://127.0.0.1:8000/health"]
      interval: 10s
      timeout: 3s
      retries: 5
      start_period: 30s
    restart: unless-stopped

  web:
    build:
      context: ./apps/web
      dockerfile: Dockerfile
    container_name: orquestr-web
    depends_on:
      api:
        condition: service_healthy
    environment:
      NEXT_PUBLIC_API_URL: http://127.0.0.1:8000
      NODE_ENV: ${NODE_ENV:-development}
    ports:
      - "127.0.0.1:3000:3000"
    networks:
      - orquestr_net
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://127.0.0.1:3000"]
      interval: 10s
      timeout: 3s
      retries: 5
      start_period: 30s
    restart: unless-stopped

volumes:
  pgdata:
    name: orquestr_pgdata
  claude_credentials:
    name: orquestr_claude_credentials

networks:
  orquestr_net:
    name: orquestr_net
    driver: bridge
```

---

## 2 · Estrutura do `Dockerfile` da `api`

`apps/api/Dockerfile`:

```dockerfile
FROM python:3.12-slim AS base

# Node.js (para Claude Code CLI)
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Claude Code CLI (versão pinada)
RUN npm install -g @anthropic-ai/claude-code@<PINNED_VERSION>

# Tool dependencies para curl healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Usuário não-root
RUN useradd -m -u 1000 orquestr
USER orquestr
WORKDIR /app

# Python deps
COPY --chown=orquestr:orquestr pyproject.toml uv.lock ./
RUN pip install --user uv && /home/orquestr/.local/bin/uv sync --frozen

# App code
COPY --chown=orquestr:orquestr src/ ./src/
COPY --chown=orquestr:orquestr migrations/ ./migrations/
COPY --chown=orquestr:orquestr alembic.ini ./

# Entrypoint: roda migrations + uvicorn
COPY --chown=orquestr:orquestr docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

ENV PATH="/home/orquestr/.local/bin:${PATH}"

EXPOSE 8000

CMD ["./docker-entrypoint.sh"]
```

`apps/api/docker-entrypoint.sh`:

```bash
#!/bin/sh
set -e

# Migrations
alembic upgrade head

# Server
exec uvicorn orquestr_ai.main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --workers 1 \
    --proxy-headers
```

> `--workers 1` no MVP. O broker SSE in-process exige single worker. Multi-worker exigiria Redis pub/sub (V1+).

---

## 3 · Estrutura do `Dockerfile` da `web`

`apps/web/Dockerfile`:

```dockerfile
FROM node:20-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

FROM node:20-slim AS dev
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
EXPOSE 3000
CMD ["npm", "run", "dev"]

FROM node:20-slim AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-slim AS production
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/package.json ./
COPY --from=deps /app/node_modules ./node_modules
EXPOSE 3000
CMD ["npm", "run", "start"]
```

Build target `dev` em desenvolvimento (hot reload), `production` em V1+.

Para alternar, em `docker-compose.yml`:
```yaml
web:
  build:
    context: ./apps/web
    target: dev   # ou production
```

---

## 4 · Volumes detalhados

| Volume | Tipo | Mount no container | Permissão | Propósito |
|---|---|---|---|---|
| `pgdata` | nomeado | `/var/lib/postgresql/data` (no `db`) | rw | Dados Postgres |
| `claude_credentials` | nomeado | `/home/orquestr/.claude` (no `api`) | rw | Auth do Claude Code CLI |
| bind workspace | bind | `/workspace/Repasse` (no `api`) | ro | Leitura do `.claude/`, `Docs/` |
| bind Gestao | bind | `/workspace/Repasse/Gestao` (no `api`) | rw | Escrita do export `.md` |

### Path do bind

O `docker-compose.yml` está em `orquestr-ai/`, que fica ao lado de `Repasse/`:

```
~/Documents/Finza/
├── Repasse/                  ← workspace gerencial do João
│   ├── .claude/
│   ├── Docs/
│   ├── Gestao/
│   └── ...
└── orquestr-ai/              ← repositório do produto
    ├── docker-compose.yml    ← bind sobe 1 nível
    ├── apps/
    │   ├── web/
    │   └── api/
    └── ...
```

Bind path no compose: `../Repasse:/workspace/Repasse:ro`.

> Em Windows com WSL2, paths Windows são convertidos automaticamente.

---

## 5 · Healthchecks

| Serviço | Comando | Intervalo | Start period |
|---|---|---|---|
| `db` | `pg_isready` | 5s | — |
| `api` | `curl -fsS http://127.0.0.1:8000/health` | 10s | 30s (espera migration) |
| `web` | `wget --spider http://127.0.0.1:3000` | 10s | 30s (espera Next.js compilar em dev) |

`depends_on` com `condition: service_healthy` encadeia ordem.

---

## 6 · Networks

- `orquestr_net` (bridge default) — interna.
- Hosts internos: `db`, `api`, `web` resolvem automaticamente.
- Nenhuma porta exposta além das 3 declaradas (todas em `127.0.0.1`).

---

## 7 · Comandos úteis

```bash
# Subir tudo
docker compose up -d

# Subir só DB (útil pra rodar api/web local fora do container)
docker compose up -d db

# Ver logs
docker compose logs -f api
docker compose logs -f web

# Restart sem rebuild
docker compose restart api

# Rebuild api (mudou Dockerfile ou requirements)
docker compose build api && docker compose up -d api

# Migrations manual
docker compose exec api alembic upgrade head
docker compose exec api alembic downgrade -1
docker compose exec api alembic revision --autogenerate -m "msg"

# Shell no container
docker compose exec api bash
docker compose exec db psql -U orquestr -d orquestr

# Limpar tudo (cuidado: apaga volume!)
docker compose down -v

# Backup manual
docker compose exec db pg_dump -U orquestr orquestr > backups/$(date +%Y%m%d-%H%M%S).sql

# Restore
docker compose exec -T db psql -U orquestr orquestr < backups/<arquivo>.sql
```

---

## 8 · Autenticação Claude Code dentro do container

Primeira execução pós `up`:

```bash
docker compose exec api claude code
# segue prompt interativo de login (browser auth)
# credentials ficam em /home/orquestr/.claude → volume claude_credentials
```

Persiste entre restarts (volume nomeado).

Alternativa **manual**: copiar `~/.claude/credentials` do host:

```bash
docker compose cp ~/.claude/credentials orquestr-api:/home/orquestr/.claude/
```

---

## 9 · Decisões e trade-offs

| Decisão | Por quê | Trade-off |
|---|---|---|
| `bridge` network (não `host`) | Isolamento + portabilidade Win/Mac/Linux | DB acessado de host só via `127.0.0.1:5432` |
| Volumes nomeados (não bind para pgdata) | Portabilidade — não depende de path host | Backup precisa de comando docker |
| Claude Code no container (não no host) | Reprodutibilidade da versão | Container maior (~500 MB extra) |
| `127.0.0.1` em vez de `0.0.0.0` | Segurança (não expõe na LAN) | Não acessível de outro device sem proxy |
| Single uvicorn worker | Simplicidade do broker SSE | Não usa multi-core para HTTP |
| Sem nginx | Localhost only | Não há TLS local (não-crítico) |

---

## 10 · Tamanhos esperados

| Item | Tamanho |
|---|---|
| Imagem `db` (postgres:16-alpine) | ~250 MB |
| Imagem `api` (custom Python + Node) | ~600 MB |
| Imagem `web` (Next.js dev) | ~300 MB |
| Volume `pgdata` (uso normal) | 100-500 MB |
| Volume `claude_credentials` | <1 MB |
| **Total disco** | ~1.5 GB inicial + dados |

---

## 11 · Limitações conhecidas

1. **Windows + WSL2**: bind paths podem ter latência. Considerar `delegated` ou `cached` no Mac.
2. **Subprocess do Claude Code**: cwd precisa estar no `/workspace/Repasse` (bind ro), mas o Claude Code lê `.claude/credentials` em `/home/orquestr/.claude` (volume separado).
3. **Multi-user**: arquitetura atual não suporta. V1+ exige Redis + workers + auth.
