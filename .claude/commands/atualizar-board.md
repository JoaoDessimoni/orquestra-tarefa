---
description: Reler Gestao/ e regravar o JSON inline do BOARD.html. Útil quando o usuário editou arquivos em Gestao/ manualmente (fora do fluxo dos comandos /pendencia, /reuniao, /analise, /relatorio) ou quer forçar resync do board.
---

# /atualizar-board — sincronizar BOARD.html com Gestao/

`$ARGUMENTS` é ignorado. Este comando não aceita argumentos.

## Execução

Invoque o agente `board-updater` sem brief adicional. Ele faz tudo:

1. Inventaria `Gestao/Pendencias/`, `Reunioes/`, `Analises/`, `Analises/<dia>/Relatorio/`, `1on1s/`.
2. Lê frontmatter de cada `.md`.
3. Monta JSON com schema fixo.
4. Reescreve o bloco `<script type="application/json" id="board-data">` em `BOARD.html`.
5. Reporta sumário (totais por categoria + timestamp).

## Quando usar

- Editou um `.md` em `Gestao/` à mão (sem passar pelos comandos canônicos).
- Suspeita que o board está defasado (KPIs não batem com o que você vê em `Gestao/`).
- Acabou de mover/renomear arquivos entre pastas.
- Primeira execução depois de criar `BOARD.html` (popular o JSON inicial).

## Não use para

- Mudar layout, cores, ou views do `BOARD.html` — o updater **não toca** em HTML/CSS/JS. Edite o arquivo direto.
- Adicionar novos campos ao JSON — atualize o schema no agente `board-updater.md` e o renderizador em `BOARD.html` antes.

## Saída esperada

```
✓ Board atualizado.
  Pendências: 5 (abertas: 5, atrasadas: 0)
  Reuniões:   0 (últimos 30d: 0)
  Análises:   1 (rascunhos: 1)
  Relatórios: 1 (rascunhos: 1, enviados: 0)
  1on1s:      0 (pessoas: 0)
  Gerado em: 2026-05-18T14:32:00-03:00
```
