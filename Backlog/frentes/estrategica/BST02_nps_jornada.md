---
id: BST02
title: Implementar coleta de NPS no fim da jornada Finza via IA
frente: estrategica
fonte: backlog
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
    - Backlog/reunioes/15-05-2026/2026-05-15-jornada-cliente-diretoria.md
  solicitacoes: []
  analises:
    - Backlog/analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM23
owner: João Vinícius
implementador: null
sponsor: Diretoria
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-Q3
dependencias: []
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

## Dependências cruzadas

- **Sinergia:** BTR02 (multi-org) — NPS por carteira/originador.
- Nota 2026-06-02: dependência de BVA01 (base de contexto Valentina) removida — frente Valentina foi zerada. A base de contexto necessária para o agente que envia o NPS deixa de ser pré-requisito formal; revisitar quando novas demandas Valentina forem criadas.

## Observações PO

**Pontos de atenção:**

1. **RICE 4.9 é conservador.** Confidence 5 reflete que implementar é fácil, mas EXTRAIR VALOR é difícil. NPS vira vaidade sem ação derivada.
2. **Momento do envio é a maior alavanca.** NPS 1h depois da formalização vai ser inflado. NPS 30 dias depois é mais real mas tem fadiga. Validar com Produto antes de implementar.
3. **ST-8 (ação para score baixo) é o ponto-chave do projeto.** Sem isso, é métrica decorativa.
4. **"Pesquisa via IA" pode soar automática demais.** Mensagem precisa ter tom humano. ST-1 inclui calibragem de tom.
5. **Esforço M.** Dependência de BVA01 removida em 2026-06-02 (frente Valentina zerada) — item deixa de estar atrelado ao cronograma de Valentina.
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
- 2026-06-02 — **Dependência removida.** `dependencias: [BVA01]` → `[]`. Frente Valentina foi zerada (todos os BVA cancelados — Valentina já preparada p/ Rhino + multi-org via dev João Pedro). A base de contexto Valentina deixa de ser pré-requisito formal do NPS; revisitar quando novas demandas Valentina surgirem.

## Notas

Definir formato da pesquisa em conjunto com Produto/Diretoria — sem isso, qualquer implementação fica especulativa. Sem ação para score baixo, NPS vira vaidade.
