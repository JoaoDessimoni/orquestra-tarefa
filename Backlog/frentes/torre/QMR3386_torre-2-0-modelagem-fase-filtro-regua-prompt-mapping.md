---
id: QMR3386
title: [Sprint 2] Torre 2.0: Modelagem fase/filtro/régua → prompt mapping
frente: torre
status: cancelado
prioridade: media
fonte: quimera+jira
quimera: 3386
jira: IAF-145
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

# QMR3386 — [Sprint 2] Torre 2.0: Modelagem fase/filtro/régua → prompt mapping

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3386 · Jira IAF-145 · categoria: Cobrança

## Contexto

Primeira peça da Torre 2.0. Definir o modelo de dados que mapeia condições da régua de cobrança (fase, filtro, dias em atraso, etc.) para qual prompt o agente deve usar naquele momento.

## Critério de aceite

* Schema definido (tabelas/colunas novas no Supabase)
* Migration criada (passa pelo fluxo dev/PR/prod)
* Modelo suporta no mínimo: filtro por dias em atraso, filtro por fase contratual, sobrescrita manual via tag
* Documentação do modelo (relacionamento prompt ↔ régua/filtro)

## Dependência

Bloqueado pela spec técnica IAF-139 (Sprint 1).

## Apoio

* Marcos Rodrigues (régua e gestão de carteira)
* Joao Lucas (revisão técnica)

## Prazo

22/mai/2026

## Epic

IAF-130

## Rastreabilidade

- **Responsável:** João Vinícius Dessimoni
- **Quimera:** #3386 (status fonte mapeado → `cancelado`)
- **Jira:** IAF-145 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-04-27

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.