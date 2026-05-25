# Variáveis de Ambiente — OrquestrAI

> `.env.example` completo + descrição de cada variável. Última atualização: 20/05/2026.

## Fontes

- [DOCKER_COMPOSE.md](DOCKER_COMPOSE.md)
- [STACK_TECNICO.md](../02-arquitetura/STACK_TECNICO.md)

---

## 1 · `.env.example` (raiz do repo)

```env
# ============================================================
# OrquestrAI — Configuração local
# Copie este arquivo para .env e ajuste valores
# ============================================================

# ─── Postgres ────────────────────────────────────────────────
POSTGRES_DB=orquestr
POSTGRES_USER=orquestr
POSTGRES_PASSWORD=changeme_local_only

# ─── Backend (api) ───────────────────────────────────────────
# URL gerada automaticamente pelo docker-compose; descomente
# se rodar api fora do container apontando para DB do compose:
# DATABASE_URL=postgresql+asyncpg://orquestr:changeme_local_only@127.0.0.1:5432/orquestr

# Workspace montado no container
WORKSPACE_PATH=/workspace/Repasse
EXPORT_PATH=/workspace/Repasse/Gestao

# Limites operacionais
MAX_CONCURRENT_EXECUTIONS=3
EXECUTION_TIMEOUT_SECONDS=900

# Logging
LOG_LEVEL=INFO

# Claude Code CLI
CLAUDE_CONFIG_DIR=/home/orquestr/.claude

# ─── Frontend (web) ──────────────────────────────────────────
NEXT_PUBLIC_API_URL=http://127.0.0.1:8000
NODE_ENV=development

# ─── CORS (api) ──────────────────────────────────────────────
CORS_ALLOW_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# ─── Auth (preparado para V1+) ───────────────────────────────
AUTH_ENABLED=false

# ─── Backups ─────────────────────────────────────────────────
BACKUP_DIR=./backups

# ─── Compose (opcional) ──────────────────────────────────────
COMPOSE_PROJECT_NAME=orquestr-ai
```

---

## 2 · Descrição detalhada

### 2.1 Postgres

| Var | Default | Descrição |
|---|---|---|
| `POSTGRES_DB` | `orquestr` | Nome do banco |
| `POSTGRES_USER` | `orquestr` | Usuário/owner |
| `POSTGRES_PASSWORD` | (sem default) | **Obrigatória**. Senha local |

> Por estar tudo em `127.0.0.1`, a senha não atravessa rede pública. Ainda assim, evite `password`. Use string aleatória qualquer.

### 2.2 Backend (api)

| Var | Default | Descrição |
|---|---|---|
| `DATABASE_URL` | gerado | DSN completa. Geralmente vazio (compose injeta) |
| `WORKSPACE_PATH` | `/workspace/Repasse` | Path do workspace dentro do container |
| `EXPORT_PATH` | `/workspace/Repasse/Gestao` | Path base para export `.md` |
| `MAX_CONCURRENT_EXECUTIONS` | `3` | Máximo de subprocess Claude Code simultâneos |
| `EXECUTION_TIMEOUT_SECONDS` | `900` (15min) | Timeout default por execução |
| `LOG_LEVEL` | `INFO` | `DEBUG`/`INFO`/`WARNING`/`ERROR` |
| `CLAUDE_CONFIG_DIR` | `/home/orquestr/.claude` | Onde Claude Code grava credenciais |

### 2.3 Frontend (web)

| Var | Default | Descrição |
|---|---|---|
| `NEXT_PUBLIC_API_URL` | `http://127.0.0.1:8000` | URL pública para fetches do browser |
| `NODE_ENV` | `development` | `development`/`production` |

> `NEXT_PUBLIC_*` é exposto ao browser. Não coloque secrets.

### 2.4 CORS

| Var | Default | Descrição |
|---|---|---|
| `CORS_ALLOW_ORIGINS` | `http://localhost:3000,http://127.0.0.1:3000` | CSV de origens permitidas |

### 2.5 Auth (preparado para V1+)

| Var | Default | Descrição |
|---|---|---|
| `AUTH_ENABLED` | `false` | Quando `true` (V1+), exige login básico |
| `AUTH_USERNAME` | — | (V1+) Usuário fixo |
| `AUTH_PASSWORD_HASH` | — | (V1+) bcrypt hash |

### 2.6 Backups

| Var | Default | Descrição |
|---|---|---|
| `BACKUP_DIR` | `./backups` | Onde `scripts/backup.sh` deposita dumps |

### 2.7 Compose

| Var | Default | Descrição |
|---|---|---|
| `COMPOSE_PROJECT_NAME` | `orquestr-ai` | Prefixo de containers/volumes |

---

## 3 · Quando muda o quê

| Cenário | Vars envolvidas |
|---|---|
| Trocar de DB local para externo | `DATABASE_URL` |
| Mudar local do workspace | `WORKSPACE_PATH` + bind no `docker-compose.yml` |
| Subir paralelo a outro projeto | `COMPOSE_PROJECT_NAME` |
| Habilitar auth (V1+) | `AUTH_ENABLED`, `AUTH_USERNAME`, `AUTH_PASSWORD_HASH` |
| Aumentar concorrência | `MAX_CONCURRENT_EXECUTIONS` |
| Debug | `LOG_LEVEL=DEBUG` |

---

## 4 · Validação ao subir

O `apps/api/src/orquestr_ai/settings.py` usa `pydantic-settings`:

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    database_url: str
    workspace_path: str = "/workspace/Repasse"
    export_path: str = "/workspace/Repasse/Gestao"
    max_concurrent_executions: int = 3
    execution_timeout_seconds: int = 900
    log_level: str = "INFO"
    claude_config_dir: str = "/home/orquestr/.claude"
    cors_allow_origins: list[str] = ["http://localhost:3000"]
    auth_enabled: bool = False

settings = Settings()
```

Falha de validação no startup → container `api` falha healthcheck.

---

## 5 · Segurança

| Regra | Por quê |
|---|---|
| `.env` no `.gitignore` | Senha de DB não vai para repo |
| `.env.example` sem secrets | Documentação sem vazamento |
| `127.0.0.1` em todas as portas | Não expõe na LAN |
| `POSTGRES_PASSWORD` qualquer string | Local apenas; não usado fora do compose |
| Sem `ANTHROPIC_API_KEY` no MVP | Claude Code CLI usa sua própria auth (volume `claude_credentials`) |

---

## 6 · Troubleshooting

| Sintoma | Causa provável | Solução |
|---|---|---|
| `api` falha "FATAL: password authentication failed" | `POSTGRES_PASSWORD` mudou após primeiro up | `docker compose down -v` (apaga volume!) ou ajustar via `psql` |
| Frontend não acessa API | `NEXT_PUBLIC_API_URL` errado | Verificar `.env` + restart `web` |
| Execução não dispara | `CLAUDE_CONFIG_DIR` sem credenciais | Logar Claude Code dentro do container (`docker compose exec api claude code`) |
| Bind path "workspace not found" | Repo OrquestrAI não está paralelo a Repasse/ | Ajustar bind path no compose ou mover repos |
| Healthcheck `api` falha | Migration travou ou Claude Code sem permissão | `docker compose logs api` |
