---
description: Adiciona um slide a um deck Finza existente. Roda writer → designer → builder no slide novo, depois reviewer no arquivo inteiro. Use quando o usuário quer expandir um deck sem refazer tudo.
---

# /novo-slide — injetar slide em deck existente

Você vai adicionar **um único slide** a um deck `.html` já em `Apresentacoes/executando/` ou `entregues/`.

## Passo 0 — Parsing dos argumentos

`$ARGUMENTS` deve conter: `<arquivo.html> <conceito do slide>`. Se não veio claro, pergunte via `AskUserQuestion`:

1. **Qual deck?** (caminho do `.html` ou nome).
2. **Qual conceito o slide vai carregar?** (1 frase).
3. **Posição no deck?** (antes do slide N / depois do slide N / no final / pergunte se "no fim" funciona).

## Passo 1 — Carregar contexto

- Leia o `.html` existente para entender:
  - Quantos slides já há.
  - Vocabulário visual e classes em uso.
  - Posição alvo do novo slide.
- Carregue:
  - **`.claude/skills/finza-deck-animado/SKILL.md`** (padrão do deck animado; o slide novo parte de um slide do `template.html`)
  - `.claude/skills/finza-tom-voz/SKILL.md`
  - `.claude/skills/finza-contexto/SKILL.md`

## Passo 2 — Research (se preciso)

Se o conceito do slide depende de fato que pode não estar no deck atual, invoque `finza-researcher` com escopo restrito.

Pule research se o conceito for puramente narrativo (transição, fechamento) ou se você já tem fatos suficientes no contexto.

## Passo 3 — Writer

Invoque `slide-writer` apenas para esse 1 slide. Forneça:
- Conceito.
- Visual-âncora desejado (consulte o mapa "quero mostrar X, uso Y" em `finza-deck-animado/referencias/componentes.md`; em dúvida, pergunte).
- Fatos do researcher (se houve).
- Estilo dos slides vizinhos no deck (para coerência).

## Passo 4 — Designer

Invoque `slide-designer` com:
- Texto do writer.
- Tipo de slide.
- Sample do CSS já existente no `.html` (pra não duplicar classes).

## Passo 5 — Builder

Builder **não regenera o arquivo inteiro**. Em vez disso:

1. Abre o `.html` existente.
2. Localiza o ponto de inserção (`<section class="s ...">` após o slide alvo).
3. Insere o novo `<section>` via `Edit`, copiado do slide-base do `template.html` indicado pelo designer, com `data-label`, `data-notes`, `data-act` (se abrir ato) e data-attributes de animação.
4. Se usar componente/demo que o deck ainda não tem, copia do template o CSS e o JS correspondentes (incluindo o registro em `HOOKS`) via Edit.
5. **Renumera** os kickers `NN ·` dos slides seguintes e corrige os `data-go` do resumo (índices base 0) que apontarem depois do ponto de inserção. O contador `N / M` é automático.

## Passo 6 — Reviewer

Invoque `slide-reviewer` no arquivo inteiro (não só no slide novo — porque mudança em um slide pode quebrar HUD/CSS).

Loop de correção via Edit até reviewer aprovar.

## Passo 7 — Atualizar BRIEFING (se for deck principal)

Se o deck for `apresentacao_cto_*.html` ou outro deck rastreado no BRIEFING:
- Incremente versão (`v8 → v9`).
- Adicione entrada no histórico explicando o slide novo.
- Atualize "Estrutura dos N slides" reflectindo nova contagem e novo conteúdo.

## Passo 8 — Encerramento

```
✓ Slide adicionado em Apresentacoes/<pasta>/<arquivo>.html
  - Posição: slide N
  - Conceito: <conceito>
  - Tipo: <tipo do design>
  - Reviewer: [aprovado | K observações]
  - BRIEFING atualizado: [sim | n/a]

Total de slides agora: N
```
