# Plataformas Finza

Referência das 5 plataformas que compõem o ecossistema tech da Finza, na ordem do fluxo do cliente. Última atualização: 12/05/2026.

> **Fontes:** `Apresentacoes/Boas Vinda FINZA - Tech - 2026.pdf` (slides 17, 20-27, 29-30), `Apresentacoes/Roadmap Agentes IA — Operações Finza.pdf`, `Docs/repasse-joao-vinicius-iaf.html`, organograma TI & Produtos (slide 17 do PDF FinzaDay).

---

## Organograma resumido — TI & Produtos

**CTO**: Leonardo Caixeta

Sob DEV (área principal):
- **João Vinicius** — Supervisor — responsável por **IA & Automação** + **Dados**
- **Thiago** — Supervisor
- **Marco** — TechLead — responsável por **MF (Gestão de Cobranças)** + **Finza Start (Portal de Negócios)**
- **Girlan** — TechLead — responsável por **Falcon (Motor de Crédito)** + **Veritas (KYC)**

Sob Produtos:
- **Herivelton** — Head de Produtos
- **Bryan** — PO

**Observação importante:** das 5 plataformas Finza, apenas a **Torre de Controle** está sob a IAF (sob você). As outras 4 (Finza Start, Falcon, Veritas, MF) são responsabilidade dos TechLeads Marco e Girlan. A IAF **integra** com todas, mas não governa o roadmap delas.

---

## 1 · Finza Start (Portal de Negócios)

**Slogan:** Plataforma para oferta de crédito inteligente.

### O que faz
Front-end usado pelo **cliente Finza** (correspondente — não o cliente final). É onde o representante comercial do cliente Finza:
1. Solicita crédito para um lead (cliente final)
2. Plataforma libera o crédito (após aprovação Falcon)
3. Faz a simulação do financiamento
4. Envia proposta para o cliente final
5. Coleta assinatura de contrato + prova de vida (via Veritas)
6. Vincula o neurônio à máquina, anexa NF e despacha equipamento
7. Cliente confirma recebimento
8. Indústria recebe valor integral + acesso ao acervo de neurônios

### Papel no fluxo
**Etapa 1** — Originação. Porta de entrada de qualquer operação Finza. Sem Finza Start não há contrato.

### Responsável
**Marco** (TechLead). Time: Ronald (FullStack), Wilianne/Uly (Back), Murillo (Front), Raul Neto (FullStack), Cássio (QA).

### Stack
React + back próprio. Integra com Falcon, Veritas e MF.

### Status / projetos futuros
Em produção. Foco 2026: expandir Finza Start para novas indústrias (em produção 15/03/26 conforme slide 30 do FinzaDay).

### Relação com a IAF
A Torre não toca diretamente o Finza Start — mas o contrato gerado nessa plataforma é o que vira título cobrado pela Torre meses depois. Erros de cadastro/segmentação no Start chegam na IAF como "cobrança indevida".

---

## 2 · Falcon (Motor de Crédito)

**Slogan:** Decisões ágeis e precisas.

### O que faz
Motor de análise de crédito. **Não tem front-end voltado ao cliente final** — é puramente engine. Avalia em segundos:
- Inteligência Artificial — risco de crédito
- Automação — jornada de crédito sem intervenção humana
- Aprendizado de máquina — modelos em evolução contínua

Tem dashboard administrativo (FinzaDay slide 21) com indicadores: total análises, aprovadas/reprovadas, taxa de aprovação, tempo médio, níveis de aprovação por venda/locação.

### Papel no fluxo
**Etapa 2** — Análise de crédito. Recebe o pedido do Finza Start e libera ou nega limite.

### Responsável
**Girlan** (TechLead). Time: Diogo (FullStack), Lucas Silva (FullStack), Yago (Front), Melqui (Back), Carlos (QA).

### Stack
Não documentado em detalhe nas fontes. Standard FinzaTech: Python/Node + React no admin + ML models.

### Relação com a IAF
Aprovação do Falcon define quem vira cliente Finza — e portanto quem pode virar inadimplente lá na ponta. Mudanças na política de crédito **alteram o perfil da carteira que a Torre cobra**. Vale alinhar com Girlan quando políticas mudam.

---

## 3 · Veritas (KYC)

**Slogan:** Decisões ágeis e precisas.

