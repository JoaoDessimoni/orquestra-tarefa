---
name: finza-contexto
description: Resumo executivo do negócio Finza, plataformas, organograma TI&Produtos e contexto do squad IAF. Carregar antes de produzir qualquer conteúdo destinado a deck/análise/pendência para evitar fabricação de fatos. NÃO substitui os docs canônicos em Docs/finza/ — é índice + sumário; para detalhe operacional, leia os docs originais.
---

# Finza — contexto executivo

Resumo destilado dos docs canônicos em `Docs/finza/` e `Backlog/contexto/`. Atualize aqui apenas quando os docs originais forem atualizados — este arquivo é a versão condensada deles, mantida pelo agente `context-curator` (via `/contexto sync-skill`).

> **Última revisão estrutural: 03/06/2026.** Mudanças desde a v inicial: Torre e Esperanza overviews migraram para `Backlog/contexto/`; squad IAF passou a operar por **8 frentes de backlog** (§3.1, incluindo `sustentacao`); pendências táticas P01–P06 viraram histórico (§6).

---

## 1 · O que é a Finza

Fintech de **crédito consignado** que opera via rede de correspondentes (representantes). Cliente da Finza é o **correspondente**, não o consumidor final — o correspondente usa as plataformas Finza para originar, analisar, formalizar e cobrar crédito junto ao consumidor final.

Modelo de receita: spread em operações de crédito, FIDCs, securitização. Tese de produto: digitalizar a operação ponta a ponta — da originação à cobrança — substituindo cartório/papel por motor próprio.

---

## 2 · As 5 plataformas Finza (o funil)

| # | Plataforma | Etapa | TechLead | O que faz |
|---|---|---|---|---|
| 1 | **Finza Start** | Originação | Marco | Portal do **correspondente** (não do cliente final). Representante solicita crédito para um lead, simula financiamento, envia proposta, coleta assinatura + prova de vida, vincula neurônio à máquina. |
| 2 | **Falcon** | Análise de crédito | Girlan | Motor sem front. Avalia risco em segundos via credit scoring + ML, libera ou nega limite. Sustenta toda a originação. |
| 3 | **Veritas** | KYC + Compliance | Girlan | Entra após aprovação do Falcon. Documentos, biometria, antifraude, due diligence. Em 2026 vira motor de KYC próprio. |
| 4 | **Módulo Financeiro (MF)** | Backoffice cobrança | Marco | Gera títulos, parcelas, boletos. Integra com FIDCs e bancarizadores. Fonte da verdade financeira. Base fria da Torre. |
| 5 | **Torre de Controle** | Cobrança | **João Vinícius (IAF)** | Único sistema sob a IAF. Onde a Esperanza vive, onde as réguas são configuradas, onde campanhas HyperFlow (API oficial Meta) são disparadas. |

**Chave de leitura para apresentações:** IAF atua **só na etapa 5**. As 4 anteriores são vizinhanças — integramos, não governamos.

---

## 3 · Squad IAF — o que é

**IAF = iA Finza.** Squad de IA Aplicada, responsável pela **Torre de Controle** e pelos agentes IA que rodam dentro/em volta dela.

**Supervisor:** João Vinícius (desde 07/05/2026).
**Predecessor:** Mateus (deixou plano de 6 sprints aprovado em 28/abr).
**Reporte:** Leonardo Caixeta (CTO Finza).

**Agentes do squad:**
- **Esperanza** — em produção. Cobrança no WhatsApp, multi-canal, multi-tenant. Conduz a régua de cobrança Finza (amigável → Cobrança 4.0 → extrajudicial). Mapa textual em `Backlog/contexto/mapa_esperanza.md`.
- **Valentina** — SAC / atendimento. Já preparada para receber a carteira Rhino e o multi-org (validado com o dev João Pedro). Frente `valentina` (prefixo `BVA`) **zerada em 2026-06-02** — itens BVA01–BVA05 cancelados (perderam objeto); novas demandas serão criadas posteriormente.
- **Clara** — formalização. Comprovantes de endereço, tratativa de reprovados, biometria. Frente `clara` (prefixo `BCL`).
- **Lívia** — jurídico / distrato. Fluxo de carta de anuência (envolve Jurídico, fora do escopo estrito IAF). Frente `livia` (prefixo `BLV`).
- **Prudente, Francisco, Salvador, Socorro** — citados no histórico (Salvador/Socorro precederam/coexistem com Esperanza); sem frente própria ativa. `<!-- TODO: confirmar papel atual com gestor -->`

