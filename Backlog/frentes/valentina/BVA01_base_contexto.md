---
id: BVA01
title: Construir base de contexto Valentina sobre jornada Finza completa
frente: valentina
status: a-refinar
prioridade: alta
rice:
  reach: 8
  impact: 8
  confidence: 6
  effort: 6
  score: 6.4
esforco: L
valor_negocio: alto
origem:
  pendencias: [P13]
  reunioes:
    - Gestao/Reunioes/15-05-2026/2026-05-15-reuniao-diretoria-jornada-cliente.md
  solicitacoes: []
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM10
owner: João Vinícius
implementador: null
sponsor: Diretoria
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-Q3
dependencias: []
bloqueia: [BVA04]
riscos:
  - Documentação dispersa pela Finza pode estar desatualizada/conflitante — base construída em cima vira ferramenta de erro.
  - Sem mecanismo de curadoria contínua, base vira snapshot que envelhece em meses.
  - Esforço L pode estar subestimado se descobrir que a jornada Finza não tem mapa unificado (cada área tem o próprio).
premissas:
  - Há docs dispersos em Confluence/Notion/Drive que servem de base de partida.
  - Diretoria libera tempo de operação para responder dúvidas durante construção (não é só leitura de doc).
  - Plataforma Estia (mencionada no Doc 22/04) ou outra solução de RAG suporta o volume.
tags: [valentina, base-conhecimento, jornada, diretoria, rag]
---

# BVA01 — Construir base de contexto Valentina sobre jornada Finza completa

## História de usuário

Como **cliente Finza interagindo com Valentina**,
quero **respostas lastreadas em conhecimento estruturado sobre a jornada Finza**,
para **não receber respostas genéricas que dependem de prompt momentâneo**.

## Contexto

Valentina (SAC/N1 Finza) opera sem uma base de conhecimento consolidada. Cada interação é resolvida pelo prompt momentâneo, sem lastro documental sobre a jornada do cliente. Diretoria explicitou em 15/05/2026 que construir essa base é prioridade. Ela alimenta também a Esperanza.

**Origens convergentes:**
- Reunião com diretoria 15/05/2026.
- Doc `2026-04-22_gemini_agentes-operacoes-finza.txt`: Mateus explica que Valentina deve "ser a socorro da Finza, no número da Finza, intermediar entre as áreas, tentar solucionar o problema do cara conversando com esses agentes especialistas".
- Mateus menciona plataforma **Estia** como solução de treinamento/curadoria — investigar se ainda é a aposta ou se virou RAG na Torre.

## Critérios de aceite

- **CA-1** — Given inventário de docs dispersos consolidado, When supervisor publica, Then mapeia o que existe (Confluence, Notion, Drive, e-mails recorrentes, FAQs antigas).
- **CA-2** — Given jornada Finza documentada, When publicada, Then cobre 5 etapas: originação → análise → formalização → repasse → pós-venda — com regras, exceções, vocabulário.
- **CA-3** — Given base consultável criada, When Valentina é configurada para usar, Then chunks têm metadados (etapa, originador, plataforma envolvida) que permitem filtros (similar ao mecanismo `filter_definition_id` da Torre — BTR02).
- **CA-4** — Given Valentina usando a base, When 100 conversas reais são analisadas, Then taxa de respostas com referência à base >70%.
- **CA-5** — Given base versionada, When item é alterado, Then histórico é preservado (não é Word fluido).
- **CA-6** — Given curadoria contínua estabelecida, When mudanças operacionais acontecem, Then alguém é dono da atualização (não vira órfão).

## Subtarefas

- [ ] **ST-1 — Levantar o que JÁ EXISTE documentado** ⚠️ PO: NÃO COMEÇAR DO ZERO se há base.
  - Confluence, Notion, Drive, FAQs antigas, e-mails recorrentes de suporte.
  - Mateus mencionou **Estia** como plataforma de treinamento — entender se está em uso ou parado.
- [ ] **ST-2 — Mapear jornada Finza completa** com áreas — 5 etapas (originação → pós-venda).
  - Sessão com Jéssica + Felipe (cobrança) + Mariana (formalização — substituiu Mari) + Marco (TL Finza Start).
- [ ] **ST-3 — Decidir arquitetura** — RAG dentro da Torre (similar BTR02) vs Estia vs outro RAG.
  - Recomendação PO: dentro da Torre (BTR02 já tem `filter_definition_id`).
- [ ] **ST-4 — Estruturar chunks com metadados** — etapa, originador, plataforma.
- [ ] **ST-5 — Cobrir regras de negócio + exceções + vocabulário interno.**
- [ ] **ST-6 — Versionar** — fonte da verdade, não snapshot.
- [ ] **ST-7 — Integrar com Valentina e Esperanza** via MCP ou injeção de contexto.
- [ ] **ST-8 — Estabelecer curadoria contínua** — quem mantém? sprint mensal? quem aprova mudança?
- [ ] **ST-9 — Calibrar** — 100 conversas piloto + medir taxa de uso da base.

## Dependências cruzadas

- **Bloqueia:** BVA04 (originador automático) — alimenta os perfis por originador.
- **Sinergia forte:** BAU01 (MCPs) e BTR02 (multi-org com RAG filtrado).
- **Possível absorção em BTR02:** se decisão arquitetural for RAG-na-Torre, este item vira "popular o RAG da Torre com docs da jornada".

## Observações PO

**Pontos de atenção:**

1. **Maior risco: virar snapshot que envelhece.** ST-8 (curadoria contínua) é crítico, não opcional.
2. **Decisão de arquitetura é a peça mais importante.** Estia (Blips/Mateus) vs Torre (próprio squad) vs outro — definir cedo, senão vai construir em cima da arquitetura errada.
3. **Recomendação PO: convergir com BTR02.** A Torre multi-org já tem o mecanismo de filtro de conhecimento (`filter_definition_id`). Construir BVA01 dentro dessa estrutura = base unificada Valentina + Esperanza, multi-tenant.
4. **Esforço L pode estar subestimado.** Documentar jornada completa Finza é exercício que envolve 5+ áreas. Reservar 6-12 dev-semanas + tempo de stakeholders.
5. **"Diretoria como sponsor" significa que ninguém vai mexer no dia a dia.** Identificar champion operacional (Jéssica? Felipe?) que mantém vivo após entrega.

## Definição de pronto

- [ ] Base consultável em produção
- [ ] Valentina (e Esperanza) consumindo via MCPs ou injeção
- [ ] Curadoria contínua estabelecida com dono identificado
- [ ] Pelo menos 70% das conversas Valentina referenciando a base
- [ ] Auditoria mensal estabelecida

## Histórico

- 2026-05-22 — Item criado a partir de P13 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM10) consolidando reunião com diretoria de 15/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 6.4. Esforço: L (corrigido de M — subestimado). CAs reescritos em G/W/T. Decisão de arquitetura marcada como ST-3 — sinaliza convergência com BTR02 (recomendação PO). Adicionada subtarefa de curadoria contínua não-negociável. Risco "vira snapshot" elevado.

## Notas

Levantar o que já existe documentado antes de começar do zero. Provavelmente há docs dispersos que servem de base. Decidir arquitetura (Torre vs Estia vs outro) antes de qualquer linha de RAG.
