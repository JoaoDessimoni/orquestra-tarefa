---
id: BTR06
title: Estruturar inteligências específicas por empresa/carteira na Torre
frente: torre
status: cancelado
prioridade: media
rice:
  reach: null
  impact: null
  confidence: null
  effort: null
  score: null
esforco: null
valor_negocio: medio
origem:
  pendencias: [P33]
  reunioes:
    - Gestao/Reunioes/18-05-2026/2026-05-18-alinhamento-jessica-revisao-roadmap.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM20
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: null
deadline_alvo: null
cancelado_em: 2026-05-22
absorvido_por: BTR02
dependencias: []
bloqueia: []
riscos: []
premissas: []
tags: [torre, inteligencia-especifica, jessica, personalizacao, cancelado]
---

# BTR06 — Estruturar inteligências específicas por empresa/carteira na Torre

> **STATUS: CANCELADO em 22/05/2026.** Escopo absorvido por **BTR02 — Implementação Multi-Org na Torre**. Mantido no backlog como histórico e referência de decisão.

## Motivo do cancelamento

A arquitetura atual da Torre **já suporta inteligências específicas por empresa/carteira sem duplicação de configuração**. O "perfil de IA" por carteira é composto por três camadas configuráveis de forma independente:

### 1. Conhecimento (RAG) com filtros — ponto principal

Cada documento de conhecimento pode ter um `filter_definition_id` opcional. Quando definido, o documento só é recuperado na busca semântica para contatos que atendem ao filtro. Na prática:

- "Manual de Cobrança FIDC X" → visível apenas para contatos da carteira X
- "Política de Renegociação Empresa Y" → visível apenas para CNPJ da empresa Y
- Conhecimento geral (ex: scripts de atendimento) → sem filtro, disponível para todos

O filtro é um `filter_definition` existente (os mesmos usados em campanhas/portfólios), ou seja, a granularidade é a mesma: por carteira, por status de título, por tipo de cliente, por originador, etc.

### 2. Regras (Directives)

As regras de comportamento do agente já permitem definir instruções específicas por contexto. Regras diferentes por carteira hoje exigiriam versões distintas do agente, mas a base está preparada para receber escopo de filtro (mesma mecânica do conhecimento).

### 3. Prompt base (comum)

O prompt define a personalidade e contexto geral — permanece único e compartilhado, sem duplicação.

## Endereçando os critérios de aceite originais

- **CA-1 (Definição de inteligência específica):** No modelo atual = combinação de (prompt base comum) + (regras aplicáveis) + (documentos de conhecimento acessíveis ao contato). A especificidade por empresa/carteira é controlada via filtros nos documentos e, futuramente, nas regras. Não é uma "versão separada do agente", é modulação por configuração sobre base comum — exatamente o que o roadmap propõe.
- **CA-2 (Arquitetura de perfil documentada):** O perfil de IA de uma carteira é definido como:
  ```
  Perfil(carteira) = prompt_base
                   + rules (comuns + específicas da carteira)
                   + knowledge WHERE filter_definition matches contato
  ```
  Já implementado para a camada de conhecimento (IAF-139). Regras ainda não têm escopo de filtro mas a extensão é direta.
- **CA-3 (Validação com 2-3 carteiras piloto):** Executável hoje na camada de conhecimento — cadastrar documentos com filtros apontando para 2-3 carteiras específicas e validar via "Testar busca semântica" (campo CNPJ disponível para simular o contexto do contato).

## Itens residuais — para onde foram

O que ainda falta para fechar completamente este escopo virou **subtarefas internas do BTR02 (Implementação Multi-Org na Torre)**:

- Escopo de filtro em Regras (mesmo modelo do RAG — regra com `filter_definition_id` só ativa para contatos elegíveis)
- UI de "perfil por carteira" que agrupe visualmente quais regras e conhecimentos estão ativos para uma carteira específica
- Execução da validação piloto com 2-3 carteiras reais

## Histórico

- 2026-05-22 — Item criado a partir de P33 (pendência). Status inicial: bruto.
- 2026-05-22 — **Cancelado.** Análise de arquitetura mostrou que o cenário já é coberto pela camada de conhecimento com `filter_definition_id` (multi-org). Itens residuais (filtro em Regras + UI de perfil + piloto) foram absorvidos como subtarefas internas de **BTR02 (Multi-Org)**. Mantido no backlog para rastreabilidade da decisão.

## Notas

A presença deste item arquivado serve como **documentação viva** da decisão de cancelamento — futuro gestor que ler o backlog vai entender por que BTR06 foi descartado e onde o escopo vive hoje.
