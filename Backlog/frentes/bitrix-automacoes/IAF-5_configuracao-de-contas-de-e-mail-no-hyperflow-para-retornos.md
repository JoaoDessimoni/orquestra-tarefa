---
id: IAF-5
title: [Bitrix ID-707] Configuração de contas de e-mail no Hyperflow para retornos de boletos
frente: bitrix-automacoes
status: entregue
prioridade: media
fonte: jira
quimera: null
jira: IAF-5
categoria: null
deliverable_type: null
story_points: null
tipo_origem: Tarefa
responsavel: Mateus Mesquita
criada: 2026-03-06
concluida: 2026-05-08
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

# IAF-5 — [Bitrix ID-707] Configuração de contas de e-mail no Hyperflow para retornos de boletos

## Descrição (espelho — fonte: jira)

> Origem: Jira IAF-5 · categoria: null

Solicitante: Jessica Felipe (jessica.felipe@finza.com.br)  
Área Solicitante: Cobrança  
Demanda Original: Configuração conta de e-mail Hyperflow  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/707/](https://blips.bitrix24.com.br/crm/type/1170/details/707/)

Descrição detalhada:

Solicitação de configuração de contas de e-mail na plataforma Hyperflow para tratamento de retornos de cobrança diretamente pela plataforma Omnichannel.

1) Contas de e-mail a serem vinculadas ao Hyperflow

* boletos@blips.com.br
* boletos@ideal.com.br
* boletos@finza.com.br

Objetivo: permitir que os retornos recebidos por essas contas sejam tratados diretamente na plataforma Omnichannel, possibilitando atendimento personalizado por mais esse canal.

2) Colaboradores que devem visualizar os protocolos gerados

* Maria Eduarda Medeiros Silva
* Felipe de Souza Domingos
* Igor Joaquim de Carvalho

Garantir que esses usuários tenham permissão para visualizar/atender os protocolos originados pelos e-mails acima na fila/canal adequado dentro do Hyperflow.

3) Regra de tratamento automático para retornos de erro  
Os e-mails de retorno com as seguintes características devem ser finalizados automaticamente (sem ação manual), pois não haverá tratativa por parte do time:

* Título/Assunto: "Delivery Status Notification (Delay)"
* Remetente: "mailer-daemon@googlemail.com"

Necessário configurar regra/filtro no fluxo do Hyperflow/Omnichannel para identificar esses casos e encerrar automaticamente o protocolo/chamado correspondente.

Observações:

* Relacionado à organização Finza na Hyperflow (há outras demandas de acesso já abertas para este cliente, como <custom data-type="smartlink" data-id="id-0">https://blips-dev.atlassian.net/browse/IA2-565#icft=IA2-565</custom>, mas esta demanda é especificamente para configuração de canais de e-mail e regras de tratamento).

## Rastreabilidade

- **Responsável:** Mateus Mesquita
- **Jira:** IAF-5 (projeto IAF)
- **Categoria fonte:** null
- **Criada:** 2026-03-06
- **Concluída:** 2026-05-08

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=jira.