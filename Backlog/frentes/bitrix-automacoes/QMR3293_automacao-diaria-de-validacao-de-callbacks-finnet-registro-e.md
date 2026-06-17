---
id: QMR3293
title: [Bitrix ID-861] Automação diária de validação de callbacks Finnet (Registro e Liquidação)
frente: bitrix-automacoes
status: cancelado
prioridade: alta
fonte: quimera+jira
quimera: 3293
jira: IAF-17
categoria: Cobrança
deliverable_type: Outros
story_points: 8
tipo_origem: Tarefa
responsavel: João Vinícius Dessimoni
criada: 2026-03-18
concluida: null
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

# QMR3293 — [Bitrix ID-861] Automação diária de validação de callbacks Finnet (Registro e Liquidação)

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3293 · Jira IAF-17 · categoria: Cobrança

Solicitante: leonardo@finza.com.br  
Área Solicitante: Finza  
Demanda Original: Criação de automação para validação diária de callbacks da Finnet (Registro e Liquidação)  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/861/](https://blips.bitrix24.com.br/crm/type/1170/details/861/)

Descrição detalhada:  
Implementar uma automação diária que valide a ausência de callbacks da Finnet para registros e liquidações de boletos. A automação deve:

* Suportar múltiplas empresas do grupo (parametrizável por empresa).
* Autenticar na API da Finnet usando credenciais seguras (armazenadas em cofre de segredos).
* Consultar boletos nas janelas temporais definidas (D-3 para registro e D-3 para liquidação) e identificar títulos que deveriam gerar callback mas não tiveram retorno.
* Validar, no Módulo Financeiro, se o callback correspondente (registro ou liquidação) foi recebido para cada título consultado.
* Persistir todos os erros/ocorrências/insights em estrutura dedicada no BigQuery (dataset e tabela a definir), incluindo: id do título, empresa, data do boleto, tipo de callback esperado (registro/liq), resposta da API, timestamp da validação, e metadados do processo.
* Registrar logs e métricas (execuções, número de falhas, tempo de execução) para monitoramento.
* Gerar um arquivo anexo (CSV/Excel) com os títulos impactados e enviar automaticamente um email para o contato da Finnet quando houver inconsistências, com cópia para os stakeholders internos configuráveis.
* Implementar regras de retry em caso de falha temporária de comunicação com a Finnet e alertas em caso de falhas persistentes.
* Garantir idempotência das execuções diárias e evitar duplicidade de envios/em registros.

Requisitos não funcionais:

* Segurança: credenciais em cofre, conexão TLS, logging sem dados sensíveis.
* Observabilidade: métricas expostas (Prometheus/GCP Monitoring) e logs centralizados.
* Armazenamento: BigQuery (dataset/tabela a definir) com esquema alinhado com o documento de referência.
* Documentação: seguir o DOC fornecido como referência principal.

Documentação / referência principal:

[https://docs.google.com/document/d/1AiHvZCeE7UijBGp5NHCSptrHMBKnOlPTMOlAfyYOBj0/edit?usp=sharing](https://docs.google.com/document/d/1AiHvZCeE7UijBGp5NHCSptrHMBKnOlPTMOlAfyYOBj0/edit?usp=sharing)

Acceptance criteria (mínimos):  
1) Execução diária agendada que verifica callbacks de registro e liquidação (janela D-3).  
2) Erros persistidos em BigQuery com dados mínimos listados acima.  
3) Email automático enviado para Finnet com arquivo anexo quando houver títulos impactados.  
4) Logs e métricas disponíveis para investigação e monitoramento.  
5) Execução deve ser idempotente e possuir retries configurados.

Contato/apoio:

* Solicitante: leonardo@finza.com.br

Observações adicionais:

* Ajustar dataset/tabela no BigQuery conforme arquitetura do time de dados.
* Definir lista de contatos da Finnet e modelo de email (assunto/corpo) antes da primeira execução.

## Rastreabilidade

- **Responsável:** João Vinícius Dessimoni
- **Quimera:** #3293 (status fonte mapeado → `refinado`)
- **Jira:** IAF-17 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-03-18

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.
- 2026-06-15 — Status sincronizado do Quimera #3293: cancelado. Responsável: João Vinícius Dessimoni.
