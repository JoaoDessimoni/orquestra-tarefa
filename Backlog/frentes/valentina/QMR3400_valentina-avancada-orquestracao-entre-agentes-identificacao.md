---
id: QMR3400
title: [Sprint 5] Valentina avançada: orquestração entre agentes + identificação automática empresa origem
frente: valentina
status: cancelado
prioridade: media
fonte: quimera+jira
quimera: 3400
jira: IAF-159
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

# QMR3400 — [Sprint 5] Valentina avançada: orquestração entre agentes + identificação automática empresa origem

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3400 · Jira IAF-159 · categoria: Cobrança

## Contexto

Evolução da Valentina como recepção/intermediária Finza:

1. Orquestração: identifica intenção do cliente e delega para o agente especialista (Esperança, Clara, Francisco)
2. Identificação automática de empresa origem do contrato Finza (Blips, Rino, etc.) sem perguntar ao cliente — gap mencionado por Mateus na reunião

## Critério de aceite

* Valentina conversa fluida com cliente, identifica problema e chama agente certo
* Identifica origem do contrato consultando módulo financeiro (Plataforma Blips ou sistema novo Finza)
* Quando origem confirmada, direciona corretamente para empresa que vendeu o equipamento (problemas técnicos)
* Eval cobrindo casos: cobrança → Esperança, formalização → Clara, técnico → empresa origem
* Documentado no playbook

## Dependência

* Francisco em prod (Sprint 1)
* Clara multi-org em prod (Sprint 1+)
* Sistema novo Finza integrado (Sprint 2)

## Prazo

26/jun/2026

## Epic

IAF-130

## Rastreabilidade

- **Responsável:** João Vinícius Dessimoni
- **Quimera:** #3400 (status fonte mapeado → `cancelado`)
- **Jira:** IAF-159 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-04-27

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.