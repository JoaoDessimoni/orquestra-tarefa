---
id: P26
title: Implementar tratativa de reprovados em formalização (negativa + reembolso)
status: aberta
prioridade: alta
origem: Reunião Jéssica formalização 2026-05-18 14h-15h
owner: João Vinícius
criada: 2026-05-19
deadline: 2026-06-15
tags: [clara, formalizacao, reembolso, reprovado, jessica, compliance]
---

## Contexto

Fluxo atual: cliente paga entrada → entra em formalização → análise jurídica/compliance pode reprovar → cliente fica sem retorno claro + sem visibilidade do reembolso. Jéssica trouxe em 18/05 (14h) que Clara assume comunicação da negativa + coleta de dados de reembolso. Humano executa o reembolso (IA não movimenta dinheiro).

Vinculada à iniciativa RM13 do Roadmap (frente Clara). Sinergia com P28 (raia Bitrix de reembolso).

## Proposta

Implementar fluxo Clara:
1. Em retorno negativo na "Análise de Formalização", Clara comunica o cliente sobre a negativa — tom humano, não burocrático.
2. Clara solicita dados de reembolso: banco, agência, conta corrente, chave PIX (titular CNPJ).
3. Clara valida formato básico dos dados (banco existe, CNPJ bate).
4. Clara cria entrada na raia Bitrix de reembolso (P28) com os dados.
5. Operador humano executa reembolso via raia.
6. Clara acompanha e dá visibilidade ao cliente sobre o status.

Regras de coleta consolidadas na seção [Regras operacionais](../../Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md#regras-operacionais-referência--não-viram-pendência) da análise mestre.

## Quem depende

- Compliance — templates de comunicação aceitos juridicamente.
- Time financeiro — fluxo de reembolso operacional.
- P28 (raia Bitrix) — alvo de entrada da Clara.
- Time Clara — implementação.

## Histórico

- 2026-05-19 — Aberta. Origem: análise mestre do Roadmap 2026Q3 (RM13) consolidando reunião Jéssica formalização de 18/05/2026.

## Próxima ação

Validar com compliance se a comunicação automatizada de reprovação tem fricção jurídica — não codar sem essa luz verde.
