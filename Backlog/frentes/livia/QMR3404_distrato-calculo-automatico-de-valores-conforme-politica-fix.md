---
id: QMR3404
title: Distrato — Cálculo automático de valores conforme política fixa
frente: livia
status: em-curso
prioridade: media
fonte: quimera+jira
quimera: 3404
jira: IAF-163
categoria: Cobrança
deliverable_type: Outros
story_points: 2
tipo_origem: Subtarefa
responsavel: João Pedro
criada: 2026-04-27
concluida: null
prazo: 2026-06-12
prazo_estimado: True
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: [QMR3394]
tags: [fonte-quimera-jira, cat-cobranca]
---

# QMR3404 — Distrato — Cálculo automático de valores conforme política fixa

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3404 · Jira IAF-163 · categoria: Cobrança

Implementar a política fixa de cálculo de distrato definida no escopo (IAF-138).

## Critério de aceite

* Função pura `calcular_distrato(contract)` retorna breakdown:

    * Valor remanescente
    * Multa contratual (% configurável)
    * Logística reversa (Intel Post)
    * Total a pagar pelo cliente
    
* Testes unitários cobrindo: contrato no início, no meio, próximo ao fim, com inadimplência, sem inadimplência
* Política configurável (não hardcoded) — pode ser ajustada sem deploy

## Rastreabilidade

- **Responsável:** João Pedro
- **Quimera:** #3404 (status fonte mapeado → `em-curso`)
- **Jira:** IAF-163 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-04-27
- **Prazo (estimado):** 2026-06-12
- **Subtarefa de** (bloqueia): QMR3394 — convertida de subtarefa Jira IAF-153

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.