---
id: P25
title: Implementar solicitação e recebimento de comprovantes de endereço pela Clara
status: aberta
prioridade: alta
origem: Reunião Jéssica formalização 2026-05-18 14h-15h
owner: João Vinícius
criada: 2026-05-19
deadline: 2026-06-15
tags: [clara, formalizacao, comprovante, endereco, jessica]
---

## Contexto

Hoje a solicitação de comprovantes de endereço é processo manual humano. Jéssica trouxe na reunião de 18/05 (14h) que Clara assume o papel de solicitar e receber, mantendo o humano para validar e incluir na plataforma Blips. Princípio não-negociável: IA facilitadora, humano decisor.

Vinculada à iniciativa RM12 do Roadmap (frente Clara).

## Proposta

Implementar fluxo Clara:
1. Solicitar comprovantes ao cliente conforme regra vigente (3 endereços: empresa, residencial, entrega — últimos 30 dias; conta de consumo ou fatura cartão).
2. Receber arquivos enviados pelo cliente.
3. Validar formato básico (arquivo é imagem/PDF legível, não cópia escaneada).
4. Transferir para validação humana — humano valida conteúdo e inclui na plataforma Blips.
5. Acompanhar status com o cliente até inclusão confirmada.

Regras operacionais consolidadas na seção [Regras operacionais](../../Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md#regras-operacionais-referência--não-viram-pendência) da análise mestre do Roadmap.

## Quem depende

- Time de Plataforma Blips — endpoint de inclusão de comprovante.
- Compliance — validação humana e critérios de aceite.
- Time Clara — implementação do fluxo conversacional.

## Histórico

- 2026-05-19 — Aberta. Origem: análise mestre do Roadmap 2026Q3 (RM12) consolidando reunião Jéssica formalização de 18/05/2026.

## Próxima ação

Documentar fluxo end-to-end com cliente exemplo antes de codar — alinha expectativa de comportamento da Clara com Jéssica e compliance.
