# Schema Postgres — OrquestrAI

> Schema relacional completo. DDL executável + diagrama ER + índices + decisões. Última atualização: 20/05/2026.

## Fontes

- [GLOSSARIO.md](GLOSSARIO.md)
- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md)
- Schema implícito dos `.md` em `Gestao/` (Pendências, Análises, Relatórios)

---

## 1 · Diagrama ER (ASCII)

```
┌─────────────────┐         ┌─────────────────┐         ┌──────────────────┐
│     agents      │         │     skills      │         │    settings      │
├─────────────────┤         ├─────────────────┤         ├──────────────────┤
│ id (uuid) PK    │         │ id (uuid) PK    │         │ key (text) PK    │
│ slug (uniq)     │         │ slug (uniq)     │         │ value (jsonb)    │
│ name            │         │ name            │         │ updated_at       │
│ description     │         │ description     │         └──────────────────┘
│ system_prompt   │         │ body_md         │
│ model           │         │ tags (jsonb[])  │
│ tools (jsonb[]) │         │ created_at      │
│ is_subagent     │         │ updated_at      │
│ created_at      │         │ deleted_at      │
│ updated_at      │         └─────────────────┘
│ deleted_at      │                  │
└────────┬────────┘                  │
         │                           │
         │M:N                        │M:N
         │                           │
   ┌─────┴───────────┐    ┌──────────┴────────┐
   │ agent_subagents │    │   agent_skills    │
   ├─────────────────┤    ├───────────────────┤
   │ agent_id   FK   │    │ agent_id     FK   │
   │ sub_id     FK   │    │ skill_id     FK   │
   │ position (int)  │    │ position (int)    │
   └─────────────────┘    └───────────────────┘
         │
         │
         │ 1:N
         ▼
┌──────────────────────────┐
│      executions          │              ┌──────────────────────┐
├──────────────────────────┤              │   execution_events   │
│ id (uuid) PK             │              ├──────────────────────┤
│ agent_id      FK         │◀──── 1:N ────│ id (uuid) PK         │
│ agent_snapshot (jsonb)   │              │ execution_id    FK   │
│ input (text)             │              │ seq (int)            │
│ cwd (text)               │              │ event_type           │
│ status                   │              │ payload (jsonb)      │
│ started_at               │              │ created_at           │
│ ended_at                 │              └──────────────────────┘
│ duration_ms              │
│ output_md (text)         │
│ tokens_input (int)       │
│ tokens_output (int)      │
│ tool_calls_count (int)   │
│ cost_estimated_usd       │
│ error_message            │
│ aborted_by               │
└──────────────────────────┘
         │
         │ M:N (via analysis_executions)
         ▼
┌──────────────────────────┐         ┌──────────────────────────┐
│       analyses           │         │       reports            │
├──────────────────────────┤         ├──────────────────────────┤
│ id (uuid) PK             │◀── 1:N ─│ id (uuid) PK             │
│ slug (uniq)              │         │ slug (uniq)              │
│ title                    │         │ title                    │
│ kind (enum)              │         │ analysis_id    FK        │
│ question (text)          │         │ destinatario             │
│ body_md (text)           │         │ body_md (text)           │
│ status (enum)            │         │ status (enum)            │
│ tags (jsonb[])           │         │ classificacao (enum)     │
│ created_at               │         │ tags (jsonb[])           │
│ updated_at               │         │ exported_at              │
│ published_at             │         │ exported_path            │
│ deleted_at               │         │ created_at               │
│ exported_at              │         │ updated_at               │
│ exported_path            │         │ deleted_at               │
└────────┬─────────────────┘         └──────────────────────────┘
         │
         │M:N
         ▼
┌──────────────────────────┐
│   analysis_executions    │
├──────────────────────────┤
│ analysis_id   FK         │
│ execution_id  FK         │
│ note (text)              │
│ created_at               │
└──────────────────────────┘
```

---

## 2 · Tipos / Enums

