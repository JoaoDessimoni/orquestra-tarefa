---
id: QMR3389
title: [Sprint 2] Torre 2.0: Validação E2E — migrar prompt "cobrança 91+ dias" para a engine
frente: torre
status: cancelado
prioridade: media
fonte: quimera+jira
quimera: 3389
jira: IAF-148
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

# QMR3389 — [Sprint 2] Torre 2.0: Validação E2E — migrar prompt "cobrança 91+ dias" para a engine

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3389 · Jira IAF-148 · categoria: Cobrança

## Contexto

Primeiro caso de uso real da nova engine. Hoje o prompt de "cobrança >91 dias" é hardcoded. Migrar para o novo sistema, garantir paridade comportamental e validar fluxo completo.

## Critério de aceite

* Prompt 91+ dias cadastrado na nova UI
* Régua configurada: contratos com `dias_atraso > 90` recebem este prompt
* Teste com contrato real (ou mock) confirmando que o prompt correto é usado
* Comparação A/B: comportamento idêntico ao prompt hardcoded anterior
* Rollback documentado caso algo dê errado

## Dependência

Backend + UI prontos.

## Prazo

29/mai/2026

## Epic

IAF-130

## Rastreabilidade

- **Responsável:** João Vinícius Dessimoni
- **Quimera:** #3389 (status fonte mapeado → `cancelado`)
- **Jira:** IAF-148 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-04-27

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.