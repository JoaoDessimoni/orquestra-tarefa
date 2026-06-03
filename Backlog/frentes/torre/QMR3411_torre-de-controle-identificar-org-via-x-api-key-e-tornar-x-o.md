---
id: QMR3411
title: Torre de Controle: identificar org via x-api-key e tornar x-org-slug opcional em integrações/webhooks
frente: torre
status: em-curso
prioridade: media
fonte: quimera+jira
quimera: 3411
jira: IAF-171
categoria: TI
deliverable_type: Outros
story_points: 5
tipo_origem: Tarefa
responsavel: Marcos Rodrigues
criada: 2026-04-29
concluida: null
prazo: 2026-06-17
prazo_estimado: True
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: []
tags: [fonte-quimera-jira, cat-ti]
---

# QMR3411 — Torre de Controle: identificar org via x-api-key e tornar x-org-slug opcional em integrações/webhooks

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3411 · Jira IAF-171 · categoria: TI

## Objetivo

Atualizar o sistema de **Integrações e Webhooks** da Torre de Controle para que o header `x-org-slug` deixe de ser obrigatório e que as APIs passem a identificar a organização da requisição diretamente pela `x-api-key` enviada.

## Contexto

* As **API keys são criadas dentro de cada org**, ou seja, toda chave já tem vínculo com uma organização.
* Hoje os endpoints exigem `x-org-slug` no header, o que é redundante (e fonte de erro) quando a `x-api-key` já carrega essa informação.
* Se atualmente **não houver vínculo registrado** entre `api_key` e `org` no banco/modelo, esse vínculo precisa ser **adicionado/garantido** como parte desta tarefa.

## Escopo

### 1. Modelo / Banco

* Garantir que cada `api_key` tem referência clara à `org` que a criou.
* Caso o relacionamento não exista hoje, adicionar a coluna/relacionamento e fazer backfill das chaves existentes.

### 2. APIs (Integrações + Webhooks)

* Tornar `x-org-slug` **opcional** no header.
* Implementar resolução automática da org a partir da `x-api-key`:

    * Validar a chave
    * Recuperar a org dona da chave
    * Usar essa org como contexto da requisição
    
* Quando `x-org-slug` for enviado:

    * **Validar consistência** com a org da api key
    * Se divergente → retornar 403 (api key não pertence à org informada)
    

### 3. Compatibilidade

* Manter backwards compatibility para integrações antigas que ainda enviam `x-org-slug`.
* Não quebrar webhooks/integrações em uso.

## Critérios de aceite

* \[ \] Tabela/relacionamento `api_keys ↔ orgs` confirmado (ou criado, se ausente)
* \[ \] Endpoint de webhooks aceita requisições só com `x-api-key` (sem `x-org-slug`)
* \[ \] Endpoints de integrações aceitam requisições só com `x-api-key` (sem `x-org-slug`)
* \[ \] Quando ambos forem enviados, retorno é 403 se a api key não pertencer ao slug informado
* \[ \] Webhooks/integrações existentes continuam funcionando sem alteração
* \[ \] Documentação interna da API atualizada refletindo que `x-org-slug` é opcional

## Observações

* Conferir o módulo `IntegrationsModule` da Torre (hooks `useApiKeys`, page `IntegrationsPage`) e edge functions de webhook (`receive-webhook`, `dispatch-webhook`, `ai-conversation-webhook`).
* Em caso de dúvida sobre a arquitetura da Torre, alinhar com Joao Lucas Freitas (tech leader / Torre de Controle).

## Rastreabilidade

- **Responsável:** Marcos Rodrigues
- **Quimera:** #3411 (status fonte mapeado → `em-curso`)
- **Jira:** IAF-171 (projeto IAF)
- **Categoria fonte:** TI
- **Criada:** 2026-04-29
- **Prazo (estimado):** 2026-06-17

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.