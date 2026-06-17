---
title: Alinhamento Jéssica — formalização (Clara, biometria, reembolso, raia Bitrix)
data: 2026-05-18
participantes: [Jéssica (Gerente Cobrança), João Vinícius]
duracao: 1h
tipo: alinhamento
tags: [jessica, clara, formalizacao, biometria, reembolso, bitrix, raia, operacao]
pendencias-geradas: [P25, P26, P27, P28]
---

# Formalização — Jéssica (2026-05-18 14h-15h)

Segunda reunião do dia, dedicada à formalização (Clara). Continuação de `2026-05-18_alinhamento-jessica-revisao-geral.md`.

## Decisões

1. **Clara opera em 3 fluxos:** comprovantes, reprovados, biometria. Um item de backlog por fluxo.
2. **Princípio "IA facilitadora, humano decisor"** — não-negociável em todos os 3 fluxos.
3. **Raia Bitrix de reembolso** é pendência de processo (configuração no Bitrix), não de código.
4. **Regras operacionais** ficam em `Backlog/analises/19-05-2026/` como seção de referência — não viram pendências.

## Fluxos especificados

| Fluxo | Clara faz | Humano faz |
|---|---|---|
| Comprovantes de endereço | Solicita (3 endereços, últimos 30 dias) + recebe + transfere | Valida + inclui na Plataforma Blips |
| Reprovados em formalização | Comunica negativa + solicita dados de reembolso (banco/agência/conta/PIX CNPJ) | Executa o reembolso |
| Biometria | Identifica gatilho atual + acompanha se não concluir em 2h (lembrete, orientações) | — |

## Pendências geradas

| ID | Descrição | Prioridade | Deadline |
|---|---|---|---|
| P25 | Clara: comprovantes de endereço | alta | 2026-06-15 |
| P26 | Clara: tratativa de reprovados | alta | 2026-06-15 |
| P27 | Clara: biometria (depende de mapear gatilho atual) | alta | 2026-06-30 |
| P28 | Raia Bitrix de reembolsos (configuração) | alta | 2026-06-05 |

## Próximos passos

- Definir owner da raia Bitrix (TI Finza ou operações cobrança).
- Mapear gatilho atual de biometria antes de codar o acompanhamento.
- Validar com compliance que comunicação automática de reprovação não tem fricção jurídica.

## Notas

- Jéssica enfatizou: IA pode coletar, organizar, comunicar e acompanhar — **não pode aprovar, rejeitar ou movimentar dinheiro**.
- Raia Bitrix é paralela à automação de histórico contínuo (RM21/P34) — projetos independentes no mesmo sistema.
- Conexão com diretoria 15/05: fechar Clara é o primeiro grande marco visível da jornada do cliente.
