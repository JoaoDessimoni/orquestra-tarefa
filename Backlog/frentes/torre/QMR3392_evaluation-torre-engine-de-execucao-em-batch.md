---
id: QMR3392
title: [Sprint 3] Evaluation Torre: engine de execução em batch
frente: torre
status: cancelado
prioridade: media
fonte: quimera+jira
quimera: 3392
jira: IAF-151
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

# QMR3392 — [Sprint 3] Evaluation Torre: engine de execução em batch

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3392 · Jira IAF-151 · categoria: TI

## Contexto

Mecanismo que roda todos os cenários cadastrados contra uma versão do prompt e produz relatório de pass/fail.

## Critério de aceite

* Botão "Rodar evaluation" na tela do prompt → dispara batch
* Para cada cenário: chama LLM com (prompt + contexto + input) e captura resposta
* Comparação resposta vs expected: usar **LLM-as-judge** (mais robusto para textos livres) com fallback para keyword check quando expected é estruturado
* Relatório: % pass, lista de fails com diff, tempo total
* Histórico de runs por versão de prompt
* Custo de tokens por run (transparência)

## Apoio

* Carlos Magno (IA2) — eval STIA usa abordagem similar

## Prazo

10/jun/2026

## Epic

IAF-130

## Rastreabilidade

- **Responsável:** João Vinícius Dessimoni
- **Quimera:** #3392 (status fonte mapeado → `cancelado`)
- **Jira:** IAF-151 (projeto IAF)
- **Categoria fonte:** TI
- **Criada:** 2026-04-27

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.