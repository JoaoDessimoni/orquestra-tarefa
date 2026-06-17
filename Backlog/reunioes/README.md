# Reuniões — Squad IAF

Notas de reunião do supervisor. Um arquivo por reunião.

> Crie via `/reuniao "<título>"`. Edite os campos de discussão/decisões durante ou após a reunião.

---

## Estrutura datada

```
Backlog/reunioes/
└── <dd-mm-aaaa>/                       # pasta do dia (ex: 20-05-2026/)
    └── <YYYY-MM-DD>_<slug>.md          # 1 arquivo por reunião
```

## Convenção

**Pasta do dia:** `<dd-mm-aaaa>/` (ex: `20-05-2026/`).
**Arquivo:** `<YYYY-MM-DD>_<slug>.md`
- Data ISO no arquivo (ordena cronologicamente). Slug em kebab-case ASCII.
- Exemplos:
  - `15-05-2026/2026-05-15_alinhamento-jessica.md`
  - `20-05-2026/2026-05-20_status-leonardo.md`

**Frontmatter:**
```yaml
---
title: <título>
data: YYYY-MM-DD
participantes: [Pessoa1, Pessoa2]
duracao: 30min
tipo: alinhamento | 1on1 | review | brainstorm | escalation | externa
tags: []
---
```

**Seções:** Pauta · Discussão · Decisões · Ações geradas · Próximos passos · Notas

---

## Diferença Reuniões vs 1on1s

- `Backlog/reunioes/` — reuniões com 2+ pessoas além de mim, ou eventos com pauta formal.
- `Backlog/1on1s/` — encontros recorrentes 1-a-1 com membros do squad.

Se a fronteira for ambígua, prefira `reunioes/` e adicione tag `1on1` no frontmatter.