```sql
CREATE TYPE agent_model AS ENUM (
    'opus',
    'sonnet',
    'haiku'
);

CREATE TYPE execution_status AS ENUM (
    'running',
    'done',
    'error',
    'aborted',
    'unknown'
);

CREATE TYPE execution_event_type AS ENUM (
    'status',
    'token',
    'tool_call',
    'tool_result',
    'error',
    'done',
    'ping'
);

CREATE TYPE analysis_kind AS ENUM (
    'investigacao',
    'comparativo',
    'rfc',
    'postmortem',
    'proposta',
    'cruzamento'
);

CREATE TYPE analysis_status AS ENUM (
    'rascunho',
    'revisao',
    'publicada'
);

CREATE TYPE report_status AS ENUM (
    'rascunho',
    'revisao',
    'enviado'
);

CREATE TYPE report_classificacao AS ENUM (
    'interno',
    'restrito',
    'publico'
);
```

---

## 3 · DDL completo

### 3.1 `agents`

```sql
CREATE TABLE agents (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    slug            TEXT        NOT NULL UNIQUE,
    name            TEXT        NOT NULL,
    description     TEXT        NOT NULL DEFAULT '',
    system_prompt   TEXT        NOT NULL,
    model           agent_model NOT NULL DEFAULT 'sonnet',
    tools           JSONB       NOT NULL DEFAULT '[]'::jsonb,
    is_subagent     BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,

    CONSTRAINT agents_slug_format CHECK (slug ~ '^[a-z0-9][a-z0-9-]*[a-z0-9]$'),
    CONSTRAINT agents_prompt_size CHECK (length(system_prompt) <= 50000),
    CONSTRAINT agents_tools_is_array CHECK (jsonb_typeof(tools) = 'array')
);

CREATE INDEX idx_agents_active ON agents (created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_agents_is_subagent ON agents (is_subagent) WHERE deleted_at IS NULL;
```

### 3.2 `skills`

```sql
CREATE TABLE skills (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    slug            TEXT        NOT NULL UNIQUE,
    name            TEXT        NOT NULL,
    description     TEXT        NOT NULL DEFAULT '',
    body_md         TEXT        NOT NULL DEFAULT '',
    tags            JSONB       NOT NULL DEFAULT '[]'::jsonb,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,

    CONSTRAINT skills_slug_format CHECK (slug ~ '^[a-z0-9][a-z0-9-]*[a-z0-9]$'),
    CONSTRAINT skills_tags_is_array CHECK (jsonb_typeof(tags) = 'array')
);

CREATE INDEX idx_skills_tags ON skills USING GIN (tags) WHERE deleted_at IS NULL;
CREATE INDEX idx_skills_active ON skills (created_at DESC) WHERE deleted_at IS NULL;
```

### 3.3 Tabelas de junção (M:N)

```sql
CREATE TABLE agent_skills (
    agent_id    UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    skill_id    UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
    position    INT  NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (agent_id, skill_id)
);

CREATE INDEX idx_agent_skills_skill ON agent_skills (skill_id);

CREATE TABLE agent_subagents (
    agent_id    UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    sub_id      UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    position    INT  NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (agent_id, sub_id),
    CONSTRAINT agent_subagents_no_self CHECK (agent_id <> sub_id)
);

CREATE INDEX idx_agent_subagents_sub ON agent_subagents (sub_id);

-- Detecção de ciclo: aplicada na aplicação (Python) com travessia de grafo
-- antes de inserir. Postgres não tem CHECK constraints transversais simples.
```

### 3.4 `executions`

