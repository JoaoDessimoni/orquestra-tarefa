---
id: IAF-2
title: [Bitrix ID-1181] IA não está classificando os cancelamentos - Painel Cancelados e PDD
frente: bitrix-automacoes
status: refinado
prioridade: alta
fonte: jira
quimera: null
jira: IAF-2
categoria: null
deliverable_type: null
story_points: null
tipo_origem: Bug
responsavel: Mateus Mesquita
criada: 2026-03-06
concluida: null
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

# IAF-2 — [Bitrix ID-1181] IA não está classificando os cancelamentos - Painel Cancelados e PDD

## Descrição (espelho — fonte: jira)

> Origem: Jira IAF-2 · categoria: null

Solicitante: bruno.garcia@finza.com.br  
Área Solicitante: Finza  
Demanda Original: O dash "Análise Cancelados" do Painel Cancelados e PDD não está mostrando a classificação dos motivos de cancelamento pela IA. Se eu filtro por Classificar: Plataforma todos os cancelamentos estão classificados. Se eu filtro por qualquer IA (IA e Nascimento, IA, Nascimento) ele apresenta um alto volume de contatos sem motivo classificado. Me parece ser que a IA não está classificando e atualizando a classificação para leitura. Por favor, verifiquem.

Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1181/](https://blips.bitrix24.com.br/crm/type/1170/details/1181/)

Detalhes observados (anexo): imagem do painel "Painel Cancelados e PDD" - filtro ativo "Análise Cancelados", data jan. de 2026. Treemap mostra "Contratos por Motivo de Cancelamento" e contador superior direito indica "Contratos sem Motivo: 208". Filtro de classificação na tela mostra opções: "CLASSIFICAR: IA E N...". Quando selecionado "Classificar: Plataforma" as classes aparecem normalmente; quando selecionado qualquer opção referente a IA (ex: "IA e Nascimento", "IA", "Nascimento") há grande volume de contratos sem motivo classificado.

Hipóteses iniciais a verificar:

* Processo de inferência/serviço de IA pode estar com falha (modelo não recebendo mensagens, erro em job agendado, serviço offline).
* Resultado da inferência pode não estar sendo persistido na tabela/coluna usada pelo painel (problema de escrita/atualização).
* Pipeline de ingestão/atualização que popula o campo de classificação pode estar com erro ou bloqueado (mensagens em fila/Kafka, jobs Airflow/DBT falhando).
* Painel (query/Looker/LookerStudio) pode estar filtrando o campo errado ou a lógica de atualização/refresh não está refletindo novos registros.
* Questões de versão do modelo (novo modelo sem mapping antigo) ou alteração no nome do campo/valores de classificação.

O que pedimos que o time verifique inicialmente:

1) Reproduzir o problema localmente no ambiente de produção: aplicar filtro por Classificar=IA e comparar com Plataforma.  
2) Checar logs do serviço de inferência/treinamento (últimas execuções, erros, throughput).  
3) Verificar a tabela/coluna onde a classificação IA é gravada (últimos registros, timestamps, contagem de nulls) e confirmar se houve writes recentes.  
4) Conferir jobs/ETL responsáveis por atualizar a classificação no dataset usado pelo painel (status dos jobs, erros, tempo da última execução).  
5) Validar se houve deploy/alteração recente no modelo, no nome de campo ou no pipeline que altere valores esperados.  
6) Se for identificação de falha na persistência ou inferência, realizar correção e, se necessário, reprocessar/backfill os contratos sem motivo (ex.: 208 casos indicados no anexo).  
7) Informar causa raiz, ação tomada e estimativa de tempo para resolução e para eventual reprocessamento/backfill.

Critérios de aceitação:

* Painel "Análise Cancelados" exibe a classificação por IA corretamente ao aplicar filtros de Classificar=IA\* (sem apresentar alto volume sem motivo).
* Logs e jobs relacionados mostram sucesso nas últimas execuções relevantes.
* Se aplicável, backfill executado e número de contratos sem motivo reduzido/reportado.

Anexos/Links:

* Imagem enviada no Bitrix: [https://blips.bitrix24.com.br/bitrix/services/main/ajax.php?action=crm.controller.item.getFile&SITE_ID=s1&entityTypeId=1170&id=1181&fieldName=UF_CRM_95_1746795386&fileId=648023](https://blips.bitrix24.com.br/bitrix/services/main/ajax.php?action=crm.controller.item.getFile&SITE_ID=s1&entityTypeId=1170&id=1181&fieldName=UF_CRM_95_1746795386&fileId=648023)

Solicitante original: Bruno Fernandes Garcia (bruno.garcia@finza.com.br)

## Rastreabilidade

- **Responsável:** Mateus Mesquita
- **Jira:** IAF-2 (projeto IAF)
- **Categoria fonte:** null
- **Criada:** 2026-03-06

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=jira.