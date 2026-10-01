---
title: Hyperflow — uso real vs cobrado e avaliação da proposta de novo plano
data: 2026-09-17
autor: João Vinícius
tipo: investigacao
fontes-consultadas:
  - "E-mail comercial Hyperflow (proposta de readequação de plano, vigência Meta 01/10)"
  - "blips-bigdata.bronze_hyperflow_finza.LIST_ALL_BILLS"
  - "blips-bigdata.bronze_hyperflow_finza.GET_USAGE_INFO"
  - "blips-bigdata.bronze_hyperflow_finza.GET_WABA_MESSAGE_TEMPLATES"
  - "blips-bigdata.bronze_hyperflow_finza.LIST_BROADCAST_SCHEDULE_LOGS"
  - "blips-bigdata.bronze_external_hyperflow.list_all_chats"
  - "blips-bigdata.VIEWS_DASHES.custo_hyperflow_rateio_depto"
relacionadas: []
status: rascunho
tags: [hyperflow, custo, bigquery, cobranca, fornecedor, negociacao]
---

# Hyperflow — uso real vs cobrado e avaliação da proposta de novo plano

**Data:** 17 de setembro de 2026
**Autor:** João Vinícius
**Tipo:** investigação

## Contexto

O Hyperflow enviou proposta de readequação do plano da Finza. O argumento: a mensalidade contratada é de R$ 749,00, mas o consumo efetivo dos últimos três meses foi de R$ 5.905,23, R$ 4.292,73 e R$ 2.514,80 — a diferença sai como **excedente**, com custo unitário superior ao praticado dentro da franquia. A proposta prevê migrar do formato "por conversa" para a nova modalidade de cobrança da Meta (vigência 01/10), dimensionar a quantidade de *Services* pelo histórico dos últimos três meses e ganhar previsibilidade.

O e-mail não abre a conta. Esta análise reconstrói a conta pelo BigQuery antes de qualquer resposta ao fornecedor.

## Pergunta de investigação

O que exatamente estamos consumindo e pagando no Hyperflow, e a proposta de readequação de plano resolve o problema real?

## Dados / Insumos

Projeto `blips-bigdata`, tenant FINZA. Duas tabelas sustentam a análise:

- **`bronze_hyperflow_finza.LIST_ALL_BILLS`** — faturas emitidas (13 desde ago/2025).
- **`bronze_hyperflow_finza.GET_USAGE_INFO`** — extrato de consumo diário por tipo de evento, com separação entre franquia e excedente.

Complementares: `GET_WABA_MESSAGE_TEMPLATES` (categoria Meta dos templates), `LIST_BROADCAST_SCHEDULE_LOGS` (disparo por template), `bronze_external_hyperflow.list_all_chats` (volume de atendimento) e `VIEWS_DASHES.custo_hyperflow_rateio_depto` (rateio por departamento).

**Validação:** os três valores do e-mail são exatamente as faturas de **jun, jul e ago/2026** — o e-mail listou do mais recente para o mais antigo. O consumo não está caindo; está **subindo**.

## Cruzamento / Análise

### 1. A fórmula da fatura

```
Fatura = R$ 749,00 (plano) + excedente do ciclo
```

Confirmada à vírgula em 9 dos 11 meses fechados:

| Ciclo | Excedente (uso) | Fatura | Confere |
|---|---:|---:|:--:|
| 2025-10 | 60,10 | 809,10 | ✓ |
| 2025-11 | 96,03 | 845,03 | ✓ |
| 2025-12 | 97,70 | 846,70 | ✓ |
| 2026-01 | 104,60 | 853,60 | ✓ |
| 2026-02 | 168,43 | 917,43 | ✓ |
| 2026-03 | 1.686,93 | 2.435,93 | ✓ |
| 2026-04 | 1.454,05 | 2.203,05 | ✓ |
| 2026-05 | 2.199,53 | 2.948,53 | ✓ |
| 2026-06 | 1.765,80 | 2.514,80 | ✓ |
| 2026-07 | 3.492,96 | 4.292,73 | −50,77 ¹ |
| 2026-08 | 5.071,70 | 5.905,23 | −84,53 ¹ |

¹ O snapshot do BigQuery é tirado **antes do ciclo fechar** (31/07 15h42 e 29/08 12h15 — o dia 30/08 sequer existe na tabela). A diferença de 1–2% é corte de snapshot, não divergência de cobrança.

**Total pago desde ago/2025: R$ 26.070,13 em 13 faturas.** O plano puro somaria R$ 9.737. **63% do que pagamos ao Hyperflow é excedente.** Nos últimos 3 meses a proporção sobe para **82%**.