### 3.1 · As 8 frentes do backlog IAF

O trabalho do squad é organizado em **8 frentes** no backlog estratégico (`Backlog/frentes/`). Bitrix & Automações é frente unificada com dois prefixos (BBT, BAU). Cada item tem prefixo por frente:

| Frente | Prefixo | Escopo | Sponsor padrão |
|---|---|---|---|
| Bitrix & Automações | `BBT` / `BAU` | Bitrix Cobrança 4.0 + HyperFlow + automações n8n | Jéssica |
| Torre | `BTR` | Plataforma Torre (multi-org, dashboards, refatoração, RCS) | Jéssica |
| Clara | `BCL` | Agente de formalização | Jéssica |
| Esperanza | `BES` | Agente de cobrança/renegociação | Jéssica |
| Valentina | `BVA` | Agente de SAC | Jéssica |
| Lívia | `BLV` | Agente jurídico/distrato | Jurídico + Jéssica |
| Estratégica | `BST` | Transversal — NPS, narrativa IA, processo | João Vinícius / diretoria |
| Sustentação | — | Bugs, infra/deploy, correções operacionais (itens `QMR####` importados do Quimera) | Jéssica |

> **Dois esquemas de ID convivem:** itens **internos** nascem `B<prefix><nn>` (ex.: `BES03`); itens **importados do Quimera** mantêm a key de origem `QMR####` (ex.: `QMR3415`). Ambos vivem em `Backlog/frentes/<frente>/`.

Estado mestre vive em `Backlog/BACKLOG.md`. Priorização por RICE (skill `po-backlog`). Iniciativas de alto nível agregam itens no **roadmap** (análise `tipo: roadmap` em `Backlog/analises/`).

---

## 4 · Torre de Controle — o sistema sob a IAF

**Proposta:** sistema operacional da cobrança Finza. Title-centric, multi-tenant, com IA aprovada por humano. Atua entre **1.000 e 100.000+ contatos**, multi-canal nativo, cobrança preventiva D-7/D-1.

**6 objetivos estratégicos** (de `Backlog/contexto/torre_de_controle_overview.md` §2):
1. Maximizar recuperação de inadimplência
2. Reduzir custo por contato
3. Manter consumidor protegido
4. Visibilidade total da operação
5. Operação sem dependência de TI
6. Inteligência aplicada

**Capacidades técnicas (números):**
- 21 telas, 14 crons, 12 status, 86+ variáveis, 64 edge functions
- 5 papéis RBAC, multi-tenant nativo
- Integrações: Evolution, Hyperflow, n8n, Resend, SendGrid, Twilio, Zenvia, Vonage
- Memória persistente, dedup 4D, reconciliação ETL, atribuição de pagamento em janela 48h
- 3 modos do Maestro (orquestrador de campanhas)

Detalhes operacionais completos em `Backlog/contexto/torre_de_controle_overview.md`.

---

## 5 · Esperanza — o agente em produção

Agente IA conversacional que conduz cobrança no WhatsApp. Não é chatbot — é agente com 27 ferramentas MCP, 5 camadas de prompt, multi-provider, modelo **Claude Sonnet 4**.

**Fases da régua que opera:**
- **D-10 → D+15 · Amigável** — lembrete e aviso pré-vencimento.
- **D+16 → D+60 · Cobrança 4.0** — negociação digital ativa, notificação extrajudicial por e-mail, desconto/parcelamento. *(Fase principal.)*
- **D+46+ · Extrajudicial** — notificação por correio, protesto em cartório, cancelamento e retirada de equipamento.

**9 funções verificáveis nas tools MCP** (de `Backlog/contexto/esperanza_agent_overview.md`):
identificação por telefone/CPF · consulta de dívida/contratos/títulos · blocklist · desconto por tier · parcelamento · PIX/boleto · promessa · avanço de funil · escalonamento.

**4 gaps de qualidade mapeados** (pelo supervisor):
- E01 delírio em conversas longas
- E02 cobranças indevidas
- E03 informações imprecisas
- E04 workflow >1m30s

---

## 6 · Problemas técnicos mapeados na Torre (P01–P06) — histórico

> **Nota (27/05/2026):** estes seis problemas foram o **diagnóstico inicial** do supervisor (deck CTO 13/05). Os IDs `P01`–`P06` eram pendências táticas em `Gestao/Pendencias/`, **subsistema aposentado** — viraram itens de backlog (`Backlog/frentes/`) e iniciativas de roadmap. Mantidos aqui como contexto fundador. Hoje a tarefa estratégica vive no Backlog; a tática, como subtarefa de item de backlog.

