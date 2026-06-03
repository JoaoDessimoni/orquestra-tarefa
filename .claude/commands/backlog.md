---
description: Gerencia backlog estratégico em Backlog/. Subcomandos — add, refine, review, prioritize, analyze, regenerate, list, show, from, from-solicitacao. Cada item é um .md por frente com história, critérios de aceite, subtarefas, RICE.
---

# /backlog — gerenciar backlog estratégico do supervisor

`$ARGUMENTS` define o subcomando:

| Forma | O que faz |
|---|---|
| `/backlog` (vazio) | Lista itens ativos agrupados por frente. Equivalente a `list`. |
| `/backlog add "<título>"` | Cria item `a-refinar`. Pergunta frente (7 opções: bitrix-automacoes, torre, clara, esperanza, valentina, livia, estrategica), sponsor, origem. Para frente unificada, pergunta prefix (BBT ou BAU). NÃO exige RICE. |
| `/backlog refine <id>` | Refina item — quebra subtarefas (schema novo: id, title, description, responsavel, esforco, prazo, status, dependencias), escreve história Given/When/Then, calcula RICE, identifica riscos. Status passa para `em-refinamento` (parcial) ou `refinado` (completo). |
| `/backlog review <id>` | Aplica checklist INVEST + completude. Devolve relatório com bloqueadores e observações. NÃO edita. |
| `/backlog prioritize [--frente=X]` | Recalcula RICE de itens refinados, mostra ranking, sugere mudanças de prioridade. Aplica só com confirmação. Banda `urgente` requer dupla validação (RICE ≥ 7.0 + declaração de sponsor). |
| `/backlog cancel <id>` | Cancela item com motivo obrigatório. Item permanece arquivado no backlog para rastreabilidade. |
| `/backlog analyze` | Operação macro. Detecta sobreposições, dependências circulares, frentes negligenciadas, itens parados >30d, deadlines críticos. |
| `/backlog regenerate` | Reescreve `Backlog/BACKLOG.md` mestre **e** regrava o JSON inline (`<script id="backlog-data">`) do `backlog.html`, **e** aciona o agente `mapa-updater` para regravar o `mapa-mental.html` (mesma fonte, projeção em canvas). Idempotente. Os `.md` são fonte da verdade — os HTMLs são projeção descartável. |
| `/backlog list [--frente=X --status=Y --prio=Z]` | Listagem filtrada. Status: a-refinar, em-refinamento, refinado, em-curso, bloqueado, cancelado, entregue. |
| `/backlog show <id>` | Exibe item completo. |
| `/backlog from-solicitacao <arquivo>` | Operação especial — lê doc em `Backlog/solicitacoes/` e propõe N itens. Usuário confirma quais aceitar. |

## Execução

Invoque `po-backlog` passando o subcomando + args.

Brief para o agente:
```
Subcomando: <add|refine|review|prioritize|analyze|regenerate|list|show|from|from-solicitacao>
Args: <args>
```

## Quando pedir input adicional

- **add** sem título: peça via `AskUserQuestion`.
- **add** com título mas sem frente: pergunte (liste as 7).
- **refine** sem ID: liste itens `bruto` e pergunte qual refinar.
- **review** sem ID: liste itens `refinado` e pergunte qual revisar.
- **from-solicitacao** sem arquivo: liste `Backlog/solicitacoes/*` e pergunte qual.
- **show** sem ID: liste todos os IDs e pergunte qual exibir.

## Encerramento

Após execução, reporte conforme padrão do agente:

```
OPERAÇÃO: <add|refine|review|...>
ITEM: <id> | -
ARQUIVO: <caminho> | -
RESULTADO: <1-2 linhas>
ORIGEM: [P## histórico, reunião, solicitação, análise] (se aplicável)
PRÓXIMO PASSO: <se aplicável>
PROJEÇÕES: backlog.html + mapa-mental.html regenerados | não-aplicável (só em `regenerate`)
BACKLOG.md: regenerado | não-aplicável
```

Para `list` e `show`, mostre o output do agente direto.

## Sequência recomendada para refinement de backlog inteiro

Quando o gestor faz refinement em sessão dedicada (provável cenário com Jéssica):

1. `/backlog list --status=bruto --prio=alta` — ver o que está priorizado para refinar.
2. Para cada item: `/backlog refine <id>` — sessão de 15-30min por item.
3. `/backlog prioritize` — após refinar 5-10, recalcular ranking global.
4. `/backlog analyze` — detectar sobreposições e dependências entre os refinados.
5. `/backlog regenerate` — atualizar `BACKLOG.md` mestre + `backlog.html` + `mapa-mental.html`.

## Tático vs estratégico (pendências aposentadas)

O comando `/pendencia` e o agente `pendencia-tracker` foram **aposentados em 27/05/2026**. Não há mais artefato de pendência tática separado — tudo tático vive como **subtarefa de item de backlog**.

- **Item de backlog** (`Backlog/frentes/`) — história estratégica (dura semanas/meses), sponsor de negócio, critérios de aceite, RICE.
- **Subtarefa** (dentro do item) — unidade tática (dura dias), com responsável e status próprios. É aqui que o trabalho de curto prazo é rastreado.

Os IDs `Pnn` antigos sobrevivem apenas como rótulo de origem (`origem.pendencias`) — referência histórica, não arquivo vivo.
