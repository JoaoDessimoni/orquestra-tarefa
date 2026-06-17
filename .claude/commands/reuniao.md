---
description: Cria nota de reunião em Backlog/reunioes/. Template padrão Finza com participantes, pauta, decisões, ações geradas, próximos passos. Não usa agente externo — operação direta do Claude.
---

# /reuniao — registrar nota de reunião

`$ARGUMENTS` é o tópico/título da reunião. Se vazio, pergunte via `AskUserQuestion`.

## Passo 1 — Inputs

Pergunte em uma única chamada `AskUserQuestion`:

1. **Título curto** (1 frase). Ex: "Alinhamento com Jéssica — priorização semanal".
2. **Data** (default: hoje em ISO). Se passada, peça `YYYY-MM-DD`.
3. **Participantes** (lista separada por vírgula).
4. **Pauta resumida** (1-3 bullets) — opcional, pode preencher depois.

## Passo 2 — Gerar slug e caminho

- `slug = kebab-case(título)` (ASCII, sem acento, sem espaço).
- `pasta-dia = dd-mm-aaaa` derivada da data.
- Se for 1on1 (tipo `1on1`), grave em `Backlog/1on1s/<dd-mm-aaaa>/<data>-1on1-<pessoa>.md`.
- Senão: `caminho = Backlog/reunioes/<dd-mm-aaaa>/<data>_<slug>.md`.

Pasta do dia é criada automaticamente pelo Write se não existir. Se o arquivo já existir, sufixar com `-2`, `-3`, etc.

## Passo 3 — Criar arquivo

Use Write com este template:

```markdown
---
title: <título>
data: <YYYY-MM-DD>
participantes: [<p1>, <p2>, ...]
duracao: <ex: 30min>            # opcional, preencher depois
tipo: alinhamento | 1on1 | review | brainstorm | escalation  # ajuste
tags: []                         # opcional
---

# <título>

**Data:** <data legível, ex: 15 de maio de 2026>
**Participantes:** <p1, p2>

## Pauta
- <bullet 1>
- <bullet 2>

## Discussão
<notas livres durante a reunião — preencher conforme aconteceu>

## Decisões
- <decisão 1>
- <decisão 2>

## Ações geradas
<!-- Para cada ação estratégica, criar item via /backlog add depois -->
- [ ] <ação 1> — owner: <quem>, deadline: <quando>
- [ ] <ação 2>

## Próximos passos
- <ação 1> — owner: <quem>, deadline: <quando>

## Notas / observações
<contexto, citações, links>
```

## Passo 4 — Confirmar e oferecer próximas ações

```
✓ Nota criada: Backlog/reunioes/<dd-mm-aaaa>/<data>_<slug>.md
                (ou Backlog/1on1s/<dd-mm-aaaa>/<data>-1on1-<pessoa>.md)

Próximas ações possíveis:
- "Preenche a discussão" — dite ou cole notas e eu redijo.
- "Cria itens de backlog" — para cada item em "Ações geradas", abro via /backlog add.
- "Pronto" — fecho aqui.
```

## Regras

- **Pasta do dia obrigatória.** Mesmo que só tenha 1 reunião no dia, fica em `<dd-mm-aaaa>/`.
- **Datas absolutas no nome do arquivo e no frontmatter.** `YYYY-MM-DD` no arquivo, `dd-mm-aaaa` na pasta.
- **Participantes em array YAML.** Sem espaço entre vírgulas: `[Joao, Jessica]`.
- **Slug ASCII e curto.** Não use o título inteiro.
- **Não invente** pauta/discussão/decisões. Deixe placeholders se o usuário não ditou.
- **Para 1:1s recorrentes** com a mesma pessoa, tipo `1on1` → o arquivo vai para `Backlog/1on1s/<dd-mm-aaaa>/` (não `Reunioes/`).
