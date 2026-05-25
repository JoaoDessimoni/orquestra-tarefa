# Execução de Agentes — Contrato técnico

> Peça mais sensível do sistema. Define como o backend invoca o Claude Code CLI local, captura output, gerencia processo. Última atualização: 20/05/2026.

## Fontes

- [VISAO_GERAL.md](VISAO_GERAL.md)
- [STREAMING_SSE.md](STREAMING_SSE.md)
- [REGRAS_DE_NEGOCIO.md](../03-dominio/REGRAS_DE_NEGOCIO.md) §3 (RN-11 a RN-19)

---

## 1 · Decisão arquitetural recapitulada

O backend **NÃO** chama a Anthropic API diretamente.
O backend **invoca o binário do Claude Code CLI** como subprocess.

**Por quê:**
- Reusa a licença/conta Claude do usuário (sem custo API duplicado).
- Reusa todo o ecossistema do Claude Code: agentes `.claude/agents/`, skills `.claude/skills/`, slash commands `.claude/commands/`, hooks, MCP servers.
- O Claude Code já faz tool use, gerenciamento de turnos, parsing de output — não reimplementamos.

**Trade-off aceito:**
- Acoplamento ao formato de output do Claude Code CLI (que pode mudar entre versões).
- Necessidade de o binário Claude Code estar acessível ao processo `api`.

---

## 2 · Estratégia: container `api` invoca Claude Code do host

Container Docker normalmente não tem acesso ao binário do host. Três opções avaliadas:

| Estratégia | Descrição | Veredito |
|---|---|---|
| **A. Instalar Claude Code dentro do container `api`** | `apt install` ou similar no Dockerfile | ❌ Reinstala/atualiza separado; pode divergir do que João usa |
| **B. Bind-mount do binário Claude Code + node** | Monta `/usr/local/bin/claude` e `nodejs` do host | ⚠️ Frágil entre Win/Mac/Linux |
| **C. Backend roda fora do Docker em dev; Docker só pra DB + web** | `api` rodando local (Python venv); Claude Code direto | ✅ Mais simples; padrão dev local |
| **D. Sidecar container com Node + Claude Code instalado** | Imagem custom com Node 20 + `npm i -g @anthropic-ai/claude-code` | ✅ Reproduzível; isola versão |

**Decisão MVP: opção D (sidecar container).**

Dockerfile do `api`:
```dockerfile
FROM python:3.12-slim

# Node para Claude Code CLI
RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Claude Code (versão pinada)
RUN npm install -g @anthropic-ai/claude-code@<VERSAO>

# Resto do setup Python
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN pip install uv && uv sync --frozen
COPY src/ ./src/
COPY migrations/ ./migrations/

CMD ["uvicorn", "orquestr_ai.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

<!-- TODO: confirmar nome do pacote npm e versão a pinar — confirmar com João -->

**Autenticação Claude Code dentro do container:**
- O usuário faz `claude code` interativo uma vez para autenticar (ou copia `~/.claude/credentials` do host via bind-mount).
- Variável `CLAUDE_CONFIG_DIR=/home/orquestr/.claude` no container.
- Volume `claude_credentials` montado em `/home/orquestr/.claude`.

Spec completa no [DOCKER_COMPOSE.md](../06-infra/DOCKER_COMPOSE.md).

---

## 3 · Contrato de invocação

### 3.1 Comando

```
claude code \
  --print \
  --output-format stream-json \
  --model <MODELO> \
  --allowed-tools <LISTA_TOOLS_CSV> \
  --append-system-prompt <PROMPT_DO_AGENTE> \
  --cwd <CWD_VALIDADO> \
  <INPUT_DO_USUARIO>
```

| Flag | Valor | Origem |
|---|---|---|
| `--print` | (sem) | Modo non-interactive |
| `--output-format` | `stream-json` | Eventos NDJSON, um por linha |
| `--model` | `opus`/`sonnet`/`haiku` | `agent_snapshot.model` |
| `--allowed-tools` | `Read,Edit,Grep,...` | `agent_snapshot.tools` |
| `--append-system-prompt` | prompt do agente | `agent_snapshot.system_prompt` + skills compiladas |
| `--cwd` | path validado | `executions.cwd` |
| input | texto do usuário | `executions.input` (passado como argumento posicional) |

<!-- TODO: validar flags exatas do Claude Code CLI (--allowed-tools, --append-system-prompt) com versão atual -->

### 3.2 Compilação do prompt final

O prompt enviado é construído por:

```python
def build_system_prompt(agent_snapshot: AgentSnapshot) -> str:
    parts = [agent_snapshot.system_prompt]
    for skill in agent_snapshot.skills:
        parts.append(f"\n\n---\n\n# Skill: {skill.name}\n\n{skill.body_md}")
    for sub in agent_snapshot.subagents:
        parts.append(f"\n\n---\n\n# Subagente disponível: {sub.slug}\n\n{sub.description}")
    return "\n".join(parts)
