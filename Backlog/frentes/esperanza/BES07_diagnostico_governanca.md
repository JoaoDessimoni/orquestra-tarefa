---
id: BES07
title: Diagnóstico completo Esperanza — governança, confiabilidade, KPIs estratégicos
frente: esperanza
fonte: backlog
status: a-refinar
prioridade: alta
rice:
  reach: 9
  impact: 8
  confidence: 6
  effort: 7
  score: 6.17
esforco: L
valor_negocio: alto
origem:
  pendencias: []
  reunioes: []
  solicitacoes:
    - Backlog/solicitacoes/Perguntas a serem respondidas & melhorias_correções IA's.txt
  analises: []
roadmap_vinculado: null
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-25
refinada: 2026-05-25
deadline_alvo: 2026-Q4
dependencias: [BES05]
bloqueia: [BST03]
riscos:
  - **CRÍTICO** — Item é umbrella massivo (14 categorias no doc origem). Sem quebra em itens-filhos, vira nunca-termina.
  - Observabilidade de IA exige instrumentação fina — risco de subestimar esforço.
  - "Score de confiança" e "detecção de delírio" são problemas de pesquisa, não engenharia simples.
  - Comparativo IA vs Humano exige dado de operador humano que pode não estar instrumentado.
  - Demanda do negócio (Jéssica) tem expectativa de "ter a visão pronto" — alinhar timeline realista.
premissas:
  - Lead técnico Esperanza consegue instrumentar o agente para observabilidade adicional.
  - Dado de operador humano (tempo, resolução, tabulação) pode ser extraído.
  - Squad tem capacidade para implementação L no Q4.
tags: [esperanza, diagnostico, observabilidade, governanca, kpis, delirio, jessica]
---

# BES07 — Diagnóstico completo Esperanza — governança, confiabilidade, KPIs estratégicos

## História de usuário

Como **gestor de cobrança Finza**,
quero **visão completa da maturidade operacional da Esperanza — governança, confiabilidade, capacidade real, comparativo com humano, gargalos, KPIs estratégicos**,
para **decidir onde investir, onde frear, onde escalar a IA com base em dado e não em palpite**.

## Contexto

O doc `Perguntas a serem respondidas & melhorias_correções IA's.txt` (Jéssica) lista **14 categorias** de diagnóstico que precisam ser respondidas para que o negócio confie na operação da Esperanza:

1. **Governança de atendimento** — visibilidade ponta a ponta do que entra/sai.
2. **Confiabilidade das respostas (delírio/hallucination)** — auditoria, score de confiança, logs.
3. **Capacidade real de resolução** — não basta cumprir treinamento, precisa resolver.
4. **Comparativo IA vs Humano** — onde humano resolve e IA não.
5. **Diagnóstico de cobertura operacional** — resolve, transfere, abandona, falha.
6. **Motivos de resolução** — o que funciona, padrão replicável.
7. **Motivos de transferência** — por que escala humano.
8. **Potencial de evolução** — onde dá pra automatizar mais.
9. **Diagnóstico de informações sistêmicas** — visão completa do cliente.
10. **Governança de protocolos** — encerramento, reabertura, fila exceção, SLA.
11. **Monitoramento de falhas** — observabilidade operacional.
12. **Classificação de origem do problema** — onde a falha nasceu (treinamento, prompt, Torre, sistema, integração, regra, fluxo, contexto, info, autonomia).
13. **Indicadores estratégicos** — funil completo, taxa resolução real, transferência, abandono, timeout, delírio, SLA, aderência, assertividade, retrabalho, reclamação, inconsistência.
14. **Objetivo final** — IA comparável a humano nos fluxos possíveis.

**Origem da demanda:** Doc explícito de Jéssica com escopo amplo.

⚠️ **Este item é UMBRELLA.** Não cobre tudo em uma sprint — é programa de discovery + instrumentação distribuído ao longo de Q3-Q4. Os itens BES03 (volume transferências), BES04 (tabulações) e BES06 (relatório pré-Torre) cobrem PARCIALMENTE 3 das 14 categorias.

