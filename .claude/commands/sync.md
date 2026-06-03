---
description: Sincroniza as projeções do Backlog de uma vez — backlog.html (kanban) e mapa-mental.html (canvas), ambos projeção de Backlog/frentes/. Roda backlog regenerate + mapa-updater a partir das fontes .md. Um só "atualizar tudo".
argument-hint: "[--backlog | --mapa]  (vazio = tudo)"
---

# /sync — sincronizar as projeções do Backlog

As duas projeções HTML da raiz são **descartáveis**; a verdade vive nos `.md` do `Backlog/`. Este comando regenera ambas a partir da fonte, garantindo que o que você vê bate com o que está no disco.

```
Backlog/frentes/**/*.md ──▶  backlog.html      (po-backlog regenerate)  · kanban
                        └─▶  mapa-mental.html  (mapa-updater)           · canvas
```

## Execução

`$ARGUMENTS` filtra o escopo (vazio = tudo):

| Forma | Roda |
|---|---|
| `/sync` | Tudo: backlog → mapa |
| `/sync --backlog` | Só `po-backlog regenerate` (que já encadeia o `mapa-updater`) |
| `/sync --mapa` | Só `mapa-updater` |

Sequência completa (`/sync` sem args):

1. Invoque o agente `po-backlog` com `Subcomando: regenerate`. Ele reescreve `Backlog/BACKLOG.md` + `backlog.html`, e ao final chama o `mapa-updater`.
2. Se o passo 1 não tiver acionado o `mapa-updater` (ex: rodou parcial), invoque-o diretamente.
3. Consolide os sumários num só relatório.

> Os mapas **textuais** (`Backlog/contexto/mapa_*.md`) **não** entram no `/sync` — são curadoria humana, não projeção mecânica. Para esses, use `/contexto` ou `/mapa <assunto>`.

## Saída esperada

```
✓ Sync completo — <timestamp>

backlog.html + BACKLOG.md
  Itens: N (a-refinar X · refinado Y · em-curso Z · …)

mapa-mental.html
  Frentes: N · Itens: N · Dependências: N

⚠ Warnings: <lista consolidada ou "nenhum">
```

## Quando usar

- Editou vários `.md` à mão e quer reconciliar tudo.
- Fim de sessão de refinement de backlog.
- Suspeita de defasagem entre o que vê nas projeções e o disco.
- Antes de abrir as projeções para apresentar a alguém.

## Não use para

- Mudar layout/cores das projeções — edite o HTML direto.
- Atualizar mapas textuais ou docs de contexto — use `/contexto`.
