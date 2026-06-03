---
id: IAF-21
title: [Bitrix ID-1347] Solicitação FINZA para correção de Envio de Notificação Extrajudicial.
frente: bitrix-automacoes
status: entregue
prioridade: alta
fonte: jira
quimera: null
jira: IAF-21
categoria: null
deliverable_type: null
story_points: null
tipo_origem: Bug
responsavel: Marcos Rodrigues
criada: 2026-03-18
concluida: 2026-03-26
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

# IAF-21 — [Bitrix ID-1347] Solicitação FINZA para correção de Envio de Notificação Extrajudicial.

## Descrição (espelho — fonte: jira)

> Origem: Jira IAF-21 · categoria: null

Solicitante: Rodolfo Santos (rodolfo.santos@blips.com.br)  
Área Solicitante: Processos  
Demanda Original: A automação do Bitrix na raia de Notificação Extrajudicial está enfrentando problema (enviando para clientes adimplentes e IDEAL pra BLIPS e vice-versa). A área de Processos já desativou para evitar mais casos. Conversado com Mateus, decidido que deve ser uma funcionalidade presente na Torre de Cobrança. Ao finalizar, por favor, informar Jéssica, Sara e Emely.  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1347/](https://blips.bitrix24.com.br/crm/type/1170/details/1347/)

Descrição detalhada (IA e Automação):  
Contexto e problema:

* A automação responsável pelo envio de Notificação Extrajudicial está disparando mensagens para clientes em situação adimplente e também está trocando destinatários entre as filas/tags IDEAL <-> BLIPS (envio cruzado). Isso gerou a necessidade de desativar a automação para evitar contatos indevidos.
* Decisão da área: a lógica de envio deve residir na Torre de Cobrança (centralizar a regra de definição de público/segmento antes do disparo).

Comportamento atual observado:

* Notificações sendo enviadas a clientes adimplentes.
* Destinatários sendo atribuídos incorretamente entre IDEAL e BLIPS.
* Automação atualmente desativada pela área de Processos.

Comportamento esperado:

* A automação só envie Notificação Extrajudicial para clientes que preencham critérios de inadimplência estabelecidos (definir regras com Processos).
* A segmentação IDEAL vs BLIPS deve ser determinística e aplicada antes do envio, sem envios cruzados.

Impacto:

* Contatos indevidos com clientes adimplentes (reputacional e legal).
* Paralisação da rotina de notificações, impactando cobrança.
* Alta prioridade para restabelecer funcionamento correto com segurança.

Requisitos e dados necessários:

1) Regras de definição de inadimplência e critérios para Notificação Extrajudicial (solicitar definição final da área de Processos).    
2) Exemplos/IDs de clientes que receberam notificações indevidas (se disponíveis) para reproduzir o problema.  
3) Logs de execução da automação e histórico de disparos (timestamps, payloads, parâmetros de segmentação).    
4) Configurações atuais do Bitrix (workflows/raias) e das integrações com IDEAL/BLIPS.  
5) Acesso a ambientes de homologação para testes antes de reativação.

Proposta de ação (passos sugeridos):  
1) Reunir com Processos (Rodolfo/Jéssica/Sara/Emely) para confirmar regras e obter exemplos.    
2) Analisar logs e histórico para identificar causa raiz (falha na condição de segmentação, dados de cliente inconsistentes, mapeamento incorreto de filas).    
3) Implementar correção na lógica (preferencialmente centralizada na Torre de Cobrança) que determine destinatário e condição de envio antes do disparo.    
4) Criar testes automatizados e testes manuais com base em casos reais para validar comportamento (incluir casos limites).    
5) Testar em ambiente de homologação e só então reativar em produção.    
6) Monitoramento pós-reativação por X dias (sugestão: 3 dias) com rollback rápido se novos envios indevidos ocorrerem.

Critérios de aceitação:

* Não há envios para clientes que estejam adimplentes (confirmado por amostra de X clientes e logs).  
* Segmentação IDEAL vs BLIPS correta em 100% dos casos testados.  
* Processo documentado e com responsáveis definidos.  

Notificações e comunicação:

* Ao finalizar, informar Jéssica, Sara e Emely (nomes fornecidos pelo solicitante).  
* Manter Rodolfo como ponto de contato da área de Processos.

Prioridade: Urgente (solicitação marcada como urgente pela área) - Prioridade técnica sugerida: 1 (Altíssima).

Observações adicionais:

* Caso se confirme que o problema é causado por dados inconsistentes, considerar job de correção/validação de base antes de reativar.  
* Se existirem outros fluxos que dependam dessa automação, listar e avaliar risco de impactos.

## Rastreabilidade

- **Responsável:** Marcos Rodrigues
- **Jira:** IAF-21 (projeto IAF)
- **Categoria fonte:** null
- **Criada:** 2026-03-18
- **Concluída:** 2026-03-26

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=jira.