---
id: IAF-11
title: [Bitrix ID-1507] Direcionamento correto de atendimentos via hyper
frente: bitrix-automacoes
status: entregue
prioridade: alta
fonte: jira
quimera: null
jira: IAF-11
categoria: null
deliverable_type: null
story_points: null
tipo_origem: Bug
responsavel: Mateus Mesquita
criada: 2026-03-17
concluida: 2026-03-24
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

# IAF-11 — [Bitrix ID-1507] Direcionamento correto de atendimentos via hyper

## Descrição (espelho — fonte: jira)

> Origem: Jira IAF-11 · categoria: null

Solicitante: Roberta Gonçalves  
Área solicitante: Ongoing  
Demanda original: Transferência incorreta por estar no setor errado. Cliente em fase de pagamento de frete sendo direcionado ao time de ongoing/gestão de carteiras, na verdade precisa ser direcionado ao time de documentação.  
Link Bitrix: [https://blips.bitrix24.com.br/crm/type/1170/details/1507/](https://blips.bitrix24.com.br/crm/type/1170/details/1507/)

Descrição detalhada (contexto e requisitos):

* Contexto: Usuários em processo de pagamento de frete estão sendo encaminhados ao time de Ongoing/gestão de carteiras, o que não corresponde ao fluxo esperado para casos de documentação/validação de pagamento de frete.
* Comportamento observado: Transferência para setor incorreto (Ongoing) quando o cliente está na fase de pagamento de frete.
* Comportamento esperado: Encaminhar automaticamente para o time de Documentação (ou fila de documentação) quando o status/intent indicar pagamento de frete/documentação pendente.

Reprodução (informações úteis para triagem):

1) Cliente inicia fluxo no hyper e chega à etapa de pagamento de frete.  
2) Sistema realiza roteamento atual e direciona para Ongoing/gestão de carteiras.  
3) Resultado: atendimento alocado ao time errado.

Impacto: Alto — provoca retrabalho, atrasos na conclusão do pagamento de frete e afeta experiência do cliente, além de sobrecarregar o time de Ongoing com casos de documentação.

Sugestão de investigação/ações iniciais:

* Revisar as regras de roteamento/intent no hyper relacionadas a pagamento de frete e documentação.
* Verificar condições/flags utilizadas para identificar 'fase de pagamento de frete' e garantir que o mapeamento aponte para a fila de Documentação.
* Fornecer logs ou exemplos de tickets/UIDs para validar o fluxos (se possível, solicitar exemplos ao solicitante).
* Implementar testes automatizados no fluxo de roteamento para evitar regressões.

Urgente: Sim

Prioridade sugerida: 2

Observações adicionais: caso o time precise, solicitar ao(a) solicitante exemplos de atendimentos específicos para facilitar a reprodução.

## Rastreabilidade

- **Responsável:** Mateus Mesquita
- **Jira:** IAF-11 (projeto IAF)
- **Categoria fonte:** null
- **Criada:** 2026-03-17
- **Concluída:** 2026-03-24

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=jira.