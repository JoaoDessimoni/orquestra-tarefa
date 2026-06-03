---
id: QMR3384
title: [Sprint 1] Spec técnica Torre 2.0: Prompts adaptáveis por régua + Sistema de Evaluation
frente: torre
status: entregue
prioridade: media
fonte: quimera+jira
quimera: 3384
jira: IAF-139
categoria: Cobrança
deliverable_type: Outros
story_points: 5
tipo_origem: Tarefa
responsavel: Leandro Marques
criada: 2026-04-27
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

# QMR3384 — [Sprint 1] Spec técnica Torre 2.0: Prompts adaptáveis por régua + Sistema de Evaluation

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3384 · Jira IAF-139 · categoria: Cobrança

## Contexto

Decisão arquitetural: Distrato e Retirada NÃO serão agentes separados — serão **prompts que o agente da Torre recebe baseado em fase de régua/filtro**. Além disso, time de negócio precisa de **sistema de evaluation** para testar versões antes de subir para prod.

Sem essa spec aprovada, Sprint 2 (desenvolvimento) não inicia.

## Escopo da spec

### Engine de prompts adaptáveis

* Modelagem: como mapear fase/filtro/régua → prompt específico
* Backend: troca de prompt em runtime baseado em condição (ex: 91+ dias no contrato → prompt distrato)
* UI: tela onde time Finza configura visualmente quais prompts ativam quando (autonomia de curadoria)
* Migração: prompt cobrança 91+ dias hoje hardcoded vira o primeiro caso de uso

### Sistema de Evaluation

* Cenários de teste: input do cliente + saída esperada
* Engine de execução em batch (rodar todos os cenários contra versão X do prompt)
* Comparação resultado vs esperado (LLM-as-judge OU regex/keyword check — definir na spec)
* Versionamento staging/prod com gate: só sobe pra prod se eval passar
* Lições do STIA evaluation (Carlos Magno construiu: IA2-1120, IA2-1145, IA2-861, IA2-907)

## Critério de aceite

* Documento técnico (\~5-10 páginas) com:

    * Modelo de dados (tabelas/colunas novas)
    * Diagramas de fluxo
    * Mockups de UI (esboço, não final)
    * Plano de migração de prompts existentes
    * Estimativa de esforço por componente
    
* Aprovado por Mateus + Joao Lucas
* Compartilhado com Marcos (régua) e Carlos Magno (eval STIA)

## Apoio

* **Marcos Rodrigues** — input sobre régua, gestão de carteira, filtros (12 das 15 últimas tasks dele são Torre)
* **Carlos Magno (IA2)** — input sobre eval STIA (lições aprendidas)
* **Joao Lucas** — revisão técnica

## Prazo

15/mai/2026 (final do sprint)

## Epic

IAF-130

## Rastreabilidade

- **Responsável:** Leandro Marques
- **Quimera:** #3384 (status fonte mapeado → `entregue`)
- **Jira:** IAF-139 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-04-27
- **Concluída:** 2026-06-02

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.