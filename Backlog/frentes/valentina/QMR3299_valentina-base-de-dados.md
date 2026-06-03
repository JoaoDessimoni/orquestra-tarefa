---
id: QMR3299
title: [Bitrix ID-1371] Valentina base de dados
frente: valentina
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3299
jira: IAF-24
categoria: Cobrança
deliverable_type: Outros
story_points: 8
tipo_origem: Bug
responsavel: Leandro Marques
criada: 2026-03-18
concluida: 2026-04-06
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

# QMR3299 — [Bitrix ID-1371] Valentina base de dados

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3299 · Jira IAF-24 · categoria: Cobrança

Solicitante: joao.martins@blips.com.br (João Martins)  
Área Solicitante: Cobrança  
Demanda Original:

Bom dia,

Valentina está informando que o cliente não possuí títulos em aberto porém tem. Acredito estar apontando para fonte de dados da Blips/Ideal

Evidencia protocolo:  
0503266788748  
0303267219344

Peço apoio

Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1371/](https://blips.bitrix24.com.br/crm/type/1170/details/1371/)

Descrição detalhada (para Time de IA e Automação):

Objetivo:

* Investigar e corrigir a divergência reportada pela Valentina onde o CRM/IA indica que o cliente não possui títulos em aberto, embora existam títulos ativos na fonte (Blips/Ideal).

Contexto inicial e evidências:

* Protocolos fornecidos para investigação: 0503266788748, 0303267219344.
* Suspeita de origem: inconsistência na base de dados ou no processo de leitura/transformação entre Blips/Ideal → Torre de Controle → componente de IA Valentina.

Ações sugeridas (passos iniciais):

1) Reproduzir o erro usando os protocolos fornecidos: consultar a Torre de Controle, a base Blips/Ideal e os endpoints/queries que alimentam a Valentina para verificar o fluxo completo de dados.  
2) Validar se os registros (títulos) existem na fonte (Blips/Ideal) e se foram propagados corretamente até a camada consumida pela IA (camadas ETL, filas, APIs, caches).  
3) Checar mapeamento de campos e filtros aplicados (ex.: status, flag de elegibilidade, datas de vencimento) que possam causar exclusão ou ocultação do título.  
4) Verificar logs de sincronização/erros nas últimas 24-72h e presença de falhas/latência/caches expirados no pipeline.  
5) Se identificado bug na transformação/consulta, propor correção (ajuste de query, regra de negócio, tratamento de nulos/formatos) e aplicar em ambiente de homologação.  
6) Testar a correção com os protocolos fornecidos e com amostras adicionais; validar que Valentina passa a apresentar os títulos corretamente.

Entregáveis esperados:

* Relatório de diagnóstico com evidências (queries, prints, contagens) apontando a origem da divergência.
* Correção implementada (ou plano de correção) e passos para deploy/rollback.
* Testes de validação com os protocolos fornecidos e critérios de aceitação.

Critérios de aceitação:

* Para os protocolos fornecidos, Valentina deve exibir os títulos em aberto existentes na fonte.
* Relatório com descrição clara da causa raiz e ação aplicada.

Informações necessárias do solicitante (se não disponíveis):

* Indicar exemplos adicionais (prints ou IDs) e datas/horários em que foi observado o problema, se possível.
* Confirmação se houve mudanças recentes nos processos de sincronização ou deploys na Torre/Valentina.
* Contato do responsável técnico da fonte Blips/Ideal, se necessário para investigação.

Prioridade recomendada: 1 (Altíssima) — solicitada como urgente.

Prazo sugerido: resposta inicial com diagnóstico dentro de 24 horas para início da investigação.

Solicitante para contato: joao.martins@blips.com.br

## Rastreabilidade

- **Responsável:** Leandro Marques
- **Quimera:** #3299 (status fonte mapeado → `entregue`)
- **Jira:** IAF-24 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-03-18
- **Concluída:** 2026-04-06

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.