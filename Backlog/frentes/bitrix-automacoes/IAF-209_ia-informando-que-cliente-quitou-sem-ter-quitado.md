---
id: IAF-209
title: [Bitrix ID-1919] IA informando que cliente quitou sem ter quitado
frente: bitrix-automacoes
status: em-curso
prioridade: alta
fonte: jira
quimera: null
jira: IAF-209
categoria: null
deliverable_type: null
story_points: null
tipo_origem: Bug
responsavel: Leandro Marques
criada: 2026-05-19
concluida: null
prazo: 2026-06-23
prazo_estimado: True
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: []
tags: [fonte-jira]
---

# IAF-209 — [Bitrix ID-1919] IA informando que cliente quitou sem ter quitado

## Descrição (espelho — fonte: jira)

> Origem: Jira IAF-209 · categoria: null

Solicitante: João Martins  
Área Solicitante: Cobrança  
Demanda Original: Boa tarde Senhores(as)

Cliente recebeu informação por parte da Socorro provavelmente com a Esperanza em subagente no qual o cliente não possuía débitos e estava quitado.

Grato J

Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1919/](https://blips.bitrix24.com.br/crm/type/1170/details/1919/)  
Anexo/Evidência: [https://blips.bitrix24.com.br/bitrix/services/main/ajax.php?action=crm.controller.item.getFile&SITE_ID=s1&entityTypeId=1170&id=1919&fieldName=UF_CRM_95_1746795386&fileId=862205](https://blips.bitrix24.com.br/bitrix/services/main/ajax.php?action=crm.controller.item.getFile&SITE_ID=s1&entityTypeId=1170&id=1919&fieldName=UF_CRM_95_1746795386&fileId=862205)

Descrição detalhada da tarefa:  
Investigar possível falha na IA/agente Socorro, com provável uso da Esperanza como subagente, que informou incorretamente a uma cliente que não havia débitos pendentes e que o contrato/CNPJ estava quitado.

Contexto do anexo:  
A evidência mostra uma conversa no WhatsApp Business/Blip no setor de Cobrança, posteriormente transferida de bot para atendimento humano. A cliente Daiane contesta uma nova comunicação de cobrança mostrando uma mensagem anterior enviada por “Socorro N.”, na qual foi informado que, após conferência de CNPJ e contrato, estaria “tudo pago”, sem parcelas, boletos, máquinas ou suprimentos em aberto. Essa informação aparenta estar em contradição com a cobrança atual, gerando confusão para a cliente e impacto direto no processo de cobrança.

Objetivo:  
1\. Verificar os logs/conversa relacionados ao atendimento indicado no Bitrix ID 1919 e no anexo.  
2\. Identificar se a resposta incorreta partiu da IA Socorro e/ou do subagente Esperanza.  
3\. Validar quais fontes, ferramentas, integrações ou bases de consulta foram utilizadas para concluir que o cliente estava quitado.  
4\. Comparar a resposta da IA com a situação real de débitos do cliente no sistema de cobrança/CRM.  
5\. Corrigir a causa raiz da informação incorreta, caso seja falha de prompt, regra, consulta, integração, interpretação de retorno ou roteamento entre agentes/subagentes.  
6\. Sugerir ou aplicar salvaguardas para impedir que a IA confirme quitação sem evidência confiável da base oficial.  
7\. Registrar evidências da análise e orientar o time de Cobrança sobre o status final do caso.

Critério de aceite:

* Causa da informação incorreta identificada.
* Correção aplicada ou plano de correção definido.
* IA não deve informar que um cliente está quitado quando ainda há débitos ou quando a consulta não for conclusiva.
* Retorno registrado para o solicitante/time de Cobrança com a conclusão da análise.

## Rastreabilidade

- **Responsável:** Leandro Marques
- **Jira:** IAF-209 (projeto IAF)
- **Categoria fonte:** null
- **Criada:** 2026-05-19
- **Prazo (estimado):** 2026-06-23

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=jira.