```sql
CREATE TABLE executions (
    id                  UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id            UUID                NOT NULL REFERENCES agents(id) ON DELETE RESTRICT,
    agent_snapshot      JSONB               NOT NULL,
    input               TEXT                NOT NULL,
    cwd                 TEXT                NOT NULL,
    status              execution_status    NOT NULL DEFAULT 'running',
    started_at          TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    ended_at            TIMESTAMPTZ,
    duration_ms         INT,
    output_md           TEXT,
    tokens_input        INT,
    tokens_output       INT,
    tool_calls_count    INT                 NOT NULL DEFAULT 0,
    cost_estimated_usd  NUMERIC(10, 6),
    error_message       TEXT,
    aborted_by          TEXT,

    CONSTRAINT executions_input_size CHECK (length(input) <= 10000),
    CONSTRAINT executions_ended_after_started CHECK (ended_at IS NULL OR ended_at >= started_at),
    CONSTRAINT executions_snapshot_has_keys CHECK (
        agent_snapshot ? 'slug'
        AND agent_snapshot ? 'system_prompt'
        AND agent_snapshot ? 'model'
        AND agent_snapshot ? 'tools'
    )
);

CREATE INDEX idx_executions_agent ON executions (agent_id, started_at DESC);
CREATE INDEX idx_executions_status ON executions (status, started_at DESC);
CREATE INDEX idx_executions_started_at ON executions (started_at DESC);
```

### 3.5 `execution_events`

```sql
CREATE TABLE execution_events (
    id              UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
    execution_id    UUID                    NOT NULL REFERENCES executions(id) ON DELETE CASCADE,
    seq             INT                     NOT NULL,
    event_type      execution_event_type    NOT NULL,
    payload         JSONB                   NOT NULL DEFAULT '{}'::jsonb,
    created_at      TIMESTAMPTZ             NOT NULL DEFAULT NOW(),

    UNIQUE (execution_id, seq)
);

CREATE INDEX idx_execution_events_exec_seq ON execution_events (execution_id, seq);
CREATE INDEX idx_execution_events_type ON execution_events (event_type);
```

### 3.6 `analyses`

```sql
CREATE TABLE analyses (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    slug            TEXT            NOT NULL UNIQUE,
    title           TEXT            NOT NULL,
    kind            analysis_kind   NOT NULL DEFAULT 'investigacao',
    question        TEXT            NOT NULL DEFAULT '',
    body_md         TEXT            NOT NULL DEFAULT '',
    status          analysis_status NOT NULL DEFAULT 'rascunho',
    tags            JSONB           NOT NULL DEFAULT '[]'::jsonb,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    published_at    TIMESTAMPTZ,
    exported_at     TIMESTAMPTZ,
    exported_path   TEXT,
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_analyses_status ON analyses (status, updated_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_analyses_kind ON analyses (kind) WHERE deleted_at IS NULL;
CREATE INDEX idx_analyses_tags ON analyses USING GIN (tags) WHERE deleted_at IS NULL;
```

### 3.7 `analysis_executions`

```sql
CREATE TABLE analysis_executions (
    analysis_id     UUID    NOT NULL REFERENCES analyses(id) ON DELETE CASCADE,
    execution_id    UUID    NOT NULL REFERENCES executions(id) ON DELETE RESTRICT,
    note            TEXT    NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (analysis_id, execution_id)
);

CREATE INDEX idx_analysis_executions_exec ON analysis_executions (execution_id);
```

### 3.8 `reports`

```sql
CREATE TABLE reports (
    id              UUID                   PRIMARY KEY DEFAULT gen_random_uuid(),
    slug            TEXT                   NOT NULL UNIQUE,
    title           TEXT                   NOT NULL,
    analysis_id     UUID                   NOT NULL REFERENCES analyses(id) ON DELETE RESTRICT,
    destinatario    TEXT                   NOT NULL,
    body_md         TEXT                   NOT NULL DEFAULT '',
    status          report_status          NOT NULL DEFAULT 'rascunho',
    classificacao   report_classificacao   NOT NULL DEFAULT 'interno',
    tags            JSONB                  NOT NULL DEFAULT '[]'::jsonb,
    created_at      TIMESTAMPTZ            NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ            NOT NULL DEFAULT NOW(),
    exported_at     TIMESTAMPTZ,
    exported_path   TEXT,
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_reports_status ON reports (status, updated_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_reports_analysis ON reports (analysis_id);
CREATE INDEX idx_reports_destinatario ON reports (destinatario) WHERE deleted_at IS NULL;
```

