---
id: P12
title: Implementar coleta de NPS no fim da jornada Finza via IA
status: aberta
prioridade: alta
origem: Reunião Diretoria 2026-05-15 — jornada cliente Finza
owner: João Vinícius
criada: 2026-05-19
deadline: 2026-06-30
tags: [nps, jornada, valentina, diretoria, satisfacao]
---

## Contexto

Diretoria identificou na reunião de 15/05/2026 que não há captura sistemática de satisfação do cliente Finza no fim da jornada (após formalização concluída). Sem esse dado, não há base quantitativa para avaliar percepção de qualidade nem para retroalimentar evoluções da IA. A IA pode ocupar esse espaço executando pesquisa no momento certo e persistindo resposta para análise.

Vinculada à iniciativa RM23 do Roadmap (frente Estratégica).

## Proposta

- Definir formato da pesquisa: NPS clássica de 1 pergunta (0-10) ou múltiplas perguntas (satisfação + esforço + comentário aberto).
- Identificar gatilho de "fim da jornada" — provavelmente status da formalização = concluída.
- Valentina (ou agente dedicado) envia mensagem com pesquisa.
- Persistir resposta em base estruturada com timestamp + identificador do cliente + carteira + originador.
- Pipeline de análise (dashboard ou relatório recorrente).

## Quem depende

- Time de Plataformas — gatilho de fim da formalização.
- Time de Dados — armazenamento estruturado das respostas + dashboard.
- Diretoria/Produto — validação do formato da pesquisa.

## Histórico

- 2026-05-19 — Aberta. Origem: análise mestre do Roadmap 2026Q3 (RM23) consolidando reunião com diretoria de 15/05/2026.

## Próxima ação

Definir formato da pesquisa em conjunto com Produto/Diretoria — sem isso, qualquer implementação fica especulativa.
