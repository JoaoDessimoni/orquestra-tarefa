# Tela: Execuções

> Lista + tela de detalhe com streaming em tempo real. Coração funcional do produto. Última atualização: 20/05/2026.

## Fontes

- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md) §RF-EX
- [STREAMING_SSE.md](../02-arquitetura/STREAMING_SSE.md)
- [COMPONENTES.md](../07-design-system/COMPONENTES.md) §13 (StreamViewer)

## Rotas

- `/executions` — lista
- `/executions/new` — form disparar
- `/executions/[id]` — detalhe com stream

---

## 1 · /executions — Lista

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  Execuções                                  [⌘K]  [▶ Executar Agente]│
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  [🔍 Buscar...]  [Agente: todos ▾]  [Status: todos ▾]  [Período ▾]   │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ AGENTE          STATUS    INICIO     DURAÇÃO  TOOLS  CUSTO     ││
│  ├─────────────────────────────────────────────────────────────────┤│
│  │ ◆ researcher-f  🟢 done   há 12s     0:23     4      0.012     ││
│  │ ◆ slide-writer  🟢 done   há 5m      1:48     7      0.084     ││
│  │ ◆ folder-org    🔴 error  há 18m     0:08     1      —         ││
│  │ ◆ researcher-f  🟡 running há 12s    —        2      —         ││
│  │ ◆ drafter       🟢 done   há 2h      3:12    11      0.156     ││
│  └─────────────────────────────────────────────────────────────────┘│
│  Mostrando 1–20 de 84                            [‹ Prev]  [Next ›]  │
└──────────────────────────────────────────────────────────────────────┘
```

### Colunas

| Coluna | Sortable | Conteúdo |
|---|---|---|
| Agente | ✓ | Slug com ícone ◆ |
| Status | ✓ | Badge colorido |
| Início | ✓ (default desc) | Tempo relativo (hover: data absoluta) |
| Duração | ✓ | `mm:ss` ou "—" se running |
| Tools | — | Count |
| Custo | ✓ | USD ou "—" |

### Filtros

- Busca em input (agente slug, id da execução)
- Agente: dropdown com todos os agentes
- Status: multi-select badges (running/done/error/aborted/unknown)
- Período: presets (Hoje, 7d, 30d, Custom)

### Linha clickable → `/executions/[id]`

### API

`GET /api/executions?agent_slug=...&status=...&from=...&to=...&page=1&limit=20&sort=started_at:desc`

### Refresh
- Polling de 5s para execuções em running (atualiza row sem recarregar tudo).
- V1+: SSE de "lista" para atualizações live.

---

## 2 · /executions/new — Form de disparo

### Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  Execuções / Nova                            [Cancelar] [▶ Disparar] │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Agente*                                                             │
│  [◆ researcher-finza ▾]    sonnet · 4 tools · 2 skills              │
│                                                                      │
│  Input*                                                              │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Liste todas as plataformas Finza com responsável e status.  │  │
│  │                                                              │  │
│  │                                                              │  │
│  │                                                              │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  4.231 / 10.000 chars                                                │
│                                                                      │
│  Avançado ▾                                                          │
│  ── ─────────────                                                    │
│  cwd       [/workspace/Repasse                          ]            │
│  Modelo    [Usar do agente (sonnet) ▾]                               │
│  Timeout   [15 min (default) ▾]                                      │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Campos

| Campo | Default | Validação |
|---|---|---|
| Agente* | Pré-selecionado se `?agent=slug` na URL | required |
| Input* | "" | required, max 10000 |
| cwd | `settings.workspace_path` | path dentro do workspace |
| Modelo override | (vazio = usa do agente) | enum opus/sonnet/haiku |
| Timeout | 15 min | 60s – 60 min |

### Dispara

`POST /api/executions` → navega para `/executions/[id]` com stream ligado.

---

## 3 · /executions/[id] — Detalhe com stream

### Layout (3 zonas)

```
┌──────────────────────────────────────────────────────────────────────┐
│  Execuções / abc-12345                       [Replay] [⋮ Mais]       │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ╔═════════════════════════════════════════════════════════════╗    │
│  ║ ◆ researcher-finza · sonnet                                 ║    │
│  ║                                                             ║    │
│  ║ 🟡 RUNNING · 0:23 · 4 tool calls            [⏹ Stop]        ║    │
│  ║                                                             ║    │
│  ║ Input:                                                      ║    │
│  ║  > Liste todas as plataformas Finza com responsável...      ║    │
│  ║                                                             ║    │
│  ║ cwd: /workspace/Repasse                                     ║    │
│  ╚═════════════════════════════════════════════════════════════╝    │
│                                                                      │
│  ── Timeline (stream) ──────────────────────────────────────         │
│                                                                      │
│  ⏵ Status started · sonnet · cwd /workspace/Repasse                  │
│                                                                      │
│  Vou começar lendo os docs da pasta Docs/.                           │
│                                                                      │
│  ▸ Tool: Read /workspace/Repasse/Docs/PLATAFORMAS.md  12ms          │
│    ├─ input: { "file_path": "..." }                                  │
│    └─ result: [12 KB de conteúdo — clique para expandir]            │
│                                                                      │
│  ▸ Tool: Grep "responsavel" /workspace/Repasse/Docs/  84ms          │
│    └─ 7 matches                                                      │
│                                                                      │
│  Com base nos docs, as plataformas Finza são:                        │
│                                                                      │
│  1. **Esperanza** — agente de cobrança IA, owner: João Lucas         │
│  2. **Valentina** — assistente whatsapp, owner: Camila               │
│  [_cursor pulsante chega tokens em tempo real..._]                   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Estado: running

