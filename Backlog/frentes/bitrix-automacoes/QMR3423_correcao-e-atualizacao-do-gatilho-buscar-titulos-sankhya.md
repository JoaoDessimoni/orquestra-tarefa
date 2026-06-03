---
id: QMR3423
title: [Bitrix ID-1865] Correção e atualização do Gatilho buscar títulos Sankhya
frente: bitrix-automacoes
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3423
jira: IAF-186
categoria: Cobrança
deliverable_type: Outros
story_points: 5
tipo_origem: Bug
responsavel: João Pedro
criada: 2026-05-11
concluida: 2026-06-01
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

# QMR3423 — [Bitrix ID-1865] Correção e atualização do Gatilho buscar títulos Sankhya

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3423 · Jira IAF-186 · categoria: Cobrança

Solicitante: João Martins  
Área Solicitante: Cobrança  
Demanda Original: Bom dia Senhores(as)

Abri esse chamado anteriormente pelo formulário porém a demanda sumiu. Estou abrindo ele novamente de forma mais objetiva.

Atualmente no HyperFlow tem o gatilho de buscar títulos no Sankhya no qual puxa o campo valor desdobramento. Foi feito uma série de testes e situações pra identificar qual valor correto de coletar. O correto é o valor líquido do Sankhya. 

Com isto peço que seja ajustado neste gatilho o valor.

Além disso tem operações que não são informadas sendo uma delas Finza. Os clientes Finza não são identificados e coletados por este Gatilho.

Com isto peça que seja incluído Finza e demais que observarem não estar disponível no gatilho.

Identificamos também algumas instabilidades nessa função aonde clientes que débito não são puxados e informa uma mensagem de que não há débito gerando confusão, desgaste e inadimplência. Peço apoio no monitoramento e correção dessa conectividade.

Último ponto é que a linguagem utilizada é mais interna e pode gerar confusão para o cliente. Peço que seja alterado da seguinte maneira.

Contrato n°:  
Parcela n°:   
Identificador único: (NUFIN)  
Data vencimento:  
Valor original:  
Valor atualizado: (SE ESTIVER CORRETO)

Total original:   
Total atualizado:

Incluir gatilho na organização da Finza dentro do HyperFlow também.

Fico no aguardo, grato J.

Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1865/](https://blips.bitrix24.com.br/crm/type/1170/details/1865/)

Descrição: Corrigir e atualizar o gatilho de busca de títulos Sankhya no HyperFlow. A automação atualmente coleta o campo “valor desdobramento”, porém, após testes realizados pelo solicitante, o valor correto a ser coletado deve ser o “valor líquido” do Sankhya.

Escopo solicitado:  
1\. Ajustar o campo de valor retornado pelo gatilho para utilizar o valor líquido do Sankhya.  
2\. Verificar operações não disponíveis no gatilho, incluindo Finza, garantindo que clientes Finza sejam identificados e coletados corretamente.  
3\. Investigar e corrigir instabilidades/conectividade da função, especialmente casos em que clientes com débito não são puxados e o sistema retorna mensagem informando que não há débito, causando confusão, desgaste operacional e risco de inadimplência.  
4\. Revisar a linguagem/estrutura da mensagem retornada ao cliente para evitar termos internos e apresentar os dados no seguinte formato:

* Contrato n°:
* Parcela n°:
* Identificador único: (NUFIN)
* Data vencimento:
* Valor original:
* Valor atualizado: (se estiver correto)
* Total original:
* Total atualizado:  
  5\. Incluir o gatilho na organização da Finza dentro do HyperFlow.

Observações: Demanda marcada como urgente pelo solicitante. Impacto direto na área de Cobrança, podendo gerar confusão no atendimento, desgaste com clientes e inadimplência quando débitos existentes não são apresentados corretamente.

## Rastreabilidade

- **Responsável:** João Pedro
- **Quimera:** #3423 (status fonte mapeado → `entregue`)
- **Jira:** IAF-186 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-05-11
- **Concluída:** 2026-06-01

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.