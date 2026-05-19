---
name: finza-contexto
description: Resumo executivo do negócio Finza, plataformas, organograma TI&Produtos e contexto do squad IAF. Carregar antes de produzir qualquer conteúdo destinado a deck/análise/pendência para evitar fabricação de fatos. NÃO substitui os docs canônicos em Docs/finza/ — é índice + sumário; para detalhe operacional, leia os docs originais.
---

# Finza — contexto executivo

Resumo destilado dos docs canônicos em `Docs/finza/`. Atualize aqui apenas quando os docs originais forem atualizados — este arquivo é a versão condensada deles.

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
- **Esperanza** — em produção. Cobrança no WhatsApp, multi-canal, multi-tenant. Conduz a régua de cobrança Finza (amigável → Cobrança 4.0 → extrajudicial).
- **Valentina, Clara, Lívia, Prudente, Francisco** — mencionados, sem detalhe operacional ainda. (TODO: documentar.)

---

## 4 · Torre de Controle — o sistema sob a IAF

**Proposta:** sistema operacional da cobrança Finza. Title-centric, multi-tenant, com IA aprovada por humano. Atua entre **1.000 e 100.000+ contatos**, multi-canal nativo, cobrança preventiva D-7/D-1.

**6 objetivos estratégicos** (de `TORRE_DE_CONTROLE_OVERVIEW.md` §2):
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

Detalhes operacionais completos em `Docs/finza/TORRE_DE_CONTROLE_OVERVIEW.md`.

---

## 5 · Esperanza — o agente em produção

Agente IA conversacional que conduz cobrança no WhatsApp. Não é chatbot — é agente com 27 ferramentas MCP, 5 camadas de prompt, multi-provider, modelo **Claude Sonnet 4**.

**Fases da régua que opera:**
- **D-10 → D+15 · Amigável** — lembrete e aviso pré-vencimento.
- **D+16 → D+60 · Cobrança 4.0** — negociação digital ativa, notificação extrajudicial por e-mail, desconto/parcelamento. *(Fase principal.)*
- **D+46+ · Extrajudicial** — notificação por correio, protesto em cartório, cancelamento e retirada de equipamento.

**9 funções verificáveis nas tools MCP** (de `Docs/agentes/ESPERANZA_AGENT_OVERVIEW.md`):
identificação por telefone/CPF · consulta de dívida/contratos/títulos · blocklist · desconto por tier · parcelamento · PIX/boleto · promessa · avanço de funil · escalonamento.

**4 gaps de qualidade mapeados** (pelo supervisor):
- E01 delírio em conversas longas
- E02 cobranças indevidas
- E03 informações imprecisas
- E04 workflow >1m30s

---

## 6 · Problemas técnicos mapeados na Torre (P01–P06)

Diagnóstico do supervisor após 5 dias. Cada problema tem proposta de mitigação.

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

---

## 8 · Stakeholders relevantes

| Pessoa | Papel | Aparece em |
|---|---|---|
| Leonardo Caixeta | CTO Finza | Reporte direto do supervisor |
| Mateus | ex-supervisor IAF | Deixou plano de 6 sprints |
| Jéssica | Gerente de operação de cobrança | Ritual semanal de priorização |
| Marco | TL Finza Start + Módulo Financeiro | Vizinhança 1 e 4 |
| Girlan | TL Falcon + Veritas | Vizinhança 2 e 3 |
| Joao Lucas | Dev do squad IAF | Owner do fluxo PR + code review |

---

## 9 · Fontes (docs canônicos)

Sempre que precisar de detalhe além deste resumo, leia o doc original:

- `Docs/BRIEFING.md` — spec viva do deck CTO. Reflete estado real visual e de conteúdo.
- `Docs/finza/CONTEXTO-FINZA.md` — modelo de negócio, organograma TI&Produtos, roadmap estratégico, cedentes, neuronização.
- `Docs/finza/PLATAFORMAS.md` — referência completa das 5 plataformas.
- `Docs/finza/TORRE_DE_CONTROLE_OVERVIEW.md` — 15 seções da Torre (objetivos, conceitos, sistemas, telas, crons, status, resiliência, integrações, API, variáveis, diferenciais, casos, fora do escopo, stack).
- `Docs/agentes/ESPERANZA_AGENT_OVERVIEW.md` — 27 tools MCP, 5 camadas de prompt, multi-provider.
- `Docs/finza/repasse-joao-vinicius-iaf.html` — repasse Mateus → João Vinícius (07/05/2026).
- `Apresentacoes/referencias/Boas Vinda FINZA - Tech - 2026.pdf` — paleta corporativa.
- `Apresentacoes/referencias/Roadmap Agentes IA — Operações Finza.pdf` — plano herdado de 6 sprints.
- `Apresentacoes/referencias/Régua de Comunicação_Atualizada.pptx` — régua de cobrança operacional.