### 2. A franquia é pequena — e desenhada para o consumo errado

O plano de R$ 749 cobre cerca de **6.505 eventos/mês**, distribuídos assim:

| Tipo de evento | Franquia/mês | Preço do excedente |
|---|---:|---:|
| `whatsapp\|activation` (disparo ativo / template) | **500** | **R$ 0,55** |
| `whatsapp\|conversation` + `connection` | ~1.000 | R$ 0,45 |
| `webhook` | ~5.005 | R$ 0,025 |
| RCS (single / activation) | **0** | R$ 0,18 / R$ 0,105 |

Preço médio **dentro** da franquia: R$ 749 ÷ 6.505 = **R$ 0,115 por evento**.
Uma activation excedente custa **R$ 0,55 — 4,8× o preço médio da franquia.**

O problema não é volume genérico: é que a operação da Finza é **ativa** (cobrança sai atrás do cliente), e o plano dá franquia de apenas 500 disparos/mês.

**Activations por mês:** jun 2.632 → jul 4.725 → ago 7.123 → set 7.073 *(só até o dia 17)*.
Em agosto usamos **14× a franquia** de disparos.

### 3. Onde o dinheiro vai — agosto/2026 (excedente de R$ 5.071,70)

| Componente | Eventos excedentes | R$ | % |
|---|---:|---:|---:|
| `whatsapp\|activation` | 6.620 | 3.641,00 | **71,8%** |
| `webhook` | 24.079 | 601,98 | 11,9% |
| `whatsapp\|connection` | 1.025 | 461,25 | 9,1% |
| `rcs\|single` | 964 | 173,52 | 3,4% |
| `whatsapp\|conversation` | 381 | 171,45 | 3,4% |
| `rcs\|activation` + `rcs` | 198 | 22,50 | 0,4% |

**Quase três quartos da conta é disparo ativo de WhatsApp.**

Por departamento (rateio da fatura de agosto, R$ 5.905,23): **cobrança 83,5%** (R$ 4.932), onboarding 9,2% (R$ 543), CS 2,4% (R$ 144). A cobrança operada por IA sozinha responde por R$ 3.174 — **54% da fatura**.

### 4. A trajetória desmente a premissa da proposta

Setembro, com 17 dias corridos, já acumula R$ 4.437 de excedente — ritmo de **R$ 261/dia**, que projeta **~R$ 7.830 de excedente e fatura de ~R$ 8.579** no mês. As activations de setembro (7.073 em 17 dias) já igualaram o mês inteiro de agosto.

A proposta dimensiona o plano pela **média dos últimos três meses** (≈ 4.827 activations/mês). O run-rate de setembro é de **~13.262/mês**. Um plano calibrado pelo passado nasce **subdimensionado em ~2,7×** — e a Finza volta a pagar excedente já no primeiro mês de vigência.

### 5. O achado que a proposta não menciona: categoria dos templates

Sob a régua da Meta, o preço do template depende da **categoria** (MARKETING é a mais cara; UTILITY, transacional, é bem mais barata). Os templates aprovados da Finza estão assim:

- **63 MARKETING** · 30 UTILITY · 2 AUTHENTICATION

E o template mais disparado é `ativacao_generica` — categoria **MARKETING**, corpo de texto livre (*"Oi, tudo bem? {{1}} — Time Finza"*) — usado em **todas** as faixas de cobrança (01-07, 08-30, 31-60, 61-90 dias) e também em Retirada de Equipamentos.

Disparos em massa por categoria:

| Mês | MARKETING | UTILITY |
|---|---:|---:|
| 2026-07 | 1.122 | 281 |
| 2026-08 | 3.271 | 191 |
| 2026-09 (até 17) | 4.343 | 291 |

**~94% do disparo em massa sai como MARKETING.** Há templates transacionais clássicos classificados como MARKETING — `enviar_boleto`, `lembrete_pagamento_com_variavel`, `new_confirmacao_entrega_prod`, `link_assinatura_digital_prod`, `primeiro_acesso_prod`. O time já sabe fazer diferente: `lembrete_pagamento`, `ligacao_cobranca`, `alerta_ccb_*` e a família `torre_tp_*_util` já estão como UTILITY. A migração começou e parou no meio.

Ressalva honesta: `ativacao_generica` tem variável de texto livre, e a Meta dificilmente aprova template genérico como UTILITY. A correção não é reclassificar o template atual — é **substituí-lo por templates específicos de utilidade**, que é exatamente o que a família `torre_tp_*_util` já faz.

### 6. O que a proposta acerta e o que ela não resolve

