---
description: Cura a base de contexto viva do workspace — docs de negócio (Docs/finza/), overviews de sistema e mapas textuais (Backlog/contexto/), e re-condensa a skill finza-contexto. Detecta docs defasados, referências quebradas e contradições. Não inventa — colhe do usuário, de Gestao/ e do finza-researcher.
argument-hint: "update <assunto> | new <assunto> | audit | sync-skill | list"
---

# /contexto — curadoria da base de contexto

A base de contexto é a memória do workspace: o que sustenta decks, análises e refinamento de backlog sem inventar fato. Este comando a mantém viva.

`$ARGUMENTS` define a operação (executada pelo agente `context-curator`):

| Forma | O que faz |
|---|---|
| `/contexto` (vazio) | Equivale a `audit` — fotografia da saúde do contexto. |
| `/contexto update <assunto>` | Atualiza doc existente (`CONTEXTO-FINZA`, `PLATAFORMAS`, `mapa_<x>`, `<sistema>_overview`, `BRIEFING`). Preserva história, acrescenta o novo. |
| `/contexto new <assunto>` | Cria novo doc de contexto. Confirma se é mapa narrativo (`Backlog/contexto/mapa_<x>.md`) ou overview técnico. |
| `/contexto audit` | Aponta defasados (>30d com movimento), referências quebradas, contradições entre docs, frentes sem mapa. Não edita. |
| `/contexto sync-skill` | Re-condensa `.claude/skills/finza-contexto/SKILL.md` a partir dos docs canônicos, fiel ao original. |
| `/contexto list` | Lista os docs de contexto por pasta com data da última revisão. |

## Execução

Invoque `context-curator` passando o subcomando + assunto.

Brief para o agente:
```
Subcomando: <update|new|audit|sync-skill>
Assunto: <CONTEXTO-FINZA | PLATAFORMAS | BRIEFING | mapa_esperanza | torre_overview | ...>
```

O agente carrega `finza-mapas` + `finza-contexto` + `finza-tom-voz`, lê o que existe, invoca `finza-researcher` para fatos incertos, e edita de forma cirúrgica.

## Fronteiras (onde cada coisa mora)

| Conteúdo | Vai para |
|---|---|
| Negócio amplo da Finza (modelo, organograma, plataformas) | `Docs/finza/` |
| Mapa narrativo de agente/frente/processo | `Backlog/contexto/mapa_<assunto>.md` |
| Spec viva de plataforma vizinha | `Backlog/contexto/<sistema>_overview.md` |
| Spec do deck principal | `Docs/BRIEFING.md` |

## Quando pedir input

- `new`/`update` sem assunto: liste os docs existentes e pergunte qual.
- `new`: confirme autor e a motivação antes de redigir.

## Encerramento

```
OPERAÇÃO: update | new | audit | sync-skill | list
ARTEFATO: <caminho ou "—">
RESULTADO: <1-2 linhas>
TODOs ABERTOS: <lacunas marcadas para confirmação>
```

## Relação com outros comandos

- `/mapa <assunto>` é o atalho focado em mapa **textual** (chama o mesmo `context-curator`).
- `/sync` regenera **projeções** (HTML), não docs de contexto — coisas distintas.
- Toda análise/reunião que revele contexto durável é candidata a virar/atualizar doc aqui.
