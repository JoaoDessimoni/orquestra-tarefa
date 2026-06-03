---
id: QMR3420
title: [Bitrix ID-1859] Cobrança Indevida
frente: bitrix-automacoes
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3420
jira: IAF-183
categoria: Cobrança
deliverable_type: Outros
story_points: 5
tipo_origem: Bug
responsavel: Leandro Marques
criada: 2026-05-11
concluida: 2026-05-12
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

# QMR3420 — [Bitrix ID-1859] Cobrança Indevida

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3420 · Jira IAF-183 · categoria: Cobrança

Solicitante: João Vinicius Dessimoni  
Área Solicitante: IA  
Demanda Original: Mensagem do João Martins: Este CNPJ 59615808000126 teve cobrança hoje de um título já pago pela Esperanza, porém quando eu olho na torre de controle ele está com as informações corretas e pagas. Achei estranho e fui fazer o teste no playground e novamente mesmo estando certo na torre cobrou uma parcela já paga. Consegue verificar?

Precisamos encontrar exatamente de onde a Esperanza tira os dados para cobrar e comparar com a torre para entender o ponto de divergência, pode ser o ETL talvez que esteja causando disparidade nos dados durante um curto momento e dentro dessa janela a esperanza esta cobrando errado.

Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1859/](https://blips.bitrix24.com.br/crm/type/1170/details/1859/)  
Anexo: [https://blips.bitrix24.com.br/bitrix/services/main/ajax.php?action=crm.controller.item.getFile&SITE_ID=s1&entityTypeId=1170&id=1859&fieldName=UF_CRM_95_1746795386&fileId=848951](https://blips.bitrix24.com.br/bitrix/services/main/ajax.php?action=crm.controller.item.getFile&SITE_ID=s1&entityTypeId=1170&id=1859&fieldName=UF_CRM_95_1746795386&fileId=848951)

Descrição detalhada da tarefa:  
Investigar ocorrência de cobrança indevida realizada pela Esperanza para o CNPJ 59615808000126, onde um título/parcela já pago ou renegociado foi cobrado novamente. Segundo o solicitante, a Torre de Controle apresenta as informações corretas, com o título marcado como pago, porém a Esperanza realizou cobrança mesmo assim. O comportamento também foi reproduzido em teste no playground, indicando possível divergência entre a fonte de dados utilizada pela Esperanza e a Torre de Controle.

Objetivos da investigação:  
1\. Identificar exatamente qual fonte, endpoint, tabela, fluxo, ETL ou integração a Esperanza utiliza para obter dados de cobrança.  
2\. Comparar os dados consumidos pela Esperanza com os dados exibidos na Torre de Controle para o CNPJ 59615808000126 e para o título/parcela em questão.  
3\. Verificar se existe defasagem, atraso de sincronização, inconsistência temporária ou falha no ETL que possa gerar uma janela em que a Esperanza recebe dados desatualizados e executa cobrança incorreta.  
4\. Analisar o caso descrito no anexo, em que a cliente Adriana informa que um título foi renegociado e não deveria constar como em atraso, e o bot transfere para atendimento humano para validação do histórico da renegociação.  
5\. Corrigir a origem da divergência encontrada, evitando novas cobranças de parcelas já pagas ou renegociadas.  
6\. Se aplicável, propor validações adicionais na automação da Esperanza antes do disparo de cobrança, garantindo que títulos pagos/renegociados não sejam cobrados indevidamente.

Impacto: demanda urgente, pois envolve cobrança indevida a cliente, possível inconsistência de dados financeiros e risco de recorrência em outros CNPJs.

## Rastreabilidade

- **Responsável:** Leandro Marques
- **Quimera:** #3420 (status fonte mapeado → `entregue`)
- **Jira:** IAF-183 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-05-11
- **Concluída:** 2026-05-12

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.