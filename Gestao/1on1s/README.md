# 1:1s — Squad IAF

Notas dos encontros 1-a-1 do supervisor com cada membro do squad e stakeholders próximos.

---

## Estrutura datada

```
Gestao/1on1s/
└── <dd-mm-aaaa>/                            # pasta do dia
    └── <YYYY-MM-DD>-1on1-<pessoa>.md        # 1 arquivo por 1on1
```

## Convenção

**Pasta do dia:** `<dd-mm-aaaa>/` (ex: `16-05-2026/`).
**Arquivo:** `<YYYY-MM-DD>-1on1-<pessoa>.md`
- Data no formato ISO no arquivo.
- Nome da pessoa em kebab-case ASCII (primeiro nome, sem sobrenome).
- Exemplos:
  - `16-05-2026/2026-05-16-1on1-joao-lucas.md`
  - `22-05-2026/2026-05-22-1on1-jessica.md`

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

**Seções:**
- Como ela/ele está (bem-estar, carga, motivação)
- Trabalho atual (o que está rolando)
- Bloqueios (o que está travando)
- Feedback (do supervisor → pessoa, e pessoa → supervisor)
- Próximas ações (de quem, até quando)
- Notas

---

## Princípio

1:1 é canal **da pessoa**, não do supervisor. Pergunta primeiro, fala depois. Ouve mais que orienta.

Esses arquivos são privados — não compartilhe sem permissão da pessoa.

---

## Pessoas que vivem aqui

| Pessoa | Papel | Recorrência |
|---|---|---|
| Joao Lucas | Dev squad IAF | semanal |
| Jéssica | Gerente operação cobrança | quinzenal |
| (outros devs do squad) | — | a definir |

> Atualize esta tabela conforme rituais se firmarem.

---

## Como usar

```
/reuniao "1on1 com <pessoa>"
```

Quando o tipo for `1on1`, o comando grava direto em `Gestao/1on1s/<dd-mm-aaaa>/` (não em `Reunioes/`) — não precisa mover.

Alternativamente, peça em linguagem natural: "cria nota de 1on1 com <pessoa> hoje".
