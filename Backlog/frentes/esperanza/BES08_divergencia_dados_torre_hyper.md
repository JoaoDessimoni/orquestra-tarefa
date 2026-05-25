---
id: BES08
title: Resolver divergência de dados Torre vs Hyper (277 vs 2000 protocolos)
frente: esperanza
status: a-refinar
prioridade: alta
rice:
  reach: 7
  impact: 8
  confidence: 7
  effort: 3
  score: 13.07
esforco: S
valor_negocio: alto
origem:
  pendencias: []
  reunioes:
    - Gestao/Reunioes/18-05-2026/2026-05-18-perguntas-ia-divergencia-dados.md
  solicitacoes:
    - Backlog/solicitacoes/Perguntas IA - 2026_05_18 14_57 GMT-03_00 - Anotações do Gemini.txt
  analises: []
roadmap_vinculado: null
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-25
refinada: 2026-05-25
deadline_alvo: 2026-06-20
dependencias: []
bloqueia: [BES03, BTR03, BTR04, BES07]
riscos:
  - Causa raiz pode estar em multiple sistemas (Torre, Hyper, integração) — diagnóstico cross-team.
  - Consulta Torre roda em janela de 12h por performance — divergência temporal pode ser estrutural, não bug.
  - Sistema Hyper conta todos os agentes (Socorro, Maria, Esperança), Torre só Esperança — pode ser problema de conceito, não de dado.
  - "Criar departamento exclusivo Esperança no Hyper" foi sugerido como mitigação — mas vai isolar o dado, não corrigir a divergência conceitual.
premissas:
  - É possível reconciliar a contagem entre Torre e Hyper (não é fundamentalmente incompatível).
  - Time da Torre (Leandro/Joao Lucas) e time do Hyper têm tempo para investigar.
  - Operação aceita janela de 12h da consulta como restrição temporária.
tags: [esperanza, dados, governanca, torre, hyper, divergencia, qualidade-dados]
---

# BES08 — Resolver divergência de dados Torre vs Hyper (277 vs 2000 protocolos)

## História de usuário

Como **gestor de cobrança**,
quero **reconciliar a contagem de protocolos entre Torre e Hyper**,
para **tomar decisão com base em número único, não em discrepância de 7x entre sistemas**.

## Contexto

Em 15/05/2026, divergência detectada: Torre reporta 277 protocolos, Hyper reporta 2000. Diferença de 7x. Reunião de 18/05 ("Perguntas IA") mapeou possíveis causas:

1. **Consulta de alta complexidade na Torre roda em janela de 12h** — divergência temporal.
2. **Hyper conta todos os agentes (Socorro, Maria, Esperança)**, Torre só Esperança — divergência conceitual.
3. **Renegociações não são realizadas pela Torre** — atendimento por outro caminho.
4. **Protocolos antigos ativos no Hyper** dificultam medição.
5. **Sistema de tags configurado em modelo padrão** sem personalização.

**Origem da demanda:** Doc `Perguntas IA - 2026_05_18 14_57 GMT-03_00 - Anotações do Gemini.txt`.

**Impacto cascata:** este item BLOQUEIA dashboards (BTR03), relatórios (BTR04) e dashboard de transferências (BES03). Sem corrigir base, validação semântica valida ruído.

## Critérios de aceite

- **CA-1** — Given causas conhecidas (5 hipóteses do doc 18/05), When supervisor investiga, Then cada uma é confirmada/descartada com evidência.
- **CA-2** — Given causa raiz identificada, When publicada, Then documento explica: o que Torre conta, o que Hyper conta, por que diferem.
- **CA-3** — Given consulta da Torre, When ajustada, Then frequência é compatível com leitura operacional (12h aceitável? 1h melhor?).
- **CA-4** — Given relação Torre vs Hyper documentada, When reportada para Jéssica, Then ela consegue ler ambos os números como complementares (não como erro).
- **CA-5** — Given protocolos antigos ativos no Hyper, When investigados, Then é estabelecida regra de fechamento automático ou processo manual.
- **CA-6** — Given sistema de tags configurado, When personalizado, Then descrições específicas são adicionadas (não modelo padrão).

## Subtarefas

- [ ] **ST-1 — Mapear o que CADA SISTEMA conta** — definir conceito de "protocolo" em Torre e em Hyper.
- [ ] **ST-2 — Investigar 5 hipóteses do doc 18/05** uma a uma:
  - Janela 12h da consulta Torre.
  - Hyper conta múltiplos agentes.
  - Renegociações fora da Torre.
  - Protocolos antigos ativos.
  - Tags em modelo padrão.
- [ ] **ST-3 — Implementar separação de conversas por protocolo** (Leandro já encaminhou em dev, mover para prod).
- [ ] **ST-4 — Avaliar criação de departamento exclusivo Esperança no Hyper** — pode mitigar (isola Esperança da contagem total) mas não resolve divergência conceitual.
- [ ] **ST-5 — Revisar sistema de tags** ⚠️ Doc 18/05 sinaliza problema: descrições vagas atrapalham IA tagueadora.
- [ ] **ST-6 — Investigar fechamento de protocolos** — por que protocolos antigos permanecem ativos.
- [ ] **ST-7 — Implementar separação de registros humano vs IA** (já encaminhado pelo squad).
- [ ] **ST-8 — Otimizar consulta da Torre** — reduzir janela de 12h se possível.
- [ ] **ST-9 — Documentar relação canônica** entre números Torre e Hyper.
- [ ] **ST-10 — Validar com Jéssica** que documentação faz sentido operacionalmente.

## Dependências cruzadas

- **Bloqueia:** BES03 (volume transferências), BTR03 (validação dashboards), BTR04 (validação relatórios), BES07 (diagnóstico completo).
- **Sinergia:** BTR07 (refatoração — pode resolver janela de 12h).

## Observações PO

**Pontos de atenção:**

1. **RICE 13.07 = maior alavanca da frente Esperanza junto com BES05.** Esforço S, alavanca em 4 itens bloqueados + qualidade de dado geral.
2. **Item já em movimento.** Reunião 18/05 documentou várias ações em curso (separação de protocolos em dev → prod, investigação de fechamento). Este item formaliza o trabalho.
3. **Risco: virar projeto-mar** se tentar resolver tudo. ST-1 (definir conceitos) primeiro, depois priorizar 2-3 hipóteses.
4. **"Departamento exclusivo Esperança no Hyper" (ST-4) é workaround, não solução.** Isola o número, não corrige conceito. Avaliar antes de implementar.
5. **Cross-team (Hyper).** Sem ownership do HyperFlow no squad IAF, depende de time externo.
6. **Não é só Torre vs Hyper — é qualidade de dado em geral.** Discussão pode revelar mais inconsistências.

## Definição de pronto

- [ ] Causas raiz documentadas
- [ ] Relação canônica Torre vs Hyper publicada
- [ ] Sistema de tags personalizado em produção
- [ ] Separação humano vs IA em produção
- [ ] Protocolos antigos com regra de fechamento
- [ ] Jéssica valida documentação como compreensível

## Histórico

- 2026-05-25 — Item criado a partir de leitura crítica de `Backlog/solicitacoes/Perguntas IA - 2026_05_18 14_57 GMT-03_00 - Anotações do Gemini.txt`. Identificado como GAP no backlog. Status inicial: em-refinamento. RICE 13.07 (alta — bloqueia 4 itens). Esforço: S.

## Notas

Item já tem trabalho em curso (squad). Este card formaliza, prioriza e amarra ao backlog. Bloqueia BES03, BTR03, BTR04, BES07.
