---
id: IAF-46
title: [Bitrix ID-1487] Desativação e correção da automação de notificações extrajudiciais (n8n)
frente: bitrix-automacoes
status: entregue
prioridade: alta
fonte: jira
quimera: null
jira: IAF-46
categoria: null
deliverable_type: null
story_points: null
tipo_origem: Tarefa
responsavel: Marcos Rodrigues
criada: 2026-03-26
concluida: 2026-04-06
prazo: null
prazo_estimado: False
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: []
tags: [fonte-jira]
---

# IAF-46 — [Bitrix ID-1487] Desativação e correção da automação de notificações extrajudiciais (n8n)

## Descrição (espelho — fonte: jira)

> Origem: Jira IAF-46 · categoria: null

Solicitante: Renato Riscifina (renato.riscifina@blips.com.br)  
Área solicitante: Jurídico  
Demanda Original: Desativação da automação que cria as notificações extrajudiciais, pois estão vindo com informações erradas para o cliente.  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1487/](https://blips.bitrix24.com.br/crm/type/1170/details/1487/)

Descrição detalhada (para Time de IA e Automação):  
1) Ação imediata

* Desativar temporariamente a automação n8n responsável pela criação/envio das notificações extrajudiciais, para evitar novos envios com informações incorretas.

2) Investigação do problema

* Revisar o fluxo n8n (nodes, mapeamentos e templates) que monta o conteúdo da notificação.
* Verificar as fontes de dados utilizadas (APIs, webhooks, banco/intermediários) e checar se o erro está vindo da origem ou do processamento/mapeamento.
* Checar logs e payloads das execuções recentes para identificar quando começou o problema e quais campos/valores estão incorretos.
* Identificar quantos e quais clientes receberam notificações com dados incorretos (impact scope).

3) Correção

* Corrigir o mapeamento/transformação ou o template que está gerando informações erradas.
* Validar correção em ambiente de teste com casos reais/sem dados sensíveis expostos.
* Reativar a automação somente após validação e liberação pelo solicitante (Jurídico).

4) Mitigações e pós-ação

* Implementar verificações/validações adicionais no fluxo (ex.: checagens de consistência de campos críticos) para evitar regressões.
* Adicionar logs e alertas (falha de template, divergência de dados) para monitoramento futuro.
* Se necessário, reprocessar/envio manual das notificações corretas para clientes afetados, conforme orientação do Jurídico.

5) Informação adicional

* Urgência: Alta (solicitado como urgente).
* Não há anexos fornecidos pelo solicitante.

Recomendações para o time:

* Priorizar desativação e investigação inicial (hotfix) antes de qualquer reprocessamento.
* Documentar causa raiz e ações tomadas no card.

## Rastreabilidade

- **Responsável:** Marcos Rodrigues
- **Jira:** IAF-46 (projeto IAF)
- **Categoria fonte:** null
- **Criada:** 2026-03-26
- **Concluída:** 2026-04-06

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=jira.