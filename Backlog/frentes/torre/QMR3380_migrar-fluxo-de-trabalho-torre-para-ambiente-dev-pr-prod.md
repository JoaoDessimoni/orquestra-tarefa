---
id: QMR3380
title: [Sprint 0] Migrar fluxo de trabalho Torre para ambiente dev/PR/prod
frente: torre
status: entregue
prioridade: media
fonte: quimera+jira
quimera: 3380
jira: IAF-134
categoria: TI
deliverable_type: Outros
story_points: 8
tipo_origem: Tarefa
responsavel: João Lucas Freitas
criada: 2026-04-27
concluida: 2026-05-20
prazo: null
prazo_estimado: False
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: [QMR3385, IAF-141, IAF-142, IAF-143]
bloqueia: []
tags: [fonte-quimera-jira, cat-ti]
---

# QMR3380 — [Sprint 0] Migrar fluxo de trabalho Torre para ambiente dev/PR/prod

## Descrição (espelho — fonte: quimera+jira)

> Origem: Quimera #3380 · Jira IAF-134 · categoria: TI

## Contexto

Joao Lucas criou na sexta 24/abr o ambiente Supabase dev da Torre (project_ref dcedqaatdeobbrlwxzha, branch da main idinihcyezkqfarztrdx). A partir da Sprint 1, todo desenvolvimento na Torre passa por:

```
branch dev → PR → aprovação Mateus OU Joao Lucas → merge main → deploy prod
```

Ninguém commita direto na main. Hotfixes seguem mesmo fluxo com fast-track.

## Critério de aceite

* Documentação do fluxo (branches, PR, deploy dev, deploy prod, checklist de PR)
* Pipeline/deploy automático para ambiente dev configurado
* Checklist de PR definido (testes, descrição, link Jira)
* Time IAF (Marcos, JP SN, Leandro) treinado no novo fluxo

## Aprovadores autorizados de PR para prod

* Mateus Alberone (mateus@blips.com.br)
* Joao Lucas Freitas (joao.freitas@blips.com.br)

## Subtasks

Esta tarefa tem 4 subtasks (a serem criadas).

## Prazo

01/mai/2026 (sexta)

## Epic

IAF-130

## Rastreabilidade

- **Responsável:** João Lucas Freitas
- **Quimera:** #3380 (status fonte mapeado → `entregue`)
- **Jira:** IAF-134 (projeto IAF)
- **Categoria fonte:** TI
- **Criada:** 2026-04-27
- **Concluída:** 2026-05-20
- **Subtarefas vinculadas** (depende de): QMR3385, IAF-141, IAF-142, IAF-143

## Histórico

- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=quimera+jira.