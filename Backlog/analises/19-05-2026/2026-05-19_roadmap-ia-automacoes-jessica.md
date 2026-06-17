---
title: Roadmap IA & Automações 2026Q3 — escopo, frentes e iniciativas
data: 2026-05-19
autor: João Vinícius
tipo: roadmap
fontes-consultadas:
  - "Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt"
  - "Backlog/reunioes/18-05-2026/2026-05-18_alinhamento-jessica-revisao-geral.md"
  - "Backlog/reunioes/18-05-2026/2026-05-18_alinhamento-jessica-formalizacao.md"
  - "Backlog/reunioes/15-05-2026/2026-05-15_jornada-cliente-diretoria.md"
  - "Anotações pessoais caderno 2026-05-15/18"
relacionadas: [P12, P13, P14, P15, P16, P17, P18, P19, P20, P21, P22, P23, P24, P25, P26, P27, P28, P29, P30, P31, P32, P33, P34, P35, P36]
status: publicada
tags: [roadmap, esperanza, valentina, clara, torre, automacoes, jessica, diretoria, 2026q3]
---

# Roadmap IA & Automações 2026Q3

Consolida 3 reuniões (2026-05-15 diretoria + 2026-05-18 11h e 14h Jéssica) em **24 iniciativas (RM01–RM24)** distribuídas em **6 frentes**.

## Distribuição por frente

| Frente | Iniciativas | Alta | Média | Baixa |
|---|---|---|---|---|
| Esperanza | 6 (RM01–RM06) | 4 | 2 | 0 |
| Valentina | 5 (RM07–RM11) | 4 | 1 | 0 |
| Clara | 4 (RM12–RM15) | 4 | 0 | 0 |
| Torre | 5 (RM16–RM20) | 0 | 4 | 1 |
| Automações | 2 (RM21–RM22) | 0 | 2 | 0 |
| Estratégica | 2 (RM23–RM24) | 2 | 0 | 0 |
| **Total** | **24** | **14** | **9** | **1** |

## Iniciativas por frente

### Esperanza

| ID | Título | P## | Prioridade |
|---|---|---|---|
| RM01 | Renegociação de valores vencidos com transferência humana | P16, P17 | alta |
| RM02 | Mapear volume de transferências IA→humano por departamento | P18 | alta |
| RM03 | Tabulações automáticas via IA | P19 | media |
| RM04 | Discovery Esperanza — fluxo, escopo e domínio | P20 | alta |
| RM05 | Resgatar relatório pré-Torre de redirecionamento IA→humano | P21 | alta |
| RM06 | Mapear agentes IA por número (Finza e Blips) | P22 | media |

### Valentina

| ID | Título | P## | Prioridade |
|---|---|---|---|
| RM07 | Identificar originador automaticamente | P23 | alta |
| RM08 | Mapear demandas Rhino na Valentina | P24 | alta |
| RM09 | Roteamento Rhino → suporte Rhino (**urgente**, da diretoria) | P15 | alta |
| RM10 | Base de contexto Valentina (jornada Finza completa) | P13 | alta |
| RM11 | MCPs das plataformas Finza | P14 | media |

### Clara

| ID | Título | P## | Prioridade |
|---|---|---|---|
| RM12 | Comprovantes de endereço (solicitar + receber) | P25 | alta |
| RM13 | Tratativa de reprovados em formalização | P26 | alta |
| RM14 | Biometria — envio e acompanhamento | P27 | alta |
| RM15 | Nova raia Bitrix para visibilidade de reembolsos | P28 | alta |

### Torre de Controle

| ID | Título | P## | Prioridade |
|---|---|---|---|
| RM16 | Integração Rhino ao ecossistema Torre | P29 | media |
| RM17 | Validação conjunta de dashboards | P30 | media |
| RM18 | Validação dos relatórios IA | P31 | media |
| RM19 | RCS (Rich Communication Services) | P32 | baixa |
| RM20 | Inteligências específicas por empresa/carteira | P33 | media |

### Automações

| ID | Título | P## | Prioridade |
|---|---|---|---|
| RM21 | Bitrix Cobrança 4.0 — histórico contínuo (log acumulado) | P34 | media |
| RM22 | Revisão gatilhos Hyper + novas oportunidades | P35 | media |

### Estratégica

| ID | Título | P## | Prioridade |
|---|---|---|---|
| RM23 | NPS pós-formalização via IA | P12 | alta |
| RM24 | Discovery: narrativa "o que a IA faz para o negócio Finza" | P36 | alta |

## Regras operacionais (referência — não viram pendência)

Especificações de negócio que orientam a implementação de Clara (RM12–RM14).

### Comprovação de endereço
Comprovantes dos últimos 30 dias (conta consumo: água/luz/internet; fatura cartão). Para 3 endereços: empresa (em nome da empresa, sócio ou responsável), residencial do responsável (pais/cônjuge aceito; cônjuge exige certidão de casamento), local de entrega. **Não aceitos:** terceiros, cartão CNPJ, NF como comprovante, escaneados/fotocópias.

### Adicional construção civil
Foto da fachada + 3 NFs (NFS-e ou NF-e) emitidas pelo cliente nos últimos 3 meses, válidas e legíveis.

### Coleta de dados para reembolso
Banco, agência, conta corrente, chave PIX — todos vinculados ao CNPJ do contrato. Devolução exclusivamente em conta do mesmo CNPJ.

## Dependências e sequenciamento

1. **RM04 (Discovery Esperanza) precede RM01–RM03 e RM05** — sem discovery, evolução funcional é especulativa.
2. **RM14 (Biometria) depende de mapear gatilho atual** — não codar sem entender o trigger.
3. **RM10 (Base contexto Valentina) é insumo de RM07 e RM08** — sem fonte da verdade, identificar originador vira improviso.
4. **RM11 (MCPs) é projeto de longo prazo** — deadline 2026-07-15, depende de TI Plataformas.
5. **RM15 (Raia Bitrix) é independente de código** — pode acontecer em paralelo às RM12–RM14.
6. **RM24 (Narrativa IA) é pré-requisito para apresentações executivas.**

## Pontos de atenção imediatos (2026-05-19)

- **RM09/P15 (Rhino Valentina)** — deadline 2026-05-26, diretoria espera.
- **RM04/P20 (Discovery Esperanza)** — destrava 4 outras iniciativas, deve iniciar na semana.
- **RM24/P36 (Narrativa IA)** — gargalo de comunicação executiva.
