# Streaming SSE — Protocolo de eventos

> Spec do protocolo de Server-Sent Events para transmitir output de execução ao browser em tempo real. Última atualização: 20/05/2026.

## Fontes

- [EXECUCAO_DE_AGENTES.md](EXECUCAO_DE_AGENTES.md)
- [SCHEMA_POSTGRES.md](../03-dominio/SCHEMA_POSTGRES.md) §3.5 (`execution_events`)

---

## 1 · Por quê SSE (e não WebSocket)

- **Unidirecional**: backend → browser. WebSocket bidirecional é overkill.
- **Simples**: HTTP comum, reconexão automática nativa do browser.
- **Compatível com proxies/firewalls**: usa HTTP padrão.
- **Streaming nativo no Next.js + EventSource API no browser**.

Trade-off aceito: cliente não envia eventos pelo mesmo canal (precisa REST separado pra abort).

---

## 2 · Endpoint

```
GET /api/events/executions/{execution_id}

Headers:
  Accept: text/event-stream
  Cache-Control: no-cache

Resposta:
  Content-Type: text/event-stream; charset=utf-8
  Cache-Control: no-cache
  Connection: keep-alive
  X-Accel-Buffering: no
```

### Comportamento

- Se `execution_id` não existe → 404 `{error: "not_found"}`.
- Se execução já terminou → backend faz **replay** dos eventos persistidos em `execution_events` e fecha conexão.
- Se execução está em curso → backend envia eventos persistidos até o momento, depois conecta ao broker pub/sub interno para eventos em tempo real.
- Cliente que cai e reconecta com header `Last-Event-ID: <seq>` recebe eventos a partir de `seq+1`.

---

## 3 · Formato de evento

SSE format:
```
id: <seq>
event: <event_type>
data: <json_payload>

```

Linha em branco final delimita o evento.

### Exemplo de stream

```
id: 0
event: status
data: {"state":"started","model":"sonnet","tools":["Read","Grep"],"cwd":"/workspace/Repasse"}

id: 1
event: token
data: {"delta":"Vou começar lendo "}

id: 2
event: token
data: {"delta":"o arquivo BRIEFING.md."}

id: 3
event: tool_call
data: {"tool":"Read","input":{"file_path":"/workspace/Repasse/Docs/BRIEFING.md"},"call_id":"tu_01"}

id: 4
event: tool_result
data: {"call_id":"tu_01","content":"<conteúdo truncado>","is_error":false,"duration_ms":12}

id: 5
event: token
data: {"delta":"\n\nO briefing trata de..."}

id: 6
event: ping
data: {"ts":"2026-05-20T14:32:00Z"}

id: 7
event: done
data: {"duration_ms":12340,"tool_calls_count":3,"tokens_input":1850,"tokens_output":420,"cost_estimated_usd":0.012,"status":"done","output_md":"..."}
```

---

## 4 · Tipos de evento

### 4.1 `status`

Emitido no início e em mudanças de estado.

```json
{
  "state": "started" | "thinking" | "tool_using" | "completing",
  "model": "sonnet",
  "tools": ["Read","Grep","Glob"],
  "cwd": "/workspace/Repasse",
  "ts": "2026-05-20T14:31:58.123Z"
}
```

### 4.2 `token`

Texto incremental do assistant. Pode ser apenas alguns caracteres.

```json
{
  "delta": "texto incremental"
}
```

> O frontend acumula `delta`s para montar `output_md` em UI.

### 4.3 `tool_call`

Agente vai invocar uma ferramenta.

```json
{
  "tool": "Read",
  "input": { "file_path": "/path/to/file" },
  "call_id": "tu_<id>"
}
```

### 4.4 `tool_result`

Resultado da ferramenta.

```json
{
  "call_id": "tu_<id>",
  "content": "resultado (texto ou estrutura)",
  "is_error": false,
  "duration_ms": 42
}
```

> Se `content` muito grande (>10kb), backend trunca para 10kb + emite flag `truncated:true`. Conteúdo completo permanece em `execution_events.payload`.

### 4.5 `error`

Erro durante execução.

```json
{
  "message": "FileNotFoundError: ...",
  "traceback": "...",
  "fatal": true | false
}
```

> `fatal:true` → execução vai terminar com status `error`. `fatal:false` → erro recuperável (ex: tool específica falhou mas agente continua).

### 4.6 `ping`

Keep-alive a cada 15s sem outro evento. Evita timeout de proxy/load-balancer.

```json
{ "ts": "2026-05-20T14:32:00Z" }
```

### 4.7 `done`

Último evento. Após este, conexão SSE fecha.

```json
{
  "status": "done" | "error" | "aborted",
  "duration_ms": 12340,
  "tool_calls_count": 3,
  "tokens_input": 1850,
  "tokens_output": 420,
  "cost_estimated_usd": 0.012,
  "output_md": "markdown final"
}
```

---

## 5 · Reconexão e replay

### 5.1 Cliente envia `Last-Event-ID`

Quando o EventSource do browser reconecta após queda, envia automaticamente:

```
GET /api/events/executions/<id>
Last-Event-ID: 42
```

Backend responde com eventos `seq >= 43` apenas.

