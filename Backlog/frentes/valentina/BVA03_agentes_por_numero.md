---
id: BVA03
title: Mapear quais agentes IA estão em quais números (Finza vs Blips)
frente: valentina
status: em-refinamento
prioridade: alta
rice:
  reach: 9
  impact: 7
  confidence: 9
  effort: 1
  score: 56.7
esforco: XS
valor_negocio: medio
origem:
  pendencias: [P22]
  reunioes: []
  solicitacoes: []
  analises:
    - Gestao/Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md
roadmap_vinculado: RM06
owner: João Vinícius
implementador: null
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-25
deadline_alvo: 2026-06-05
dependencias: []
bloqueia: [BVA02, BVA04]
riscos:
  - Inventário pode revelar caos maior que esperado (números sem agente, agentes em números errados) — ação corretiva derivada pode estourar prazo.
  - Time de Plataformas pode resistir a documentar (varejo histórico).
premissas:
  - Existe alguém em TI/Plataformas que conhece o inventário ou pode reconstruir.
  - Bitrix Hyper tem registro de números cadastrados.
tags: [esperanza, valentina, numeros, blips, roteamento, inventario]
---

# BVA03 — Mapear quais agentes IA estão em quais números (Finza vs Blips)

## História de usuário

Como **supervisor IAF**,
quero **inventário canônico de quais agentes IA estão em quais números (Finza e Blips)**,
para **eliminar zonas de ambiguidade sobre quem responde o quê em qual canal**.

## Contexto

Anotação do caderno: investigar números Finza e Blips — quais agentes IA estão em quais números, e como o roteamento funciona. Hoje não há tabela canônica disso, o que cria zonas de ambiguidade sobre quem responde o quê em qual canal. Pré-requisito para discussões de roteamento (incluindo BVA02 Rhino).

**Origem técnica:** Doc `2026-04-22_gemini_agentes-operacoes-finza.txt` mostra que houve uma reorganização recente (Esperança 100% Finza, Valentina lançada como saque) — provável que números estejam desalinhados com nova arquitetura.

## Critérios de aceite

- **CA-1** — Given lista de números oficiais Finza + Blips obtida do time de Plataformas, When publicada, Then cada número tem: agente IA atual, carteira atendida, regra de roteamento, canal, organização Hyper, status (ativo/inativo).
- **CA-2** — Given inventário publicado, When supervisor/squad consulta, Then resposta única, sem ambiguidade.
- **CA-3** — Given lacunas identificadas (números órfãos, agentes em números errados), When documentadas, Then viram itens táticos de correção (não ficam só no relatório).
- **CA-4** — Given tabela versionada, When mudança acontece, Then é atualizada antes da mudança entrar em produção (não depois).

## Subtarefas

- [ ] **ST-1 — Pedir inventário formal ao time de Plataformas** — quem é o ponto focal? Marco? Mateus? alguém de Hyper?
- [ ] **ST-2 — Listar números oficiais** — Finza e Blips, ativos e inativos.
- [ ] **ST-3 — Para cada número documentar:**
  - Agente IA atual (Esperança / Valentina / Clara / outro / nenhum)
  - Carteira atendida (Finza / Blips / Rhino / outras)
  - Regra de roteamento atual
  - Canal (WhatsApp, RCS, SMS, voz)
  - Organização Hyper (Blips ou Finza)
  - Status (ativo / inativo / em transição)
- [ ] **ST-4 — Publicar em `Backlog/contexto/`** como tabela canônica versionada.
- [ ] **ST-5 — Identificar lacunas** — números órfãos, agentes em números errados, sobreposições.
- [ ] **ST-6 — Cada lacuna vira pendência tática** (não item de backlog).
- [ ] **ST-7 — Distribuir tabela** para Jéssica + Squad como referência ativa.

## Dependências cruzadas

- **Bloqueia:** BVA02 (roteamento Rhino), BVA04 (originador automático). Sem inventário, ambos são especulativos.
- Pré-requisito implícito para discussões de canal (BTR05 RCS).

## Observações PO

**Pontos de atenção:**

1. **RICE 56.7 destoa do resto — é o item de menor esforço com maior alavanca.** Esforço XS, bloqueia 2 itens, vale fazer imediatamente.
2. **Trabalho administrativo, não técnico.** Risco principal: time de Plataformas não priorizar resposta. Pressão de supervisor pode resolver em 1 dia.
3. **Lacunas serão a parte assustadora.** Inventário sério geralmente revela 1-2 números órfãos, 1 número com agente errado, e algum agente sombra. Reservar tempo para tratativas.
4. **Tabela só é útil se for mantida.** ST-4 (versionamento) e disciplina de "atualizar antes de mudar em prod" são processo, não tarefa.

## Definição de pronto

- [ ] Inventário publicado em `Backlog/contexto/`
- [ ] Lacunas listadas e tratadas (ou viraram pendência tática)
- [ ] Tabela referenciada por BVA02 e BVA04 nas próximas refinements

## Histórico

- 2026-05-22 — Item criado a partir de P22 (pendência). Status inicial: bruto. Origem: análise mestre do Roadmap 2026Q3 (RM06) consolidando anotações de caderno.
- 2026-05-25 — **Refinamento PO.** Status promovido a `em-refinamento`. RICE 56.7 — destaque máximo da frente. Esforço: XS. Adicionada dependência reversa: BVA02 e BVA04 dependem deste. CAs em G/W/T. Subtarefa explícita de "lacunas viram pendência tática" para não inflar backlog.

## Notas

Pedir ao time de Plataformas o inventário de números e canais. Sem isso, BVA02 e BVA04 são especulação. Item de maior ROI imediato da frente.
