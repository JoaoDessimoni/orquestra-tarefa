---
description: Roda folder-organizer para auditar arquitetura do workspace. Detecta arquivos fora do lugar, nomes fora da convenção, duplicatas, READMEs ausentes. Apresenta plano; não executa nada sem confirmação.
---

# /organizar — auditoria de arquitetura

Invoque `folder-organizer` para escanear todo o workspace.

Brief para o agente:
```
Audite todo o workspace conforme CLAUDE.md.
Apresente plano de organização — não execute moves nem renames sem confirmação.
Inclua:
- Arquivos fora do lugar
- Nomes fora da convenção (por pasta)
- Duplicatas
- READMEs ausentes/desatualizados
- Referências quebradas em CLAUDE.md e Docs/BRIEFING.md
```

## Encerramento

Repasse o plano do agente ao usuário sem editar — ele precisa ver as ações propostas item a item.

Se o usuário responder com "confirma" / "executa" / "ok":
- Re-invoque `folder-organizer` com instrução de executar **apenas** as ações confirmadas.
- Pergunte item-a-item antes de qualquer apagamento (move e rename podem ir em lote; delete não).

Se o usuário pedir só parte ("move os PDFs mas não renomeie ainda"):
- Filtre o plano e execute só o subset.

Após execução, peça ao agente o `RELATÓRIO DE ORGANIZAÇÃO` final e exiba ao usuário.
