---
id: BTR08
title: Sistema de templates e cópia para acelerar configuração de réguas
frente: torre
status: a-refinar
prioridade: media
rice:
  reach: 6
  impact: 6
  confidence: 7
  effort: 4
  score: 6.3
esforco: M
valor_negocio: medio
origem:
  pendencias: []
  reunioes:
    - Gestao/Reunioes/20-05-2026/2026-05-20-filtros-prompts-trigger-agenda.md
  solicitacoes:
    - Backlog/solicitacoes/Filtros prompts e Trigger agenda - 2026_05_20 16_59 GMT-03_00 - Anotações do Gemini.txt
  analises: []
roadmap_vinculado: null
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-25
refinada: 2026-05-25
deadline_alvo: 2026-Q4
dependencias: [BTR02]
bloqueia: []
riscos:
  - Templates podem virar "configuração escondida" que confunde gestor — se template muda, todas as réguas mudam.
  - Sistema de cópia mal feito pode duplicar erro (régua errada copiada vira 5 réguas erradas).
  - Multi-org adiciona complexidade — template é global ou por org?
premissas:
  - Estrutura de régua na Torre é estável o suficiente para criar templates sem refatoração.
  - Operação aceita usar templates como ponto de partida (não como mandato).
tags: [torre, regua, templates, configuracao, jessica, ux]
---

# BTR08 — Sistema de templates e cópia para acelerar configuração de réguas

## História de usuário

Como **gestor de cobrança / curador de IA**,
quero **templates de régua + função de cópia entre réguas**,
para **configurar nova régua em minutos, não em horas, e reduzir erro de configuração manual**.

## Contexto

Em reunião 20/05/2026 (Doc `Filtros prompts e Trigger agenda`), João Pedro Borges criticou a lentidão operacional para configurar réguas: "muitos cliques e detalhes". Leandro e supervisor propuseram criar templates ou sistemas de cópia para acelerar.

**Origem da demanda:** Doc reunião 20/05:
> "João Pedro Borges Martins criticou a lentidão operacional atual para configurar as réguas, citando que o processo envolve muitos cliques e detalhes. Leandro Marques Gontijo Jersé e João Vinicius Dessimoni Fernandes discutiram a ideia de criar templates ou sistemas de cópia para acelerar a configuração e reduzir o trabalho manual."

Item complementa BTR02 (multi-org) — quando nova org é criada, templates poupam horas de setup.

## Critérios de aceite

- **CA-1** — Given biblioteca de templates de régua criada, When gestor abre, Then encontra 5+ templates iniciais (cobrança amigável, cobrança 4.0, extrajudicial, formalização follow-up, NPS).
- **CA-2** — Given gestor seleciona template, When aplica, Then nova régua é pré-preenchida com parâmetros padrão + campos editáveis evidentes.
- **CA-3** — Given função "copiar régua existente", When usada, Then duplica configuração permitindo edição independente (sem afetar régua original).
- **CA-4** — Given template é alterado, When gestor é avisado, Then é claro o impacto — afeta réguas existentes ou só futuras?
- **CA-5** — Given multi-org operando (BTR02), When template é definido, Then é claro se é global (todas orgs) ou por org.
- **CA-6** — Given primeira semana após release, When gestor configura nova régua, Then tempo de configuração cai >50% vs baseline.

## Subtarefas

- [ ] **ST-1 — Levantar baseline** — quanto tempo médio leva pra configurar régua hoje?
  - Sem baseline, "redução de 50%" é palpite.
- [ ] **ST-2 — Aguardar BTR02 fase 2** — multi-org afeta escopo de template (global vs por org).
- [ ] **ST-3 — Definir biblioteca inicial** de templates:
  - Cobrança amigável (D-10 a D+15)
  - Cobrança 4.0 (D+16 a D+60)
  - Extrajudicial (D+46+)
  - Formalização follow-up
  - NPS pós-jornada
- [ ] **ST-4 — Implementar função de template** — pré-preenchimento + campos editáveis.
- [ ] **ST-5 — Implementar função "copiar régua"** — duplicação isolada.
- [ ] **ST-6 — Definir governança** — quem cria/altera templates? Squad? Gestor?
- [ ] **ST-7 — UX de aviso de impacto** — alteração de template avisa quais réguas usam.
- [ ] **ST-8 — Decidir escopo multi-org** — global vs por org (BTR02).
- [ ] **ST-9 — Validação UX com gestor real** (João Pedro Borges) antes de publicar.
- [ ] **ST-10 — Medir baseline pós-release** — confirmar ganho.

## Dependências cruzadas

- **Depende de:** BTR02 (multi-org) — define escopo (global vs por org).

## Observações PO

**Pontos de atenção:**

1. **RICE 6.3 — média alavanca, esforço médio.** Vale fazer mas não é prioridade-1.
2. **Sem baseline (ST-1), métrica de sucesso é palpite.** Não pular.
3. **Template é faca de dois gumes.** Bem feito = aceleração. Mal feito = bug em escala (template errado vira 5 réguas erradas).
4. **Multi-org complica escopo.** Decidir global vs por org cedo, senão refaz.
5. **Item é UX-heavy.** ST-9 (validação com gestor real) é crítico — sem isso, sistema "elegante" pode não resolver dor real.
6. **Sinergia com BTR02 fase 2 é estrutural.** Considerar absorver como subtarefa de BTR02 se refinement mostrar redundância.

## Definição de pronto

- [ ] Biblioteca de templates publicada (mínimo 5)
- [ ] Função "copiar régua" em produção
- [ ] UX de impacto validada
- [ ] Tempo de configuração reduzido >50% vs baseline
- [ ] Governança documentada

## Histórico

- 2026-05-25 — Item criado a partir de leitura crítica de `Backlog/solicitacoes/Filtros prompts e Trigger agenda - 2026_05_20 16_59 GMT-03_00 - Anotações do Gemini.txt`. Identificado como GAP no backlog — demanda explícita do gestor (João Pedro Borges) sobre lentidão de configuração. Status inicial: em-refinamento. RICE 6.3. Esforço: M.

## Notas

Sem baseline (ST-1), ganho de 50% é palpite. Considerar absorver em BTR02 se refinement mostrar redundância arquitetural.
