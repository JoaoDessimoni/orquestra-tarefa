# Tela: Settings

> Configurações single-user. Paths, modelo padrão, pricing table, info de versão. Última atualização: 20/05/2026.

## Fontes

- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md) §RF-ST
- [REGRAS_DE_NEGOCIO.md](../03-dominio/REGRAS_DE_NEGOCIO.md) §7
- [SCHEMA_POSTGRES.md](../03-dominio/SCHEMA_POSTGRES.md) §3.9 + §3.11 (seed)

## Rota

`/settings`

---

## 1 · Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  Settings                                                            │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ─── Workspace ────────────────────────────                          │
│  Path do workspace                                                   │
│  [/workspace/Repasse                                       ] [Testar]│
│  ✓ Validado: Claude Code v0.5.2 detectado no path                    │
│                                                                      │
│  Path de export Gestao/                                              │
│  [/workspace/Repasse/Gestao                                ]         │
│                                                                      │
│  ─── Modelo padrão ────────────────────────                          │
│  Modelo Claude para novos agentes                                    │
│  ○ Opus    ◉ Sonnet    ○ Haiku                                       │
│                                                                      │
│  ─── Execução ─────────────────────────────                          │
│  Máximo de execuções concorrentes  [3 ▾]                             │
│  Timeout default por execução      [15 min ▾]                        │
│                                                                      │
│  ─── Pricing table (estimativa de custo) ────────                    │
│  Custo por 1M tokens (USD)                                           │
│                                                                      │
│             input    output                                          │
│  Opus      [15.00]  [75.00]                                          │
│  Sonnet    [ 3.00]  [15.00]                                          │
│  Haiku     [ 0.80]  [ 4.00]                                          │
│                                                                      │
│  ─── Sistema ──────────────────────────────                          │
│  OrquestrAI versão       1.0.0 (build 2026-05-20-abc123)             │
│  Backend                 http://localhost:8000  ✓ healthy            │
│  Banco                   Postgres 16.2  ✓ connected                  │
│  Claude Code CLI         v0.5.2  ✓ detected                          │
│                                                                      │
│                                                       [Salvar mudanças]
└──────────────────────────────────────────────────────────────────────┘
```

---

## 2 · Seções

### 2.1 Workspace

| Campo | Tipo | Default | Validação |
|---|---|---|---|
| `workspace_path` | text | `/workspace/Repasse` | RN-32: path existe + Claude Code responde |
| `export_path` | text | `/workspace/Repasse/Gestao` | path existe ou criar |

Botão **Testar**: chama `POST /api/settings/validate-workspace` que executa `claude code --version` com `cwd=path` e retorna `{valid, version, error}`.

### 2.2 Modelo padrão

Radio com 3 opções. Aplicado quando se cria novo Agente sem escolher modelo.

### 2.3 Execução

- `max_concurrent`: 1, 2, 3, 4, 5 (default 3)
- `execution_timeout_seconds`: 60s, 5min, 15min (default), 30min, 60min

### 2.4 Pricing table

Tabela editável (3 modelos × 2 colunas). Salva como JSON em `settings.pricing_table`. Schema validado per RN-33.

### 2.5 Sistema (somente leitura)

- Versão do OrquestrAI (do `/version`)
- Status backend (`/health`)
- Status DB
- Versão do Claude Code CLI detectada

---

## 3 · Salvar

Botão único "Salvar mudanças" no fim da página (sticky em viewport curto).

- `PATCH /api/settings` com diff das mudanças
- Toast success
- Re-fetch settings após save

Se algum valor inválido → toast danger + highlight do campo.

---

## 4 · API

| Endpoint | Para |
|---|---|
| `GET /api/settings` | Carrega todas as settings |
| `PATCH /api/settings` | Atualiza parcial |
| `POST /api/settings/validate-workspace` | Testa workspace_path |
| `GET /api/health` | Status do sistema |
| `GET /api/version` | Versão e build SHA |

---

## 5 · Validações cliente

```typescript
const settingsSchema = z.object({
  workspace_path: z.string().min(1).startsWith('/'),
  export_path: z.string().min(1).startsWith('/'),
  default_model: z.enum(['opus','sonnet','haiku']),
  max_concurrent: z.number().int().min(1).max(10),
  execution_timeout_seconds: z.number().int().min(60).max(3600),
  pricing_table: z.record(
    z.enum(['opus','sonnet','haiku']),
    z.object({ input: z.number().nonnegative(), output: z.number().nonnegative() })
  ),
});
```

---

## 6 · Roadmap V1+

- **Auth toggle**: `AUTH_ENABLED` env (out of MVP)
- **Tema (light/dark)**: V2
- **Idioma (i18n)**: V2
- **Notificações** (Slack/email config): V1
- **API key Anthropic** (para uso direto além de CLI): V2
