---
id: QMR3422
title: [Bitrix ID-1863] Adicionar email alternativo pra disparos cobrança Blips
frente: torre
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3422
jira: IAF-185
categoria: Cobrança
deliverable_type: Outros
story_points: 5
tipo_origem: Tarefa
responsavel: João Pedro
criada: 2026-05-11
concluida: 2026-05-12
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

# QMR3422 — [Bitrix ID-1863] Adicionar email alternativo pra disparos cobrança Blips

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3422 · Jira IAF-185 · categoria: Cobrança

Solicitante: João Martins  
Área Solicitante: Cobrança  
Demanda Original: Precisamos ajustar o fluxo no n8n de envio de email, principalmente da Blips, pra usar mais de um email e evitar bloqueios. O Miqueias disponibilizou outro email pra usarmos e dividir o volume de envio (boletos@blips.com.br)  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1863/](https://blips.bitrix24.com.br/crm/type/1170/details/1863/)

Descrição: Ajustar o fluxo de automação no n8n responsável pelo envio de emails de cobrança, principalmente relacionados à Blips, para permitir o uso de mais de uma conta/remetente de email. O objetivo é dividir o volume de disparos entre os emails disponíveis e reduzir o risco de bloqueios por volume ou reputação.

Escopo esperado:

* Localizar o fluxo/cenário no n8n utilizado para disparos de email de cobrança da Blips.
* Incluir/configurar o email alternativo disponibilizado por Miqueias: boletos@blips.com.br.
* Implementar uma lógica de distribuição de envios entre o email atual e o novo email alternativo, conforme viabilidade técnica do fluxo.
* Validar que os disparos continuam ocorrendo corretamente após a alteração.
* Garantir que a mudança não interrompa os envios de cobrança existentes.

Observações:

* Não foi informado link direto do fluxo no n8n.
* Demanda marcada como urgente pelo solicitante.

## Rastreabilidade

- **Responsável:** João Pedro
- **Quimera:** #3422 (status fonte mapeado → `entregue`)
- **Jira:** IAF-185 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-05-11
- **Concluída:** 2026-05-12

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.