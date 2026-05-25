# Setup Local — OrquestrAI

> Passo-a-passo do zero até `http://localhost:3000` funcionando. Última atualização: 20/05/2026.

## Fontes

- [DOCKER_COMPOSE.md](DOCKER_COMPOSE.md)
- [VARIAVEIS_AMBIENTE.md](VARIAVEIS_AMBIENTE.md)
- [ESTRUTURA_REPO.md](ESTRUTURA_REPO.md)

---

## 1 · Pré-requisitos

| Item | Versão mínima | Como instalar |
|---|---|---|
| **Docker Desktop** | 24+ (com Compose v2) | https://docker.com |
| **Git** | qualquer recente | https://git-scm.com |
| **Make** (opcional) | qualquer | nativo Linux/macOS; Windows: WSL2 |
| **8 GB RAM livres** | — | recomendado para rodar 3 containers + Claude Code |
| **5 GB disco livre** | — | imagens + volume DB |

### Sistema operacional suportado

- ✅ macOS 13+ (Intel ou Apple Silicon)
- ✅ Ubuntu 22+ (e derivados)
- ✅ Windows 11 + WSL2 (Ubuntu)
- ⚠️ Windows nativo (sem WSL2): não testado

---

## 2 · Clonar o repositório

```bash
cd ~/Documents/Finza        # ou onde Repasse/ já mora
git clone <url-do-orquestr-ai> orquestr-ai
cd orquestr-ai
```

A árvore resultante deve ser:

```
~/Documents/Finza/
├── Repasse/                 ← workspace gerencial pré-existente
└── orquestr-ai/             ← repositório recém-clonado
```

> O `docker-compose.yml` faz bind `../Repasse:/workspace/Repasse:ro`. Por isso a paridade do path importa.

---

## 3 · Configurar variáveis

```bash
cp .env.example .env
```

Edite `.env` com seu editor:

```bash
nano .env
# ou
code .env
```

Mínimo necessário pra subir: ajuste `POSTGRES_PASSWORD` para qualquer string (não use o `changeme_local_only` literal por hábito).

---

## 4 · Subir os containers

```bash
docker compose up -d
```

Saída esperada:

```
[+] Running 4/4
 ✔ Network orquestr_net               Created
 ✔ Container orquestr-db              Started
 ✔ Container orquestr-api             Started
 ✔ Container orquestr-web             Started
```

Aguarde ~30-60s para healthchecks ficarem verdes:

```bash
docker compose ps
```

Saída desejada:

```
NAME            STATUS              PORTS
orquestr-db     Up (healthy)        127.0.0.1:5432->5432/tcp
orquestr-api    Up (healthy)        127.0.0.1:8000->8000/tcp
orquestr-web    Up (healthy)        127.0.0.1:3000->3000/tcp
```

---

## 5 · Autenticar Claude Code dentro do container

Primeiro uso pós setup:

```bash
docker compose exec api claude code
```

Saída esperada (interativo):
```
Welcome to Claude Code!
To get started, you'll need to authenticate.
Open the following URL in your browser: ...
```

Abra a URL no browser, autentique. As credenciais ficam em `/home/orquestr/.claude` no container (volume nomeado `claude_credentials`, persistente).

**Alternativa**: copiar credenciais do host (se Claude Code já está logado lá):

```bash
docker compose cp ~/.claude/credentials orquestr-api:/home/orquestr/.claude/
docker compose restart api
```

> No Windows + WSL2, ajuste o path `~/.claude` para `~/.wsl/.claude` se necessário.

---

## 6 · Verificar saúde

```bash
curl http://127.0.0.1:8000/health
```

Esperado:

```json
{
  "status": "ok",
  "uptime_seconds": 87,
  "db": "connected",
  "claude_code_cli": "v0.5.2"
}
```

Se `claude_code_cli` = `null`, faça o passo 5.

---

## 7 · Acessar a UI

Abra: **http://localhost:3000**

Esperado: Dashboard vazio (KPIs todos zerados) + Welcome card com CTA "+ Novo Agente".

---

## 8 · Smoke test manual (AC do MVP)

Para validar o setup completo, rode os critérios de aceitação de [ESCOPO_MVP §3](../01-requisitos/ESCOPO_MVP.md):

1. **Criar Skill** "Contexto Finza":
   - `/skills/new`
   - Body: cole conteúdo do `Docs/finza/CONTEXTO-FINZA.md` (ou trecho)
   - Salvar
2. **Criar Agente** "Researcher Finza":
   - `/agents/new`
   - Modelo: Sonnet
   - Ferramentas: Read, Grep, Glob
   - System prompt: descrição do agente
   - Skill vinculada: Contexto Finza
