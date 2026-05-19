---
description: CRUD de pendências em Gestao/Pendencias/. Subcomandos: add, list, update, close, reopen, init. Cada pendência é um .md com frontmatter padrão e histórico imutável.
---

# /pendencia — gerenciar backlog do supervisor

`$ARGUMENTS` define o subcomando:

| Forma | O que faz |
|---|---|
| `/pendencia` (vazio) | Lista pendências abertas. Equivalente a `list`. |
| `/pendencia add "<título>"` | Abre nova. Pergunta prioridade, origem, deadline se faltarem. |
| `/pendencia list [--all | --status=X | --owner=Y | --atrasadas]` | Lista filtrada. |
| `/pendencia update <id> <campo>=<valor>` | Atualiza status/prioridade/deadline/owner. |
| `/pendencia close <id>` | Fecha. Pergunta "resultado" para o histórico. |
| `/pendencia reopen <id>` | Reabre. Pergunta razão. |
| `/pendencia init` | Popula P01–P06 a partir do BRIEFING (só se não existirem). |
| `/pendencia show <id>` | Exibe o arquivo da pendência completo. |

## Execução

Invoque `pendencia-tracker` passando o subcomando + args.

Brief para o agente:
```
Subcomando: <add|list|update|close|reopen|init|show>
Args: <args>
```

## Quando pedir input adicional

- **add** sem título: peça via `AskUserQuestion`.
- **add** com título mas sem prioridade/origem: pergunte em uma chamada.
- **close** sem ID: liste abertas primeiro e pergunte qual.
- **update** com campo inválido: liste campos válidos (status, prioridade, deadline, owner, tags).

## Encerramento

Após execução, reporte:

```
✓ <operação> — [P0N | custom_<slug>]
  Arquivo: Gestao/Pendencias/<arquivo>.md
  Status atual: <status> · Prioridade: <prio> · Deadline: <data ou —>
```

Para `list`, mostre a tabela do agente direto.
