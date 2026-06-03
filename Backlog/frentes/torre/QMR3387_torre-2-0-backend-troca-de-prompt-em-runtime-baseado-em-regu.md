---
id: QMR3387
title: [Sprint 2] Torre 2.0: Backend — troca de prompt em runtime baseado em régua
frente: torre
status: cancelado
prioridade: media
fonte: quimera+jira
quimera: 3387
jira: IAF-146
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

# QMR3387 — [Sprint 2] Torre 2.0: Backend — troca de prompt em runtime baseado em régua

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3387 · Jira IAF-146 · categoria: Cobrança

## Contexto

Edge Function (Supabase Deno) que, na hora de chamar o LLM, avalia a régua/filtros do contrato e seleciona o prompt correto baseado no mapeamento da IAF-XXX (modelagem).

## Critério de aceite

* Função `resolve_prompt(contract_id)` retorna o prompt ativo para aquele contrato no momento
* Cache em memória (TTL curto) para evitar lookup a cada mensagem
* Fallback seguro: se nenhuma regra casar, usa prompt default (cobrança padrão)
* Logs de qual prompt foi usado em cada interação (para auditoria)
* Testes unitários cobrindo: 0 dias atraso, 30 dias, 60 dias, 91+ dias, fase de distrato, sobrescrita manual

## Dependência

Bloqueado pela modelagem (Sprint 2 — primeira task).

## Apoio

* Joao Lucas (revisão técnica)

## Prazo

27/mai/2026

## Epic

IAF-130

## Rastreabilidade

- **Responsável:** João Vinícius Dessimoni
- **Quimera:** #3387 (status fonte mapeado → `cancelado`)
- **Jira:** IAF-146 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-04-27

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.