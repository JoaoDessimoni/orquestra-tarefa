---
id: P18
title: Mapear volume de transferências IA→humano por departamento e agente
status: aberta
prioridade: alta
origem: Roadmap IA & Automações 18/05/2026 — reunião revisão geral com Jéssica
owner: João Vinícius
criada: 2026-05-19
deadline: 2026-06-05
tags: [esperanza, transferencias, mapeamento, jessica, dados]
---

## Contexto

Sem visibilidade hoje sobre quantas transferências IA→humano acontecem, em qual departamento, com qual agente. Gargalo operacional invisível — sem o dado, não há base para dimensionar equipes nem identificar oportunidades de automação adicional. Jéssica explicitou em 18/05/2026 como uma das prioridades altas da Esperanza.

Vinculada à iniciativa RM02 do Roadmap (frente Esperanza).

## Proposta

- Instrumentar Esperanza para emitir evento estruturado a cada transferência: timestamp, departamento destino, agente destino (se identificável), motivo da transferência, ID de sessão.
- Storage em base estruturada (com retenção razoável).
- Dashboard de volume com cortes: por departamento, por agente, por motivo, por carteira, por dia/semana/mês.
- Validação dos números com Jéssica e operação para garantir que a leitura faz sentido.

## Quem depende

- Time de Dados — storage e dashboard.
- Time Esperanza — instrumentação dos eventos.
- Jéssica — validação semântica dos dados.

## Histórico

- 2026-05-19 — Aberta. Origem: análise mestre do Roadmap 2026Q3 (RM02) consolidando reunião revisão geral com Jéssica de 18/05/2026.

## Próxima ação

Escopar evento de transferência com o time Esperanza e definir storage com time de Dados.