```

Tamanho final logado para auditoria. Truncamento se >100k chars (raro com limite individual de 50k).

---

## 4 · Ciclo de vida da execução

```
┌──────────────────────────────────────────────────────────────┐
│                  ClaudeCodeRunner (asyncio)                  │
│                                                              │
│  start(execution_id):                                        │
│    1. Load executions.agent_snapshot                         │
│    2. Validate cwd (path inside workspace_path)              │
│    3. Check concurrency limit                                │
│    4. Spawn process:                                         │
│         proc = await asyncio.create_subprocess_exec(         │
│             "claude", "code", *args,                         │
│             cwd=cwd,                                         │
│             stdout=asyncio.subprocess.PIPE,                  │
│             stderr=asyncio.subprocess.PIPE,                  │
│             stdin=None,                                      │
│             start_new_session=True,                          │
│         )                                                    │
│    5. Register process in runtime_registry                   │
│    6. Spawn tasks:                                           │
│         - read_stdout_task                                   │
│         - read_stderr_task                                   │
│         - watchdog_task (timeout)                            │
│    7. UPDATE executions SET status='running'                 │
│                                                              │
│  read_stdout_task:                                           │
│    async for line in proc.stdout:                            │
│        event = parse_stream_json(line)                       │
│        seq += 1                                              │
│        INSERT execution_events (execution_id, seq, ...)      │
│        await broker.publish(execution_id, event)             │
│                                                              │
│  on_process_exit():                                          │
│    code = await proc.wait()                                  │
│    flush remaining events                                    │
│    status = 'done' if code==0 else 'error'                   │
│    compute metrics (duration, tokens, cost)                  │
│    INSERT final 'done' event                                 │
│    UPDATE executions (status, ended_at, ...)                 │
│    await broker.publish_done(execution_id)                   │
│    remove from runtime_registry                              │
│                                                              │
│  abort(execution_id):                                        │
│    proc = runtime_registry.get(execution_id)                 │
│    proc.terminate()  # SIGTERM                               │
│    try: await asyncio.wait_for(proc.wait(), 5.0)             │
│    except TimeoutError: proc.kill()  # SIGKILL               │
│    status = 'aborted', aborted_by = '<source>'               │
└──────────────────────────────────────────────────────────────┘
```

### 4.1 Parser do `stream-json`

Claude Code com `--output-format stream-json` emite NDJSON. Cada linha é objeto JSON com shape `{type, ...}`. Tipos conhecidos:

| Type Claude Code | Mapeamento OrquestrAI |
|---|---|
| `system` (init) | `event_type=status`, `payload={state:'started', model:..., tools:...}` |
| `assistant` (texto progressivo) | `event_type=token`, `payload={delta: '...'}` |
| `tool_use` | `event_type=tool_call`, `payload={name, input}` |
| `tool_result` | `event_type=tool_result`, `payload={tool_use_id, content, is_error}` |
| `error` | `event_type=error`, `payload={message, traceback}` |
| `result` (final) | `event_type=done`, `payload={total_cost_usd, num_turns, total_tokens}` |

<!-- TODO: confirmar shape exato do stream-json no Claude Code atual; pode ter mudado -->

### 4.2 Watchdog / timeout

- Timeout default: **15 minutos** por execução (configurável via `settings.execution_timeout_seconds`).
- Watchdog task aguarda `asyncio.sleep(timeout)`; se não terminou, chama `abort()` com `aborted_by='timeout'`.

### 4.3 Concorrência

- `runtime_registry` é dict `{execution_id: process}` em memória.
- Semáforo `asyncio.Semaphore(max_concurrent)` controla limite (default 3).
- Se semáforo cheio: retorna `429 Too Many Requests` (não enfileira no MVP).

---

## 5 · Tratamento de erros

| Cenário | Detecção | Resposta |
|---|---|---|
| Claude Code não encontrado | `FileNotFoundError` no `create_subprocess_exec` | `500` + log; aviso no Settings |
| Crash do subprocess (exit ≠ 0) | `proc.returncode != 0` | Status `error`, mensagem do stderr |
| Crash do backend mid-execução | Reboot detecta `running` antigo | Status `unknown` (RN-19) |
| Stream-json malformado | Parser exception | Log + evento `error`; tenta continuar lendo |
| stderr volumoso | Buffer em memória capped (1MB) | Trunca + flag `stderr_truncated` no payload |
| Output `done` ausente | `proc.wait()` retorna mas sem `result` | Emite `done` sintético + status `done` |
| Abort durante busy I/O | SIGTERM falha em 5s | SIGKILL forçado |

---

## 6 · Validações de segurança

1. **Path traversal**: `cwd` resolvido com `os.path.realpath`; deve começar com `workspace_path`. Bloqueio se contém `..` ou symlinks suspeitos.
2. **Quote escaping**: argumentos passados via `create_subprocess_exec` como **lista**, nunca via shell. Sem interpolação string.
3. **Input limit**: `input` truncado em 10k chars (RN do schema).
4. **Tool allowlist**: backend só permite tools que estão no enum conhecido — se snapshot tiver tool desconhecida, falha cedo.

---

## 7 · Observabilidade

Logs estruturados por execução:

```json
{"event":"execution.started","execution_id":"...","agent_slug":"...","model":"sonnet","cwd":"..."}
{"event":"execution.event_emitted","execution_id":"...","seq":42,"type":"tool_call"}
{"event":"execution.done","execution_id":"...","duration_ms":12340,"status":"done","tool_calls":7}
{"event":"execution.error","execution_id":"...","error":"...","traceback":"..."}
```

Logs em stdout do container → visível via `docker-compose logs api`.

---

## 8 · Testes

### 8.1 Unit
- Parser de `stream-json` com fixtures de output real do Claude Code.
- Validação de cwd (path traversal).
- Detecção de ciclo em subagentes.

### 8.2 Integração
- Mock de subprocess que emite eventos canônicos.
- Fluxo completo: start → eventos → done.
- Abort (envia SIGTERM → SIGKILL).
- Crash do subprocess.

### 8.3 E2E (manual no MVP)
- Executar agente real contra workspace `Repasse/`.
- Validar AC-04, AC-05 (do [ESCOPO_MVP.md](../01-requisitos/ESCOPO_MVP.md)).