### 3.9 `settings`

```sql
CREATE TABLE settings (
    key             TEXT        PRIMARY KEY,
    value           JSONB       NOT NULL,
    description     TEXT        NOT NULL DEFAULT '',
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 3.10 Triggers de `updated_at`

```sql
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at_agents      BEFORE UPDATE ON agents      FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at_skills      BEFORE UPDATE ON skills      FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at_analyses    BEFORE UPDATE ON analyses    FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at_reports     BEFORE UPDATE ON reports     FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
CREATE TRIGGER set_updated_at_settings    BEFORE UPDATE ON settings    FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
```

### 3.11 Seed inicial de settings

```sql
INSERT INTO settings (key, value, description) VALUES
    ('workspace_path',  '"/workspace/Repasse"',           'Path absoluto do workspace montado'),
    ('default_model',   '"sonnet"',                       'Modelo padrão para novos agentes'),
    ('export_path',     '"/workspace/Repasse/Gestao"',    'Path base para exports .md'),
    ('max_concurrent',  '3',                              'Máximo de execuções concorrentes'),
    ('pricing_table',   '{"opus":{"input":15.0,"output":75.0},"sonnet":{"input":3.0,"output":15.0},"haiku":{"input":0.8,"output":4.0}}', 'USD por 1M tokens')
ON CONFLICT (key) DO NOTHING;
```

---

## 4 · Considerações de design

### 4.1 Soft delete

Tabelas com `deleted_at`: `agents`, `skills`, `analyses`, `reports`. Permite restaurar e preserva integridade referencial em `executions` (que aponta para agents). Queries SEMPRE filtram `WHERE deleted_at IS NULL` exceto em telas de "arquivados".

`executions` e `execution_events` **não têm soft delete** — execuções são imutáveis e auditáveis.

### 4.2 Snapshot do agente em execuções

`executions.agent_snapshot` (JSONB) guarda **cópia integral** do agente no momento da execução: prompt, modelo, tools, skills carregadas, subagents resolvidos. Isso garante reprodutibilidade mesmo se o agente for editado depois.

### 4.3 Slugs únicos

Todos os entidades de domínio têm `slug` único como identificador legível, além do `id` UUID. UI primária usa slug, API usa UUID.

### 4.4 Detecção de ciclo em `agent_subagents`

Validação **na aplicação** (não em SQL) ao criar relação. Pseudocódigo:

```python
def has_cycle(agent_id: UUID, sub_id: UUID) -> bool:
    visited = set()
    stack = [sub_id]
    while stack:
        current = stack.pop()
        if current == agent_id:
            return True
        if current in visited:
            continue
        visited.add(current)
        stack.extend(get_subagent_ids(current))
    return False
