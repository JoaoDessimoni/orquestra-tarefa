---
id: P28
title: Criar nova raia no Bitrix para visibilidade de reembolsos aos operadores
status: aberta
prioridade: alta
origem: Reunião Jéssica formalização 2026-05-18 14h-15h
owner: João Vinícius
criada: 2026-05-19
deadline: 2026-06-05
tags: [bitrix, raia, reembolso, jessica, operadores]
---

## Contexto

Operadores trabalham no Bitrix mas não há raia/coluna específica para "reembolso pendente de execução". Reembolsos ficam misturados em outras filas ou na cabeça do operador. Jéssica explicitou em 18/05 (14h) que adicionar a raia onde o operador já trabalha é onde a informação precisa estar para ser usada.

Vinculada à iniciativa RM15 do Roadmap (frente Clara). Independente de código — é trabalho de configuração no Bitrix. Sinergia direta com P26 (Clara cria entrada na raia).

## Proposta

- Definir critério de entrada na raia: cliente reprovado em compliance + entrada paga + dados de reembolso coletados.
- Definir critério de saída: reembolso confirmado em conta + cliente notificado.
- Configurar nova raia no Bitrix Cobrança 4.0 com esses critérios.
- Treinar operadores sobre o uso (ainda que mínimo — raia é autoexplicativa quando bem nomeada).
- Documentar internamente.

## Quem depende

- Admin Bitrix (TI Finza ou operações da cobrança) — quem efetivamente configura.
- P26 — Clara precisa saber criar entradas nessa raia (integração ou criação manual via API).
- Operadores Bitrix — receptores da raia.

## Histórico

- 2026-05-19 — Aberta. Origem: análise mestre do Roadmap 2026Q3 (RM15) consolidando reunião Jéssica formalização de 18/05/2026.

## Próxima ação

Descobrir quem configura Bitrix (TI ou operação) e abrir ticket de configuração da raia. Item mais "burocrático" do que técnico — pode destravar rápido.
