---
id: BBT01
title: Criar nova raia no Bitrix para visibilidade de reembolsos aos operadores
frente: bitrix-automacoes
status: em-refinamento
prioridade: alta
rice:
  reach: 5
  impact: 6
  confidence: 8
  effort: 2
  score: 12.0
esforco: XS
valor_negocio: alto
origem:
  pendencias: [P28]
  reunioes:
    - Gestao/Reunioes/18-05-2026/2026-05-18-alinhamento-jessica-formalizacao.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM15
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-06-30
dependencias: []
bloqueia: [BCL02]
riscos:
  - Configuração de raia no Bitrix pode exigir dev customizado se não for acessível via admin — esforço estoura.
  - Sem dono claro (quem configura Bitrix? TI? Operação?) — item pode ficar parado.
  - Raia sem ownership operacional vira fila órfã — alguém precisa ser "primeiro responsável".
premissas:
  - Configuração de raia no Bitrix Cobrança 4.0 é acessível administrativamente (sem precisar de dev customizado).
  - Operação aceita absorver a nova raia no fluxo de trabalho.
tags: [bitrix, raia, reembolso, jessica, operadores, low-tech]
---

# BBT01 — Criar nova raia no Bitrix para visibilidade de reembolsos aos operadores

## História de usuário

Como **operador de cobrança Finza**,
quero **ver reembolsos pendentes de execução em uma raia específica do Bitrix Cobrança 4.0**,
para **que reembolsos parem de se misturar com outras filas e tenham execução rastreável**.

## Contexto

Operadores trabalham no Bitrix mas não há raia/coluna específica para "reembolso pendente de execução". Reembolsos ficam misturados em outras filas ou na cabeça do operador. Jéssica explicitou em 18/05 (14h) que adicionar a raia onde o operador já trabalha é onde a informação precisa estar para ser usada.

Independente de código — é trabalho de **configuração** no Bitrix. Sinergia direta com BCL02 (Clara cria entrada na raia).

## Critérios de aceite

- **CA-1** — Given raia "Reembolso pendente" configurada no Bitrix Cobrança 4.0, When operador abre fluxo, Then a raia está visível com critério de entrada documentado.
- **CA-2** — Given cliente reprovado em compliance com entrada paga e dados de reembolso coletados, When evento dispara, Then entrada na raia é criada (manual ou via integração com BCL02).
- **CA-3** — Given reembolso confirmado em conta + cliente notificado, When operador marca, Then card sai da raia.
- **CA-4** — Given documentação interna publicada, When operador novo é treinado, Then aprende em <10 minutos.
- **CA-5** — Given primeira semana em produção, When 5+ reembolsos rodam pela raia, Then SLA de execução é medido como baseline.

## Subtarefas

- [ ] **ST-1 — Identificar quem configura Bitrix** ⚠️ PO: GATE.
  - TI Finza? Operação? Mateus? Marco?
  - Sem responsável claro, item fica parado.
- [ ] **ST-2 — Definir critério de entrada** — cliente reprovado em compliance + entrada paga + dados de reembolso coletados.
- [ ] **ST-3 — Definir critério de saída** — reembolso confirmado em conta + cliente notificado.
- [ ] **ST-4 — Configurar raia no Bitrix Cobrança 4.0** com esses critérios.
- [ ] **ST-5 — Definir primeiro responsável operacional** da raia (1 nome).
- [ ] **ST-6 — Treinar operadores** sobre o uso (mínimo — raia deve ser autoexplicativa).
- [ ] **ST-7 — Documentar funcionamento** em local canônico.
- [ ] **ST-8 — Medir baseline** — SLA médio nos primeiros 7 dias.

## Dependências cruzadas

- **Bloqueia:** BCL02 (Clara precisa saber criar entradas na raia).
- **Não bloqueia:** começar a configuração — trabalho é admin, não código.

## Observações PO

**Pontos de atenção:**

1. **RICE 12.0 = alta alavanca por esforço quase nulo.** Item mais "burocrático" que técnico — pode destravar rápido se ST-1 (identificar dono) resolver em 1 dia.
2. **Maior risco: item ficar parado sem dono.** Não é falha técnica, é falha de processo.
3. **Sem ownership operacional, raia vira fila órfã.** ST-5 (1 nome responsável) é não-negociável.
4. **Bloqueia BCL02 — então tem impacto cascata.** Mais urgente do que parece pela natureza administrativa.
5. **Documentar funcionamento (ST-7)** é o que dura. Configuração some, doc fica.

## Definição de pronto

- [ ] Raia criada e visível em produção
- [ ] Pelo menos 1 reembolso testado fluindo da entrada à saída
- [ ] Primeiro responsável operacional identificado
- [ ] Operadores treinados
- [ ] Documentação publicada em local canônico
- [ ] Baseline de SLA medido

## Histórico

- 2026-05-22 — Item criado a partir de P28 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM15) consolidando reunião Jéssica formalização de 18/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 12.0 (alta — esforço XS, alavanca clara). CAs em G/W/T. ST-1 (identificar dono Bitrix) elevado a gate. ST-5 (responsável operacional) marcado como não-negociável.

## Notas

Item mais "burocrático" do que técnico — pode destravar rápido se descobrir cedo quem configura Bitrix. Bloqueia BCL02.
