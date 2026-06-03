---
id: BES05
title: Investigar fluxo Esperanza — escopo, casos atendidos e domínio
frente: esperanza
fonte: backlog
status: em-refinamento
prioridade: alta
rice:
  reach: 9
  impact: 9
  confidence: 9
  effort: 2
  score: 36.45
esforco: S
valor_negocio: alto
origem:
  pendencias: [P20]
  reunioes:
    - Gestao/Reunioes/18-05-2026/2026-05-18-alinhamento-jessica-revisao-geral.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
    - Backlog/solicitacoes/Perguntas a serem respondidas & melhorias_correções IA's.txt
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM04
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-06-05
dependencias: []
bloqueia: [BES01, BES02, BES03, BES04, BES07]
riscos:
  - Lead técnico Esperanza pode estar sobrecarregado e adiar sessão — risco de cascata sobre todos os itens bloqueados.
  - Discovery sem método vira "conversa" sem entregável — precisa template e cobertura mínima.
premissas:
  - Lead técnico Esperanza (Leandro/Felipe) tem disponibilidade de 2h até 2026-06-05.
  - Documentação técnica parcial existe (`Docs/agentes/ESPERANZA_AGENT_OVERVIEW.md`) e pode ser ponto de partida.
tags: [esperanza, discovery, jessica, pre-requisito]
---

# BES05 — Investigar fluxo Esperanza — escopo, casos atendidos e domínio

## História de usuário

Como **supervisor IAF**,
quero **documento de discovery operacional/técnico da Esperanza**,
para **dar base sólida a toda evolução funcional (homologação, integração, métricas, tabulação) e parar de operar no escuro sobre o agente em produção**.

## Contexto

Anotação do caderno do supervisor pré-reunião com Jéssica e validada na reunião de 18/05/2026: **falta entendimento operacional sobre Esperanza**.

Quais casos ela atende? Quais não? Qual é o domínio real da IA? Sem esse discovery, qualquer evolução funcional (BES01, BES02, BES03, BES04) vira especulação.

**Origem reforçada:** Doc `Perguntas a serem respondidas & melhorias_correções IA's.txt` lista 14 categorias de diagnóstico que pressupõem que o supervisor entende o estado-base do agente. Sem discovery, nem o BES07 (diagnóstico massivo) tem onde começar.

Pré-requisito de várias outras iniciativas (5 itens bloqueados). **RICE 36.45 — provavelmente o item mais alavancado da frente Esperanza.**

## Critérios de aceite

- **CA-1** — Given 1h+ agendada com lead técnico Esperanza, When sessão acontece, Then é estruturada por template (não conversa aberta).
- **CA-2** — Given documento publicado em `Gestao/Analises/`, When supervisor revisa em isolamento, Then consegue responder com clareza: "que casos a Esperanza atende?", "que casos NÃO atende?", "qual o domínio conversacional?", "quais pontos cegos?".
- **CA-3** — Given documento, When squad referencia em discussão de outro item (ex: BES03), Then é citado como fonte (não como "ah, achei que era assim").
- **CA-4** — Given casos NÃO atendidos identificados, When listados, Then cada um vem com razão (limite técnico / decisão de produto / risco / falta de integração).

## Dependências cruzadas

- **Bloqueia:** BES01 (homologação), BES02 (imputação), BES03 (volume transferências), BES04 (tabulações), BES07 (diagnóstico massivo). **5 itens.**

## Observações PO

**Pontos de atenção:**

1. **Maior alavanca da frente.** RICE 36.45 destoa do resto justamente porque é pré-requisito — destrava muita coisa por baixo custo (S).
2. **Discovery sem método vira conversa sem entregável.** Por isso ST-1 (template) é não-negociável.
3. **Tem doc canônico em `Docs/agentes/ESPERANZA_AGENT_OVERVIEW.md`.** O discovery NÃO é começar do zero — é preencher gaps. Se o doc já está completo o suficiente, este item pode ser muito menor (XS) e virar "leitura crítica + 1 sessão de gaps".
4. **Risco real: lead técnico (Leandro) sobrecarregado.** Se sessão é adiada 2 semanas, 5 itens param. Tratar com prioridade temporal mesmo que RICE seja outro recorte.

## Definição de pronto

- [ ] Sessão executada (gravada idealmente)
- [ ] Documento publicado em `Gestao/Analises/<data>/`
- [ ] Validação com lead técnico concluída
- [ ] Squad referencia o documento em ao menos 1 outra discussão

## Histórico

- 2026-05-22 — Item criado a partir de P20 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM04) consolidando anotações de caderno e reunião com Jéssica de 18/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 36.45 destaca alavanca. Esforço: S. Template de entrevista marcado como subtarefa não-negociável. Adicionada ST-2 explicitando uso do doc canônico existente. Bloqueio sobre BES07 adicionado (diagnóstico massivo). Deadline alvo: 2026-06-05 (antes da janela de homologação BES01).

## Notas

Agendar 1h com lead técnico Esperanza esta semana — esse discovery não pode esperar. Destrava 5 outras iniciativas.
