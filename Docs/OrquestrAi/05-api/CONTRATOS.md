# Contratos (Pydantic Schemas) — OrquestrAI

> Schemas de request/response em Python pydantic-v2. Última atualização: 20/05/2026.

## Fontes

- [ENDPOINTS.md](ENDPOINTS.md)
- [SCHEMA_POSTGRES.md](../03-dominio/SCHEMA_POSTGRES.md)

---

## Convenção

- `XCreate`: shape para POST (sem id, sem timestamps).
- `XUpdate`: shape para PATCH (todos campos optional).
- `XOut`: shape de response (com id, timestamps, fields derivados).
- `XListItem`: shape resumido para listagem.
- `Page[X]`: wrapper para listagens paginadas.

---

## 1 · Comum

```python
from datetime import datetime
from typing import Generic, TypeVar
from uuid import UUID
from pydantic import BaseModel, Field

T = TypeVar('T')

class Page(BaseModel, Generic[T]):
    items: list[T]
    total: int
    page: int
    limit: int

class ErrorBody(BaseModel):
    code: str
    message: str
    field: str | None = None
    details: dict | None = None
    request_id: str

class ErrorResponse(BaseModel):
    error: ErrorBody
```

---

## 2 · Agentes

```python
from enum import Enum

class AgentModel(str, Enum):
    opus = "opus"
    sonnet = "sonnet"
    haiku = "haiku"

class AgentTool(str, Enum):
    Read = "Read"
    Edit = "Edit"
    Write = "Write"
    Grep = "Grep"
    Glob = "Glob"
    Bash = "Bash"
    WebSearch = "WebSearch"
    WebFetch = "WebFetch"

class AgentBase(BaseModel):
    slug: str = Field(min_length=1, max_length=80, pattern=r"^[a-z0-9][a-z0-9-]*[a-z0-9]$")
    name: str = Field(min_length=1, max_length=100)
    description: str = Field(default="", max_length=500)
    system_prompt: str = Field(min_length=1, max_length=50000)
    model: AgentModel = AgentModel.sonnet
    tools: list[AgentTool] = Field(default_factory=list, min_length=1)
    is_subagent: bool = False

class AgentCreate(AgentBase):
    skill_ids: list[UUID] = Field(default_factory=list)
    subagent_ids: list[UUID] = Field(default_factory=list)

class AgentUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    system_prompt: str | None = None
    model: AgentModel | None = None
    tools: list[AgentTool] | None = None
    is_subagent: bool | None = None
    skill_ids: list[UUID] | None = None
    subagent_ids: list[UUID] | None = None

class SkillRef(BaseModel):
    id: UUID
    slug: str
    name: str

class AgentOut(AgentBase):
    id: UUID
    skills: list[SkillRef] = Field(default_factory=list)
    subagents: list["AgentListItem"] = Field(default_factory=list)
    executions_count: int = 0
    last_executed_at: datetime | None = None
    created_at: datetime
    updated_at: datetime

class AgentListItem(BaseModel):
    id: UUID
    slug: str
    name: str
    description: str
    model: AgentModel
    tools_count: int
    skills_count: int
    executions_count: int
    is_subagent: bool
    updated_at: datetime
```

---

## 3 · Skills

```python
class SkillBase(BaseModel):
    slug: str = Field(min_length=1, max_length=80, pattern=r"^[a-z0-9][a-z0-9-]*[a-z0-9]$")
    name: str = Field(min_length=1, max_length=100)
    description: str = Field(default="", max_length=500)
    body_md: str = Field(default="", max_length=20000)
    tags: list[str] = Field(default_factory=list, max_length=10)

class SkillCreate(SkillBase):
    pass

class SkillUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    body_md: str | None = None
    tags: list[str] | None = None

class SkillOut(SkillBase):
    id: UUID
    used_by_count: int = 0
    created_at: datetime
    updated_at: datetime

class SkillListItem(BaseModel):
    id: UUID
    slug: str
    name: str
    description: str
    tags: list[str]
    used_by_count: int
    body_size_bytes: int
    updated_at: datetime
```

---

## 4 · Execuções

