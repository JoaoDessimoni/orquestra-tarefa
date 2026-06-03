---
name: finza-mapas
description: Estrutura canônica dos mapas mentais do workspace IAF — o mapa TEXTUAL (narrativa institucional por agente/frente/sistema, padrão "de onde veio / onde estamos / para onde vamos") e o mapa VISUAL (mapa-mental.html, projeção do Backlog em canvas). Carregue antes de criar/atualizar qualquer mapa (agente context-curator, comando /mapa) ou ao referenciar um mapa em análise/deck.
---

# Finza — mapas mentais

O workspace tem **dois tipos de mapa mental**. Não confunda: têm fonte, formato e propósito distintos.

| Tipo | Arquivo | Fonte | Formato | Mantido por |
|---|---|---|---|---|
| **Textual** | `Backlog/contexto/mapa_<assunto>.md` | Conhecimento do squad + docs | Markdown narrativo | `context-curator` / `/mapa <assunto>` |
| **Visual** | `mapa-mental.html` (raiz) | `Backlog/frentes/**/*.md` | JSON inline → canvas | `mapa-updater` / `/mapa regenerar` |

> O textual é **conhecimento humano destilado** (história, pessoas, decisões, riscos). O visual é **projeção mecânica** do backlog (frentes, itens, dependências). Um não substitui o outro.

---

## 1 · Mapa TEXTUAL — narrativa institucional

Documento que captura o **estado mental** de um agente, frente, plataforma ou processo: de onde veio, onde está, para onde vai, quem segura, o que dói. É a memória que não cabe num item de backlog nem numa nota de reunião.

**Referência canônica:** `Backlog/contexto/mapa_esperanza.md` (autor João Lucas, 26/05/2026).

**Quando criar um mapa textual:**
- Um agente/frente acumulou história e contexto que se perde entre conversas (ex: Esperanza, Valentina, Torre).
- O squad fez um discovery e o output não é uma lista de tarefas, é entendimento.
- Onboarding de alguém numa frente exige "o filme inteiro", não os itens soltos.

**Quando NÃO criar:**
- É uma tarefa → item de backlog (`Backlog/frentes/`).
- É decisão de uma reunião → nota de reunião (`Gestao/Reunioes/`).
- É contexto de negócio amplo da Finza → `Docs/finza/`.
- É spec técnica de plataforma vizinha → `Backlog/contexto/<sistema>_overview.md` (overview, não mapa).

### Estrutura canônica (seções na ordem)

```markdown
<Título do assunto>
Data: DD/MM/AAAA
Autor: <nome>

De onde veio, onde estamos e para onde vamos

## De onde veio
<Origem. Por que existe. Decisões fundadoras. O que já se tentou e por quê.>

## Onde estamos
<Estado atual sem maquiagem. O que funciona, o que é frágil. Pontos de falha
declarados como pontos de falha — não esconda dívida.>

## Para onde vamos
<Direção, não promessa. Hipóteses de roadmap. O que precisa ser mapeado antes
de decidir. Marque incerteza como incerteza.>

## Principais fluxos (trabalho)
<As atividades reais do dia a dia de quem cuida disso. Numeradas.>

## Pessoas-chave
<Quem detém qual conhecimento. Quem decide o quê. Onde está o gargalo humano.>

## Principais problemas / incidentes
<Padrões de falha recorrentes. Causa-raiz quando conhecida.>

## Pendências
<O que está mapeado mas não resolvido. Vincule ao item de backlog (BXX##) quando existir.>

## Observações
<Notas técnicas, dependências críticas, "sem isso tudo desmorona".>
```

**Regras de redação (herdam `finza-tom-voz`):**
- Voz honesta. "Não considero isso consolidado hoje; é um ponto de falha" é o tom certo.
- Frases curtas. Sem jargão de consultoria.
- Datas absolutas (`26/05/2026`).
- Nomeie pessoas com papel ("Leandro — prompt", "Mateus Alberone — Hyperflow").
- Vincule a artefatos por ID: itens de backlog `BES03`, iniciativas `RM07`.
- Não invente. Conhecimento que falta vira `<!-- TODO: confirmar com <pessoa> -->`.

**Nomenclatura:** `Backlog/contexto/mapa_<assunto>.md` em kebab/snake minúsculo, ASCII (`mapa_esperanza.md`, `mapa_torre.md`, `mapa_valentina.md`). Overviews técnicos puros usam `<sistema>_overview.md` (sem prefixo `mapa_`).

---

## 2 · Mapa VISUAL — `mapa-mental.html`

Canvas interativo (DOM + SVG, single-file, sem libs) que projeta o Backlog em nós conectados: hub central → frentes → itens → subtarefas, com arestas para dependências e bloqueios.

**Fonte da verdade:** os `.md` em `Backlog/frentes/`. O HTML é **projeção descartável** — apagá-lo não perde dado, basta regenerar.

**Contrato de dados** — bloco `<script type="application/json" id="map-data">`:

```json
{
  "generated_at": "<YYYY-MM-DD>",
  "owner": "João Vinícius",
  "squad": "IAF — Inteligência Artificial Finza",
  "frentes": [
    {
      "key": "esperanza",
      "label": "Esperanza",
      "color": "#<hex>",
      "prefix": "BES",
      "sponsor": "Jéssica",
      "plataforma": "Torre de Controle",
      "desc": "<1 linha>"
    }
  ],
  "items": [
    {
      "id": "BES03", "frente": "esperanza", "title": "...",
      "status": "em-curso", "prioridade": "alta",
      "esforco": "M", "valor_negocio": "alto",
      "rice": { "reach": 8, "impact": 7, "confidence": 6, "effort": 5, "score": 6.7 },
      "dependencias": ["BES05"], "bloqueia": ["BVA02"],
      "deadline": "2026-Q3",
      "subtarefas": [ { "id": "ST-1", "title": "...", "status": "...", "isGate": true } ],
      "tags": ["esperanza", "tabulacoes"]
    }
  ]
}
```

> O `map-data` é **o mesmo conteúdo** que alimenta `backlog.html` (`id="backlog-data"`): mesmas `frentes` e `items`. A diferença é só a renderização (canvas vs kanban). Regenerar os dois a partir da mesma leitura do `Backlog/frentes/` mantém-nos coerentes.

**Regra de manutenção:** quem edita o `map-data` (`mapa-updater`) **só** toca no bloco JSON entre `<script ... id="map-data">` e `</script>`. Nunca mexe em HTML/CSS/JS. O estado de layout (pan/zoom/filtros) vive em `localStorage` no browser e não é responsabilidade do gerador.

---

## 3 · Coerência entre as projeções

```
Backlog/frentes/**/*.md   ── fonte da verdade (itens estratégicos)
        │
        ├─ /backlog regenerate ─▶ backlog.html      (id="backlog-data")  · kanban
        └─ /mapa regenerar     ─▶ mapa-mental.html   (id="map-data")      · canvas

Backlog/contexto/*.md     ── fonte da verdade (mapas textuais, overviews)
        └─ /mapa <assunto>     ─▶ mapa_<assunto>.md   (curadoria humana assistida)
```

`/sync` roda os dois geradores de projeção do backlog em sequência (backlog kanban + mapa visual). Os mapas textuais **não** entram no `/sync` — são curadoria, não projeção mecânica.
