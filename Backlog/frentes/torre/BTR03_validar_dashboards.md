---
id: BTR03
title: Validação conjunta de dashboards da Torre de Controle
frente: torre
fonte: backlog
status: em-refinamento
prioridade: media
rice:
  reach: 6
  impact: 6
  confidence: 7
  effort: 3
  score: 8.4
esforco: S
valor_negocio: medio
origem:
  pendencias: [P30]
  reunioes:
    - Gestao/Reunioes/18-05-2026/2026-05-18-alinhamento-jessica-revisao-geral.md
    - Gestao/Reunioes/18-05-2026/2026-05-18-perguntas-ia-divergencia-dados.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
    - Backlog/solicitacoes/Perguntas IA - 2026_05_18 14_57 GMT-03_00 - Anotações do Gemini.txt
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM17
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-Q3
dependencias: [BES08]
bloqueia: []
riscos:
  - Dashboards rodam consulta de 12h por performance (Doc 18/05) — gera divergência temporal com sistema real.
  - Validação sem corrigir divergência Torre vs Hyper (277 vs 2000) pode validar números errados.
  - "Conceitos validados" sem dicionário versionado vira validação verbal — perde com a primeira pessoa que sai.
premissas:
  - Time Torre tem capacidade para implementar correções derivadas.
  - Jéssica tem disponibilidade para sessões de validação por dashboard.
  - BES08 (correção divergência) entrega antes da validação semântica.
tags: [torre, dashboard, validacao, jessica]
---

# BTR03 — Validação conjunta de dashboards da Torre de Controle

## História de usuário

Como **gestor de cobrança**,
quero **dashboards da Torre com cálculos e conceitos validados conjuntamente**,
para **tomar decisão com base em métrica calibrada, não em interpretação divergente**.

## Contexto

Dashboards da Torre precisam validação conjunta — cálculos, conceitos e usabilidade. Sem essa calibragem, o time de cobrança consome números que podem estar sendo interpretados diferentemente do que foram calculados.

**Origens convergentes:**
- Doc `2026-05-18_jessica_roadmap-ia-automacoes.txt`: "Dashboard — Validação conjunta de dashboards, cálculos, conceitos e usabilidade."
- Doc `Perguntas IA - 2026_05_18`: revelou divergência crítica — 277 protocolos na Torre vs 2000 no Hyper. **Bloqueia validação semântica** porque você não pode validar conceito de número errado.
- Doc Perguntas IA: dashboards rodam consulta de 12h por performance — divergência temporal explícita.

## Critérios de aceite

- **CA-1** — Given inventário dos dashboards Torre publicado, When supervisor lista, Then cada um tem: dono, frequência de uso, último acesso, métrica principal, dependência de cálculo.
- **CA-2** — Given divergência Torre vs Hyper resolvida (BES08), When dashboards usam dado corrigido, Then refletem realidade operacional.
- **CA-3** — Given sessão de validação com Jéssica por dashboard, When realizada, Then ata documenta: cálculo (janela, base, fórmula), conceito (significado operacional), usabilidade (filtros, drill-down).
- **CA-4** — Given dicionário canônico de conceitos publicado, When consultado, Then cada termo tem definição única (não 3 versões dependendo de quem lê).
- **CA-5** — Given correções identificadas, When implementadas, Then validadas em revisita com Jéssica em <30 dias.

## Dependências cruzadas

- **Depende de:** BES08 (divergência dados Torre/Hyper).
- **Sinergia:** BTR04 (validação relatórios — mesmo dicionário de conceitos).

## Observações PO

**Pontos de atenção:**

1. **Validar dashboard antes de corrigir base é jogo perdido.** ST-2 (aguardar BES08) é gate. Sem isso, valida números errados como "validados pelo gestor".
2. **Consulta de 12h é débito técnico de UX.** Não é problema deste item resolver, mas precisa ser documentado para gestor saber "o que vejo agora é o que era há 12h".
3. **Dicionário canônico é o entregável mais valioso.** Não a sessão. Sessão sem doc fica órfã.
4. **Reuso BTR04:** mesmo dicionário serve para relatórios IA. Tratar como item conjunto.
5. **"Em-refinamento" já vinha herdado.** Trabalho parcial registrado (inventário inicial). Manter status.

## Definição de pronto

- [ ] Todos os dashboards validados
- [ ] Dicionário canônico publicado em `Backlog/contexto/`
- [ ] Correções implementadas em produção
- [ ] Revisita pós-correção concluída
- [ ] Reuso em BTR04 confirmado

## Histórico

- 2026-05-22 — Item criado a partir de P30 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM17) consolidando reunião revisão geral com Jéssica de 18/05/2026.
- 2026-05-22 — Status promovido para `em-refinamento`. Inventário inicial de dashboards começou.
- 2026-05-25 — **Refinamento PO adicional.** Origens expandidas (Doc Perguntas IA 18/05). RICE 8.4. CAs em G/W/T. Dependência forte de BES08 adicionada. Subtarefa ST-2 (aguardar correção da base) marcada como gate. Dicionário canônico elevado como entregável principal.

## Notas

Sem corrigir divergência (BES08), validar dashboard é validar ruído. Combinar dicionário com BTR04 desde o início.