```python
class ExecutionStatus(str, Enum):
    running = "running"
    done = "done"
    error = "error"
    aborted = "aborted"
    unknown = "unknown"

class ExecutionCreate(BaseModel):
    agent_slug: str
    input: str = Field(min_length=1, max_length=10000)
    cwd: str | None = None  # default = settings.workspace_path
    model_override: AgentModel | None = None
    timeout_seconds: int | None = Field(default=None, ge=60, le=3600)

class AgentSnapshot(BaseModel):
    slug: str
    name: str
    system_prompt: str
    model: AgentModel
    tools: list[AgentTool]
    skills: list[SkillRef] = Field(default_factory=list)
    subagents: list[SkillRef] = Field(default_factory=list)

class ExecutionOut(BaseModel):
    id: UUID
    agent_id: UUID
    agent_slug: str
    agent_snapshot: AgentSnapshot
    input: str
    cwd: str
    status: ExecutionStatus
    started_at: datetime
    ended_at: datetime | None
    duration_ms: int | None
    output_md: str | None
    tokens_input: int | None
    tokens_output: int | None
    tool_calls_count: int
    cost_estimated_usd: float | None
    error_message: str | None
    aborted_by: str | None

class ExecutionListItem(BaseModel):
    id: UUID
    agent_slug: str
    status: ExecutionStatus
    started_at: datetime
    ended_at: datetime | None
    duration_ms: int | None
    tool_calls_count: int
    cost_estimated_usd: float | None
    input_preview: str  # truncado a 80 chars

class ExecutionEventOut(BaseModel):
    id: UUID
    execution_id: UUID
    seq: int
    event_type: str  # status|token|tool_call|tool_result|error|done|ping
    payload: dict
    created_at: datetime

class ExecutionAbortRequest(BaseModel):
    reason: str | None = None
```

---

## 5 · Análises

```python
class AnalysisKind(str, Enum):
    investigacao = "investigacao"
    comparativo = "comparativo"
    rfc = "rfc"
    postmortem = "postmortem"
    proposta = "proposta"
    cruzamento = "cruzamento"

class AnalysisStatus(str, Enum):
    rascunho = "rascunho"
    revisao = "revisao"
    publicada = "publicada"

class AnalysisBase(BaseModel):
    slug: str = Field(pattern=r"^[a-z0-9][a-z0-9-]*[a-z0-9]$")
    title: str = Field(min_length=1, max_length=200)
    kind: AnalysisKind = AnalysisKind.investigacao
    question: str = Field(default="", max_length=1000)
    body_md: str = Field(default="", max_length=100000)
    tags: list[str] = Field(default_factory=list, max_length=10)

class AnalysisCreate(AnalysisBase):
    pass

class AnalysisUpdate(BaseModel):
    title: str | None = None
    kind: AnalysisKind | None = None
    question: str | None = None
    body_md: str | None = None
    tags: list[str] | None = None

class AnalysisStatusUpdate(BaseModel):
    status: AnalysisStatus

class AnalysisOut(AnalysisBase):
    id: UUID
    status: AnalysisStatus
    executions: list[ExecutionListItem] = Field(default_factory=list)
    reports: list["ReportListItem"] = Field(default_factory=list)
    exported_at: datetime | None
    exported_path: str | None
    published_at: datetime | None
    created_at: datetime
    updated_at: datetime

class AnalysisListItem(BaseModel):
    id: UUID
    slug: str
    title: str
    kind: AnalysisKind
    status: AnalysisStatus
    tags: list[str]
    executions_count: int
    reports_count: int
    updated_at: datetime

class LinkExecutionsRequest(BaseModel):
    execution_ids: list[UUID]
    note: str = ""
```

---

## 6 · Relatórios

```python
class ReportStatus(str, Enum):
    rascunho = "rascunho"
    revisao = "revisao"
    enviado = "enviado"

class ReportClassificacao(str, Enum):
    interno = "interno"
    restrito = "restrito"
    publico = "publico"

class ReportBase(BaseModel):
    slug: str = Field(pattern=r"^[a-z0-9][a-z0-9-]*[a-z0-9]$")
    title: str = Field(min_length=1, max_length=200)
    destinatario: str = Field(min_length=1, max_length=200)
    body_md: str = Field(default="", max_length=100000)
    classificacao: ReportClassificacao = ReportClassificacao.interno
    tags: list[str] = Field(default_factory=list, max_length=10)

class ReportCreate(ReportBase):
    analysis_id: UUID

class ReportUpdate(BaseModel):
    title: str | None = None
    destinatario: str | None = None
    body_md: str | None = None
    classificacao: ReportClassificacao | None = None
    tags: list[str] | None = None

class ReportStatusUpdate(BaseModel):
    status: ReportStatus

class ReportOut(ReportBase):
    id: UUID
    analysis_id: UUID
    analysis_slug: str
    status: ReportStatus
    exported_at: datetime | None
    exported_path: str | None
    created_at: datetime
    updated_at: datetime

class ReportListItem(BaseModel):
    id: UUID
    slug: str
    title: str
    destinatario: str
    status: ReportStatus
    classificacao: ReportClassificacao
    analysis_slug: str
    updated_at: datetime
```

