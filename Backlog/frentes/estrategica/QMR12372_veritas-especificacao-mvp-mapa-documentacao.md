---
id: QMR12372
title: Veritas 2.0 — especificação técnica do MVP e formalização do mapa de documentação
frente: estrategica
status: refinado
prioridade: media
fonte: quimera
quimera: 12372
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
  quimera: [QMR12372]
dependencias: []
bloqueia: []
tags: [fonte-quimera, cat-ti, veritas, compliance]
---

# QMR12372 — Veritas 2.0: especificação do MVP + mapa de documentação

> Origem: Quimera #12372 · categoria: TI · status fonte: `backlog`
> Discovery: https://claude.ai/artifact/T5htEJMzz6viTwntizo5iP?sk=4vt-Y2EtiwV43eDcJ4ANOQ#visao
> Mapa de documentação (documento vivo, entrega): https://claude.ai/artifact/4D3tN2qWeYRRiDG6ojRHZv?sk=o9olVTVKWQ61Fy8iamJa9g
> Regras de design: `Apresentacoes/executando/veritas-claude-design/CLAUDE.md`
> Harness anexado: `Harness/agents/`

## História

**Como** supervisor do squad IAF,
**quero** as specs técnicas do MVP do Veritas 2.0 e o mapa de documentação finalizado como documento vivo,
**para** começar o desenvolvimento das Fases 0 e 1 com escopo, regras e telas fechados.

## Contexto

- O Veritas 2.0 é a ferramenta do Compliance para monitorar a carteira, revisar o efeito das regras e avaliar validações novas sem depender de tecnologia, guiado por 5 agentes de IA (Integrador, Mapeador, Dados, Monitoramento, Gestor).
- Stack-alvo da discovery: FastAPI + React.
- Roadmap da discovery:
  - Fase 0, Fundação (4 sem.);
  - Fase 1, MVP (8 sem.);
  - Fase 2, Monitorar (6 sem.);
  - Fase 3, Escalar (4 sem.).
- **Escopo desta demanda:** Fases 0 e 1.

## Critérios de aceite

- **Dado** o repositório do Veritas, **quando** abro `.specs/`, **então** vejo specs numeradas com nome claro, executáveis em ordem, cobrindo a Fundação e o MVP.
- **Dado** as specs, **quando** reviso, **então** as regras R1–R16 da discovery aparecem onde se aplicam:
  - sem decisão de proposta;
  - confirmação com custo;
  - cofre;
  - mascaramento;
  - isolamento por organização;
  - segregação de funções;
  - auditoria.
- **Dado** o mapa de documentação, **quando** abro, **então** toda tela e funcionalidade das Fases 0 e 1 tem objetivo, regras, fluxo, estados e prévia preenchidos.
- **Dado** as telas da Fundação sem protótipo (login, organizações/usuários/chaves, trilha de auditoria), **quando** reviso o mapa, **então** elas estão propostas e documentadas.
- **Dado** mapa e specs, **quando** comparo, **então** não há divergência entre os dois.

## Subtarefas

- [ ] Propor e documentar no mapa as telas da Fundação sem protótipo. ⚠️ PO: pré-requisito das specs da Fundação.
- [ ] Specs da Fundação (esqueleto, login e perfis, cofre, trilha de auditoria, conector HTTP + catálogo de custo).
- [ ] Specs do MVP:
  - Integrador + 6 pilotos;
  - fontes de dados;
  - variáveis + Mapeador;
  - Playground v1;
  - transações via API;
  - perfil consolidado.
- [ ] Refinar o mapa de documentação para todas as telas e funcionalidades das Fases 0 e 1.
- [ ] Revisão cruzada mapa × specs.

## Observações PO

- **Responsável ainda não definido** no Quimera.
- **Fases 2 e 3 fora do escopo.** O mapa cita como previstas, sem detalhar. Se o escopo crescer, quebrar a demanda.
- **Custos de bureau estimados** (ex.: Sherlocker R$ 0,40*) não podem virar valor fechado na spec.
- **O Veritas 1 continua:** KYC, termos, retiradas, cartão de terceiro e pendências não migram. Qualquer pedido nessa linha é escopo do Veritas 1.
- **13 pontos para spec de 12 entregas + refinar o mapa é apertado.** Revisar depois da spec da Fundação.

## Rastreabilidade

- **Quimera:** #12372 (status fonte `backlog` → mapeado `refinado`)
- **Criada:** 2026-11-06

## Histórico

- 2026-11-06 — Demanda refinada e criada no Quimera (#12372), com links da discovery e do mapa de documentação na descrição. Item registrado no backlog estratégico (frente estratégica, até existir frente de compliance).
