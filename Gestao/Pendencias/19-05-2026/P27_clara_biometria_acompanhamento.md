---
id: P27
title: Implementar envio e acompanhamento de biometria pela Clara
status: aberta
prioridade: alta
origem: Roadmap IA & Automações 18/05/2026 — reunião revisão geral com Jéssica
owner: João Vinícius
criada: 2026-05-19
deadline: 2026-06-30
tags: [clara, formalizacao, biometria, jessica]
---

## Contexto

Clara deve cuidar de envio e acompanhamento de biometria. Primeiro passo é identificar o gatilho atual de envio do link de biometria ao cliente — sem entender o gatilho, qualquer implementação de acompanhamento é especulativa. Depois disso, Clara executa acompanhamento se cliente não concluir biometria em 2 horas.

Vinculada à iniciativa RM14 do Roadmap (frente Clara).

## Proposta

1. **Identificar gatilho atual** — qual evento de plataforma dispara envio do link de biometria? Quem envia hoje (humano? automação? sistema)? Qual canal (SMS, WhatsApp, e-mail)?
2. **Reproduzir/integrar** — Clara passa a ser o canal de envio, ou observa o envio existente.
3. **Acompanhamento pós-envio (2h)** — se cliente não concluir biometria em 2h, Clara entra com:
   - Chamada de atenção (lembrar pendência).
   - Orientações sobre boas práticas (formato foto, iluminação, documento aceito).
   - Suporte humanizado para resolução de dificuldade.
4. **Métricas** — taxa de conversão pré e pós-Clara.

## Quem depende

- Time de Plataformas — gatilho atual e fluxo de biometria.
- Provedor de biometria — entender restrições e capacidades.
- Time Clara — implementação.

## Histórico

- 2026-05-19 — Aberta. Origem: análise mestre do Roadmap 2026Q3 (RM14) consolidando reunião revisão geral com Jéssica de 18/05/2026.

## Próxima ação

Mapear gatilho atual de envio de biometria com time de Plataformas. Bloqueia o resto.
