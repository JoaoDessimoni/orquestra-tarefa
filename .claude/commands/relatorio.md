---
description: Cria relatório individual em Gestao/Analises/<dd-mm-aaaa>/Relatorio/. Cada relatório é derivado de uma análise (ou criado do zero) e tem destinatário definido. Pasta Relatorio/ é criada automaticamente dentro da pasta do dia.
---

# /relatorio — criar relatório individual

`$ARGUMENTS` define o subcomando:

| Forma | O que faz |
|---|---|
| `/relatorio` (vazio) | Pergunta: derivar de análise existente ou criar do zero? |
| `/relatorio from <caminho-da-analise.md>` | Deriva relatório a partir de análise. Pré-preenche frontmatter e seções. |
| `/relatorio new "<título>"` | Cria relatório do zero, sem análise-fonte. |

## Passo 1 — Identificar análise-fonte (se `from`)

Se subcomando = `from`:
1. Verifique se o arquivo existe via Read.
2. Extraia frontmatter: `title`, `data`, `tipo`, `fontes-consultadas`, `relacionadas`.
3. Use a mesma data da análise para a pasta do dia (relatório fica no MESMO dia).

Se `new` ou vazio sem análise-fonte:
1. Pergunte via `AskUserQuestion`: título, data (default hoje), destinatário.
2. `analise-fonte` no frontmatter fica `null`.

## Passo 2 — Inputs adicionais

Pergunte (em 1 chamada `AskUserQuestion`):

1. **Destinatário** (ex: "Time de negócio", "Vinícius Cunha", "Jéssica + Mateus"). Se desconhecido, deixa `<a confirmar>`.
2. **Classificação**: `interno | restrito | público` (default `interno`).
3. **Janela do conteúdo** — opcional, ex: "tickets 1871..1699" ou "demandas de 15/05 a 18/05".

## Passo 3 — Gerar slug e caminho

- `slug = kebab-case("relatorio-" + título)` (ASCII).
- `pasta-dia = dd-mm-aaaa` derivada da data.
- `caminho = Gestao/Analises/<dd-mm-aaaa>/Relatorio/<YYYY-MM-DD>_<slug>.md`.

Se a pasta `Relatorio/` não existir dentro de `<dd-mm-aaaa>/`, **crie** ao escrever o primeiro arquivo (Write resolve isso).

Se já existir, sufixar com `-2`, `-3`.

## Passo 4 — Criar arquivo

Use Write com este template:

```markdown
---
title: <título>
data: <YYYY-MM-DD>
destinatario: <quem recebe>
analise-fonte: <caminho da análise ou null>
owner: João Vinícius
status: rascunho               # rascunho | revisao | enviado
classificacao: interno         # interno | restrito | publico
janela: <opcional — ex: "tickets de 13/05 a 18/05">
tags: []
---

# <título>

**Para:** <destinatário>
**De:** João Vinícius — Supervisor IAF
**Data:** <data legível>
**Classificação:** <classificacao>

## Sumário executivo
<2-4 linhas: o que este relatório responde, principais números, principal recomendação. Direto. Sem preâmbulo.>

## Status por item
<tabela ou lista detalhada. Para report de demandas, uma linha por ticket/item.>

| <coluna 1> | Status | Previsão honesta | Responsável | Observação |
|---|---|---|---|---|
| <item> | <status> | <quando ou "depende de…"> | <quem> | <1 linha> |

## Bloqueios
<o que está travado e por quê. Quem precisa destravar.>

## Pendências geradas
<!-- Cada item pode virar pendência via /pendencia add -->
- <pendência 1>
- <pendência 2>

## Próximos checkpoints
<quando o supervisor volta com atualização. Datas absolutas.>

## Notas
<contexto adicional, citações verbatim, fontes, links>
```

## Passo 4.5 — Atualizar board

Após criar o arquivo do relatório, invoque o agente `board-updater` sem brief adicional. Ele reescaneia `Gestao/` e regrava o JSON inline de `BOARD.html` na raiz do Repasse. O novo relatório aparece na view "Relatórios" do board, e a análise-fonte (se houver) ganha o badge "tem relatório" na view "Análises".

## Passo 5 — Confirmar e oferecer próximas ações

```
✓ Relatório criado: Gestao/Analises/<dd-mm-aaaa>/Relatorio/<arquivo>.md

Análise-fonte: <caminho ou "criado do zero">
Destinatário: <destinatário>
Status: rascunho

Próximas ações possíveis:
- "Revisa" — releio e ajusto tom/dados.
- "Marca como enviado" — atualizo status para `enviado`.
- "Cria pendências derivadas" — abro via /pendencia add cada item.
- "Pronto" — fecho aqui.
```

## Regras

- **Relatório SEMPRE dentro de Analises/<dd-mm-aaaa>/Relatorio/**. Nunca solto.
- **Múltiplos relatórios no mesmo dia são esperados**, cada um para destinatário ou recorte diferente.
- **`status: enviado` só depois de confirmação do usuário.** Não marque sozinho.
- **Tom técnico-executivo Finza.** Sem "ótima notícia", sem "boas perspectivas". Quando incerto, declarar incerteza.
- **Previsão honesta.** Se depende de terceiros ou está bloqueado, diga isso — não invente data.
- **Datas absolutas em todo lugar.** ISO no frontmatter; podem ser legíveis no corpo.
- **Separar escopo:** se o relatório consolida itens que não são do squad IAF, marcar explicitamente "fora do escopo IAF" em vez de omitir.
