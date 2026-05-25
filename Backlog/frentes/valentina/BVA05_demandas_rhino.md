---
id: BVA05
title: Mapear demandas relacionadas ao originador Rhino na Valentina
frente: valentina
status: a-refinar
prioridade: alta
rice:
  reach: 5
  impact: 6
  confidence: 7
  effort: 2
  score: 10.5
esforco: S
valor_negocio: alto
origem:
  pendencias: [P24]
  reunioes:
    - Gestao/Reunioes/18-05-2026/2026-05-18-alinhamento-jessica-revisao-roadmap.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM08
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-06-15
dependencias: []
bloqueia: [BTR02, BVA04]
riscos:
  - Acesso a chamados Rhino dos últimos 60 dias pode não estar disponível em base consultável (Hyper, Bitrix) sem extração manual cara.
  - Amostra de 60 dias pode ser insuficiente — Rhino é originador novo, volume pode estar baixo.
  - Regras contratuais Rhino podem ser confidenciais e exigir acesso restrito.
premissas:
  - Chamados Rhino dos últimos 60 dias são extraíveis (Hyper, Bitrix ou base BI).
  - Time de Contratos/Compliance permite acessar cláusulas Rhino para mapeamento.
  - Há pelo menos 50 chamados Rhino na janela (volume mínimo para análise).
tags: [valentina, rhino, mapeamento, jessica]
---

# BVA05 — Mapear demandas relacionadas ao originador Rhino na Valentina

## História de usuário

Como **supervisor IAF**,
quero **catálogo de demandas típicas do originador Rhino**,
para **dar lastro concreto à personalização Valentina-Rhino (BVA04) e integração Rhino-Torre (BTR02)**.

## Contexto

Rhino é originador novo no ecossistema Finza. Para a Valentina suportar adequadamente, é preciso catalogar o que tipicamente vem do Rhino — tipos de demanda, vocabulário próprio, regras contratuais específicas. Sem isso, "personalizar atendimento por originador" (BVA04) vira slogan vazio.

**Origem da demanda:** Doc `2026-05-18_jessica_roadmap-ia-automacoes.txt`:
> "Também será necessário mapear, em conjunto, as demandas relacionadas ao originador Rhino."

Insumo direto da BVA04 e BTR02.

## Critérios de aceite

- **CA-1** — Given fonte de chamados Rhino identificada, When extração é feita, Then amostra de pelo menos 60 dias / 50 chamados está disponível.
- **CA-2** — Given amostra extraída, When categorização é feita, Then cada chamado tem tipo de demanda (taxonomia compartilhada com BES04 quando possível).
- **CA-3** — Given vocabulário Rhino documentado, When publicado, Then lista jargões/termos próprios + sinônimos Finza correspondentes.
- **CA-4** — Given regras contratuais Rhino levantadas, When publicadas, Then cobrem: política de desconto, parcelamento, retirada, distrato, comprovação documental.
- **CA-5** — Given documento publicado, When BVA04 (perfil Valentina-Rhino) começa, Then é citado como fonte direta.

## Subtarefas

- [ ] **ST-1 — Identificar fonte de chamados Rhino** — Hyper (org Finza? org Blips?), Bitrix, base BI?
- [ ] **ST-2 — Extrair amostra** — 60 dias OU 50 chamados (o que vier primeiro).
- [ ] **ST-3 — Categorizar por tipo de demanda** — reusar taxonomia BES04 se disponível, ou definir nova.
- [ ] **ST-4 — Identificar vocabulário/jargão** específico do Rhino.
- [ ] **ST-5 — Levantar regras contratuais** — sessão com Contratos / Compliance.
  - Política de desconto Rhino, parcelamento, retirada, distrato, comprovação.
- [ ] **ST-6 — Documentar em `Gestao/Analises/<data>/`** — insumo para BVA04 e BTR02.
- [ ] **ST-7 — Validar com Jéssica + operação** — números fazem sentido?

## Dependências cruzadas

- **Bloqueia:** BVA04 (perfil Valentina-Rhino), BTR02 (Rhino como tenant piloto).
- **Paralelo a:** BVA02 (roteamento Rhino) — sinergia.

## Observações PO

**Pontos de atenção:**

1. **Análise antes de implementação — pilar.** RICE 10.5 reflete: esforço pequeno, alavanca grande (destrava 2 itens importantes).
2. **Risco principal: acesso ao dado.** Rhino é novo. Pode não ter histórico ainda ou histórico estar em sistema sem extração fácil. Se isso virar bloqueio, mudar abordagem: entrevistar 3-5 clientes Rhino diretamente.
3. **Vocabulário Rhino é a parte que ninguém pensa.** Setor industrial tem jargões próprios. Sem mapear, Valentina-Rhino vira robô confuso.
4. **Regras contratuais Rhino podem ser CONFIDENCIAIS.** Acesso a contratos exige ok da Diretoria/Comercial. Validar gate antes de pedir.
5. **Convergência com BES04 (tabulações):** se usar mesma taxonomia, dados conversam. Forte recomendação PO.

## Definição de pronto

- [ ] Catálogo de demandas Rhino publicado
- [ ] Vocabulário documentado
- [ ] Regras contratuais Rhino-específicas listadas
- [ ] Validação com Jéssica concluída
- [ ] BVA04 e BTR02 citam o documento

## Histórico

- 2026-05-22 — Item criado a partir de P24 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM08) consolidando reunião revisão geral com Jéssica de 18/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 10.5. Esforço: S. CAs em G/W/T. Convergência com BES04 (mesma taxonomia) recomendada. Observação PO sobre risco de acesso ao dado e gate jurídico para contratos.

## Notas

Pedir acesso aos chamados Rhino dos últimos 60 dias para o time de operação. Análise quantitativa primeiro, qualitativa depois. Se acesso falhar, entrevistar 3-5 clientes Rhino diretamente.
