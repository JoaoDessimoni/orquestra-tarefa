---
description: Mapas mentais do squad IAF — visual (mapa-mental.html, projeção do Backlog em canvas) e textual (Backlog/contexto/mapa_<assunto>.md, narrativa institucional). Regenera o visual a partir das frentes; cria/atualiza os textuais via context-curator.
argument-hint: "regenerar | <assunto> | list | audit"
---

# /mapa — mapas mentais do squad

Dois tipos de mapa, um comando. Veja a skill `finza-mapas` para a diferença entre eles.

`$ARGUMENTS` define a operação:

| Forma | O que faz | Quem executa |
|---|---|---|
| `/mapa regenerar` | Regenera o **visual** `mapa-mental.html` (`id="map-data"`) a partir de `Backlog/frentes/`. | agente `mapa-updater` |
| `/mapa <assunto>` | Cria ou atualiza o mapa **textual** `Backlog/contexto/mapa_<assunto>.md`. Se já existe → `update`; se não → `new`. | agente `context-curator` |
| `/mapa list` | Lista os mapas textuais existentes em `Backlog/contexto/` + estado do `mapa-mental.html` (data de geração). | leitura direta |
| `/mapa audit` | Aponta frentes/agentes ativos sem mapa textual e mapas defasados (>30d com movimento recente). | agente `context-curator` (audit) |

## Execução

### `/mapa regenerar`
Invoque `mapa-updater` sem brief. Ele relê `Backlog/frentes/`, monta o JSON e regrava só o bloco `map-data` do `mapa-mental.html`. Coerência garantida com `backlog.html` (mesma fonte).

### `/mapa <assunto>`
1. Glob `Backlog/contexto/mapa_*.md` para ver se já existe mapa do assunto.
2. Invoque `context-curator`:
   - existe → `Subcomando: update <assunto>`
   - não existe → `Subcomando: new <assunto>`
3. O agente colhe contexto (usuário + backlog da frente + reuniões/análises + `finza-researcher`) e redige na estrutura canônica (`finza-mapas` §1).

### `/mapa list` / `/mapa audit`
Leitura/auditoria — sem editar. Para `audit`, invoque `context-curator` com `Subcomando: audit`.

## Quando pedir input

- `/mapa <assunto>` sem assunto claro: pergunte qual agente/frente/processo mapear.
- Assunto novo: confirme autor e o que motivou o mapa antes de redigir.

## Encerramento

```
OPERAÇÃO: regenerar | new | update | list | audit
ARTEFATO: mapa-mental.html | Backlog/contexto/mapa_<assunto>.md
RESULTADO: <1-2 linhas>
TODOs ABERTOS: <lacunas marcadas, se mapa textual>
```

## Relação com outros comandos

- `/sync` regenera o **visual** junto com o backlog. Os **textuais** ficam de fora (curadoria).
- `/contexto` é o irmão para docs de negócio (`Docs/finza/`) e overviews — `/mapa <assunto>` é o atalho focado em mapa narrativo.
