---
id: QMR3398
title: [Sprint 4] Validação completa via Evaluation antes de subir Distrato/Retirada para prod
frente: livia
status: cancelado
prioridade: media
fonte: quimera+jira
quimera: 3398
jira: IAF-157
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

# QMR3398 — [Sprint 4] Validação completa via Evaluation antes de subir Distrato/Retirada para prod

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3398 · Jira IAF-157 · categoria: TI

## Contexto

Antes de liberar os prompts de Distrato e Retirada para clientes reais, rodar bateria completa de evaluation com cenários reais ou simulados pelo time Finza. Promoção para prod só com aprovação Mateus + Jéssica.

## Critério de aceite

* 30+ cenários de eval por agente (distrato, retirada)
* Pass rate ≥ 95% em ambos
* Time Finza (Felipe, J, Breno) revisou os outputs em sample
* Mateus + Jéssica aprovaram subida pra prod
* Plano de rollback documentado (volta para prompt anterior em 1 clique)
* Monitoramento intensivo nas primeiras 48h pós-deploy

## Dependência

Conteúdos completos + esteiras encadeadas.

## Prazo

26/jun/2026

## Epic

IAF-130

## Rastreabilidade

- **Responsável:** João Vinícius Dessimoni
- **Quimera:** #3398 (status fonte mapeado → `cancelado`)
- **Jira:** IAF-157 (projeto IAF)
- **Categoria fonte:** TI
- **Criada:** 2026-04-27

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.