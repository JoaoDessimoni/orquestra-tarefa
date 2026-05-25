---
id: BST02
title: Implementar coleta de NPS no fim da jornada Finza via IA
frente: estrategica
status: a-refinar
prioridade: alta
rice:
  reach: 7
  impact: 7
  confidence: 5
  effort: 5
  score: 4.9
esforco: M
valor_negocio: alto
origem:
  pendencias: [P12]
  reunioes:
    - Gestao/Reunioes/15-05-2026/2026-05-15-reuniao-diretoria-jornada-cliente.md
  solicitacoes: []
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM23
owner: João Vinícius
implementador: null
sponsor: Diretoria
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-Q3
dependencias: [BVA01]
bloqueia: []
riscos:
  - NPS captado pouco depois da formalização pode ser enviesado positivamente — cliente acabou de comprar, ainda não experimentou problema.
  - Taxa de resposta baixa (típico de NPS automático <20%) limita representatividade.
  - Sem ação derivada do dado, NPS vira vaidade — meta sobe, nada muda.
  - Pesquisa IA pode soar "automática demais" e gerar resposta sem qualidade.
premissas:
  - Diretoria/Produto valida formato proposto.
  - Existe gatilho técnico claro de "fim da jornada" (status formalização concluída).
  - Operação aceita absorver feedback acionável (não só consumir dashboard).
tags: [nps, jornada, valentina, diretoria, satisfacao]
---

# BST02 — Implementar coleta de NPS no fim da jornada Finza via IA

## História de usuário

Como **diretoria Finza**,
quero **captura sistemática de NPS no fim da jornada do cliente via IA**,
para **avaliar percepção de qualidade com base quantitativa e retroalimentar evoluções da IA**.

## Contexto

Diretoria identificou na reunião de 15/05/2026 que não há captura sistemática de satisfação do cliente Finza no fim da jornada (após formalização concluída). Sem esse dado, não há base quantitativa para avaliar percepção de qualidade nem para retroalimentar evoluções da IA. A IA pode ocupar esse espaço executando pesquisa no momento certo e persistindo resposta para análise.

## Critérios de aceite

- **CA-1** — Given formato da pesquisa definido em conjunto com Produto/Diretoria, When acordado, Then é simples (1-3 perguntas) e padrão de mercado (NPS 0-10).
- **CA-2** — Given gatilho "fim da jornada" identificado, When evento dispara, Then Valentina (ou agente dedicado) envia mensagem em <24h.
- **CA-3** — Given resposta do cliente recebida, When persistida, Then registro contém: timestamp, cliente, carteira, originador, score, comentário, etapa anterior.
- **CA-4** — Given dashboard publicado, When diretoria revisa, Then visualiza NPS por carteira/originador/mês com drill-down.
- **CA-5** — Given dado coletado, When score baixo (<7), Then dispara ação operacional (escalonamento humano? análise da jornada?) — não fica só no dashboard.

## Subtarefas

- [ ] **ST-1 — Definir formato da pesquisa** ⚠️ PO: SEM ISSO, CÓDIGO É ESPECULATIVO.
  - NPS clássica (0-10) ou múltiplas perguntas?
  - Sugestão PO: começar com NPS clássica + 1 comentário opcional. Simples vence.
- [ ] **ST-2 — Identificar gatilho "fim da jornada"** — provavelmente status formalização = concluída.
  - Sessão com Marco (TL Finza Start / MF) para confirmar evento.
- [ ] **ST-3 — Decidir agente que envia** — Valentina (SAC já existente) vs agente dedicado.
  - Sugestão PO: Valentina, sem criar agente novo (princípio de não fragmentar).
- [ ] **ST-4 — Definir momento exato do envio** — 24h após formalização? 7 dias? Logo após cliente receber máquina?
  - Validar com Produto.
- [ ] **ST-5 — Definir taxa de resposta esperada** — sem expectativa baseline (20%?), métrica não tem norte.
- [ ] **ST-6 — Implementar envio + coleta + persistência.**
- [ ] **ST-7 — Dashboard NPS** — por carteira, originador, mês.
- [ ] **ST-8 — Definir ação para score baixo** — escalonamento, follow-up, análise. SEM ISSO, NPS vira vaidade.
- [ ] **ST-9 — Calibragem** — 100 respostas iniciais validadas para garantir que não há viés grosseiro.

## Dependências cruzadas

- **Depende de:** BVA01 (base de contexto Valentina) — se Valentina envia, precisa entender jornada.
- **Sinergia:** BTR02 (multi-org) — NPS por carteira/originador.

## Observações PO

**Pontos de atenção:**

1. **RICE 4.9 é conservador.** Confidence 5 reflete que implementar é fácil, mas EXTRAIR VALOR é difícil. NPS vira vaidade sem ação derivada.
2. **Momento do envio é a maior alavanca.** NPS 1h depois da formalização vai ser inflado. NPS 30 dias depois é mais real mas tem fadiga. Validar com Produto antes de implementar.
3. **ST-8 (ação para score baixo) é o ponto-chave do projeto.** Sem isso, é métrica decorativa.
4. **"Pesquisa via IA" pode soar automática demais.** Mensagem precisa ter tom humano. ST-1 inclui calibragem de tom.
5. **Esforço M com dependência em BVA01.** Se BVA01 atrasar, este item atrasa.
6. **Recomendação PO: começar pequeno.** MVP = 1 pergunta NPS clássica + dashboard simples. Múltiplas perguntas em v2.

## Definição de pronto

- [ ] Pesquisa em produção
- [ ] Pelo menos 100 respostas coletadas e analisadas
- [ ] Dashboard publicado
- [ ] Ação para score baixo definida e operando
- [ ] Sem viés grosseiro identificado em primeira leva

## Histórico

- 2026-05-22 — Item criado a partir de P12 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM23) consolidando reunião com diretoria de 15/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 4.9 (conservador por confidence baixa de extrair valor). Dependência de BVA01 adicionada. ST-8 (ação para score baixo) elevado como chave do projeto. Recomendação PO: MVP simples (NPS 0-10 + 1 comentário).

## Notas

Definir formato da pesquisa em conjunto com Produto/Diretoria — sem isso, qualquer implementação fica especulativa. Sem ação para score baixo, NPS vira vaidade.
