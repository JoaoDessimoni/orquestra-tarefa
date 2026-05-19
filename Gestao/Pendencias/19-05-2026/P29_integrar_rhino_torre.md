---
id: P29
title: Integrar Rhino (novo originador) ao ecossistema operacional Torre
status: aberta
prioridade: media
origem: Roadmap IA & Automações 18/05/2026 — reunião revisão geral com Jéssica
owner: João Vinícius
criada: 2026-05-19
deadline: 2026-07-15
tags: [torre, rhino, integracao, originador, jessica]
---

## Contexto

Rhino entra como novo originador no ecossistema Finza. A Torre de Controle precisa refletir essa entrada — dashboards, relatórios e visualizações operacionais devem suportar o originador Rhino sem improviso.

Vinculada à iniciativa RM16 do Roadmap (frente Torre). Dependente de P24 (mapeamento demandas Rhino) e P15 (roteamento Rhino) para não integrar no escuro.

## Proposta

- Aguardar conclusão de P24 (entender demandas Rhino) e P15 (saber roteamento operacional).
- Levantar dados específicos do Rhino: contratos, carteiras, fluxos.
- Integrar dashboards da Torre para suportar segmentação por originador (Rhino vs Finza).
- Integrar relatórios para incluir Rhino como dimensão.
- Validar com Jéssica que a representação faz sentido operacionalmente.

## Quem depende

- P24 (mapeamento demandas Rhino) — bloqueante parcial.
- P15 (roteamento Rhino) — bloqueante parcial.
- Time de Dados — modelagem da dimensão originador.
- Time da Torre — implementação.

## Histórico

- 2026-05-19 — Aberta. Origem: análise mestre do Roadmap 2026Q3 (RM16) consolidando reunião revisão geral com Jéssica de 18/05/2026.

## Próxima ação

Aguardar P24 e P15 avançarem. Em paralelo, levantar modelo de dados atual da Torre para identificar onde a dimensão "originador" entra.
