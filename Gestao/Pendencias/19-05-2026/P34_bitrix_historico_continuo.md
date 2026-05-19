---
id: P34
title: Automação Bitrix Cobrança 4.0 — histórico contínuo
status: aberta
prioridade: media
origem: Roadmap IA & Automações 18/05/2026 — reunião revisão geral com Jéssica
owner: João Vinícius
criada: 2026-05-19
deadline: 2026-06-30
tags: [bitrix, automacao, historico, jessica, cobranca]
---

## Contexto

No Bitrix Cobrança 4.0, os campos da seção "Histórico de Atendimento" funcionam hoje em modo de sobrescrita — um preenchimento elimina o anterior. Isso destrói rastro operacional. Jéssica trouxe em 18/05 a necessidade de transformar esses campos em formato de log acumulado (histórico contínuo).

Vinculada à iniciativa RM21 do Roadmap (frente Automações). Não confundir com P28 (raia Bitrix de reembolso) — são dois projetos paralelos no mesmo sistema.

## Proposta

- Levantar quais campos da seção "Histórico de Atendimento" sofrem sobrescrita.
- Avaliar impacto em consumidores atuais desses campos (relatórios, exports, integrações).
- Decidir abordagem: alterar campos para multi-valor com timestamp, ou adicionar campo paralelo que acumula histórico.
- Implementar via admin Bitrix ou via automação custom.
- Migrar dados históricos existentes (se relevante).
- Testar com operadores piloto antes de generalizar.

## Quem depende

- Admin Bitrix — configuração / desenvolvimento.
- Consumidores dos campos atuais — não quebrar relatórios existentes.
- Operadores Bitrix — adaptação ao novo formato.

## Histórico

- 2026-05-19 — Aberta. Origem: análise mestre do Roadmap 2026Q3 (RM21) consolidando reunião revisão geral com Jéssica de 18/05/2026.

## Próxima ação

Levantar campos afetados e impacto em consumidores — qualquer mudança em campo de Bitrix tem cauda longa de consumidores.