### 5.2 Replay completo

Se execução já terminou, qualquer requisição faz replay:

```
GET /api/events/executions/<id>
```

Backend serve do DB (`execution_events ORDER BY seq`), depois envia `done` (que já está no DB) e fecha.

Útil para tela de detalhe de execução histórica — UI conecta o EventSource e vê a animação de tokens chegando como se fosse ao vivo.

> Modo "replay rápido" (sem delay artificial) ou "replay realista" (delay entre tokens proporcional ao original) — **MVP: replay rápido**, V1+ replay realista.

---

## 6 · Broker interno (in-process)

Para distribuir eventos do runner para múltiplos clientes SSE conectados na mesma execução:

```python
class ExecutionBroker:
    """In-memory pub/sub. Single-process, single-user → suficiente no MVP."""
    def __init__(self):
        self._queues: dict[UUID, list[asyncio.Queue]] = {}

    async def subscribe(self, execution_id: UUID) -> asyncio.Queue:
        q = asyncio.Queue(maxsize=1000)
        self._queues.setdefault(execution_id, []).append(q)
        return q

    def unsubscribe(self, execution_id: UUID, queue: asyncio.Queue):
        if execution_id in self._queues:
            self._queues[execution_id].remove(queue)

    async def publish(self, execution_id: UUID, event: dict):
        for q in self._queues.get(execution_id, []):
            try:
                q.put_nowait(event)
            except asyncio.QueueFull:
                logger.warning("queue_full", execution_id=execution_id)
```

> V1+: trocar por Redis pub/sub se multi-worker.

---

## 7 · Implementação no FastAPI (esqueleto)

```python
from sse_starlette.sse import EventSourceResponse

@router.get("/api/events/executions/{execution_id}")
async def stream_execution(
    execution_id: UUID,
    request: Request,
    db: AsyncSession = Depends(get_db),
    broker: ExecutionBroker = Depends(get_broker),
):
    execution = await db.get(Execution, execution_id)
    if not execution:
        raise HTTPException(404, "not_found")

    last_event_id = int(request.headers.get("Last-Event-ID", -1))

    async def event_stream():
        # 1. Replay eventos persistidos a partir de last_event_id+1
        async for ev in iter_persisted_events(db, execution_id, since=last_event_id):
            yield {
                "id": str(ev.seq),
                "event": ev.event_type.value,
                "data": json.dumps(ev.payload),
            }
            last_seen = ev.seq

        # 2. Se execução terminou, fim
        await db.refresh(execution)
        if execution.status in TERMINAL_STATUSES:
            return

        # 3. Conecta ao broker para eventos vivos
        queue = await broker.subscribe(execution_id)
        try:
            while True:
                if await request.is_disconnected():
                    break
                try:
                    event = await asyncio.wait_for(queue.get(), timeout=15.0)
                except asyncio.TimeoutError:
                    yield {"event": "ping", "data": json.dumps({"ts": now()})}
                    continue
                yield {
                    "id": str(event["seq"]),
                    "event": event["event_type"],
                    "data": json.dumps(event["payload"]),
                }
                if event["event_type"] == "done":
                    break
        finally:
            broker.unsubscribe(execution_id, queue)

    return EventSourceResponse(event_stream())
```

---

## 8 · Cliente Next.js (esqueleto)

```typescript
function useExecutionStream(executionId: string) {
  const [events, setEvents] = useState<ExecEvent[]>([]);
  const [status, setStatus] = useState<ExecStatus>('connecting');

  useEffect(() => {
    const es = new EventSource(`/api/events/executions/${executionId}`);

    es.addEventListener('status', (e) => {
      const data = JSON.parse(e.data);
      setEvents((prev) => [...prev, { type: 'status', data, seq: Number(e.lastEventId) }]);
    });

    es.addEventListener('token', (e) => {
      const data = JSON.parse(e.data);
      setEvents((prev) => [...prev, { type: 'token', data, seq: Number(e.lastEventId) }]);
    });

    es.addEventListener('tool_call', (e) => {
      const data = JSON.parse(e.data);
      setEvents((prev) => [...prev, { type: 'tool_call', data, seq: Number(e.lastEventId) }]);
    });

    es.addEventListener('done', (e) => {
      const data = JSON.parse(e.data);
      setStatus(data.status);
      setEvents((prev) => [...prev, { type: 'done', data, seq: Number(e.lastEventId) }]);
      es.close();
    });

    es.onerror = () => {
      setStatus('error');
      // EventSource reconecta automático, mas pra erros 4xx fecha
    };

    return () => es.close();
  }, [executionId]);

  return { events, status };
}
```

---

## 9 · Limites e considerações

| Item | Limite/Decisão |
|---|---|
| Tamanho de `data:` por evento | <64 KB. Conteúdo maior → backend trunca + flag |
| Frequência de ping | A cada 15s sem outro evento |
| Tempo máximo de conexão | Sem limite explícito (execução tem timeout de 15min) |
| Eventos por segundo | Sem rate limit no MVP (single-user) |
| Compressão | Sem (SSE não suporta gzip bem) |
| Versionamento do protocolo | Header `X-OrquestrAI-Stream-Version: 1` em ambas direções (futuro) |
