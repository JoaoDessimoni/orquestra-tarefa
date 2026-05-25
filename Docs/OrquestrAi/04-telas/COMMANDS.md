# Tela: Commands

> Lista read-only dos slash commands do workspace `.claude/commands/`. Última atualização: 21/05/2026.

## Fontes

- `.claude/commands/` (10 commands reais)
- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md) §RF-CM

## Rota

`/commands`

---

## 1 · Objetivo (MVP read-only)

Mostrar o catálogo de slash commands disponíveis para o supervisor invocar via Claude Code. **Não permite criação/edição no MVP** — V1+ habilita CRUD.

Justificativa: criação de slash command afeta `.claude/commands/` direto e exige re-leitura pelo Claude Code; complexidade alta para benefício baixo no MVP.

---

## 2 · Listagem (grid cards)

```
┌──── Card (dotted) ─────────────────┐  ┌──── Card ──────────────┐
│ / pendencia                         │  │ / atualizar-board       │
│ → pendencia-tracker                 │  │ → board-updater         │
│                                     │  │                         │
│ CRUD de pendências em Gestao/Pen-   │  │ Sincroniza JSON do      │
│ dencias/. Subcomandos: add, list,   │  │ BOARD.html com Gestao/. │
│ update, close, reopen, init.        │  │                         │
└─────────────────────────────────────┘  └─────────────────────────┘
```

### Conteúdo do card

- `/ <slug>` (h3 weight 600)
- `→ <target_agent>` (meta) ou `sem agente — operação direta`
- Descrição (excerpt 3 linhas)

### Filtros

- Busca textual
- Filter por agente (V1)
- Filter por tipo: invoca agente / operação direta (V1)

---

## 3 · Lista dos 10 commands reais (do `.claude/commands/`)

| Slug | Target | Descrição |
|---|---|---|
| `/pendencia` | `pendencia-tracker` | CRUD de pendências em Gestao/Pendencias/ |
| `/reuniao` | — (direto) | Cria nota de reunião em Gestao/Reunioes/ |
| `/analise` | — (direto) | Cria análise em Gestao/Analises/<dia>/ |
| `/relatorio` | — (direto) | Cria relatório derivado de análise |
| `/status` | — (direto) | Resumo executivo semanal |
| `/organizar` | `folder-organizer` | Audita arquitetura do workspace |
| `/atualizar-board` | `board-updater` | Sincroniza BOARD.html com Gestao/ |
| `/novo-deck` | pipeline 6-agentes | Cria deck Finza do zero |
| `/novo-slide` | pipeline 4-agentes | Adiciona 1 slide a deck existente |
| `/revisar-deck` | `slide-reviewer` | Audita deck existente |

---

## 4 · API (V1+)

```
GET  /api/commands
POST /api/commands         (V1+)
PATCH /api/commands/{slug} (V1+)
```

---

## 5 · Importação inicial

Endpoint utility:
```
POST /api/import/claude-commands
→ Lê .claude/commands/*.md e popula tabela commands.
```

Idempotente — re-rodar não duplica.

---

## 6 · Histórico

| Versão | Data | Mudança |
|---|---|---|
| **v2** | **2026-05-21** | Doc criado. Commands como módulo read-only do produto. |
