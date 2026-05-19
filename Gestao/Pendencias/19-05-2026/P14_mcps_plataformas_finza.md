---
id: P14
title: Criar MCPs das plataformas Finza para expandir Valentina e Esperanza
status: aberta
prioridade: media
origem: Reunião Diretoria 2026-05-15 — jornada cliente Finza
owner: João Vinícius
criada: 2026-05-19
deadline: 2026-07-15
tags: [mcp, valentina, esperanza, plataformas, diretoria]
---

## Contexto

Valentina e Esperanza hoje operam com contexto estático (prompt + base de conhecimento). Não têm acesso a estado operacional real do cliente (status do contrato, posição financeira, etapa da formalização do cliente em conversa). Diretoria nomeou MCPs explicitamente em 15/05/2026 como caminho de expansão — confirmando que o vocabulário técnico já circula no nível executivo.

Vinculada à iniciativa RM11 do Roadmap (frente Valentina).

## Proposta

- Inventariar plataformas Finza com APIs/dados relevantes para atendimento (Módulo Financeiro, plataforma de formalização, Bitrix, HyperFlow, AuditorIA, etc.).
- Priorizar em conjunto com time de Plataformas — o que dá mais alavanca para Valentina/Esperanza primeiro?
- Implementar servidor MCP por plataforma (ou um servidor MCP unificado expondo várias plataformas).
- Configurar Valentina/Esperanza para consumir esses MCPs.

## Quem depende

- Time de Plataformas — quem expõe os endpoints e detém o conhecimento das APIs.
- Time de Segurança — autenticação e autorização para MCPs.
- P13 (base de contexto Valentina) é complementar mas não bloqueante.

## Histórico

- 2026-05-19 — Aberta. Origem: análise mestre do Roadmap 2026Q3 (RM11) consolidando reunião com diretoria de 15/05/2026.

## Próxima ação

Reunir com lead de Plataformas para inventariar APIs candidatas e priorizar o primeiro MCP a construir.
