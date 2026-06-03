---
id: QMR3338
title: [Bitrix ID-663] Automação de envio de formulário de atualização cadastral semestral
frente: clara
status: cancelado
prioridade: media
fonte: quimera+jira
quimera: 3338
jira: IAF-81
categoria: Formalização
deliverable_type: Outros
story_points: 8
tipo_origem: Tarefa
responsavel: Marcos Rodrigues
criada: 2025-11-14
concluida: null
prazo: null
prazo_estimado: False
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: []
tags: [fonte-quimera-jira, cat-formalizacao]
---

# QMR3338 — [Bitrix ID-663] Automação de envio de formulário de atualização cadastral semestral

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3338 · Jira IAF-81 · categoria: Formalização

Demanda original:  
Solicitante: Sinara Martins (sinara.martins@blips.com.br)  
Área: Jurídico  
Descrição original: Olá, tudo bem?

Solicito uma automação, para que seja enviada uma mensagens contendo um formulário para atualização cadastral a todos nossos clientes a cada 6 meses.  Nesse momento o alvo do disparo seria todos os clientes com mais de 6 meses de contrato ativo. Após esse formulário voltar atualizado, seria vinculado automaticamente na plataforma.  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/663/](https://blips.bitrix24.com.br/crm/type/1170/details/663/)

Descrição detalhada (para o time de IA e Automação):  
Criar uma automação que execute as seguintes etapas:  
1) Seleção de alvo: identificar todos os clientes com mais de 6 meses de contrato ativo. Requisitos: confirmar qual campo/tabela contém a data de início do contrato ou a flag de contrato ativo e critérios exatos (ex.: >180 dias a partir de data_base).  
2) Agendamento: rodar o disparo periodicamente a cada 6 meses para cada cliente (ou executar job diário que verifica clientes cujo último disparo/formulário aceito tem >=6 meses). Definir se o critério é tempo desde início do contrato ou tempo desde último envio/atualização.  
3) Canal e template de mensagem: enviar mensagem contendo um formulário para atualização cadastral. Confirmar canal(s) desejado(s): WhatsApp (via BLiPS), e-mail, SMS ou outro. Fornecer template de mensagem e link do formulário (ou usar formulário nativo). Garantir personalização com dados do cliente.  
4) Formulário: definir campos obrigatórios/optativos no formulário, validações e modelo (ex.: endereço, telefone, documentos, dados bancários se aplicável). Definir comportamento em caso de respostas parciais.  
5) Recebimento e vinculação: quando o cliente responder, os dados devem ser validados e vinculados automaticamente na plataforma. Especificar como será feito o vínculo: anexar PDF do formulário ao registro do cliente, atualizar campos específicos na base (tabela X, campos Y), ou ambos. Definir mapeamento de campos e regras de negócio (ex.: sobrescrever somente se campo não vazio, manter histórico, criar log de mudanças, auditoria).  
6) Rastreabilidade e logs: registrar sucesso/erro de cada envio e retorno, criar métricas de entregabilidade, respostas e falhas. Notificações para time responsável em casos de erro crítico.  
7) Tratamento de consentimento e opt-out: garantir respeito a opt-outs e consentimentos de comunicação. Validar exigências legais (LGPD) e manter registro do consentimento.  
8) Performance e limites: considerar volume de clientes, throttling por canal (rate limits), tentativas/retries e backoff.  
9) Testes e rollout: plano de testes (ambiente de homologação), enviar para lote piloto antes de envio em massa, validar mapeamento e vinculação.  
10) Critérios de aceitação:

* Automação identifica corretamente clientes elegíveis (>6 meses) e dispara o formulário no canal acordado.
* Respostas do formulário são capturadas e vinculadas automaticamente ao registro do cliente conforme mapeamento definido.
* Logs de envio/recebimento disponíveis e erros reportados.
* Respeito a opt-outs e LGPD.

Informações pendentes/necessárias (favor confirmar):

* Canal(s) desejados para envio (WhatsApp / e-mail / SMS / outro).
* Modelo e campos do formulário (e ex. URL do formulário, se já existir).
* Onde e como os dados devem ser vinculados na plataforma (tabela/entidade/ID de sistema).
* Critério exato de elegibilidade (data de início do contrato, último envio, outros).
* Volume estimado de clientes alvo para dimensionamento.
* Se há preferências por horários/janelas de envio.

Observação: demanda não marcada como urgente. Prioridade sugerida: Média (3).

## Rastreabilidade

- **Responsável:** Marcos Rodrigues
- **Quimera:** #3338 (status fonte mapeado → `cancelado`)
- **Jira:** IAF-81 (projeto IAF)
- **Categoria fonte:** Formalização
- **Criada:** 2025-11-14

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.