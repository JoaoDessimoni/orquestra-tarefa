---
id: IAF-47
title: [Bitrix ID-1309] Automação dentro de gestão de carteiras - enviar contratos com atraso >91 dias para distrato
frente: livia
status: cancelado
prioridade: alta
fonte: jira
quimera: null
jira: IAF-47
categoria: null
deliverable_type: null
story_points: null
tipo_origem: Tarefa
responsavel: Mateus Mesquita
criada: 2026-03-26
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

# IAF-47 — [Bitrix ID-1309] Automação dentro de gestão de carteiras - enviar contratos com atraso >91 dias para distrato

## Descrição (espelho — fonte: jira)

> Origem: Jira IAF-47 · categoria: null

Solicitante: Renato Riscifina (renato.riscifina@blips.com.br)  
Área Solicitante: IA  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1309/](https://blips.bitrix24.com.br/crm/type/1170/details/1309/)

Demanda original:  
"É necessário que os contratos que tem um atraso superior a 91 dias sejam enviados ao funil de distrato, uma vez que ficam em aberto no funil de gestão de carteiras sem tomada de ação."

Descrição detalhada da tarefa:  
Criar uma automação no processo de gestão de carteiras que identifique contratos com atraso superior a 91 dias e mova (ou crie um card) automaticamente para o funil de distrato. A automação deve considerar os seguintes pontos:

* Critério de seleção: contratos com idade de atraso > 91 dias (a fonte do campo de atraso deve ser especificada: nome da tabela/coluna ou origem no sistema de gestão de carteiras). Se houver dúvidas sobre como é calculado o atraso, alinhar com o time de negócios para confirmar a regra (ex.: dias corridos vs. dias úteis, considerar renegociações, suspensões, etc.).
* Ação esperada: mover o contrato do funil de gestão de carteiras para o funil de distrato ou criar um card/registro no funil de distrato, preservando histórico e campos relevantes (status, data do último contato, valor em atraso, id do contrato, responsável atual).
* Frequência da automação: definir se a verificação será diária, horário específico ou em evento (recomendado: execução diária com janela de execução fora do horário de pico).
* Backfill/retroatividade: decidir se a automação deve rodar inicialmente para verificar contratos já existentes com >91 dias e mover conforme regra (recomendado: rodar backfill controlado com logs/rollbacks).
* Segurança e validações: garantir que não haja movimentos automáticos indevidos (ex.: contratos com acordos ativos ou em tratativa). Incluir exceções/whitelist de contratos que não devem ser movidos automaticamente.
* Logs e auditoria: registrar todas as ações (quem/quando/por qual rotina), possibilitar reversão manual e incluir rastreabilidade para atendimento a dúvidas.
* Notificações: notificar o time responsável e/ou dono do contrato quando um contrato for movido para distrato (e.g., via e-mail, Slack ou comentário no card).
* Testes e homologação: criar ambiente de testes e conjunto de casos de teste (incluindo contratos próximos de 91 dias, exatamente 91, 92, com acordos, etc.). Validar com time de negócios antes de rodar em produção.
* Rollout: planejar implantação gradual e monitoramento nas primeiras execuções para evitar impactos indevidos.

Dados esperados/informações necessárias ao time técnico (insira se já disponíveis ou solicitar ao solicitante):

* Onde está armazenado o indicador de atraso (tabela, coluna, API ou campo no Bitrix/CRM).
* Regras de negócio detalhadas sobre exceções (acordos, renegociações, suspensão de cobrança, etc.).
* Campos que devem ser preservados ou preenchidos no funil de distrato.
* Usuários/donos que devem receber notificações.

Prazo solicitado: Urgente (solicitante marcou como urgente)

Observações adicionais:  
Favor alinhar com Renato Riscifina para confirmação das fontes de dados e regras de exceção antes de iniciar a implementação.

## Rastreabilidade

- **Responsável:** Mateus Mesquita
- **Jira:** IAF-47 (projeto IAF)
- **Categoria fonte:** null
- **Criada:** 2026-03-26

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=jira.