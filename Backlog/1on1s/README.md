# 1on1s — Squad IAF

Notas dos encontros 1-a-1 do supervisor com cada membro do squad e stakeholders próximos.

---

## Estrutura datada

```
Backlog/1on1s/
└── <dd-mm-aaaa>/
    └── <YYYY-MM-DD>-1on1-<pessoa>.md
```

## Convenção

**Pasta do dia:** `<dd-mm-aaaa>/`. **Arquivo:** `<YYYY-MM-DD>-1on1-<pessoa>.md`
- Exemplos: `16-05-2026/2026-05-16-1on1-joao-lucas.md`

**Frontmatter:**
```yaml
---
pessoa: <Primeiro Nome>
papel: <papel no squad ou stakeholder>
data: YYYY-MM-DD
duracao: 30min
recorrencia: semanal | quinzenal | mensal | ad-hoc
---
```

**Seções:** Como ela/ele está · Trabalho atual · Bloqueios · Feedback · Próximas ações · Notas

---

## Princípio

1on1 é canal **da pessoa**, não do supervisor. Pergunta primeiro, fala depois. Ouve mais que orienta.

Esses arquivos são privados — não compartilhe sem permissão da pessoa.

---

## Pessoas que vivem aqui

| Pessoa | Papel | Recorrência |
|---|---|---|
| Joao Lucas | Dev squad IAF | semanal |
| Jéssica | Gerente operação cobrança | quinzenal |
| (outros devs do squad) | — | a definir |

---

## Como usar

```
/reuniao "1on1 com <pessoa>"
```

Quando o tipo for `1on1`, o comando grava em `Backlog/1on1s/<dd-mm-aaaa>/` (não em `reunioes/`).