## Critérios de aceite

- **CA-1** — Given diagnóstico estruturado, When publicado, Then cobre as 14 categorias do doc origem (mesmo que cada uma seja resposta breve em primeira versão).
- **CA-2** — Given governança de atendimento (categoria 1), When dashboards são publicados, Then mostra: total atendimentos, respondidos, sem resposta, timeout, erro técnico, falha de fluxo, falha sistêmica, perdidos.
- **CA-3** — Given rastreabilidade (categoria 1), When auditor consulta uma conversa, Then visualiza: input cliente, output IA, prompt usado, regra aplicada, fluxo acionado, base consultada, API consumida, tempo, status final.
- **CA-4** — Given auditoria de delírio (categoria 2), When amostra aleatória de 100 conversas é revisada, Then taxa de delírio é mensurada com critério explícito (não "feeling").
- **CA-5** — Given comparativo IA vs Humano (categoria 4), When publicado, Then identifica top 5 fluxos onde humano resolve e IA não, com causa raiz.
- **CA-6** — Given KPIs estratégicos (categoria 13), When dashboard agregado é publicado, Then traz: taxa resolução real, taxa transferência, taxa abandono, timeout, delírio, erro sistêmico, SLA, aderência treinamento, assertividade.

## Dependências cruzadas

- **Depende de:** BES05 (discovery).
- **Sinergia forte:** BES03 (volume transferências cobre categoria 5 parcial), BES04 (tabulações cobre categoria 6 parcial), BES06 (relatório pré-Torre cobre categoria 13 parcial).
- **Bloqueia:** BST03 (narrativa IA precisa dos números deste item).
- **Sinergia técnica:** BTR07 (refatoração) — observabilidade enterprise.

## Observações PO

**Pontos de atenção:**

1. **Demanda é UMBRELLA massiva.** ST-2 (priorizar 3-5 categorias) é gate. Tentar fazer 14 = nunca termina.
2. **"Score de confiança" e "detecção de delírio" são problemas de pesquisa.** Não há solução pronta. Começar simples (heurística), evoluir.
3. **Comparativo IA vs Humano exige dado humano instrumentado.** Pode ser dor — humano não loga tudo que faz.
4. **Demanda atende preocupação real do negócio.** Jéssica/Felipe estão olhando 277 protocolos na Torre vs 2000 no Hyper (BES08) e querendo saber se IA é boa o suficiente. Item é a resposta estratégica.
5. **Risco político:** se diagnóstico mostrar que IA é pior que humano em vários fluxos, narrativa de "vamos escalar com IA" sofre. Comunicar com cuidado — diagnóstico honesto é melhor que narrativa quebrada.
6. **Sugestão PO: quebrar em 5 itens-filhos imediatamente.** Esforço L vira 5 itens M/S, cada um entregável independente.

## Definição de pronto

- [ ] Diagnóstico v1 publicado (mesmo cobrindo só 3-5 categorias)
- [ ] Observabilidade básica em produção
- [ ] Score de confiança operando (mesmo heurístico)
- [ ] Painel de KPIs estratégicos publicado
- [ ] Plano para versões seguintes documentado

## Histórico

- 2026-05-25 — Item criado a partir de leitura crítica de `Backlog/solicitacoes/Perguntas a serem respondidas & melhorias_correções IA's.txt` (doc Jéssica, 14 categorias). Identificado como GAP no backlog — itens existentes (BES03/04/06) cobrem apenas 3 das 14 categorias. Status inicial: em-refinamento. RICE 6.17. Esforço: L (DEVE quebrar). Sugestão de 5 itens-filhos imediatos.

## Notas

Antes de qualquer linha de instrumentação, fazer ST-2: priorizar 3-5 categorias do doc origem. Sem priorização, vira projeto-mar.
