# Solicitações — Documentos formalizados pelo negócio

Pasta para guardar documentos originais enviados/produzidos pelo negócio que originam itens de backlog: roteiros de reunião com gestores, transcrições, especificações, e-mails formais, planilhas de demanda.

## Convenção de nome

`YYYY-MM-DD_<autor>_<assunto>.<ext>`

Exemplos:
- `2026-05-18_jessica_roadmap-ia-automacoes.txt`
- `2026-04-22_gemini_agentes-operacoes-finza.txt`
- `2026-06-10_diretoria_priorizacao-q3.pdf`

## Como referenciar

Cada item de backlog que origina de uma solicitação aqui dentro referencia no frontmatter:

```yaml
origem:
  solicitacoes:
    - Backlog/solicitacoes/2026-05-18_jessica_roadmap-ia-automacoes.txt
```

## Fluxo `from-solicitacao`

O comando `/backlog from-solicitacao <arquivo>` lê o documento, identifica N demandas distintas, propõe N itens de backlog — usuário confirma quais aceitar.
