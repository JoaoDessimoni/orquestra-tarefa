---
id: P17
title: Disponibilizar imputação direta de renegociação no Módulo Financeiro
status: aberta
prioridade: media
origem: Roadmap IA & Automações 18/05/2026 — reunião revisão geral com Jéssica
owner: João Vinícius
criada: 2026-05-19
deadline: 2026-06-30
tags: [esperanza, modulo-financeiro, jessica, integracao]
---

## Contexto

Passo seguinte à P16. Após homologação operacional do fluxo "renegociação com transferência humana", abre-se caminho para a Esperanza imputar diretamente a renegociação no Módulo Financeiro sem operador humano no meio. Reduz fricção e tempo de fechamento; depende de o fluxo já estar validado e auditável.

Vinculada à iniciativa RM01 do Roadmap (frente Esperanza). Bloqueada pela P16.

## Proposta

- Aguardar conclusão da P16 (homologação).
- Escopar integração técnica entre Esperanza e Módulo Financeiro.
- Implementar trilha de auditoria — toda imputação direta da IA precisa ser rastreável.
- Definir critérios de bypass (em que casos a IA imputa direto vs. continua transferindo para humano).
- Testes em ambiente controlado antes de produção.

## Quem depende

- P16 (homologação operacional) — bloqueante.
- Time financeiro — validar fluxo de auditoria.
- Time Esperanza — implementação.

## Histórico

- 2026-05-19 — Aberta. Origem: análise mestre do Roadmap 2026Q3 (RM01) consolidando reunião revisão geral com Jéssica de 18/05/2026.

## Próxima ação

Aguardar conclusão da P16. Em paralelo, levantar requisitos de auditoria com time financeiro para não chegar na implementação sem clareza.