3. **Executar agente**:
   - Clica "▶ Executar"
   - Input: "Liste as plataformas Finza com responsável e status."
   - cwd: `/workspace/Repasse` (default)
   - Disparar
4. **Verificar streaming**:
   - Tokens devem chegar em <2s
   - Tool calls (Read/Grep) visíveis
   - Status final = `done`
5. **Criar Análise** vinculada:
   - `/analyses/new`
   - Aba "Insumos" → anexar execução
6. **Exportar** análise → verificar arquivo `.md` em `~/Documents/Finza/Repasse/Gestao/Analises/<dia>/`

---

## 9 · Migrations e seed

Migrations rodam automaticamente no startup do `api` (entrypoint chama `alembic upgrade head`).

Para rodar manual:

```bash
docker compose exec api alembic upgrade head
docker compose exec api alembic current
```

Seed de settings é parte das migrations (data migration). Para resetar:

```bash
docker compose exec api alembic downgrade base
docker compose exec api alembic upgrade head
```

> Cuidado: `downgrade base` apaga dados se a migration de seed for de schema (não data).

---

## 10 · Backup e restore

### Backup

```bash
./scripts/backup.sh
# ou:
docker compose exec db pg_dump -U orquestr orquestr > backups/$(date +%Y%m%d-%H%M%S).sql
```

### Restore

```bash
./scripts/restore.sh backups/20260520-143000.sql
# ou:
docker compose exec -T db psql -U orquestr orquestr < backups/20260520-143000.sql
```

---

## 11 · Logs

```bash
# Todos
docker compose logs -f

# Só api
docker compose logs -f api

# Últimas 100 linhas
docker compose logs --tail=100 api

# Filtrar por execução (logs estruturados JSON)
docker compose logs api | grep '"execution_id":"abc-123"'
```

---

## 12 · Reiniciar / parar

```bash
# Restart de um serviço
docker compose restart api

# Parar tudo (preserva volumes)
docker compose down

# Parar + apagar volumes (CUIDADO: apaga DB!)
docker compose down -v

# Rebuild após mudar Dockerfile
docker compose build api && docker compose up -d api
```

---

## 13 · Atualizar versões

### Atualizar Claude Code CLI

1. Edite `apps/api/Dockerfile`: `RUN npm install -g @anthropic-ai/claude-code@<NOVA_VERSAO>`
2. `docker compose build api && docker compose up -d api`
3. Verificar: `docker compose exec api claude code --version`

### Atualizar deps Python ou Node

```bash
# Python
docker compose exec api uv sync --upgrade
docker compose restart api

# Node
docker compose exec web npm install <pacote>@latest
docker compose restart web
```

---

## 14 · Troubleshooting

| Sintoma | Solução |
|---|---|
| `orquestr-db` não fica healthy | Verifique `POSTGRES_PASSWORD` no `.env`; `docker compose logs db` |
| `orquestr-api` Loop reiniciando | Provável erro de migration. `docker compose logs api` |
| Frontend tela em branco | Cache Next dev. `docker compose restart web` |
| `claude code` retorna "command not found" | Imagem `api` não foi rebuilt com Node. Refaça `docker compose build api` |
| Execução fica em `running` para sempre | Veja `docker compose logs api` para crash do subprocess; reinicie `api` (RN-19 recupera) |
| Permissão negada ao escrever em `Gestao/` | Ajustar permissão do diretório no host (`chmod -R +w ../Repasse/Gestao`) |
| Bind path "no such file" | Path do `Repasse/` errado. Ajuste bind no compose ou mova repos |

---

## 15 · Limpar tudo (reset completo)

```bash
docker compose down -v
docker system prune -a --volumes
# Cuidado: apaga todas as imagens não usadas e volumes do sistema
```

Depois reinicie do passo 4.

---

## 16 · Performance dicas

- **macOS/Windows**: I/O em bind mount tem latência. Para dev intenso, mantenha workspace dentro do filesystem do Docker Desktop ou WSL2.
- **RAM**: subir 3 containers + Claude Code ≈ 1.5-2 GB residentes.
- **Build cache**: docker build usa cache; mudar `requirements`/`package.json` invalida.

---

## 17 · Próximos passos

Após setup OK:
1. Importar agentes do `.claude/agents/` (V1 — RF-AG-09).
2. Importar análises antigas de `Gestao/` (V1 — RF-AN-07).
3. Configurar pricing table em Settings.
4. Criar primeiros 2-3 agentes manualmente para começar a usar.