### O que faz
Camada de compliance e segurança. Entra **após** o Falcon aprovar o crédito. Três frentes:
- **Análise KYC** — verificação completa de identidade + análise de risco
- **Gestão de Retirada** — fluxo de criação, assinatura digital e verificação por QR Code
- **Compliance & Monitoramento** — controle de pendências, orientação antifraude, due diligence com revisões periódicas

Dashboard (FinzaDay slide 23) consolida: índice de risco KYC, taxa de reprovação, suspeita, SLA médio, processo criminal, motivos de reprovação (documento falso, crime do colarinho, etc.).

### Papel no fluxo
**Etapa 3** — Compliance + KYC. Após Falcon aprovar, Veritas valida que o cliente é quem diz ser.

### Responsável
**Girlan** (TechLead). Time: mesmo do Falcon (Yago, Melqui) + Carlos (QA).

### Stack
Integração com idwall (prova de vida — visto no slide 27 do FinzaDay), biometria, OCR de documentos.

### Status / projetos futuros
**Motor de KYC proprietário** está no foco da missão 2026 — automação que elimina dependências de terceiros (FinzaDay slide 30). Hoje depende parcialmente de fornecedores externos.

### Relação com a IAF
KYC robusto reduz fraude no funil — e fraude na entrada é uma causa raiz de inadimplência crônica lá na Torre. Quando a IAF detectar perfis recorrentes de calote, vale flag para Veritas reforçar a régua de entrada.

---

## 4 · Módulo Financeiro (MF)

**Slogan:** Backoffice da operação Finza.

### O que faz
O backoffice onde o **time de cobrança Finza** mais atua no dia a dia. Acompanha a vida do cliente após contrato fechado. Cobre 5 frentes (FinzaDay slide 22):

1. **Gestão Cobrança Avulsa** — Link de pagamento Cartão de Crédito, Pix, gestão de pagamento de entrada/sinal/frete
2. **Criação do Contrato e Cobrança** — Registro no MF, geração automática das parcelas, emissão e disponibilização dos boletos
3. **Integração com Bancos e FIDCs** — Integração com bancarizadores, gestão de instruções bancárias, gestão de recompras de parcelas/contratos FIDCs
4. **Gestão das Parcelas** — Monitoramento de vencimentos/pagamentos, atualização de status, histórico e rastreabilidade
5. **Renegociação ou Reparcelamento** — Renegociação de parcelas, refinanciamento de contrato (novos prazos e taxas), **fluxo de renegociação via IA/MCP** (este é o ponto de integração direta com a Torre/Esperanza)

### Papel no fluxo
**Etapa 4** — Após assinatura do contrato (etapa 3+), o MF gera os títulos e acompanha vencimentos. É a **fonte da verdade financeira** da carteira ativa.

### Responsável
**Marco** (TechLead). Time: David Turati (FullStack), Valter (Back-end), Matheus Rangel (FullStack), Tiago Lemos (Back-end), Cássio (QA), + vaga Front Pleno aberta.

### Stack
React + back. Integração com bancarizadores, FIDCs, e — via MCP — com a Torre/Esperanza.

### Cedentes que circulam aqui
FIDC, Blips, Finza, Ideal, Suprimentos. Cada um com regras próprias de prazo, juros e cobrança.

### Relação com a IAF
**Crítica.** A Torre se alimenta da base fria do MF para monitorar inadimplência. A Esperanza consulta MF (e Sankhya, via integração) em tempo real antes de tomar ação. Mudança de campo/status no MF propaga para tudo que a IAF faz.

---

## 5 · Torre de Controle

**Slogan:** Sistema operacional da cobrança Finza.

### O que faz
Plataforma onde a equipe de cobrança Finza opera o dia a dia. **Não é um agente de IA** — é a plataforma onde a IA (Esperanza), as automações, os filtros e os disparos vivem. Módulos:

- **Rede de contatos do cliente** — telefones, e-mails, vínculos
- **Réguas de cobrança com filtros personalizáveis** — quem cai em qual fluxo
- **Campanhas integradas (HyperFlow → WhatsApp via API oficial Meta / outros canais)** — disparo dinâmico
- **Configuração da Esperanza** — prompt, tools, personalidade, funções
- **Rotinas ETL** — alimentam a Torre com dados frios do MF, Sankhya, BigQuery
- **Integrações sistêmicas** — módulo próprio com MCP, Bitrix, etc.

### Como funcionam as campanhas
Cada campanha cobre um assunto específico. Dentro dela rodam clientes que caem nas **réguas** configuradas. Cada régua pode ter vários filtros — tudo dinâmico e customizável. Hoje há **régua hard-coded de cobrança 91+ dias** que é o primeiro caso de uso da Torre 2.0 (vai virar prompt versionado).

