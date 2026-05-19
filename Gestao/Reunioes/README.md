# Reuniões — Squad IAF

Notas de reunião do supervisor. Um arquivo por reunião.

> Crie via `/reuniao "<título>"`. Edite manualmente os campos de discussão/decisões durante ou após a reunião.

---

## Estrutura datada

```
Gestao/Reunioes/
└── <dd-mm-aaaa>/                       # pasta do dia (ex: 20-05-2026/)
    └── <YYYY-MM-DD>-<slug>.md          # 1 arquivo por reunião
```

## Convenção

**Pasta do dia:** `<dd-mm-aaaa>/` (ex: `20-05-2026/`).
**Arquivo:** `<YYYY-MM-DD>-<slug>.md`
- Data no formato ISO no arquivo (ordena cronologicamente).
- Slug em kebab-case ASCII (sem acento).
- Exemplos:
  - `15-05-2026/2026-05-15-alinhamento-jessica.md`
  - `20-05-2026/2026-05-20-status-leonardo.md`

**Frontmatter:**
```yaml
---
title: <título>
data: YYYY-MM-DD
participantes: [Pessoa1, Pessoa2]
duracao: 30min
tipo: alinhamento | review | brainstorm | escalation | externa
tags: []
---
```

**Seções:**
- Pauta
- Discussão
- Decisões
- Pendências geradas (vincular via `/pendencia add` depois)
- Próximos passos
- Notas / observações

---

## Diferença Reuniões vs 1:1s

- `Gestao/Reunioes/` — reuniões com 2+ pessoas além de mim, ou eventos com pauta formal.
- `Gestao/1on1s/` — encontros recorrentes 1-a-1 com membros do squad.

Se a fronteira for ambígua, prefira `Reunioes/` e adicione tag `1on1` no frontmatter.

---

## Como usar

```
/reuniao                          # pergunta tudo
/reuniao "<título>"               # já sabe o título
```

Para listar reuniões da semana: peça `/status` ou faça `Glob` em `Gestao/Reunioes/**/*.md` (recursivo, pega todas as pastas datadas).
