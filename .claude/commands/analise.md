---
description: Cria documento de análise individual em Backlog/analises/<dd-mm-aaaa>/. Cada análise é autônoma — investigação técnica, comparativo, RFC, post-mortem ou cruzamento de respostas. Pasta do dia é criada automaticamente.
---

# /analise — criar análise individual

`$ARGUMENTS` é o título/tema da análise. Se vazio, pergunte via `AskUserQuestion`.

## Passo 1 — Inputs

Pergunte em uma única chamada `AskUserQuestion`:

1. **Título curto** (1 frase). Ex: "Cruzamento das demandas anexo com respostas do time".
2. **Data** (default: hoje em ISO). Se passada, peça `YYYY-MM-DD`.
3. **Tipo**: `investigacao | comparativo | rfc | postmortem | proposta | cruzamento`.
4. **Fontes consultadas** (lista) — opcional, pode preencher depois.

## Passo 2 — Gerar slug e caminho

- `slug = kebab-case(título)` (ASCII, sem acento, sem espaço).
- `pasta-dia = dd-mm-aaaa` derivada da data informada.
- `caminho = Backlog/analises/<dd-mm-aaaa>/<YYYY-MM-DD>_<slug>.md`.

Se a pasta `<dd-mm-aaaa>/` não existir, **crie** (Write em qualquer arquivo dentro cria a pasta).

Se o arquivo já existir, sufixar com `-2`, `-3`, etc.

## Passo 3 — Criar arquivo

Use Write com este template:

```markdown
---
title: <título>
data: <YYYY-MM-DD>
autor: João Vinícius
tipo: investigacao | comparativo | rfc | postmortem | proposta | cruzamento
fontes-consultadas: []        # ex: ["mensagem do João Lucas em 15/05", "Docs/finza/PLATAFORMAS.md"]
relacionadas: []              # ids de pendências (P02, P05) ou outras análises
status: rascunho              # rascunho | revisao | publicada
tags: []
---

# <título>

**Data:** <data legível, ex: 18 de maio de 2026>
**Autor:** João Vinícius
**Tipo:** <tipo>

## Contexto
<por que essa análise existe — qual a pergunta de fundo, qual o gatilho>

## Pergunta de investigação
<a pergunta específica que esta análise responde, em 1 frase>

## Dados / Insumos
<o que foi consultado: mensagens, docs, métricas, tickets, conversas>

## Cruzamento / Análise
<o trabalho de fato — confronto entre dados, raciocínio, evidências>

## Conclusão
<resposta direta à pergunta de investigação, sem rodeios>

## Próximas ações
<!-- Cada ação estratégica pode virar item de backlog via /backlog add -->
- [ ] <ação 1> — owner: <quem>, deadline: <quando>
- [ ] <ação 2>

## Notas / observações
<contexto adicional, citações verbatim, links>
```

## Passo 4 — Confirmar e oferecer próximas ações

```
✓ Análise criada: Backlog/analises/<dd-mm-aaaa>/<arquivo>.md

Próximas ações possíveis:
- "Gera relatório" — derive um relatório dessa análise para destinatário específico via /relatorio from <arquivo>.
- "Cria itens de backlog" — para cada ação estratégica em "Próximas ações", abro via /backlog add.
- "Pronto" — fecho aqui.
```

## Regras

- **Pasta do dia obrigatória.** Mesmo que só tenha 1 análise no dia, fica em `<dd-mm-aaaa>/`.
- **Cada análise é individual.** Se o usuário quer responder 2 perguntas diferentes no mesmo dia, são 2 arquivos.
- **Slug ASCII e curto.** Não use o título inteiro.
- **Não invente** dados, conclusões ou fontes. Se faltar info, deixe `<!-- TODO: confirmar -->`.
- **Tom técnico-executivo.** Frases curtas, números absolutos, sem jargão de consultoria.
- **Datas absolutas.** No frontmatter e no corpo, `2026-05-18`, nunca "hoje".
