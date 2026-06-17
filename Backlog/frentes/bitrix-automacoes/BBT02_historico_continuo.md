---
id: BBT02
title: Automação Bitrix Cobrança 4.0 — histórico contínuo
frente: bitrix-automacoes
fonte: backlog
status: a-refinar
prioridade: media
rice:
  reach: 6
  impact: 5
  confidence: 6
  effort: 4
  score: 4.5
esforco: M
valor_negocio: medio
origem:
  pendencias: [P34]
  reunioes:
    - Backlog/reunioes/18-05-2026/2026-05-18-alinhamento-jessica-revisao-geral.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
  analises:
    - Backlog/analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM21
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-Q3
dependencias: []
bloqueia: []
riscos:
  - **CRÍTICO** — Bitrix tem cauda longa de consumidores não óbvios (relatórios, exports, integrações). Mudança em campo "Histórico de Atendimento" pode quebrar fluxo desconhecido.
  - Histórico antigo pode se perder na migração se não for tratado explicitamente.
  - Bitrix nativo pode não suportar multi-valor nesse campo — alternativa é campo paralelo, dobrando complexidade.
  - Dado em modo log acumulado fica enorme rapidamente — performance pode degradar.
premissas:
  - Bitrix Cobrança 4.0 suporta multi-valor ou campo paralelo sem comprometer performance.
  - Há mecanismo de identificar consumidores atuais do campo.
  - Histórico anterior pode ser migrado (não se perde por automação).
tags: [bitrix, automacao, historico, jessica, cobranca]
---

# BBT02 — Automação Bitrix Cobrança 4.0 — histórico contínuo

## História de usuário

Como **operador de cobrança Finza**,
quero **que os campos da seção "Histórico de Atendimento" no Bitrix acumulem registros em vez de sobrescrever o anterior**,
para **preservar rastro operacional completo de cada cliente**.

## Contexto

No Bitrix Cobrança 4.0, os campos da seção "Histórico de Atendimento" funcionam hoje em modo de sobrescrita — um preenchimento elimina o anterior. Isso destrói rastro operacional.

**Origem da demanda:** Doc `2026-05-18_jessica_roadmap-ia-automacoes.txt`:
> "BITRIX Cobrança - Histórico: Automação para registro e consulta de histórico no Bitrix Cobrança 4.0. Os campos da seção 'Histórico de Atendimento' deverão ser adicionados em formato de histórico contínuo, evitando que um preenchimento sobreponha o outro."

Não confundir com BBT01 (raia Bitrix de reembolso) — são dois projetos paralelos no mesmo sistema.

## Critérios de aceite

- **CA-1** — Given campos atuais da seção "Histórico de Atendimento" mapeados, When inventário publicado, Then lista campos afetados + consumidores conhecidos.
- **CA-2** — Given novo modelo de "histórico contínuo" implementado, When operador preenche, Then registro acumula com: timestamp, autor, conteúdo, mantendo histórico anterior íntegro.
- **CA-3** — Given consumidores atuais (relatórios, exports, integrações) verificados, When publicação em produção, Then continuam funcionando sem regressão.
- **CA-4** — Given histórico anterior, When migração roda, Then dado antigo é preservado (não some por substituição).
- **CA-5** — Given operadores piloto, When testam, Then validam que UX faz sentido (não vira parede de texto).

## Dependências cruzadas

- Sem dependência direta de outro item de backlog.
- **Atenção:** mudança em campo Bitrix tem cauda longa de consumidores não-óbvios.

## Observações PO

**Pontos de atenção:**

1. **Maior risco: cauda longa de consumidores.** ST-2 é GATE não-negociável. Qualquer mudança em campo Bitrix sem mapear consumidores quebra fluxo silencioso.
2. **"Histórico contínuo" pode virar parede de texto.** ST-4 (validar UX com operadores) é crítico. Se vira muito longo, ninguém lê e o histórico volta a ser desperdiçado.
3. **Política de retenção (ST-8)** é onde projeto morre se não decidido. Histórico de 5 anos atrás precisa ficar acessível? Auditoria pede?
4. **Decisão técnica (ST-3) afeta tudo.** Multi-valor é mais bonito, campo paralelo é mais seguro, tabela externa é mais escalável. Discutir com TI antes de implementar.
5. **Sem dependência direta de outro item, MAS sinergia forte com BTR07 (refatoração)** se Bitrix migrar de plataforma — não construir solução sobre arquitetura que sai.

## Definição de pronto

- [ ] Campos do histórico em modo acumulado em produção
- [ ] Consumidores existentes verificados sem regressão
- [ ] Operadores piloto validaram a mudança
- [ ] Política de retenção documentada
- [ ] Migração de histórico antigo concluída

## Histórico

- 2026-05-22 — Item criado a partir de P34 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM21) consolidando reunião revisão geral com Jéssica de 18/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 4.5. Esforço: M. CAs em G/W/T. ST-2 (consumidores) elevado a gate não-negociável. Política de retenção (ST-8) marcada como decisão necessária. 3 abordagens técnicas listadas para discussão.

## Notas

Mudança em campo Bitrix tem cauda longa. Levantar consumidores com calma antes de implementar. Validar abordagem técnica com TI.
