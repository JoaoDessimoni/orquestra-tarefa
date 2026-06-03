---
id: QMR3376
title: Roadmap 7 Agentes IA Finza (Reunião 22/abr/2026)
frente: estrategica
status: em-curso
prioridade: media
fonte: quimera+jira
quimera: 3376
jira: IAF-130
categoria: Cobrança
deliverable_type: Outros
story_points: 8
tipo_origem: Epic
responsavel: João Vinícius Dessimoni
criada: 2026-04-27
concluida: null
prazo: 2026-06-26
prazo_estimado: True
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: []
tags: [fonte-quimera-jira, cat-cobranca]
---

# QMR3376 — Roadmap 7 Agentes IA Finza (Reunião 22/abr/2026)

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3376 · Jira IAF-130 · categoria: Cobrança

## Contexto

Reunião com Jéssica Margaritha (líder Operações Finza), J e Felipe em 22/abr/2026. Carteira cresceu 40% (out/25 → mar/26) e a estratégia para escalar é via tecnologia: 7 agentes de IA.

**Transcrição:** https://docs.google.com/document/d/1m3NpVtk1OsuNJnkCsXAwCOdCZ7C7eshwClw3aH2X77I/edit

## Os 7 agentes

1. **Esperança** — Cobrança Finza (já em prod, Torre)
2. **Valentina** — Saque/Recepção Finza (em deploy, Estia)
3. **Distrato** — Política fixa + Intel Post (Torre, prompt adaptável por régua)
4. **Retirada de Equipamentos** — Intel Coast + transportadora (Torre, prompt adaptável)
5. **Clara** — Documentação + Formalização Finza+Blips (Estia, multi-org)
6. **Saque Finza** — = Valentina (boleto, CCB, financiamento)
7. **Reembolso/Reprovação** — funcionalidade dentro da Clara

## Decisões arquiteturais

* **Distrato + Retirada → Torre** com prompts adaptáveis por fase de régua/filtro (não agentes separados)
* **Sistema de Evaluation na Torre** — time de negócio testa antes de subir para prod
* **Fluxo dev → PR → aprovação Mateus/Joao Lucas → prod** (a partir de Sprint 1)
* **Formalização = Clara única** (Finza + Blips) com curadoria via Estia
* **Hyper:** trocar automação Onboarding → Formalização (não renomear)

## Sprints

* Sprint 0 (27/abr–01/mai): Imediato — Valentina live, Hyper, fluxo dev
* Sprint 1 (04/mai–15/mai): Fundação + escopos + spec Torre 2.0
* Sprint 2 (18/mai–29/mai): Torre 2.0 prompts adaptáveis + integração sistema novo Finza
* Sprint 3 (01/jun–12/jun): Evaluation + conteúdo Distrato
* Sprint 4 (15/jun–26/jun): Conteúdo Retirada + Esteiras
* Sprint 5 (29/jun–10/jul): Dashboards + maturidade

**Entrega total:** 10/jul/2026.

## Stakeholders

* **Operações Finza:** Jéssica Margaritha (líder), J (líder operacional), Felipe e Breno (jovens aprendizes — curadoria)
* **Time IAF:** Marcos Rodrigues, João Pedro da Silva Neto, Leandro Marques
* **Apoio:** Joao Lucas Freitas (Tech Lead), Rian Silveira (IA2 — Clara), Carlos Magno (IA2 — STIA)

## Sistema novo Finza

Entrega prevista: **15/mai/2026**. Substitui Bitrix na coleta/validação de documentos e assinatura CCB. Integração obrigatória da Clara após o lançamento.

## Rastreabilidade

- **Responsável:** João Vinícius Dessimoni
- **Quimera:** #3376 (status fonte mapeado → `em-curso`)
- **Jira:** IAF-130 (projeto IAF)
- **Categoria fonte:** Cobrança
- **Criada:** 2026-04-27
- **Prazo (estimado):** 2026-06-26

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.