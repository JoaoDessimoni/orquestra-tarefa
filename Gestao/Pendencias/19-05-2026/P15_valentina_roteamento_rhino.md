---
id: P15
title: Ajustar Valentina para roteamento Rhino → suporte Rhino (urgente)
status: aberta
prioridade: alta
origem: Reunião Diretoria 2026-05-15 — jornada cliente Finza
owner: João Vinícius
criada: 2026-05-19
deadline: 2026-05-26
tags: [valentina, rhino, urgente, roteamento, diretoria]
---

## Contexto

Diretoria sinalizou em 15/05/2026 como "o quanto antes" — não é projeto futuro, é correção urgente. Demandas vindas do originador Rhino estão sendo roteadas para o suporte genérico Finza (Valentina) em vez do suporte específico Rhino. Isso polui o atendimento Finza e priva o Rhino do contexto adequado.

Vinculada à iniciativa RM09 do Roadmap (frente Valentina). Deadline mais curto de todo o ciclo (1 semana).

## Proposta

- Mapear como o originador Rhino é identificável tecnicamente na entrada da Valentina (canal, numero, prefixo de mensagem, contexto da sessão).
- Implementar regra de roteamento: se originador = Rhino, transferir para o fluxo de suporte Rhino dedicado.
- Validar com operação que o "suporte Rhino" existe operacionalmente e está pronto para receber.

## Quem depende

- Time de Operação Finza — mapeamento do fluxo Rhino existente.
- Time de Plataformas — implementação do roteamento.
- Suporte Rhino — confirmar capacidade de absorver volume.

## Histórico

- 2026-05-19 — Aberta. Origem: análise mestre do Roadmap 2026Q3 (RM09) consolidando reunião com diretoria de 15/05/2026.

## Próxima ação

Alinhar com operação Finza onde fica o "suporte Rhino" e qual é o fluxo de transferência atual. Sem isso, qualquer ajuste de roteamento é meia-implementação.
