---
id: BVA04
title: Ajustar Valentina para identificar originador automaticamente
frente: valentina
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
  pendencias: [P23]
  reunioes:
    - Gestao/Reunioes/18-05-2026/2026-05-18-alinhamento-jessica-revisao-roadmap.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM07
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-Q3
dependencias: [BVA01, BVA03, BVA05]
bloqueia: []
riscos:
  - "Identificação automática" pode não ser viável tecnicamente — Mateus disse explicitamente em 22/04 que Módulo Financeiro hoje não diferencia originador.
  - Sem base de contexto Valentina (BVA01), perfis por originador são caixas vazias.
  - Personalizar atendimento por originador exige curadoria contínua que escala mal (cada originador novo = novo perfil).
premissas:
  - É possível identificar originador via algum sinal (canal/número/payload/pergunta direta).
  - Existe pelo menos 1 originador além de Finza padrão (Rhino) para validar o conceito.
  - Curadoria contínua tem dono (Jéssica? operação?).
tags: [valentina, originador, jessica, novas-industrias, multi-tenant]
---

# BVA04 — Ajustar Valentina para identificar originador automaticamente

## História de usuário

Como **cliente de originador específico (Rhino, etc.)**,
quero **que Valentina me reconheça automaticamente e use contexto adequado ao meu originador**,
para **receber atendimento personalizado sem precisar explicar de quem sou cliente**.

## Contexto

Valentina hoje atende como se houvesse apenas um originador. Com a Finza absorvendo novas indústrias (Rhino e outros), a IA precisa identificar o originador na entrada e personalizar atendimento. Cada originador tem contrato, fluxo e operação diferentes — atendimento genérico vira atendimento ruim.

**Origem da demanda:** Doc `2026-05-18_jessica_roadmap-ia-automacoes.txt`:
> "Atendimento para novas indústrias — O agente deverá estar apto a identificar automaticamente o originador (indústria) e personalizar o atendimento conforme a necessidade de cada operação."

⚠️ **Restrição técnica conhecida:** Doc `2026-04-22_gemini_agentes-operacoes-finza.txt`, Mateus → Jéssica: "hoje no Módulo Financeiro, do jeito que funciona, a gente não consegue saber qual foi a empresa que originou o contrato Finza".

## Critérios de aceite

- **CA-1** — Given mecanismo de identificação acordado (técnico ou pergunta direta), When cliente inicia conversa, Then originador é identificado em <3 turnos.
- **CA-2** — Given originador identificado, When Valentina responde, Then usa perfil específico (prompt + regras + conhecimento filtrado).
- **CA-3** — Given 2 perfis configurados (Finza padrão + Rhino), When 100 conversas reais rodam, Then taxa de identificação correta >85%.
- **CA-4** — Given perfil incorreto identificado, When detectado, Then Valentina corrige sem irritar o cliente (perguntar "estou falando com cliente Rhino?" no início).
- **CA-5** — Given mecanismo de curadoria estabelecido, When novo originador entra na Finza, Then o processo de criar novo perfil está documentado (não improviso).

## Subtarefas

- [ ] **ST-1 — Aguardar BVA01 (base de contexto) e BVA03 (inventário números) e BVA05 (demandas Rhino).**
  - Sem essas peças, perfis viram caixas vazias.
- [ ] **ST-2 — Levantar como o originador É IDENTIFICÁVEL** — canal, prefixo, payload, contexto.
  - Se não-viável tecnicamente → estratégia "Valentina pergunta no primeiro turno".
- [ ] **ST-3 — Definir modelo de "perfil por originador"** — prompt diff + regras diff + conhecimento filtrado.
  - Sinergia com BTR02 (multi-org): perfil pode usar o mesmo `filter_definition_id` da Torre.
- [ ] **ST-4 — Configurar 2 perfis piloto:** Finza padrão + Rhino.
- [ ] **ST-5 — Implementar identificação na entrada da conversa.**
- [ ] **ST-6 — Validar com 100 conversas reais** — métricas de identificação correta.
- [ ] **ST-7 — Documentar processo de criação de novo perfil** (para escalonar).
- [ ] **ST-8 — Mecanismo de correção** — Valentina deve perguntar quando confiança é baixa.

## Dependências cruzadas

- **Depende de:** BVA01 (base de contexto), BVA03 (inventário números), BVA05 (demandas Rhino).
- **Sinergia forte:** BTR02 (multi-org com filter_definition_id).

## Observações PO

**Pontos de atenção:**

1. **RICE 4.9 reflete confiança baixa.** A viabilidade técnica não está garantida — Mateus mesmo disse que MF não diferencia. Item pode mudar de escopo drasticamente após discovery.
2. **"Personalizar atendimento por originador" pode ser slogan vazio.** Validar com Jéssica: qual É a diferença real de atendimento? Vocabulário? Contrato? Política de desconto? Se a diferença é mínima, item é overengineering.
3. **Item depende de 3 outros (BVA01, BVA03, BVA05).** É iniciativa-derivada, não pioneira. Reservar para Q3/Q4 quando dependências entregarem.
4. **Curadoria contínua = ponto fraco.** Novo originador = novo perfil. Sem processo, vira caos. ST-7 não é decoração.
5. **Sugestão PO: começar com "Valentina pergunta originador no primeiro turno"** como MVP. Identificação automática vira v2.

## Definição de pronto

- [ ] Identificação automática em produção
- [ ] Pelo menos 2 perfis configurados (Finza padrão + Rhino)
- [ ] Validação em conversas reais (>85% acurácia)
- [ ] Processo de criar novo perfil documentado
- [ ] Curadoria contínua com dono identificado

## Histórico

- 2026-05-22 — Item criado a partir de P23 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM07) consolidando reunião revisão geral com Jéssica de 18/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 4.9 — confidence baixa reflete restrição técnica Mateus. Esforço: M. Adicionadas dependências (BVA01, BVA03, BVA05). Sugestão PO: MVP "Valentina pergunta" antes de identificação automática. Observação PO sobre risco de overengineering se diferença real entre perfis for mínima.

## Notas

Levantar com time de Plataformas como o originador chega na entrada da Valentina — sem isso, identificação automática é palpite. MVP "Valentina pergunta" pode entregar valor em 1 sprint.