---

## 7 · Settings

```python
class PricingEntry(BaseModel):
    input: float = Field(ge=0)   # USD por 1M tokens
    output: float = Field(ge=0)

class SettingsOut(BaseModel):
    workspace_path: str
    export_path: str
    default_model: AgentModel
    max_concurrent: int = Field(ge=1, le=10)
    execution_timeout_seconds: int = Field(ge=60, le=3600)
    pricing_table: dict[AgentModel, PricingEntry]

class SettingsUpdate(BaseModel):
    workspace_path: str | None = None
    export_path: str | None = None
    default_model: AgentModel | None = None
    max_concurrent: int | None = None
    execution_timeout_seconds: int | None = None
    pricing_table: dict[AgentModel, PricingEntry] | None = None

class WorkspaceValidateResponse(BaseModel):
    valid: bool
    claude_code_version: str | None
    error: str | None
```

---

## 8 · Dashboard

```python
class DashboardKpis(BaseModel):
    agents_active: int
    executions_this_month: int
    cost_this_month_usd: float
    analyses_published: int
    reports_sent: int

class ExecutionsByDayItem(BaseModel):
    date: str  # YYYY-MM-DD
    count: int

class DashboardOut(BaseModel):
    kpis: DashboardKpis
    recent_executions: list[ExecutionListItem]
    executions_by_day: list[ExecutionsByDayItem]
```

---

## 9 · Export

```python
class ExportRequest(BaseModel):
    override_path: str | None = None  # V1+

class ExportResponse(BaseModel):
    exported_path: str
    exported_at: datetime
    bytes_written: int
    was_overwrite: bool
```

---

## 10 · Health / Version

```python
class HealthResponse(BaseModel):
    status: str  # "ok" | "degraded" | "down"
    uptime_seconds: int
    db: str  # "connected" | "down"
    claude_code_cli: str | None  # versão detectada

class VersionResponse(BaseModel):
    version: str
    build_sha: str
    build_date: str
```

---

## 11 · Generation flow

```
backend (pydantic) ──► FastAPI ──► /openapi.json
                                       │
                                       ▼
                            openapi-typescript
                                       │
                                       ▼
                       apps/web/lib/api/types.gen.ts
                                       │
                                       ▼
                            useTypedFetch<'AgentOut'>()
```

Script `npm run gen:api` no monorepo regenera tipos. Pre-commit hook validar diff.

---

## 12 · Exemplos JSON

### Criar agente

```http
POST /api/agents HTTP/1.1
Content-Type: application/json

{
  "slug": "researcher-finza",
  "name": "Researcher Finza",
  "description": "Pesquisa fatos no contexto Finza",
  "system_prompt": "# Researcher Finza\n\nVocê é...",
  "model": "sonnet",
  "tools": ["Read", "Grep", "Glob"],
  "is_subagent": false,
  "skill_ids": [],
  "subagent_ids": []
}
```

### Resposta de execução (201 → 200 polled)

```http
HTTP/1.1 201 Created
Content-Type: application/json
Location: /api/executions/9c4e8a7d-...

{
  "id": "9c4e8a7d-...",
  "agent_id": "uuid-...",
  "agent_slug": "researcher-finza",
  "agent_snapshot": { ... },
  "input": "Liste plataformas Finza",
  "cwd": "/workspace/Repasse",
  "status": "running",
  "started_at": "2026-05-20T14:32:00Z",
  "ended_at": null,
  "duration_ms": null,
  "output_md": null,
  "tokens_input": null,
  "tokens_output": null,
  "tool_calls_count": 0,
  "cost_estimated_usd": null,
  "error_message": null,
  "aborted_by": null
}
```

### Erro

```http
HTTP/1.1 409 Conflict
Content-Type: application/json

{
  "error": {
    "code": "slug_already_exists",
    "message": "Já existe um item com este slug.",
    "field": "slug",
    "details": null,
    "request_id": "req-abc-123"
  }
}
```
