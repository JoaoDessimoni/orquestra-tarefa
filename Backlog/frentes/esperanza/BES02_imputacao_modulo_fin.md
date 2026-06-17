---
id: BES02
title: Disponibilizar imputação direta de renegociação no Módulo Financeiro
frente: esperanza
fonte: backlog
status: a-refinar
prioridade: media
rice:
  reach: 6
  impact: 8
  confidence: 4
  effort: 7
  score: 2.7
esforco: L
valor_negocio: alto
origem:
  pendencias: [P17]
  reunioes:
    - Backlog/reunioes/18-05-2026/2026-05-18-alinhamento-jessica-revisao-geral.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
  analises:
    - Backlog/analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM01
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-Q3
dependencias: [BES01]
bloqueia: []
riscos:
  - **CRÍTICO** — IA imputando renegociação direta no MF significa IA movimentando dinheiro/contrato sem humano. Risco contratual e regulatório alto. Sem governança forte, é caminho para incidente.
  - Auditoria insuficiente vira passivo — sem trilha rastreável por imputação, não há defesa em caso de questionamento jurídico.
  - Critérios de bypass vagos viram porta dos fundos — "em casos onde já está validado" é descrição, não regra executável.
  - Módulo Financeiro pode não ter endpoint compatível com auditoria por agente IA (e não por usuário humano).
premissas:
  - **PRECISA SER VALIDADA** — Módulo Financeiro tem endpoint disponível para receber imputação automatizada com auditoria.
  - BES01 (homologação operacional) é gate técnico, mas BES02 precisa de gate JURÍDICO/COMPLIANCE adicional (não é continuação automática).
  - Diretoria/Jurídico/Compliance aceitam IA como ator autônomo em transação contratual sob condições controladas.
tags: [esperanza, modulo-financeiro, jessica, integracao, compliance-critico]
---

# BES02 — Disponibilizar imputação direta de renegociação no Módulo Financeiro

## História de usuário

Como **gestor de cobrança**,
quero **que Esperanza imute renegociações diretamente no Módulo Financeiro (sem humano no meio) em casos com baixíssimo risco contratual**,
para **reduzir fricção e tempo de fechamento em fluxos validados, sob trilha de auditoria completa**.

## Contexto

Passo seguinte à BES01. Após homologação operacional do fluxo "renegociação com transferência humana", abre-se caminho para a Esperanza imputar diretamente a renegociação no Módulo Financeiro sem operador humano no meio.

**Origem da demanda:** Doc `2026-05-18_jessica_roadmap-ia-automacoes.txt`:
> "Após validação e conformidade operacional, disponibilizar à IA a possibilidade de imputar diretamente a renegociação no Módulo Financeiro, sem necessidade de transferência para um operador humano."

⚠️ **PO: Esta é a frase mais arriscada do roadmap.** Aprovação de Jéssica é necessária mas NÃO suficiente. Requer governança extra (Jurídico, Compliance, CTO).

## Critérios de aceite

- **CA-1** — Given critérios de bypass formalmente acordados (em documento, não em reunião), When IA detecta cenário compatível, Then imputa direto — caso contrário, transfere para humano.
- **CA-2** — Given imputação direta executada, When evento é registrado, Then 100% das imputações têm trilha completa: timestamp, ID conversa Esperanza, prompt+regra aplicados, modelo usado, valores antes/depois, hash da resposta IA, ID da operação no MF.
- **CA-3** — Given trilha de auditoria, When auditor externo solicita, Then é possível reconstituir cada decisão da IA a partir dos logs.
- **CA-4** — Given homologação técnica concluída, When piloto controlado roda em janela limitada (ex: 50 imputações em 7 dias), Then taxa de erro/discrepância < 1% — caso contrário, reverte para fluxo humano.
- **CA-5** — Given Compliance + Jurídico avalizaram a abordagem, When carta de risco é assinada, Then operação em produção é liberada.

## Dependências cruzadas

- **Depende de:** BES01 (homologação operacional) — bloqueante operacional, mas NÃO suficiente.
- **Depende de:** Aprovação jurídica/compliance separada — não-mapeada como item de backlog ainda (pode virar BLV0X — frente Lívia).
- **Time financeiro:** validar fluxo de auditoria.
- **Time Esperanza:** implementação.

## Observações PO

**Pontos de atenção, ceticismo e contraproposta:**

1. **Esta é uma demanda de alto risco que pode não valer a pena.** A redução de fricção (1 humano a menos) precisa ser muito maior que o risco regulatório/contratual. Vale **levantar números antes de implementar**: quantas renegociações/dia? Quanto custa o humano nesse passo? O ganho compensa o risco?
2. **RICE intencionalmente conservador** (confidence=4, effort=7) — sem clareza jurídica e sem números de baseline, este item é especulativo.
3. **Sponsor explicitou demanda em frase única.** Jéssica pediu, mas provavelmente não considerou o custo regulatório. Validar com ela se "imputação direta" significa mesmo "sem humano nenhum" ou "humano só valida output da IA por amostragem" — pode ser ganho de 90% sem o risco.
4. **Contraproposta sugerida:** em vez de imputação direta, manter humano como "validador 1-click" (IA prepara, humano confirma com 1 clique). Reduz fricção em 80% mantendo governança.
5. **Não destravar este item só porque BES01 entregou.** Mesmo após BES01, é prudente exigir alinhamento jurídico explícito.

## Definição de pronto

- [ ] Carta de risco assinada por Compliance + Jurídico + CTO
- [ ] Critérios de bypass documentados como regra executável
- [ ] Piloto concluído com taxa de erro < 1%
- [ ] Trilha de auditoria operacional em produção
- [ ] Reversão automatizada testada (kill-switch)

## Histórico

- 2026-05-22 — Item criado a partir de P17 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM01) consolidando reunião revisão geral com Jéssica de 18/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. Reposicionado como item de RISCO ALTO — RICE conservador (2.7) reflete baixa confidence enquanto não há clareza jurídica. CAs reescritos em G/W/T. Subtarefas detalhadas com gate jurídico antes do código. Adicionada contraproposta "validador 1-click" como alternativa de menor risco. Esforço: L (não M).

## Notas

Antes de qualquer linha de código, levantar com Jurídico/Compliance se IA pode imputar transação no MF sem ferir LGPD Art. 20 (decisão automatizada). Esse é o gate real, não a BES01.
