---
id: QMR3292
title: [Bitrix ID-817] Erro IA dados financeiros
frente: bitrix-automacoes
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3292
jira: IAF-16
categoria: Cobrança
deliverable_type: Outros
story_points: 13
tipo_origem: Bug
responsavel: Leandro Marques
criada: 2026-03-18
concluida: 2026-04-29
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

# QMR3292 — [Bitrix ID-817] Erro IA dados financeiros

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3292 · Jira IAF-16 · categoria: Cobrança

Solicitante: Thiago Garcia (thiago.garcia@blips.com.br)  
Área Solicitante: IA  
Demanda Original: Erro IA dados financeiros  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/817/](https://blips.bitrix24.com.br/crm/type/1170/details/817/)

Descrição detalhada:  
Cliente reportou que a IA informou que restaria apenas 1 boleto para quitação do contrato, porém ao verificar o cliente (via dados financeiros) há outros boletos em aberto. Em anexo foram enviados relatos de dois ocorridos. CNPJs envolvidos:

* 43.440.358/0001-48
* 36.363.205/0001-89

Anexo (relatos/documentos): [https://blips.bitrix24.com.br/bitrix/services/main/ajax.php?action=crm.controller.item.getFile&SITE_ID=s1&entityTypeId=1170&id=817&fieldName=UF_CRM_95_1746795386&fileId=542793](https://blips.bitrix24.com.br/bitrix/services/main/ajax.php?action=crm.controller.item.getFile&SITE_ID=s1&entityTypeId=1170&id=817&fieldName=UF_CRM_95_1746795386&fileId=542793)

Reproduzir / Observações iniciais:

* Verificar quais fontes de dados (tabelas/endpoint) a IA consulta para compor o status de boletos/parcelas.
* Conferir se há problemas de frescor (staleness), agregação incorreta ou regras de negócio que filtram boletos pagos/abertos.
* Validar se os CNPJs acima retornam resultado diferente entre a base transacional e o modelo de IA.
* Incluir logs e amostras de requisições/respostas da API de IA para o(s) cliente(s) afetados.

Impacto:

* Informação incorreta ao cliente sobre boletos em aberto, podendo causar perda de confiança e problemas financeiros.

O que pedimos ao time IA e Automação:

1) Investigar a origem da discrepância entre os dados financeiros reais e a resposta da IA.  
2) Identificar se é problema de ingestão/refresh de base, regra de negócio do modelo, ou bug na consulta/consulta de agregação.  
3) Corrigir o modelo/regra ou pipeline que causa a discrepância.  
4) Documentar a causa raiz e a correção aplicada.

Dados adicionais que podem ajudar:

* IDs dos clientes (CNPJs listados acima).
* Horário aproximado dos relatos (ver anexo para datas/horários se presentes).

Prioridade sugerida: Alta (2) — não marcado como urgente, mas impacto cliente relevante.

Prazo: (não informado) - solicitar confirmação do SLA com a área solicitante se necessário.

## Rastreabilidade

- **Responsável:** Leandro Marques
- **Quimera:** #3292 (status fonte mapeado → `entregue`)
- **Jira:** IAF-16 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-03-18
- **Concluída:** 2026-04-29

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.