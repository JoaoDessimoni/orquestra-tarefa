---
id: QMR3297
title: [Bitrix ID-1341] Solicitação Prioridades Vinicius Cunha - 3°
frente: bitrix-automacoes
status: entregue
prioridade: alta
fonte: quimera+jira
quimera: 3297
jira: IAF-22
categoria: Cobrança
deliverable_type: Outros
story_points: 8
tipo_origem: Bug
responsavel: João Lucas Freitas
criada: 2026-03-18
concluida: 2026-04-05
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

# QMR3297 — [Bitrix ID-1341] Solicitação Prioridades Vinicius Cunha - 3°

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3297 · Jira IAF-22 · categoria: Cobrança

Solicitante: joao.martins@blips.com.br (João Martins)  
Área Solicitante: Cobrança  
Demanda Original:  
Boa tarde Senhores segue formalização da demanda passada no grupo dia 26/02/2026.

3️⃣ Ajustes no CRM (Bitrix)  
Garantir atuação correta do time, com espelhamento fiel da base da Torre de Controle.

Para que a base de cobrança ativa pelo time de cobrança(humano) seja idêntica a torre refletindo a realidade atingindo o público correto.

att;

Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1341/](https://blips.bitrix24.com.br/crm/type/1170/details/1341/)

Descrição detalhada (para Time de IA e Automação):

Objetivo:

* Garantir que a base de cobrança ativa apresentada no CRM (Bitrix) esteja perfeitamente espelhada com a base fonte "Torre de Controle", de modo que o público listado para o time de cobrança humano seja idêntico ao da Torre.

Escopo inicial:

* Analisar o processo de sincronização/espelhamento entre Torre de Controle e Bitrix (pontos de integração, ETL/ELT, APIs, jobs agendados, scripts de transformação).
* Identificar divergências entre as duas bases (quantitativas e qualitativas) e suas causas (filtros incorretos, mapeamento de campos, erros em jobs, latência, registros duplicados/excluídos).
* Propor e aplicar correções para garantir a consistência contínua (reconciliação automática, monitoramento, alertas).

Entregáveis esperados:

1) Relatório diagnóstico com evidências das principais discrepâncias (amostras, contagens, logs) e localização do problema (query/endpoint/job responsável).  
2) Lista de correções propostas (alterações em queries, filtros, jobs, tratamento de dados) com estimativa de esforço e riscos.  
3) Implementação das correções em ambiente de homologação e plano de validação.  
4) Script ou processo de reconciliação periódico (ex.: job diário) que compara Torre x Bitrix e gera alertas quando divergência > X% ou > N registros.  
5) Testes e validação com sample de usuários; deploy em produção com rollback claro.

Critérios de aceitação (exemplos):

* Contagem total de registros ativos no CRM = contagem na Torre de Controle ± tolerância definida (sugerir 0-1% inicialmente).
* Para um conjunto de 100 registros amostrados, 100% dos IDs e status correspondam entre as bases.
* Logs de sincronização sem erros críticos nas últimas 24h (após correção).

Dados e informações necessárias do solicitante para avançar rapidamente:

* Exemplos de casos onde o público divergiu (IDs ou prints) e datas/hora do ocorrido.
* Informação sobre o processo atual: hora/frequência da sincronização, se é push da Torre ou pull do Bitrix, e endpoints/queries utilizados (se disponíveis).
* Nome do responsável técnico na Torre de Controle e no CRM para alinhamento.

Prioridade e prazo:

* Urgente (solicitado como urgente). Prioridade no Jira definida como 1 (Altíssima).
* Recomenda-se resposta inicial dentro de 24 horas para início da investigação.

Observações adicionais:

* Se houver dependência de outros times (dados/tower infra), incluir os contatos e abrir sub-tasks com o time de Dados, caso necessário.
* Caso a demanda seja sobre regras de negócio (quem deve entrar na base ativa), garantir alinhamento com o time de Negócios/Cobrança antes de aplicar filtros.

Solicitante para contato: joao.martins@blips.com.br

## Rastreabilidade

- **Responsável:** João Lucas Freitas
- **Quimera:** #3297 (status fonte mapeado → `entregue`)
- **Jira:** IAF-22 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-03-18
- **Concluída:** 2026-04-05

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.