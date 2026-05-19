---
description: Roda o slide-reviewer em qualquer .html de Apresentacoes/. Devolve relatório com bloqueadores e observações. Não corrige — só aponta. Para corrigir, peça depois de ver o relatório.
---

# /revisar-deck — auditar deck existente

`$ARGUMENTS` deve ser o caminho ou nome do `.html`. Se não veio, liste os disponíveis com `Glob`:

```
Apresentacoes/executando/*.html
Apresentacoes/entregues/*.html
```

Pergunte qual via `AskUserQuestion` se houver múltiplos.

## Execução

Invoque `slide-reviewer` com o caminho do arquivo.

Aguarde o relatório.

## Encerramento

Reporte o relatório do reviewer **na íntegra**. Não resuma — o usuário precisa ver bloqueadores e observações detalhados.

Após o relatório, ofereça:

```
Próximos passos disponíveis:
- "Corrige B01 e B02" — eu chamo o builder para aplicar correções via Edit.
- "Aprovado, move pra entregues/" — eu movo o arquivo.
- "Iterar slide N" — eu rodo writer→designer→builder só nesse slide.
```

Não execute nenhuma ação sem o usuário pedir.
