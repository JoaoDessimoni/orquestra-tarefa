---
id: QMR3397
title: [Sprint 4] Esteiras sequenciais Torre: cobrança → distrato → retirada (régua automática)
frente: livia
status: cancelado
prioridade: media
fonte: quimera+jira
quimera: 3397
jira: IAF-156
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

# QMR3397 — [Sprint 4] Esteiras sequenciais Torre: cobrança → distrato → retirada (régua automática)

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3397 · Jira IAF-156 · categoria: Cobrança

## Contexto

Conectar os 3 prompts em uma esteira sequencial: contrato avança automaticamente cobrança → distrato (>91 dias) → retirada (após distrato concluído ou após N dias sem resolução).

Pedido direto de Jéssica na reunião 22/abr: "as etapas são sequenciais, é onde a carteira de cobrança é gerida".

## Critério de aceite

* Régua transita prompts automaticamente baseado em estado do contrato
* Auditoria visível: histórico de transição de prompts por contrato
* Cliente recebe comunicação adequada na transição (não muda de tom abruptamente)
* Operador pode forçar transição manualmente via UI (caso especial)
* Cenários de eval cobrindo as 3 transições

## Dependência

Conteúdos Distrato e Retirada prontos.

## Prazo

20/jun/2026

## Epic

IAF-130

## Rastreabilidade

- **Responsável:** João Vinícius Dessimoni
- **Quimera:** #3397 (status fonte mapeado → `cancelado`)
- **Jira:** IAF-156 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-04-27

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.