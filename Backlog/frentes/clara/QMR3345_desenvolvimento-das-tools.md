---
id: QMR3345
title: [FRANCISCO] Desenvolvimento das tools
frente: clara
status: entregue
prioridade: media
fonte: quimera+jira
quimera: 3345
jira: IAF-90
categoria: Formalização
deliverable_type: Outros
story_points: 3
tipo_origem: Subtarefa
responsavel: João Pedro
criada: 2026-04-09
concluida: 2026-04-12
prazo: null
prazo_estimado: False
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: [IAF-49]
tags: [fonte-quimera-jira, cat-formalizacao]
---

# QMR3345 — [FRANCISCO] Desenvolvimento das tools

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3345 · Jira IAF-90 · categoria: Formalização

O cérebro do agente - RAG, tools de negócio, contexto e o modelo em si. É aqui que mora o valor do produto.

- [x] Integração RAG (Base de Conhecimento) - importação RAG via vector store, sendo possível utilização do STIA para treinamento.
- [x] Tools de negócio - `buscar_contrato`, `buscar_ultima_conexao`, `buscar_bloqueio`, `buscar_desbloqueio`, `buscar_financeiro_cliente`, `buscar_liberacao_confianca`, `buscar_telemetria_uso`.
- [x] Montagem de contexto e prompt - Monta Contexto (busca as últimas mensagens e gera histórico para contexto), carregamento do prompt via GitHub, merge com histórico.
- [x] Francisco (AI Agent) - node principal, conexão das tools, parâmetros e variante.

## Rastreabilidade

- **Responsável:** João Pedro
- **Quimera:** #3345 (status fonte mapeado → `entregue`)
- **Jira:** IAF-90 (projeto IAF)
- **Categoria fonte:** Formalização
- **Criada:** 2026-04-09
- **Concluída:** 2026-04-12
- **Subtarefa de** (bloqueia): IAF-49 — convertida de subtarefa Jira IAF-49

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.