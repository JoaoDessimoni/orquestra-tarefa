---
id: BST01
title: Definir raia para tickets em validação no board Kanban
frente: estrategica
status: em-curso
prioridade: media
rice:
  reach: null
  impact: null
  confidence: null
  effort: null
  score: null
esforco: null
valor_negocio: medio
origem:
  pendencias: [P11]
  reunioes: []
  solicitacoes: []
  analises:
    - Gestao/Analises/18-05-2026/2026-05-18_demandas-cobranca-time-negocio.md
roadmap_vinculado: null
owner: João Vinícius
implementador: null
sponsor: João Lucas (Tech Lead)
criada: 2026-05-22
refinada: null
deadline_alvo: null
dependencias: []
bloqueia: []
riscos: []
premissas: []
tags: [processo, board, raia, marcos]
---

# BST01 — Definir raia para tickets em validação no board Kanban

## História de usuário

<!-- TODO: refinar via /backlog refine BST01 -->
Como **dev do squad IAF**,
quero **critério claro de raia para tickets em validação (Torre vs fora-Torre)**,
para **seguir padrão automaticamente sem precisar perguntar caso a caso**.

## Contexto

Na resposta de 15/05/2026, Marcos Rodrigues pediu orientação direta: "mesma coisa para todos os tickets em validação (devo mudar a raia?) que eram features da torre ou fix...".

Trata-se de uma decisão de processo de board (Kanban) — definir se tickets em validação que são features/fixes da Torre permanecem na raia atual ou mudam para uma raia específica (por exemplo, "Em validação Torre" vs raia geral de validação).

O ticket 1807 está nessa situação, mas Marcos sinaliza que há outros equivalentes.

## Critérios de aceite

<!-- TODO: refinar via /backlog refine BST01 -->
- CA-1: Lista de tickets atualmente em validação que são da Torre publicada.
- CA-2: Critério decidido em conjunto com Marcos e João Lucas.
- CA-3: Padrão documentado para que squad siga automaticamente.

## Subtarefas

- [ ] Conversar com Marcos para listar todos os tickets atualmente em validação que são da Torre.
- [ ] Definir critério: raia única "Em validação" ou raias separadas por contexto (Torre, fora-Torre, etc.).
- [ ] Documentar a decisão para que o squad siga o padrão automaticamente.
- [ ] Eventual conversa cruzada com João Lucas (Tech Lead) para alinhar critério com o restante do board.

## Dependências cruzadas

- Sem dependência direta de outro item de backlog.

## Riscos

<!-- TODO: levantar em refinement -->

## Premissas

- Marcos e João Lucas têm disponibilidade para decisão de processo em sessão curta.

## Definição de pronto

- [ ] Critério decidido
- [ ] Documentação publicada
- [ ] Squad treinado/comunicado

## Histórico

- 2026-05-18 — Pendência P11 aberta. Origem: análise de cruzamento das demandas do anexo com respostas do squad.
- 2026-05-22 — Item de backlog criado a partir de P11. Status: em-curso (preservado da pendência).

## Notas

Status `em-curso` preservado da pendência P11. Item de processo de board, não código. Listar com Marcos os tickets em validação (preferencialmente na próxima sync ou 1on1) e fechar critério.
