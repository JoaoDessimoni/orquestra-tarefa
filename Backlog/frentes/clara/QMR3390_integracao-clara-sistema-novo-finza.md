---
id: QMR3390
title: [Sprint 2] Integração Clara ↔ sistema novo Finza
frente: clara
status: cancelado
prioridade: media
fonte: quimera+jira
quimera: 3390
jira: IAF-149
categoria: Formalização
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
tags: [fonte-quimera-jira, cat-formalizacao]
---

# QMR3390 — [Sprint 2] Integração Clara ↔ sistema novo Finza

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3390 · Jira IAF-149 · categoria: Formalização

## Contexto

Sistema novo Finza (Léo + Álan) substitui Bitrix na coleta/validação de documentos e assinatura CCB. Entrega prevista: 15/mai/2026. A Clara precisa integrar com este novo sistema após o lançamento.

## Critério de aceite

* Mapear API/endpoints do sistema novo Finza
* Adaptar gatilhos da Clara (que hoje vão para Bitrix) para o novo sistema
* Status novos no sistema novo refletem corretamente no fluxo da Clara
* Documentos enviados pelo cliente são validados antes de avançar a esteira (resolve gap atual: avanço automático sem validação)
* Testado em ambiente dev com casos reais (ou mock)

## Risco

Se sistema novo atrasar (>15/mai), Sprint 2 desliza ou esta task vai pra Sprint 3.

## Apoio

* Joao Lucas (revisão técnica)
* Léo + Álan (time sistema novo Finza)

## Prazo

29/mai/2026

## Epic

IAF-130

## Rastreabilidade

- **Responsável:** João Vinícius Dessimoni
- **Quimera:** #3390 (status fonte mapeado → `cancelado`)
- **Jira:** IAF-149 (projeto IAF)
- **Categoria fonte:** Formalização
- **Criada:** 2026-04-27

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.