**Acerta:** manter franquia de 500 disparos numa operação que dispara 7.000 é a pior configuração possível. Pagar R$ 0,55 no excedente contra R$ 0,115 de preço médio de franquia é sangria. Readequar é necessário.

**Não resolve:** o e-mail troca o tamanho do plano, não o **preço unitário do disparo** — que é o que determina a conta. E dimensiona pelo passado, numa curva que dobra a cada dois meses.

## Conclusão

A conta do fornecedor está **correta e auditável**: a fórmula `749 + excedente` reproduz 9 das 11 faturas fechadas à vírgula. Não há erro de cobrança a contestar.

Mas o diagnóstico do e-mail é raso. O custo não subiu porque o plano ficou pequeno — subiu porque **a operação virou ativa**: 72% da fatura é disparo de WhatsApp, 83% dela vem da cobrança, e ~94% desses disparos saem na categoria MARKETING, a mais cara da régua da Meta.

Readequar o plano é necessário, mas **insuficiente e prematuro**:

1. Dimensionar pela média jun–ago subdimensiona o plano em ~2,7× frente ao ritmo de setembro.
2. O que decide a conta é o **preço unitário por activation dentro da franquia** — número que a proposta não apresenta.
3. Migrar os disparos transacionais de MARKETING para UTILITY e ampliar o uso de RCS (R$ 0,18 contra R$ 0,55 do WhatsApp, −67% por disparo) ataca o custo unitário. Negociar plano antes de arrumar o mix é comprar caro um consumo que dá para reduzir.

**Recomendação:** não assinar antes de 01/10. Pedir a abertura da proposta e negociar com os números desta análise em mãos.

### Perguntas a devolver ao Hyperflow

1. Qual o **preço unitário por activation dentro da franquia** no plano proposto, e qual o preço do excedente? (Hoje: R$ 0,115 médio de franquia contra R$ 0,55 de excedente.)
2. Na nova modalidade Meta, qual o preço por **categoria** — marketing, utility, authentication? Utility segue mais barata?
3. O que exatamente conta como *Service* na proposta — activation, conversation, connection, webhook, RCS? Com qual franquia cada um?
4. Por que `webhook` e `connection` são cobrados à parte, e isso permanece no modelo novo?
5. RCS tem franquia zero hoje. Com qual preço e franquia entra no plano novo? Há fallback cobrado quando o destinatário não tem RCS?
6. O plano pode ser **dimensionado por faixa com revisão trimestral**, em vez de valor fixo travado num histórico de 3 meses?

## Próximas ações

<!-- Cada ação estratégica pode virar item de backlog via /backlog add -->
- [ ] Responder ao Hyperflow com as 6 perguntas antes de qualquer assinatura — owner: João Vinícius, deadline: 2026-09-24 (antes da vigência 01/10)
- [ ] Auditar os templates de cobrança e migrar os transacionais de MARKETING para UTILITY (padrão `torre_tp_*_util`) — owner: squad IAF, deadline: 2026-10-15
- [ ] Substituir `ativacao_generica` por templates específicos de utilidade nas réguas de cobrança — owner: squad IAF
- [ ] Avaliar ampliação de RCS como canal primário de disparo (−67% por evento) e medir cobertura real da base — owner: squad IAF
- [ ] Instrumentar acompanhamento mensal de uso × fatura via `/bq` para não ser pego de surpresa de novo — owner: João Vinícius

## Notas / observações

- **Metodologia reprodutível:** todas as queries estão em `.claude/skills/bigquery-finza/hyperflow.md` §4. Agente `bq-analyst`, comando `/bq`.
- **Ressalva de snapshot:** `GET_USAGE_INFO` é capturado antes do fechamento do ciclo; nos meses de jul e ago/2026 subestima a fatura em R$ 50–85 (1–2%).
- **Ressalva de rótulo:** `referencemonth` em `LIST_ALL_BILLS` escorrega — a fatura rotulada `2025-11` (R$ 846,70) carrega consumo de dezembro, e a `2025-12` (R$ 853,60) carrega janeiro. Reconciliação foi feita por valor e `dueat`.
- **Ressalva de escopo:** `LIST_BROADCAST_SCHEDULE_LOGS` cobre **disparo em massa**; activations 1:1 disparadas por fluxo/API não aparecem lá. A proporção 94% MARKETING vale para o disparo em massa, que é o grosso do volume — mas não é o universo inteiro de activations.
- **Projeção de setembro** é run-rate linear sobre 17 dias corridos. Não considera sazonalidade de fim de mês, que na cobrança tende a ser alta — ou seja, tende a ser conservadora.
