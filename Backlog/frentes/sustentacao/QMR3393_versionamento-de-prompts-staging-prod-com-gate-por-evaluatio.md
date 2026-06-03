---
id: QMR3393
title: [Sprint 3] Versionamento de prompts (staging/prod) com gate por evaluation
frente: sustentacao
status: cancelado
prioridade: media
fonte: quimera+jira
quimera: 3393
jira: IAF-152
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

# QMR3393 — [Sprint 3] Versionamento de prompts (staging/prod) com gate por evaluation

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3393 · Jira IAF-152 · categoria: TI

## Contexto

Promover um prompt de staging para prod só é permitido se a evaluation passar (% mínimo configurável). Garante que versões ruins não subam.

## Critério de aceite

* Cada prompt tem 2 versões correntes: `staging` e `prod`
* Edição mexe sempre em `staging`
* Botão "Promover para prod" exige eval rodada com pass rate ≥ X% (config inicial: 90%)
* Logs de promoção (quem promoveu, quando, eval pass rate)
* Rollback: voltar prod para versão N-1 com 1 clique
* Auditoria: ver histórico de versões e quando foi cada promoção

## Dependência

Engine de evaluation funcional.

## Prazo

12/jun/2026

## Epic

IAF-130

## Rastreabilidade

- **Responsável:** João Vinícius Dessimoni
- **Quimera:** #3393 (status fonte mapeado → `cancelado`)
- **Jira:** IAF-152 (projeto IAF)
- **Categoria fonte:** TI
- **Criada:** 2026-04-27

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.