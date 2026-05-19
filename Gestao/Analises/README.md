# Análises — Squad IAF

Análises ad-hoc produzidas pelo supervisor. Cada arquivo é um documento autônomo: investigação técnica, comparação de opções, RFC interna, post-mortem.

---

## Estrutura datada

```
Gestao/Analises/
├── <dd-mm-aaaa>/                            # pasta do dia (ex: 18-05-2026/)
│   ├── <YYYY-MM-DD>_<slug>.md               # análise individual
│   ├── <YYYY-MM-DD>_<outro-slug>.md         # outra análise do mesmo dia (1 por pergunta)
│   └── Relatorio/                           # relatórios derivados das análises do dia
│       └── <YYYY-MM-DD>_<slug>.md
```

Cada **pergunta de investigação** vira uma análise individual. Múltiplas análises por dia coexistem na mesma pasta. Cada análise pode gerar 0 ou mais relatórios em `Relatorio/`.

## Convenção

**Pasta do dia:** `<dd-mm-aaaa>/` (ex: `18-05-2026/`).
**Arquivo de análise:** `<YYYY-MM-DD>_<slug>.md` (ISO no arquivo, ordena cronologicamente).
**Arquivo de relatório:** `Relatorio/<YYYY-MM-DD>_<slug>.md`.

Exemplos:
  - `18-05-2026/2026-05-18_demandas-cobranca-time-negocio.md`
  - `18-05-2026/Relatorio/2026-05-18_relatorio-demandas-cobranca.md`
  - `02-06-2026/2026-06-02_postmortem-esperanza-delirio.md`
  - `10-06-2026/2026-06-10_comparativo-evolution-vs-twilio.md`

**Frontmatter sugerido (análise):**
```yaml
---
title: <título>
data: YYYY-MM-DD
autor: João Vinícius
tipo: investigacao | comparativo | rfc | postmortem | proposta | cruzamento
fontes-consultadas: []        # ex: ["mensagem João Lucas 15/05", "Docs/finza/PLATAFORMAS.md"]
relacionadas: [P02, P05]      # ids de pendências relacionadas
status: rascunho | revisao | publicada
tags: []
---
```

**Frontmatter sugerido (relatório, em `Relatorio/`):**
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

- Decisão técnica que precisa de rastro (qual stack, qual ferramenta, qual abordagem).
- Investigação de incidente — preserve a cronologia + causas + ações.
- Proposta para o CTO/squad — drafts antes de virar slide ou e-mail.
- Comparativo de opções com prós/contras.

Análises curtas (<1 página) podem virar slide direto. Análises densas viram **fonte** para slides futuros.

---

## Como usar

```
/analise <título>                              # cria análise individual no dia atual
/relatorio from <caminho-da-analise.md>        # cria relatório derivado de análise
/relatorio new "<título>"                      # cria relatório do zero (sem análise-fonte)
```

Também aceita linguagem natural — "cria uma análise sobre X" ou "preciso de um relatório de Y para o time de negócio" ativam os comandos automaticamente.