- Status badge amarelo
- Botão "⏹ Stop" disponível
- Tokens chegam em tempo real
- Cursor pulsante no fim
- Auto-scroll para fundo (a menos que usuário rolou pra cima)

### Estado: done

- Status badge verde
- Métricas finais: duração, tool calls, tokens (in/out), custo
- Output renderizado como markdown limpo (separado da timeline)
- Botão "Replay" disponível
- Botão "+ Anexar a Análise" (cria/edita análise vinculada)

### Estado: error / aborted

- Status badge vermelho
- Mensagem de erro visível no topo
- Timeline mostra evento `error` em destaque
- Botão "Reexecutar" (cria execução nova com mesmo input)

### Componentes

- **Header card**: identifica agente, modelo, status, controle Stop, input usado
- **StreamViewer** (ver [COMPONENTES.md §13](../07-design-system/COMPONENTES.md))
- **Output panel** (visível só quando done): markdown renderizado em card separado

### Interações

| Ação | Comportamento |
|---|---|
| Clique em "⏹ Stop" | `POST /api/executions/{id}/abort` + toast |
| Clique em tool_call colapsado | Expande mostrando input + result completo |
| Botão "Replay" | Reconecta SSE com replay mode |
| Botão "+ Anexar a Análise" | Modal com seletor de análise |
| Botão "Copiar output" | Copia output_md para clipboard |
| ⋮ Mais → "Ver JSON" | Drawer com payload completo dos eventos |

### API

- `GET /api/executions/{id}` — metadados
- `EventSource /api/events/executions/{id}` — stream (live ou replay)
- `POST /api/executions/{id}/abort` — aborta

---

## 4 · Cálculo de métricas (no fim)

Quando recebe evento `done`:
- `duration` = `ended_at - started_at`
- `tool_calls_count` = count de eventos `tool_call` na timeline
- `tokens_input/output` = do payload do `done`
- `cost` = calculado em backend (RN-18)

---

## 5 · Persistência durante stream

Backend persiste cada evento em `execution_events` **antes** de publicá-lo no broker. Garante:
- Reload da página = replay funciona
- Refresh resgata stream ao vivo a partir de `Last-Event-ID`
- Crash do backend não perde eventos já emitidos

---

## 6 · Limites visuais

| Cenário | Tratamento |
|---|---|
| Mais de 500 eventos na timeline | Virtualização (react-window) |
| Tool result >10 KB | Truncado com "[expandir completo]" — clica e faz fetch sob demanda |
| Erro fatal | Para de processar; mostra última posição + mensagem |

---

## 7 · Acessibilidade

- Header em `role="region" aria-label="Status da execução"`
- Timeline em `role="log" aria-live="polite"`
- Botão Stop com confirmação para evitar clique acidental
