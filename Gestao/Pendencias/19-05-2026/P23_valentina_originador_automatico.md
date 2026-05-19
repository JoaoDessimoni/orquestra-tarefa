---
id: P23
title: Ajustar Valentina para identificar originador automaticamente
status: aberta
prioridade: alta
origem: Roadmap IA & Automações 18/05/2026 — reunião revisão geral com Jéssica
owner: João Vinícius
criada: 2026-05-19
deadline: 2026-06-15
tags: [valentina, originador, jessica, novas-industrias]
---

## Contexto

Valentina hoje atende como se houvesse apenas um originador. Com a Finza absorvendo novas indústrias (Rhino e outros), a IA precisa identificar o originador na entrada e personalizar atendimento. Cada originador tem contrato, fluxo e operação diferentes — atendimento genérico vira atendimento ruim.

Vinculada à iniciativa RM07 do Roadmap (frente Valentina).

## Proposta

- Levantar como o originador é identificável tecnicamente — canal de entrada, prefixo de número, payload do canal, campo de contexto da sessão.
- Implementar identificação no início da conversa.
- Configurar Valentina com "perfis" por originador (prompts, regras, vocabulário).
- Validar com algumas conversas reais que a identificação está acertando.

## Quem depende

- Time de Plataformas — como identificar originador na entrada.
- P13 (base de contexto Valentina) — alimenta os perfis por originador.
- Operação Finza — validação dos perfis por originador.

## Histórico

- 2026-05-19 — Aberta. Origem: análise mestre do Roadmap 2026Q3 (RM07) consolidando reunião revisão geral com Jéssica de 18/05/2026.

## Próxima ação

Levantar com time de Plataformas como o originador chega na entrada da Valentina — sem isso, identificação automática é palpite.