Diagnóstico do supervisor após 5 dias. Cada problema tinha proposta de mitigação.

| # | Problema | Proposta |
|---|---|---|
| **P01** | Ambientes de teste — só produção + 1 banco dev como "homologação" | 3 ambientes reais (dev/hml/prd) |
| **P02** | Backend todo em Supabase Functions — telas 5–10s, regras invisíveis | Backend dedicado (FastAPI) |
| **P03** | Sem metodologia de versionamento — sem padrão entre devs | Fluxo PR + convenção + code review (Joao Lucas) |
| **P04** | Sem QA — dev testa o próprio código | Solicitante como QA. Se não escalar, QA dedicado |
| **P05** | Sem priorização de negócio — sem ranking | Ritual semanal com Jéssica + canal único |
| **P06** | Alta dependência do time de IA — tudo passa pelo IAF | Torre 2.0 + curadoria autônoma (plano herdado) |

P01–P05 dependem de decisão arquitetural/processo **fora do squad**. P06 é objetivo declarado do plano até **10/jul/2026**.

---

## 7 · Plano herdado (Mateus, aprovado 28/abr)

6 sprints até 10/jul/2026 para entregar **Torre 2.0** com curadoria autônoma. Detalhe sprint-a-sprint vive em `Apresentacoes/referencias/Roadmap Agentes IA — Operações Finza.pdf`.

**Chave de leitura:** o supervisor vai rodar este plano, não substituí-lo. Ajustes onde a realidade exigir, mas direção mantida.

O plano herdado foi **desdobrado** no backlog estratégico (8 frentes) e no roadmap de iniciativas (`Backlog/analises/<dia>/*roadmap*.md`), alimentado pelas reuniões de priorização com Jéssica (18-19/05) e pela reunião de jornada com a diretoria (15/05).

---

## 8 · Stakeholders relevantes

| Pessoa | Papel | Aparece em |
|---|---|---|
| Leonardo Caixeta | CTO Finza | Reporte direto do supervisor |
| Mateus | ex-supervisor IAF | Deixou plano de 6 sprints |
| Jéssica | Gerente de operação de cobrança | Sponsor das frentes de backlog · ritual de priorização |
| João Pedro Martins | Negócio / cobrança | Define o que os agentes podem/não podem fazer (com Jéssica) |
| Marco | TL Finza Start + Módulo Financeiro | Vizinhança 1 e 4 · ponte com o MF |
| Girlan | TL Falcon + Veritas | Vizinhança 2 e 3 |
| Joao Lucas | Dev do squad IAF | Owner do fluxo PR + code review · infra Esperanza |
| Leandro | Squad IAF | Maior conhecedor do prompt/comportamento atual da Esperanza |
| Mateus Alberone | Blips | Maior conhecedor de HyperFlow (canal Cobrança 4.0) |

---

## 10 · Fontes (docs canônicos)

Sempre que precisar de detalhe além deste resumo, leia o doc original:

- `Docs/BRIEFING.md` — spec viva do deck CTO. Reflete estado real visual e de conteúdo.
- `Docs/finza/CONTEXTO-FINZA.md` — modelo de negócio, organograma TI&Produtos, roadmap estratégico, cedentes, neuronização.
- `Docs/finza/PLATAFORMAS.md` — referência completa das 5 plataformas.
- `Backlog/contexto/torre_de_controle_overview.md` — overview da Torre (objetivos, conceitos, sistemas, telas, crons, status, resiliência, integrações, API, variáveis, diferenciais, casos, fora do escopo, stack). *(Migrou de `Docs/finza/`.)*
- `Backlog/contexto/esperanza_agent_overview.md` — Esperanza: tools MCP, camadas de prompt, multi-provider. *(Migrou de `Docs/agentes/`.)*
- `Backlog/contexto/mapa_esperanza.md` — mapa textual da Esperanza (história, pessoas, riscos).
- `Backlog/BACKLOG.md` — estado mestre das 8 frentes (itens, RICE, alertas, roadmap por trimestre).
- `Docs/finza/repasse-joao-vinicius-iaf.html` — repasse Mateus → João Vinícius (07/05/2026).
- `Apresentacoes/referencias/Boas Vinda FINZA - Tech - 2026.pdf` — paleta corporativa.
- `Apresentacoes/referencias/Roadmap Agentes IA — Operações Finza.pdf` — plano herdado de 6 sprints.
- `Apresentacoes/referencias/Régua de Comunicação_Atualizada.pptx` — régua de cobrança operacional.
