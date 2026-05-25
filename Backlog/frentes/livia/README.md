# Frente — Lívia (Jurídico / Distrato)

Itens relacionados à agente IA **Lívia**, responsável pelo domínio Jurídico e processo de Distrato na Finza.

**Sponsor padrão:** Jurídico Finza
**ID prefix:** `BLV##`

## Status atual

Frente recém-criada (22/05/2026). **Sem itens iniciais** — vai sendo populada conforme demandas do Jurídico chegam, via `/backlog add` (item bruto) ou `/backlog from-solicitacao <arquivo>` (a partir de doc formalizado).

## Escopo previsto

- Fluxos de distrato conduzidos por IA (comunicação com cliente, coleta de motivo, encaminhamento jurídico).
- Apoio jurídico durante formalização (validações pontuais, comunicação de cláusulas, esclarecimento de dúvidas).
- Compliance jurídico em interações de cobrança/renegociação (limites, tom, registro auditável).
- Integração com sistemas jurídicos internos (quando existirem).

## Princípio operacional não-negociável

**Lívia é facilitadora. Decisões jurídicas são humanas.** Em nenhum fluxo a IA decide ação judicial, encerra contrato, ou substitui parecer jurídico — apenas conduz conversa, coleta dados estruturados, encaminha para revisão humana.

## Discovery recomendado (antes de popular)

Antes de criar itens funcionais, fazer um discovery análogo ao BES05 (Esperanza) — sessão com lead jurídico para mapear:

- Casos que a Lívia deve atender (lista exaustiva).
- Casos que NÃO deve atender (limite técnico/legal/risco).
- Domínio conversacional (vocabulário, tom, restrições).
- Compliance específico do Jurídico (CDC, LGPD, regulamentação setorial).

Item de discovery deve ser o primeiro `BLV01` quando for criado.

## Fora de escopo

- Cobrança e renegociação operacional (vai para Esperanza).
- Formalização operacional (vai para Clara).
- SAC genérico (vai para Valentina).
- Decisão judicial automatizada (não está no escopo da IA — humano sempre decide).
