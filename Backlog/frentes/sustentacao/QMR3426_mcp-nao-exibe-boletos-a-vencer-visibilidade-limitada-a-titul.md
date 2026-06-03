---
id: QMR3426
title: MCP não exibe boletos a vencer — visibilidade limitada a títulos vencidos
frente: sustentacao
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3426
jira: IAF-189
categoria: Cobrança
deliverable_type: Outros
story_points: 3
tipo_origem: História
responsavel: Leandro Marques
criada: 2026-05-11
concluida: 2026-06-02
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

# QMR3426 — MCP não exibe boletos a vencer — visibilidade limitada a títulos vencidos

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3426 · Jira IAF-189 · categoria: Cobrança

Quando o MCP consulta dados de um contato via /api/ai/agent-context, recebe apenas títulos com days_overdue > 0 (já vencidos),          
  ignorando boletos com vencimento futuro (cobrança preventiva D-7, D-1, etc.).

  O frontend da Torre exibe todos os títulos ativos independentemente de estarem vencidos ou não, usando vw_titles_live com o critério    
  removed_at IS NULL e status Disponivel. O MCP deveria ter a mesma visibilidade para conseguir:

* Informar sobre boletos que vencem em breve
* Conduzir negociações preventivas antes do vencimento
* Ter visão completa da dívida do cliente, não apenas da parte já atrasada

  Comportamento esperado: o agent-context deve retornar todos os títulos ativos (removed_at IS NULL, status Disponivel),  
  independentemente de days_overdue ser positivo ou negativo — alinhado com o filtro do frontend.

  Arquivo afetado: supabase/functions/api/routes/ai.ts (mesma rota do fix recente #42).

## Rastreabilidade

- **Responsável:** Leandro Marques
- **Quimera:** #3426 (status fonte mapeado → `entregue`)
- **Jira:** IAF-189 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-05-11
- **Concluída:** 2026-06-02

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.