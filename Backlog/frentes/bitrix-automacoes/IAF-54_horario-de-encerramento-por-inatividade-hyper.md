---
id: IAF-54
title: [Bitrix ID-1623] Horário de encerramento por inatividade Hyper
frente: bitrix-automacoes
status: entregue
prioridade: baixa
fonte: jira
quimera: null
jira: IAF-54
categoria: null
deliverable_type: null
story_points: null
tipo_origem: Tarefa
responsavel: Leandro Marques
criada: 2026-04-01
concluida: 2026-04-07
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

# IAF-54 — [Bitrix ID-1623] Horário de encerramento por inatividade Hyper

## Descrição (espelho — fonte: jira)

> Origem: Jira IAF-54 · categoria: null

Solicitante: João Martins  
Área Solicitante: Cobrança  
Demanda Original: Bom dia Senhores(as)

Nós últimos dias identificamos cliente recebendo mensagem de atendimento encerrado por inatividade por volta das 00:00 ou até mais tarde que isso.

Peço que seja padronizado o envio dessa mensagem às 18:00 para os departamentos e organizações abaixo:

\--> BLIPS :  
Cobrança  
Cobrança - Suprimentos  
Cobrança Email  
Cobrança Automatizada  
FIDC  
Fallback Cobrança  
Financeiro Blips  
Financeiro Ideal  
Formalização

\--> FINZA :  
Formalização  
FIDC  
Liquidação Financeira  
Retirada de Equipamentos

Temos o departamento da IA - Financeiro no qual não precisa colocar essa mensagem caso o cliente esteja pós este horário pois a IA trabalha 24/7, somente quando a IA precisar de transferir pra um departamento depois desse horário que ela deve informar que vai enviar para um de nossos especialistas porém por estar fora de horário expediente retornaremos logo no início da jornada de trabalho.

Avaliem também a melhoria da mensagem pensando na experiência do cliente.

OBS: Todos outros departamentos criados pela equipe de Cobrança da Jéssica também deveram entrar nessa regra.

Grato J  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1623/](https://blips.bitrix24.com.br/crm/type/1170/details/1623/)  
Descrição: Demanda original: padronizar o envio da mensagem de encerramento por inatividade no Hyper para ocorrer às 18:00 nos departamentos informados de BLIPS e FINZA, evitando que clientes recebam a mensagem por volta de 00:00 ou depois.

Descrição detalhada:

* Ajustar a regra de horário de encerramento por inatividade para que a mensagem seja enviada às 18:00.
* Aplicar a regra aos departamentos listados da operação de Cobrança/Financeiro em BLIPS e FINZA, incluindo também novos departamentos criados pela equipe de Cobrança da Jéssica.
* Considerar exceção para o departamento IA - Financeiro: não enviar mensagem de encerramento por inatividade após esse horário quando o atendimento permanecer na IA, pois a operação é 24/7.
* Quando a IA - Financeiro precisar transferir para um departamento humano fora do horário de expediente, informar ao cliente que o encaminhamento será realizado e que o retorno ocorrerá no início da próxima jornada de trabalho.
* Avaliar e propor melhoria no texto da mensagem, considerando melhor experiência do cliente.
* Validar se a regra deve contemplar todos os departamentos atuais e futuros vinculados à operação de Cobrança mencionada.

Objetivo esperado:

* Eliminar disparos tardios da mensagem de encerramento por inatividade.
* Padronizar comunicação de encerramento fora do expediente.
* Preservar a operação 24/7 da IA - Financeiro com tratamento adequado para transferências após o horário comercial.

## Rastreabilidade

- **Responsável:** Leandro Marques
- **Jira:** IAF-54 (projeto IAF)
- **Categoria fonte:** null
- **Criada:** 2026-04-01
- **Concluída:** 2026-04-07

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=jira.