### Papel no fluxo
**Etapa 5** — Saúde do cliente. Quando o MF detecta inadimplência, a Torre assume. Cobrança amigável → 4.0 → notificação extrajudicial → recuperação → judicial.

### Responsável
**João Vinicius** (Supervisor IAF) — único sistema sob gestão direta da IAF. Tech Lead cross-squad: **Joao Lucas Freitas**. Time: Marcos Rodrigues, João Pedro da Silva Neto, Leandro Marques.

### Stack
React 19 + Vite 7 + Tailwind 4 + shadcn/ui · Supabase (Postgres + Edge Functions Deno) · 2 ambientes (prod + dev branch criados por Joao Lucas em 24/abr) · MCP · BigQuery (datasets `FINANCEIRO.deals`, `COBRANCA.envios_cobranca`, `PLATAFORMA.negotiation`, `SANKHYA.TitulosFull`) · Multi-tenant `org_{slug}`.

### Agentes que vivem na Torre / orbitam a IAF
| Agente | Função | Status | Dono |
|---|---|---|---|
| **Esperanza** | Cobrança Finza — amigável → 4.0 → extrajudicial | Em produção | Marcos Rodrigues |
| **Valentina** | Recepção/saque Finza — orquestradora WhatsApp | Em deploy | João Pedro |
| **Clara** | Formalização Finza+Blips (multi-org) | Em adaptação | A definir (transição IA2→IAF) |
| **Francisco** | Diagnóstico técnico (módulo financeiro + neurônio/IoT) | Deploy final Sprint 1 | A definir |
| **Distrato** | Cancelamento contratual (prompt dentro da Torre 2.0) | A desenvolver Sprint 3 | — |
| **Retirada** | Logística reversa (prompt dentro da Torre 2.0) | A desenvolver Sprint 4 | — |
| **Reembolso** | Funcionalidade dentro da Clara | A desenvolver Sprint 3 | — |
| **Saque Finza** | = Valentina, evolução em curso | — | João Pedro |

### Curadoria de conteúdo
Time Finza dedicado: **Felipe, J, Breno** — recebem acesso à STIA (sistema de treinamento Blips/Finza) + à Torre 2.0 para configurar prompts sem precisar de dev.

### Plano em curso (resumo)
- **Torre 2.0** (Sprint 2, 18/mai → 29/mai) — vira plataforma de orquestração; prompts adaptáveis por régua/filtro/fase; UI visual para o time Finza editar
- **Sistema de Evaluation** (Sprint 3, 01/jun → 12/jun) — LLM-as-judge, pass rate ≥ 90% para promoção, rollback em 1 clique
- Detalhe completo no roadmap (Mateus, aprovado pelo CTO em 28/abr, Epic IAF-130 com 37 issues, entrega total prevista 10/jul/2026)

---

## Tabela-resumo (cheat sheet)

| # | Plataforma | Etapa | TechLead | Sob | Status |
|---|---|---|---|---|---|
| 1 | Finza Start | 1 — Originação | Marco | DEV | Em prod, expandindo |
| 2 | Falcon | 2 — Análise de crédito | Girlan | DEV | Em prod |
| 3 | Veritas | 3 — Compliance/KYC | Girlan | DEV | Em prod, motor próprio em 2026 |
| 4 | Módulo Financeiro | 4 — Aceite + título | Marco | DEV | Em prod |
| 5 | **Torre de Controle** | **5 — Cobrança** | **Joao Lucas Freitas** | **IAF** | **Em prod, Torre 2.0 em curso** |

---

## Para a IAF, o que importa

1. **A Torre é a única plataforma que mexemos.** As outras 4 são "vizinhas" — integramos, dependemos, mas não decidimos roadmap.
2. **Mudanças upstream chegam aqui.** Política de crédito (Falcon), regras de KYC (Veritas), campos do MF — tudo isso bate na carteira que a Torre cobra. Manter relacionamento com Marco, Girlan e Herivelton (Head de Produtos) é estrutural.
3. **MF é o vizinho mais quente.** A Esperanza consulta MF em tempo real. Cobrança indevida quase sempre tem raiz em campo errado/status defasado do MF. Slide 8 do deck (pendências) tem item específico sobre isso.
4. **Próximo prompt do usuário** vai detalhar problemas técnicos identificados — vão entrar no slide 8 com mais profundidade.
