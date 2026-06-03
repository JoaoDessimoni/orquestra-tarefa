---
id: QMR3344
title: [FRANCISCO] Setup inicial e normalização de entrada
frente: clara
status: entregue
prioridade: media
fonte: quimera+jira
quimera: 3344
jira: IAF-89
categoria: TI
deliverable_type: Outros
story_points: 3
tipo_origem: Subtarefa
responsavel: João Pedro
criada: 2026-04-09
concluida: 2026-04-12
prazo: null
prazo_estimado: False
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: [IAF-49]
tags: [fonte-quimera-jira, cat-ti]
---

# QMR3344 — [FRANCISCO] Setup inicial e normalização de entrada

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3344 · Jira IAF-89 · categoria: TI

Toda a camada de recebimento, normalização e gestão de estado da conversa, o "esqueleto" que sustenta o agente antes da IA entrar em cena.

- [x] Setup inicial e normalização de entrada - webhooks, variáveis globais, identificação de canal.
- [x] Fluxo de manutenção/encerramento - flag `manutencao/encerramento` com retorno antecipado.
- [x] Gestão de usuários no MongoDB - busca, criação e merge na collection `users_francisco`.
- [x] Gestão de sessões - continuidade, troca de contexto, criação, atualização e comando de limpar.
- [ ] Tratamento de arquivos - switch de tipo, download e transcrição de áudio (Whisper), normalização de entrada.
- [x] Fila de mensagens concatenadas - estados `[P] Processando` e `[B] Bloqueada` no PostgreSQL para debounce/agrupamento.

## Rastreabilidade

- **Responsável:** João Pedro
- **Quimera:** #3344 (status fonte mapeado → `entregue`)
- **Jira:** IAF-89 (projeto IAF)
- **Categoria fonte:** TI
- **Criada:** 2026-04-09
- **Concluída:** 2026-04-12
- **Subtarefa de** (bloqueia): IAF-49 — convertida de subtarefa Jira IAF-49

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.