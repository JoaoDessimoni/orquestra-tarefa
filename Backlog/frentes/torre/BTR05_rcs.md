---
id: BTR05
title: Implementar comunicação RCS (Rich Communication Services)
frente: torre
fonte: backlog
status: a-refinar
prioridade: baixa
rice:
  reach: 5
  impact: 5
  confidence: 4
  effort: 6
  score: 1.67
esforco: L
valor_negocio: baixo
origem:
  pendencias: [P32]
  reunioes:
    - Gestao/Reunioes/18-05-2026/2026-05-18-alinhamento-jessica-revisao-geral.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM19
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-Q4
dependencias: []
bloqueia: []
riscos:
  - RCS no Brasil tem cobertura desigual entre operadoras — promessa visual nem sempre se realiza.
  - Homologação RCS é processo lento — meses para entrar em produção.
  - WhatsApp Business + Hyperflow já cobre 80% dos casos de uso pretendidos — RCS pode ser redundante.
  - Custo por mensagem RCS é maior que SMS — alavanca financeira só vale se conversão for muito maior.
premissas:
  - Diretoria aceita orçamento de piloto pequeno antes de decidir.
  - Há caso de uso real que WhatsApp não cobre.
tags: [torre, rcs, comunicacao, jessica, canais, exploratorio]
---

# BTR05 — Implementar comunicação RCS (Rich Communication Services)

## História de usuário

Como **gestor de cobrança**,
quero **avaliar e potencialmente usar RCS como canal de mensageria avançado**,
para **engajar clientes com botões/carrosséis/autenticação em casos onde WhatsApp não couber**.

## Contexto

RCS (Rich Communication Services) é canal de mensageria com recursos avançados (botões interativos, carrosséis, autenticação) sobre SMS. Permite engajamento mais rico que SMS, mais nativo que WhatsApp. Item do Roadmap de prioridade baixa.

**Origem da demanda:** Doc `2026-05-18_jessica_roadmap-ia-automacoes.txt`:
> "RCS — Implementação de comunicação via Rich Communication Services, ampliando os canais digitais e o engajamento com clientes."

## Critérios de aceite

- **CA-1** — Given benchmark publicado, When supervisor lista, Then cobre 3-5 provedores RCS no Brasil (custo, cobertura, homologação, integração).
- **CA-2** — Given casos de uso prioritários identificados, When listados, Then cada um tem: WhatsApp já cobre? RCS adiciona o quê de fato? Estimativa de conversão diferencial?
- **CA-3** — Given decisão estratégica de seguir/não seguir, When tomada, Then é lastreada em piloto pequeno OU em análise comparativa clara.
- **CA-4** — Given decisão "não seguir", When documentada, Then explica o porquê para evitar retrabalho de revisita em 6 meses.

## Dependências cruzadas

- Sem dependência direta de outro item de backlog.

## Observações PO

**Pontos de atenção:**

1. **RICE 1.67 = banda BAIXA.** Confirma o que o roadmap já indica: prioridade baixa, não-urgente.
2. **WhatsApp + Hyperflow já cobre 80% dos casos.** RCS pode ser canal procurando problema.
3. **Custo por mensagem RCS é maior que SMS.** Alavanca financeira só vale se conversão for muito maior — não está claro que vale.
4. **Homologação RCS no Brasil é lenta.** Operadoras controlam acesso. Tempo de produção pode ser meses.
5. **Recomendação PO: parar no ST-3.** Se análise comparativa mostrar que RCS não traz ganho claro, fechar item como "avaliado, descartado". Não fazer piloto sem caso de uso forte.
6. **Item pode ser arquivado.** Priorizado pelo negócio em roadmap, mas é exploração de canal — não responde demanda urgente.

## Definição de pronto

- [ ] Benchmark publicado
- [ ] Caso de uso real identificado OU descartado
- [ ] Decisão go/no-go documentada
- [ ] Se piloto: executado + métricas coletadas

## Histórico

- 2026-05-22 — Item criado a partir de P32 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM19) consolidando reunião revisão geral com Jéssica de 18/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 1.67 — banda baixa confirma "exploratório". Esforço: L (sob piloto). Recomendação PO: avaliar custo/benefício e parar se análise comparativa mostrar redundância com WhatsApp.

## Notas

Não fazer piloto sem caso de uso forte. WhatsApp já cobre maioria dos casos. RCS pode ser canal procurando problema.
