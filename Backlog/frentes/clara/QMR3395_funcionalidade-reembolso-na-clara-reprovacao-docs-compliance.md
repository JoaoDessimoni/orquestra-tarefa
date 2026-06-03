---
id: QMR3395
title: [Sprint 3] Funcionalidade reembolso na Clara (reprovação docs/compliance)
frente: clara
status: cancelado
prioridade: media
fonte: quimera+jira
quimera: 3395
jira: IAF-154
categoria: TI
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
tags: [fonte-quimera-jira, cat-ti]
---

# QMR3395 — [Sprint 3] Funcionalidade reembolso na Clara (reprovação docs/compliance)

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3395 · Jira IAF-154 · categoria: TI

## Contexto

Quando cliente é reprovado em validação de documentos OU em compliance (etapas Finza), a Clara precisa atuar para fazer o distrato + reembolso financeiro. Decisão de reunião: NÃO é agente separado, é funcionalidade dentro da Clara.

## Critério de aceite

* Clara detecta reprovação (sinal do sistema novo Finza)
* Coleta dados bancários do cliente para reembolso
* Abre processo de distrato (link com IAF-XXX Distrato Sprint 3)
* Notifica time financeiro Finza para processar reembolso
* Comunica cliente em linguagem clara sobre o que acontecerá

## Dependência

* Integração Clara ↔ sistema novo Finza (Sprint 2)
* Fluxo de distrato funcional (mesmo Sprint)

## Apoio

* Rian Silveira (IA2) — co-dev Clara

## Prazo

12/jun/2026

## Epic

IAF-130

## Rastreabilidade

- **Responsável:** João Vinícius Dessimoni
- **Quimera:** #3395 (status fonte mapeado → `cancelado`)
- **Jira:** IAF-154 (projeto IAF)
- **Categoria fonte:** TI
- **Criada:** 2026-04-27

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.