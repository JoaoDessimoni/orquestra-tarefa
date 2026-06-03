---
id: QMR3399
title: [Sprint 5] Dashboards dos 7 agentes (recuperação, tempo médio, transferências, eval pass rate)
frente: torre
status: cancelado
prioridade: media
fonte: quimera+jira
quimera: 3399
jira: IAF-158
categoria: Cobrança
deliverable_type: Outros
story_points: 3
tipo_origem: Tarefa
responsavel: João Vinícius Dessimoni
criada: 2026-04-27
concluida: null
prazo: null
prazo_estimado: False
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: []
tags: [fonte-quimera-jira, cat-cobranca]
---

# QMR3399 — [Sprint 5] Dashboards dos 7 agentes (recuperação, tempo médio, transferências, eval pass rate)

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3399 · Jira IAF-158 · categoria: Cobrança

## Contexto

Pedido de Jéssica na reunião: "preciso chegar ao ponto de saber quanto que as IAs estão recuperando vs operador". Dashboards consolidando métricas de cada agente.

## Critério de aceite

* Dashboard por agente (Esperança, Valentina, Distrato, Retirada, Clara Finza, Clara Blips, Francisco):

    * Volume de atendimentos
    * % resolvidos pela IA vs % transferidos para humano
    * Tempo médio de atendimento
    * Para cobrança: % recuperação vs operador (quando comparável)
    * Eval pass rate atual do prompt em prod
    * Curadoria pendente (avaliações que time Finza precisa revisar)
    
* Acessível via Torre (ou Grafana, se for o caso)
* Filtros: período, organização (Finza/Blips), tipo de cliente

## Apoio

* Iago Ferreira (IA2 — Grafana, Dashboards) — co-dev

## Prazo

26/jun/2026

## Epic

IAF-130

## Rastreabilidade

- **Responsável:** João Vinícius Dessimoni
- **Quimera:** #3399 (status fonte mapeado → `cancelado`)
- **Jira:** IAF-158 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-04-27

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.