---
id: QMR12357
title: Nova Torre de Controle — especificação técnica do frontend, API Torre e Motor de Disparos
frente: torre
status: refinado
prioridade: media
fonte: quimera
quimera: 12357
jira: null
categoria: TI
deliverable_type: Aplicação/Sistema
story_points: 13
tipo_origem: ticket
responsavel: null
implementador: null
criada: 2026-11-06
refinada: 2026-11-06
rice: null
esforco: L
valor_negocio: alto
owner: João Vinícius
sponsor: João Vinícius
origem:
  quimera: [QMR12357]
dependencias: []
bloqueia: []
tags: [fonte-quimera, cat-ti, torre, roadmap_torre, motor_disparos, refatoracao]
---

# QMR12357 — Nova Torre de Controle: especificação técnica

> Origem: Quimera #12357 · categoria: TI · status fonte: `backlog`
> Materializa a fase de especificação do **BTR07** (Refatoração da Torre).
> Harness anexado: `Harness/agents/` (software-architect, dba, backend-dev, frontend-dev, qa-engineer, code-reviewer, tech-writer).

## História

**Como** supervisor do squad IAF,
**quero** a especificação técnica completa da nova Torre (frontend, API Torre e Motor de Disparos) escrita no padrão do harness,
**para** começar o desenvolvimento sem decisão estrutural em aberto e com um Motor de Disparos reutilizável por toda a empresa.

## Contexto

- Protótipo do frontend cerca de 90% pronto (13 telas: Dashboards, Ações, Agentes, Auditoria, Biblioteca, Campanhas, Clientes, Configurações, Custos, Disparos, Filtros, Link do cliente, Qualidade).
- Arquitetura definida:
  - Frontend Next.js + React + TypeScript + Tailwind + shadcn/ui.
  - API Torre em FastAPI/Python, com CRUD e regras da Torre.
  - Motor de Disparos em FastAPI/Python + Temporal, serviço independente e multi-sistema (WhatsApp/Meta, SMS, e-mail, canais futuros).

## Critérios de aceite

- **Dado** o repositório da nova Torre, **quando** abro `.specs/`, **então** vejo specs numeradas (`01-…`, `02-…`) com nome claro e executáveis em ordem, cobrindo API Torre, Motor e frontend.
- **Dado** a spec de stack, **quando** leio, **então** a decisão sobre o Temporal (Temporal Cloud ou hospedado por nós) está fechada, com o porquê.
- **Dado** a spec do Motor, **quando** leio, **então** ela define:
  - contrato de envio independente do canal;
  - provedores plugáveis;
  - parametrização por configuração;
  - idempotência, retry e reprocessamento;
  - retorno de status;
  - identificação do sistema solicitante;
  - limites da Meta (tier, janela de 24h, template), opt-out e LGPD.
- **Dado** as specs, **quando** reviso, **então** não há regra de cobrança no Motor (régua, carteira e campanha ficam na API Torre).
- **Dado** as specs, **quando** reviso, **então** existe plano de convivência com a Torre atual e de migração de dados.
- **Dado** o frontend, **quando** comparo com o protótipo, **então** os 10% faltantes estão especificados.

## Subtarefas

- [ ] Spec de stack e arquitetura (inclui decisão do Temporal). ⚠️ PO: gate de tudo que vem depois.
- [ ] Specs da API Torre (modelo de dados, contratos).
- [ ] Specs do Motor de Disparos (modelo de dados, contratos, workflows, provedores).
- [ ] Specs do frontend (telas + 10% faltantes).
- [ ] Plano de convivência e migração de dados da Torre atual. ⚠️ PO: sem isso, cutover vira aposta.

## Observações PO

- **Responsável ainda não definido** no Quimera.
- **O Motor é plataforma, não feature da cobrança.** Se regra de cobrança vazar para dentro dele, os outros sistemas da empresa não conseguem usar.
- **Temporal Cloud × hospedado por nós** muda custo e operação. Fechar na spec de stack antes de qualquer código.
- **13 pontos para especificar três sistemas é apertado.** Se a spec do Motor crescer, separar em demanda própria.
- **A Torre atual (Supabase) dispara de dentro do banco.** A convivência precisa garantir que só um motor dispare por campanha (risco de envio duplicado).

## Rastreabilidade

- **Quimera:** #12357 (status fonte `backlog` → mapeado `refinado`)
- **Item estratégico relacionado:** BTR07
- **Criada:** 2026-11-06

## Histórico

- 2026-11-06 — Demanda refinada e criada no Quimera (#12357), com descrição em HTML no padrão Descrição Refinada · Observação · Objetivo. Harness de agentes genéricos criado em `Harness/agents/` para anexar à demanda.