```

### 4.5 Particionamento de `execution_events`

**MVP: não particionar.** Com limite de 50k eventos/execução e ~50 execuções/mês, projeção de 5 anos = 150M rows. Postgres aguenta com índices certos. V2: avaliar particionamento por mês se necessário.

### 4.6 Custo computado vs persistido

`executions.cost_estimated_usd` é **persistido** no fim da execução (calculado da pricing_table do momento). Não recalcula on-read.

---

## 4.7 Tabelas de gestão (v2 — promovidas a MVP)

Em v2 do plano, os módulos `pendencias`, `reunioes`, `one_on_ones`, `roadmap_items` e `commands` saíram do "legacy" e viraram parte do produto. Schema abaixo, alinhado com `Gestao/*.md` existentes.

### `pendencias`

```sql
CREATE TYPE pendencia_status   AS ENUM ('aberta','em-curso','bloqueada','fechada');
CREATE TYPE pendencia_prio     AS ENUM ('alta','media','baixa');

CREATE TABLE pendencias (
    id              TEXT             PRIMARY KEY,         -- P07, P36, ...
    title           TEXT             NOT NULL,
    status          pendencia_status NOT NULL DEFAULT 'aberta',
    prioridade      pendencia_prio   NOT NULL DEFAULT 'media',
    owner           TEXT             NOT NULL DEFAULT 'João Vinícius',
    criada          DATE             NOT NULL DEFAULT CURRENT_DATE,
    deadline        DATE,
    fechada         DATE,
    origem          TEXT             NOT NULL DEFAULT '',
    tags            JSONB            NOT NULL DEFAULT '[]'::jsonb,
    body_excerpt    TEXT             NOT NULL DEFAULT '',
    body_md         TEXT             NOT NULL DEFAULT '',
    exported_path   TEXT,
    exported_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,

    CONSTRAINT pendencias_id_format CHECK (id ~ '^P[0-9]+$'),
    CONSTRAINT pendencias_fechada_consistency CHECK (
        (status = 'fechada' AND fechada IS NOT NULL) OR
        (status != 'fechada' AND fechada IS NULL)
    )
);

CREATE INDEX idx_pendencias_status ON pendencias (status, deadline) WHERE deleted_at IS NULL;
CREATE INDEX idx_pendencias_owner ON pendencias (owner) WHERE deleted_at IS NULL;
CREATE INDEX idx_pendencias_deadline ON pendencias (deadline) WHERE deleted_at IS NULL AND status != 'fechada';
CREATE INDEX idx_pendencias_tags ON pendencias USING GIN (tags) WHERE deleted_at IS NULL;
```

### `reunioes`

```sql
CREATE TYPE reuniao_tipo AS ENUM ('alinhamento','review','brainstorm','externa','1on1','escalation');

CREATE TABLE reunioes (
    id              UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
    legacy_id       TEXT             UNIQUE,            -- R01, R02 (do bootstrap)
    title           TEXT             NOT NULL,
    data            DATE             NOT NULL,
    tipo            reuniao_tipo     NOT NULL DEFAULT 'alinhamento',
    duracao         TEXT             NOT NULL DEFAULT '1h',
    participantes   JSONB            NOT NULL DEFAULT '[]'::jsonb,
    tags            JSONB            NOT NULL DEFAULT '[]'::jsonb,
    body_md         TEXT             NOT NULL DEFAULT '',
    body_excerpt    TEXT             NOT NULL DEFAULT '',
    exported_path   TEXT,
    exported_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_reunioes_data ON reunioes (data DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_reunioes_tipo ON reunioes (tipo) WHERE deleted_at IS NULL;
```

### `reuniao_pendencias` (M:N — reunião gera pendências)

```sql
CREATE TABLE reuniao_pendencias (
    reuniao_id    UUID NOT NULL REFERENCES reunioes(id) ON DELETE CASCADE,
    pendencia_id  TEXT NOT NULL REFERENCES pendencias(id) ON DELETE CASCADE,
    PRIMARY KEY (reuniao_id, pendencia_id)
);
CREATE INDEX idx_rp_pendencia ON reuniao_pendencias (pendencia_id);
```

### `one_on_ones`

```sql
CREATE TYPE one_on_one_recorrencia AS ENUM ('semanal','quinzenal','mensal','ad-hoc');

CREATE TABLE one_on_ones (
    id              UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
    legacy_id       TEXT                    UNIQUE,
    pessoa          TEXT                    NOT NULL,
    papel           TEXT                    NOT NULL DEFAULT '',
    data            DATE                    NOT NULL,
    duracao         TEXT                    NOT NULL DEFAULT '30min',
    recorrencia     one_on_one_recorrencia  NOT NULL DEFAULT 'quinzenal',
    tags            JSONB                   NOT NULL DEFAULT '[]'::jsonb,
    body_md         TEXT                    NOT NULL DEFAULT '',
    body_excerpt    TEXT                    NOT NULL DEFAULT '',
    classificacao   TEXT                    NOT NULL DEFAULT 'restrito',  -- 1on1 default restrito
    exported_path   TEXT,
    exported_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_ones_pessoa ON one_on_ones (pessoa, data DESC) WHERE deleted_at IS NULL;
```

### `roadmap_items`

```sql
CREATE TYPE roadmap_frente AS ENUM ('esperanza','valentina','clara','torre','automacoes','estrategica');
CREATE TYPE roadmap_status AS ENUM ('nao-iniciado','em-curso','bloqueado','concluido');

CREATE TABLE roadmap_items (
    id              TEXT             PRIMARY KEY,           -- RM01, RM24
    title           TEXT             NOT NULL,
    frente          roadmap_frente   NOT NULL,
    status          roadmap_status   NOT NULL DEFAULT 'nao-iniciado',
    prioridade      pendencia_prio   NOT NULL DEFAULT 'media',
    progresso       INT              NOT NULL DEFAULT 0 CHECK (progresso BETWEEN 0 AND 100),
    owner           TEXT             NOT NULL DEFAULT 'João Vinícius',
    descricao       TEXT             NOT NULL DEFAULT '',
    tags            JSONB            NOT NULL DEFAULT '[]'::jsonb,
    analise_id      UUID,                                   -- FK fraca para analyses (análise-fonte)
    criada          DATE             NOT NULL DEFAULT CURRENT_DATE,
    atualizada      DATE,
    concluida       DATE,
    deleted_at      TIMESTAMPTZ,

    CONSTRAINT roadmap_id_format CHECK (id ~ '^RM[0-9]+$')
);

CREATE INDEX idx_roadmap_frente ON roadmap_items (frente, status) WHERE deleted_at IS NULL;
```

### `roadmap_pendencias` (M:N)

```sql
CREATE TABLE roadmap_pendencias (
    roadmap_id    TEXT NOT NULL REFERENCES roadmap_items(id) ON DELETE CASCADE,
    pendencia_id  TEXT NOT NULL REFERENCES pendencias(id) ON DELETE CASCADE,
    PRIMARY KEY (roadmap_id, pendencia_id)
);
CREATE INDEX idx_rmp_pendencia ON roadmap_pendencias (pendencia_id);
```

### `commands`

```sql
CREATE TABLE commands (
    slug            TEXT             PRIMARY KEY,           -- pendencia, atualizar-board, ...
    description     TEXT             NOT NULL DEFAULT '',
    target_agent    TEXT,                                   -- agent slug (fraco — não FK)
    body_md         TEXT             NOT NULL DEFAULT '',
    is_read_only    BOOLEAN          NOT NULL DEFAULT TRUE, -- MVP: read-only para os 10 commands existentes
    created_at      TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ      NOT NULL DEFAULT NOW(),

    CONSTRAINT commands_slug_format CHECK (slug ~ '^[a-z0-9][a-z0-9-]*[a-z0-9]$')
);
```

### `analise_pendencias` (M:N — análise relaciona pendências)

```sql
CREATE TABLE analise_pendencias (
    analise_id    UUID NOT NULL REFERENCES analyses(id) ON DELETE CASCADE,
    pendencia_id  TEXT NOT NULL REFERENCES pendencias(id) ON DELETE CASCADE,
    PRIMARY KEY (analise_id, pendencia_id)
);
CREATE INDEX idx_ap_pendencia ON analise_pendencias (pendencia_id);
```

> **Atenção**: `analyses` (definido em §3.6) tem campo `relacionadas JSONB` para refs livres. A tabela M:N acima estrutura essa relação para queries eficientes ("Análises que tocam P15?"). MVP pode optar por uma ou outra; recomendamos M:N para V1+.

---

## 5 · Migration strategy

- Alembic com `auto_generate=False` (sempre revisar SQL gerado).
- Migrations imutáveis após merge.
- Toda migration deve ter `downgrade()` implementado.
- Seed de `settings` em migration separada (data migration), não em DDL.

Spec detalhada em [06-infra/SETUP_LOCAL.md](../06-infra/SETUP_LOCAL.md).
