---
id: IAF-48
title: [Bitrix ID-1303] Retirar os avisos de cobrança
frente: bitrix-automacoes
status: entregue
prioridade: media
fonte: jira
quimera: null
jira: IAF-48
categoria: null
deliverable_type: null
story_points: null
tipo_origem: Tarefa
responsavel: Mateus Mesquita
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

# IAF-48 — [Bitrix ID-1303] Retirar os avisos de cobrança

## Descrição (espelho — fonte: jira)

> Origem: Jira IAF-48 · categoria: null

Solicitante: Emily Ribeiro (emilly.ribeiro@blips.com.br)  
Área solicitante: IA  
Demanda Original: Retirar os avisos de cobrança, pois o boleto do cliente foi prorrogado, porém a IA ainda manda mensagens de cobrança  
Link Bitrix (anexo): [https://blips.bitrix24.com.br/bitrix/services/main/ajax.php?action=crm.controller.item.getFile&SITE_ID=s1&entityTypeId=1170&id=1303&fieldName=UF_CRM_95_1746795386&fileId=695683](https://blips.bitrix24.com.br/bitrix/services/main/ajax.php?action=crm.controller.item.getFile&SITE_ID=s1&entityTypeId=1170&id=1303&fieldName=UF_CRM_95_1746795386&fileId=695683)

Descrição detalhada (para Time de IA e Automação):  
Contexto:

* Cliente: Eliseu Greniski (CNPJ 38.428.706/0001-21) / telefone +55 42 99975 8264
* Protocolo: 1802267894750
* Conversa registrada em 18/02 (mensagens e áudio). Atendimento transferido com observação de cobrança indevida.
* Nota no atendimento: Bot registrou interação "Feito por: Bot -18/02 - 10:10".

Problema reportado:

A IA/automação continua enviando avisos de cobrança mesmo após o boleto do cliente ter sido prorrogado (ou após alteração/cancelamento do vencimento). Isso resulta em mensagens de cobrança indevidas para o cliente.

Objetivo:  
Identificar por que o disparo de avisos de cobrança não foi suprimido após a prorrogação/alteração do boleto e aplicar correções para que, em casos de prorrogação, cancelamento ou ajuste de vencimento, a IA não envie cobranças automáticas indevidas.

O que verificar / passos sugeridos:  
1) Reproduzir o caso com o histórico do cliente (usar protocolo e timestamps do anexo) para checar o fluxo de decisão que aciona a mensagem de cobrança.  
2) Validar origem dos dados de vencimento (sistema financeiro / base de dados) usados pelo orquestrador/engine que decide envios. Conferir se há atraso na atualização do status (prorrogado/cancelado) que pode gerar envios indevidos.  
3) Checar regras/flags que desabilitam envios (ex.: flag "prorrogado", "cancelado", status de boleto) e se o conector/cron respeita essas flags.  
4) Revisar templates e filas de disparo (agendamentos pendentes) para remover/atualizar envios já agendados quando houver alteração no vencimento.  
5) Verificar logs de envio e tarefas agendadas entre 18/02 e datas relacionadas para identificar envios ocorridos indevidamente.  
6) Implementar correção: garantir que alterações de vencimento/cancelamento provoquem cancelamento/occultamento dos avisos pendentes (sincronização imediata ou retry com debounce), ou bloquear envios se houver alteração no prazo nas últimas X horas.  
7) Propor uma proteção adicional: sinalizar manualmente casos transferidos/abertos por atendimento para bloquear envios até que o caso seja resolvido.  
8) Testes e rollout: criar casos de teste automatizados cobrindo alteração de vencimento e garantir rollback/monitoramento após deploy.

Critérios de aceitação:

* Em caso de prorrogação/alteração de vencimento/cancelamento, nenhum aviso de cobrança é enviado após a mudança para os clientes afetados.
* Logs demonstram que o envio foi cancelado ou não disparado após a alteração.
* Procedimento documentado para atendimento bloquear envios manualmente quando necessário.

Informações adicionais (do anexo):

* Imagem do chat com transferência do atendimento e observação: "Resumo Atendimento Esperança: O cliente Eliseu está reclamando de cobranças automáticas indevidas..." (ver link do anexo para captura completa).

Solicitante sugere: Remover/pausar os avisos de cobrança para o cliente em questão até apuração. Se for necessário, permitir bloqueio manual pelo time de atendimento.

Prioridade sugerida: Média (3) - não marcado como urgente pelo solicitante, porém tem impacto em experiência do cliente e deve ser resolvido com prioridade moderada.

## Rastreabilidade

- **Responsável:** Mateus Mesquita
- **Jira:** IAF-48 (projeto IAF)
- **Categoria fonte:** null
- **Criada:** 2026-03-26
- **Concluída:** 2026-04-06

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=jira.