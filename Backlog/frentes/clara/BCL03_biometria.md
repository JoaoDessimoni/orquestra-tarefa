---
id: BCL03
title: Implementar envio e acompanhamento de biometria pela Clara
frente: clara
fonte: backlog
status: em-curso
prioridade: alta
rice:
  reach: 7
  impact: 6
  confidence: 6
  effort: 4
  score: 6.3
esforco: M
valor_negocio: alto
origem:
  pendencias: [P27]
  reunioes:
    - Gestao/Reunioes/18-05-2026/2026-05-18-alinhamento-jessica-revisao-geral.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM14
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-08-30
dependencias: []
bloqueia: []
riscos:
  - Gatilho de envio do link de biometria pode estar em sistema que ninguém do squad IAF tem acesso/visão (Veritas, Falcon, Bitrix) — discovery pode estourar prazo.
  - Provedor de biometria pode não permitir integração de acompanhamento sem novo contrato.
  - SLA de 2h é estimativa do negócio, não baseado em dado — pode ser muito agressivo (cliente acordando de manhã) ou muito frouxo (perda de pipeline).
  - Cliente acompanhamento pode virar spam se não calibrado.
premissas:
  - Existe gatilho técnico mapeável que dispara envio do link de biometria.
  - Time de Plataformas (Veritas owner: Girlan) consegue documentar fluxo atual em 1 sessão.
  - Provedor de biometria suporta integração de acompanhamento sem renegociar contrato.
tags: [clara, formalizacao, biometria, jessica, veritas]
---

# BCL03 — Implementar envio e acompanhamento de biometria pela Clara

## História de usuário

Como **cliente em formalização**,
quero **receber suporte humanizado da Clara se não conseguir concluir biometria em 2h**,
para **resolver dúvidas e dificuldades sem precisar abrir chamado**.

## Contexto

Clara deve cuidar de envio e acompanhamento de biometria. Primeiro passo é identificar o gatilho atual de envio do link de biometria ao cliente — sem entender o gatilho, qualquer implementação de acompanhamento é especulativa.

**Origem da demanda:** Doc `2026-05-18_jessica_roadmap-ia-automacoes.txt`:
> "Envio e acompanhamento de biometria — Identificar o gatilho responsável pelo envio do link de biometria ao cliente. Após o envio, caso o cliente não realize o processo no prazo de até 2 horas, executar tratativa de acompanhamento com: chamada de atenção; orientações sobre boas práticas; suporte para conclusão da etapa de biometria."

⚠️ Biometria toca em Veritas (KYC) — plataforma owner Girlan, **fora da IAF**.

## Critérios de aceite

- **CA-1** — Given fluxo atual de biometria mapeado, When supervisor publica documento, Then identifica: quem dispara, qual canal, qual sistema (Veritas?), qual provedor, qual SLA.
- **CA-2** — Given gatilho mapeado, When Clara é configurada, Then ou (a) envia o link diretamente OU (b) observa envio e dispara acompanhamento após 2h.
- **CA-3** — Given cliente não conclui biometria em 2h, When Clara é acionada, Then envia: (1) chamada de atenção; (2) orientações práticas (formato foto, iluminação, doc aceito); (3) oferta de suporte humanizado.
- **CA-4** — Given calibragem inicial, When 30 dias de operação rodam, Then taxa de conversão pós-Clara > taxa pré-Clara (baseline).
- **CA-5** — Given cliente conclui biometria, When status volta, Then Clara confirma com cliente (não fica acompanhando indefinidamente).

## Dependências cruzadas

- **Depende de:** Time de Plataformas / Girlan (Veritas) — fluxo atual + integração possível.
- **Provedor de biometria:** entender restrições e capacidades.

## Observações PO

**Pontos de atenção:**

1. **Demanda fora da IAF.** Biometria está em Veritas (Girlan). Item depende de cooperação cross-team — risco político maior do que técnico.
2. **SLA de 2h é palpite de Jéssica, não dado.** Validar com base real antes de implementar. Pode ser 30min ou 6h.
3. **"Acompanhamento" sem calibragem vira spam.** ST-6 (limite de re-envios) é crítico.
4. **Texto da chamada de atenção é delicado.** Cliente que falha biometria pode estar frustrado, perdido, sem internet, ou desistindo. Diferencial entre "ajudar" e "pressionar" está no tom.
5. **Sugestão PO: começar observando o envio (não enviando).** Reduz invasão em Veritas, valida o gatilho na prática, e migrar para envio direto se ganho ficar claro.
6. **Métrica chave: conversão.** Não basta acompanhar mais — precisa CONVERTER mais. Sem isso, item entrega "barulho" não "valor".

## Definição de pronto

- [ ] Gatilho atual documentado
- [ ] Clara enviando + acompanhando em produção
- [ ] Métricas de conversão coletadas por pelo menos 2 semanas
- [ ] Conversão pós-Clara > baseline pré-Clara (>5%)

## Histórico

- 2026-05-22 — Item criado a partir de P27 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM14) consolidando reunião revisão geral com Jéssica de 18/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 6.3. Esforço: M. CAs em G/W/T. ST-1 (mapear gatilho) elevado a não-negociável. Recomendação PO: arquitetura "observar primeiro, enviar depois" para reduzir invasão em Veritas. SLA de 2h marcado para validação com dado real (não palpite).

## Notas

Mapear gatilho atual de envio de biometria com Girlan (Veritas) ANTES de qualquer linha de código. Item é cross-team, depende de cooperação com fora da IAF.
