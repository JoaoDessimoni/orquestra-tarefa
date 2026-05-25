---
id: BTR04
title: Validação de cálculos e conceitos dos relatórios IA da Torre
frente: torre
status: em-curso
prioridade: media
rice:
  reach: 6
  impact: 6
  confidence: 7
  effort: 3
  score: 8.4
esforco: S
valor_negocio: medio
origem:
  pendencias: [P31]
  reunioes:
    - Gestao/Reunioes/18-05-2026/2026-05-18-alinhamento-jessica-revisao-roadmap.md
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM18
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-Q3
dependencias: [BTR03, BES08]
bloqueia: []
riscos:
  - Relatórios podem ter cauda longa de consumidores não-óbvios (auditoria, contratos, regulatório) — mudança quebra fluxo desconhecido.
  - Relatórios "subutilizados" podem estar parados por motivo legítimo (sazonalidade) — descomissionar prematuramente vira dor.
premissas:
  - Time Torre/Dados tem capacidade para revisão.
  - Dicionário canônico de BTR03 está disponível para reuso.
tags: [torre, relatorios-ia, validacao, jessica]
---

# BTR04 — Validação de cálculos e conceitos dos relatórios IA da Torre

## História de usuário

Como **gestor de cobrança**,
quero **relatórios IA da Torre com cálculos validados e nomenclatura padronizada**,
para **eliminar ambiguidade entre relatórios e fortalecer decisões baseadas em dados**.

## Contexto

Relatórios gerenciais e operacionais relacionados à IA — produzidos pela Torre — precisam validação conjunta com o time de cobrança. Análogo a BTR03 (dashboards), mas focado em relatórios em vez de painéis vivos. Mesma preocupação de calibragem semântica.

**Origem da demanda:** Doc `2026-05-18_jessica_roadmap-ia-automacoes.txt`:
> "Relatório IA — Validação conjunta de dashboards, cálculos, conceitos e usabilidade dos relatórios gerenciais e operacionais relacionados à IA."

## Critérios de aceite

- **CA-1** — Given inventário de relatórios IA publicado, When listado, Then cada um tem: recorrência, formato, destinatário, dono, último envio.
- **CA-2** — Given dicionário canônico de BTR03 disponível, When relatórios são validados, Then reusam definições (não criam concorrentes).
- **CA-3** — Given relatórios redundantes/obsoletos identificados, When propostos para descomissionamento, Then validados com destinatário antes de remover.
- **CA-4** — Given nomenclatura padronizada, When publicada, Then mesmo conceito = mesmo nome em todos os relatórios.

## Subtarefas

- [ ] **ST-1 — Aguardar BTR03 entregar dicionário canônico.**
- [ ] **ST-2 — Aguardar BES08 corrigir divergência de dados.**
- [ ] **ST-3 — Levantar quais relatórios IA existem** (recorrência, formato, destinatário, dono).
- [ ] **ST-4 — Validar cálculos e definições conceituais** com Jéssica.
- [ ] **ST-5 — Identificar relatórios redundantes ou subutilizados.**
- [ ] **ST-6 — Padronizar nomenclatura** (mesmo conceito = mesma definição).
- [ ] **ST-7 — Validar com destinatário antes de descomissionar.**
- [ ] **ST-8 — Documentar dicionário expandido** em `Backlog/contexto/` (reusa o de BTR03).

## Dependências cruzadas

- **Depende de:** BTR03 (dicionário canônico), BES08 (divergência dados).
- **Sinergia direta:** BTR03 (mesma calibragem semântica).

## Observações PO

**Pontos de atenção:**

1. **Não faz sentido rodar em paralelo com BTR03.** Validar relatórios sem dicionário canônico de BTR03 = duplicar trabalho. Tratar como BTR03 fase 2.
2. **Cauda longa de consumidores.** Relatório que ninguém usa pode ter sumido do radar mas estar em fluxo regulatório/auditoria. ST-7 (validar antes de descomissionar) é gate.
3. **Reuso completo com BTR03.** Mesmas pessoas, mesmas sessões, mesmo dicionário. Considerar fundir os dois itens se refinement mostrar redundância.
4. **"Validação conjunta" = sponsor não-aussente.** Jéssica precisa estar nas sessões. Sem ela, é exercício sem entregável real.

## Definição de pronto

- [ ] Inventário publicado
- [ ] Validação executada
- [ ] Dicionário canônico expandido publicado
- [ ] Relatórios redundantes descomissionados (com aprovação de destinatário)
- [ ] Nomenclatura padronizada em produção

## Histórico

- 2026-05-22 — Item criado a partir de P31 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM18) consolidando reunião revisão geral com Jéssica de 18/05/2026.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 8.4. Esforço: S. Dependências de BTR03 e BES08 adicionadas. Observação PO sobre fundir com BTR03 se refinement mostrar redundância.

## Notas

Considerar fundir com BTR03. Mesmo time, mesma calibragem semântica, mesmo dicionário.
