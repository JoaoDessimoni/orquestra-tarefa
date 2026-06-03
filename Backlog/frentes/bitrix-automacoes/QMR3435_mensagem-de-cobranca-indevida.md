---
id: QMR3435
title: [Bitrix ID-1909] Mensagem de cobrança indevida
frente: bitrix-automacoes
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3435
jira: IAF-206
categoria: Cobrança
deliverable_type: Outros
story_points: 3
tipo_origem: Bug
responsavel: Leandro Marques
criada: 2026-05-19
concluida: 2026-05-25
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

# QMR3435 — [Bitrix ID-1909] Mensagem de cobrança indevida

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3435 · Jira IAF-206 · categoria: Cobrança

Solicitante: Cleidilene Silva  
Área Solicitante: Ongoing  
Demanda Original: Cliente está recebendo mensagens automáticas de cobrança, mesmo com título baixado na plataforma. Protocolo do envio da mensagem 1805269554842  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1909/](https://blips.bitrix24.com.br/crm/type/1170/details/1909/)

Descrição: Verificar e corrigir o fluxo de automação responsável pelo disparo de mensagens de cobrança para clientes com títulos já baixados na plataforma. A demanda indica que um cliente continuou recebendo mensagens automáticas de cobrança mesmo após a baixa do título, o que caracteriza cobrança indevida e pode gerar impacto direto na experiência do cliente e na operação de cobrança.

Pontos para análise:

* Investigar o protocolo de envio da mensagem: 1805269554842.
* Validar se a baixa do título foi corretamente registrada na plataforma antes do disparo.
* Verificar a regra/condição da automação que seleciona clientes para envio de cobrança.
* Identificar se há atraso de sincronização, falha de leitura de status do título ou ausência de validação antes do envio.
* Aplicar a correção necessária para impedir novos disparos de cobrança para títulos baixados.
* Caso aplicável, revisar outros casos semelhantes para avaliar recorrência.

Prioridade: 1

Board: Finza  
ID da Board: 10553  
Tipo de Issue: Bug/Correção - 10004  
Anexos/Links: Sem anexo informado.

## Rastreabilidade

- **Responsável:** Leandro Marques
- **Quimera:** #3435 (status fonte mapeado → `entregue`)
- **Jira:** IAF-206 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-05-19
- **Concluída:** 2026-05-25

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.