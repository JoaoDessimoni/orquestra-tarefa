---
id: BES03
title: Mapear volume de transferências IA→humano por departamento e agente
frente: esperanza
fonte: backlog
status: em-curso
prioridade: alta
rice:
  reach: 8
  impact: 7
  confidence: 8
  effort: 4
  score: 11.2
esforco: M
valor_negocio: alto
origem:
  pendencias: [P18]
  reunioes:
    - Gestao/Reunioes/18-05-2026/2026-05-18-alinhamento-jessica-revisao-geral.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
    - Backlog/solicitacoes/Perguntas IA - 2026_05_18 14_57 GMT-03_00 - Anotações do Gemini.txt
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM02
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-07-15
dependencias: [BES05]
bloqueia: [BST03]
riscos:
  - Divergência de volume entre Torre e Hyper (277 vs 2000 em 15/05) sinaliza que medição atual é não-confiável — sem corrigir essa divergência, dashboard novo pode replicar números errados.
  - Definição de "transferência" não é única — IA→humano explícito é diferente de IA→IA→humano ou de timeout→humano. Sem taxonomia clara, o dado vira ruído.
  - Time de Dados pode não ter capacidade no Q3 para criar storage estruturado.
premissas:
  - Esperanza emite (ou pode emitir com baixo esforço) eventos estruturados a cada decisão de transferência.
  - Storage estruturado pode ser criado em base existente (Supabase ou nova Postgres pós-BTR07).
  - Jéssica e operação têm tempo para validar leitura semântica do dashboard.
tags: [esperanza, transferencias, mapeamento, jessica, dados, observabilidade]
---

# BES03 — Mapear volume de transferências IA→humano por departamento e agente

## História de usuário

Como **gestor de cobrança**,
quero **dashboard com volume de transferências IA→humano por departamento, agente e motivo**,
para **dimensionar equipe, identificar gargalos e priorizar onde a IA precisa evoluir**.

## Contexto

Sem visibilidade hoje sobre quantas transferências IA→humano acontecem, em qual departamento, com qual agente. Gargalo operacional invisível — sem o dado, não há base para dimensionar equipes nem identificar oportunidades de automação adicional.

**Origens convergentes:**
- Doc `2026-05-18_jessica_roadmap-ia-automacoes.txt`: "Mapear o volume de transferências por departamento e por agente, com objetivo de identificar: Volume operacional; Dimensionamento das equipes; Possíveis gargalos no fluxo de atendimento."
- Doc `Perguntas IA - 18/05`: divergência crítica detectada — 277 protocolos na Torre vs 2000 no Hyper no mesmo dia. **Esse problema bloqueia BES03 até ser corrigido.**

## Critérios de aceite

- **CA-1** — Given conversa Esperanza encerrada com transferência, When evento é emitido, Then registro contém: timestamp, agente origem, departamento destino, agente destino (se IA→IA), motivo (taxonomia fixa), ID sessão, carteira, originador, status final.
- **CA-2** — Given eventos persistidos, When janela de retenção é configurada, Then dados de 90 dias estão disponíveis para consulta em <2s.
- **CA-3** — Given dashboard publicado, When gestor abre, Then visualiza distribuição por departamento, agente, motivo, carteira, originador, dia/semana/mês — com drill-down.
- **CA-4** — Given dashboard validado, When Jéssica revisa, Then valida semanticamente que números fazem sentido (não diverge de operação real >5%).
- **CA-5** — Given divergência Torre vs Hyper conhecida (277 vs 2000), When dashboard é publicado, Then documenta claramente o que é contabilizado e o que NÃO é — para evitar leitura errada.

## Dependências cruzadas

- **Depende de:** BES05 (discovery — entender o que Esperanza faz hoje), BES08 (divergência Torre/Hyper — corrigir antes de medir).
- **Bloqueia:** BST03 (narrativa IA) que precisa de números para lastrear.
- **Sinergia:** BES04 (tabulações — esquema de storage compartilhado).

## Observações PO

**Pontos de atenção:**

1. **Dashboard sem corrigir divergência base = ferramenta de auto-engano.** Sem BES08 (divergência Torre vs Hyper) resolvido, este dashboard pode mostrar 277 transferências quando o real é 2000. Sinalizar dependência forte.
2. **"Motivo de transferência" é o atributo mais difícil de capturar.** A IA precisa rotular sua própria saída — risco de viés (IA tende a rotular como "fora de escopo" o que na verdade foi "falha técnica"). Mitigação: amostra manual de 100 conversas para auditar acurácia do rótulo.
3. **Jéssica vai querer cortes que ainda não foram pensados.** Reservar tempo para 2-3 iterações pós-publicação.
4. **Dado público vs dado interno.** Volume por agente humano específico pode gerar leitura punitiva — alinhar com Jéssica se dashboard é só para liderança ou para o time inteiro.

## Definição de pronto

- [ ] Evento instrumentado em produção
- [ ] Dashboard publicado
- [ ] Validação semântica com Jéssica concluída
- [ ] Documentação do que conta vs não conta publicada
- [ ] Pelo menos 30 dias de dado coletado

## Histórico

- 2026-05-22 — Item criado a partir de P18 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM02) consolidando reunião revisão geral com Jéssica de 18/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. CAs reescritos em G/W/T. Adicionada dependência forte de BES08 (divergência Torre/Hyper) — sem corrigir base, dashboard amplifica erro. RICE 11.2 reflete prioridade alta. Esforço: M. Subtarefa de taxonomia adicionada antes da instrumentação. Observações PO incluem alerta sobre viés do rótulo IA→própria saída.

## Notas

Antes de qualquer instrumentação, fechar taxonomia de "motivo de transferência" com Jéssica e lead técnico Esperanza. Sem taxonomia única, qualquer dashboard vira ruído.
