# Análises — Squad IAF

Análises ad-hoc do supervisor. Cada arquivo é um documento autônomo: investigação técnica, comparativo, RFC, post-mortem, cruzamento.

---

## Estrutura datada

```
Backlog/analises/
├── <dd-mm-aaaa>/
│   ├── <YYYY-MM-DD>_<slug>.md          # análise individual
│   └── relatorios/                     # relatórios derivados
│       └── <YYYY-MM-DD>_<slug>.md
```

Cada **pergunta de investigação** vira uma análise individual. Múltiplas análises por dia coexistem na mesma pasta.

## Convenção

**Pasta do dia:** `<dd-mm-aaaa>/` (ex: `18-05-2026/`).
**Arquivo de análise:** `<YYYY-MM-DD>_<slug>.md`.
**Arquivo de relatório:** `relatorios/<YYYY-MM-DD>_<slug>.md`.

**Frontmatter (análise):**
```yaml
---
title: <título>
data: YYYY-MM-DD
autor: João Vinícius
tipo: investigacao | comparativo | rfc | postmortem | proposta | cruzamento | roadmap
fontes-consultadas: []
relacionadas: []
status: rascunho | revisao | publicada
tags: []
---
```

**Frontmatter (relatório):**
```yaml
---
title: <título>
data: YYYY-MM-DD
destinatario: <quem recebe>
analise-fonte: <caminho da análise ou null>
owner: João Vinícius
status: rascunho | revisao | enviado
classificacao: interno | restrito | publico
---
```

---

## Quando usar

- Decisão técnica com rastro (qual stack, ferramenta, abordagem).
- Investigação de incidente — cronologia + causas + ações.
- Proposta para CTO/squad.
- Comparativo de opções com prós/contras.
- Consolidação de roadmap por ciclo.
