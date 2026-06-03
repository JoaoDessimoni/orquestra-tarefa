---
id: QMR3291
title: [Bitrix ID-615] Projeto IA atendimento Nível 1 em 100% dos atendimentos de cobrança
frente: bitrix-automacoes
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3291
jira: IAF-15
categoria: Cobrança
deliverable_type: Outros
story_points: 13
tipo_origem: Tarefa
responsavel: Leandro Marques
criada: 2026-03-18
concluida: 2026-05-06
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

# QMR3291 — [Bitrix ID-615] Projeto IA atendimento Nível 1 em 100% dos atendimentos de cobrança

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3291 · Jira IAF-15 · categoria: Cobrança

Solicitante: Jessica Felipe (jessica.felipe@finza.com.br)  
Área solicitante: Cobrança  
Demanda Original: Projeto IA atendimento Nível 1 em 100% dos atendimentos de cobrança  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/615/](https://blips.bitrix24.com.br/crm/type/1170/details/615/)

Contexto e problema:

* Atualmente a plataforma Hyper (Hyperflow) aciona a IA apenas no primeiro contato com o cliente. Em casos de atendimentos transferidos de outros departamentos, as IAs (Esperanza e Valentina) não são acionadas.
* Como consequência, um volume significativo de casos de baixa complexidade está sendo direcionado ao time de especialistas humanos da Cobrança, aumentando custo operacional e tempo de atendimento.

Objetivo da demanda:

* Permitir que as IAs Esperanza e Valentina sejam acionadas também em atendimentos recebidos via transferência entre setores, garantindo que a triagem automática ocorra em 100% dos atendimentos de cobrança antes de encaminhar ao time de especialistas.

Escopo esperado / Requisitos mínimos:

1) Avaliar compatibilidade/configuração na plataforma Hyperflow para acionar as IAs em interações transferidas (não apenas no primeiro contato);  
2) Implementar a lógica necessária para que, ao receber um atendimento transferido para Cobrança, as IAs Esperanza e Valentina sejam executadas e decidam se o caso segue para atendimento humano;  
3) Garantir que apenas após o crivo (verificação/triagem) das IAs o caso seja encaminhado ao time de especialistas;  
4) Definir critérios de decisão/thresholds que as IAs devem utilizar para encaminhar para especialistas (ex.: confiança abaixo de X% ou intents de alta complexidade);  
5) Testes em ambiente de homologação com amostras de transferências reais e validação pós-implementação;  
6) Plano de rollback/mitigação caso a alteração impacte negativamente outros pipelines ou cause regressão;  
7) Entregáveis: documentação das mudanças, plano de testes, cronograma estimado para implementação e métricas alvo (ex.: redução de X% nas transferências para especialistas, aumento de Y% de atendimentos resolvidos por IA).

Criticidade / Prioridade:

* Urgente. Solicitante indicou necessidade imediata. Prioridade atribuída: 1 (altíssima).

Observações e pedido ao time de IA/Automação:

* Encaminhar essa solicitação ao time da Hyperflow (contato/portal de suporte) para avaliação de viabilidade técnica e solicitamos estimativas de prazo.
* Confirmar dependências (ex.: versão da plataforma Hyperflow, necessidade de alteração de roteadores/flows, eventos de transferência que disparam a IA).
* Informar risco de impacto em outras integrações/pipelines e necessidade de comunicação com times remetentes das transferências.

Solicitação de retorno:

* Por favor, estruturar a solicitação junto ao time da Hyper e posicionar a área solicitante quanto aos prazos previstos para implementação.

Anexo original:

* (Nenhum arquivo anexado ao Bitrix)

## Rastreabilidade

- **Responsável:** Leandro Marques
- **Quimera:** #3291 (status fonte mapeado → `entregue`)
- **Jira:** IAF-15 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-03-18
- **Concluída:** 2026-05-06

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.