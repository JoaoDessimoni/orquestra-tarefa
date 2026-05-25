# CLAUDE.md — Repasse / Workspace gerencial do Supervisor IAF

Esta pasta é o **workspace gerencial** do João Vinícius (Supervisor IAF, Finza). Ela serve a três propósitos:

1. **Produção de decks/apresentações** no padrão visual Finza — pipeline de agentes especializados.
2. **Gestão do squad IAF** — pendências, reuniões, análises, 1:1s.
3. **Base de contexto viva** — `Docs/` é a fonte da verdade sobre IAF, Torre, Esperanza, plataformas Finza.

Conforme o contexto crescer, a arquitetura aqui descrita evolui. Este arquivo é vivo — atualize sempre que mudar a estrutura.

---

## 0 · Roteamento automático (LER ANTES DE QUALQUER RESPOSTA)

**Antes de responder qualquer prompt, o Claude DEVE avaliar quais skills, agentes ou comandos deste workspace se aplicam — sem o usuário marcar.**

Sequência obrigatória no início de cada turno:

1. Ler a lista de skills disponíveis no `<system-reminder>` (finza-contexto, finza-design-system, finza-tom-voz + skills de comando `pendencia`, `reuniao`, `analise`, `relatorio`, etc.).
2. Considerar os 8 agentes em `.claude/agents/` e os 9 comandos em `.claude/commands/`.
3. Se o pedido do usuário se encaixar em um comando/skill, **invoque-o automaticamente** via a ferramenta Skill — não execute manualmente nem peça pro usuário digitar o comando.

### Gatilhos diretos

| Quando o usuário menciona... | Use |
|---|---|
| pendência tática, bloqueio, "preciso lembrar de…", tarefa atômica do supervisor | `/pendencia` (skill `pendencia`) ou agente `pendencia-tracker` |
| demanda do negócio, história, épico, item, refinar, priorizar backlog, solicitação da Jéssica | `/backlog` (skill `backlog`) ou agente `po-backlog` |
| anexo formalizado, doc do gestor, transcrição de reunião com demandas | `/backlog from-solicitacao <arquivo>` |
| reunião, ata, alinhamento (2+ pessoas) | `/reuniao` (skill `reuniao`) |
| 1:1, 1on1, conversa individual com pessoa do squad | `/reuniao` com tipo `1on1` (move depois para `1on1s/`) |
| análise, investigação, comparativo, RFC, post-mortem | `/analise` (skill `analise`) |
| relatório, report, status para terceiros, devolutiva | `/relatorio` (skill `relatorio`) |
| status semanal, resumo da semana, "como tá o squad" | `/status` |
| deck, slide, apresentação | pipeline `/novo-deck`, `/novo-slide`, `/revisar-deck` |
| pasta fora do lugar, README desatualizado, organização | `/organizar` (agente `folder-organizer`) |
| fato técnico Finza, IAF, Torre, Esperanza | agente `finza-researcher` antes de redigir |
| board, dashboard, painel, visão geral, "como tá tudo" | abrir `BOARD.html` na raiz (projeção de Gestao/, auto-alimentado); usar `/atualizar-board` se sincronia parece defasada |
| visualizar backlog, ver itens, kanban backlog | abrir `backlog.html` na raiz (projeção do Backlog/, regenerado por `/backlog regenerate`) |

### Encadeamento

Quando o pedido cruza 2+ domínios (ex: "analisa essas demandas e gera relatório"), encadeie comandos em sequência: `/analise` → `/relatorio from <análise>` → `/pendencia add` para cada ação derivada.

### Quando NÃO usar comando

- Pergunta puramente informativa ("o que é a Torre?") — responda direto, citando docs em `Docs/finza/` se necessário.
- Conversa exploratória sem artefato a gerar — responda direto, ofereça transformar em comando depois.

---

## 1 · Arquitetura

```
Repasse/
├── .claude/                          # Configuração do agente
│   ├── agents/                       # Sub-agentes especializados (10)
│   │   ├── finza-researcher.md       # Pesquisa nos docs de contexto
│   │   ├── slide-architect.md        # Estrutura outline do deck
│   │   ├── slide-writer.md           # Redige texto no tom Finza
│   │   ├── slide-designer.md         # Define layout/visual do slide
│   │   ├── slide-builder.md          # Implementa HTML/CSS/JS vanilla
│   │   ├── slide-reviewer.md         # QA: checklist Finza
│   │   ├── folder-organizer.md       # Mantém arquitetura organizada
│   │   ├── pendencia-tracker.md      # Gerencia Gestao/Pendencias (TÁTICO)
│   │   ├── po-backlog.md             # Gerencia Backlog/ — Product Owner do squad (ESTRATÉGICO)
│   │   └── board-updater.md          # Reescreve JSON inline de BOARD.html (projeção de Gestao/)
│   ├── commands/                     # Slash commands (11)
│   │   ├── novo-deck.md              # Orquestra deck completo
│   │   ├── novo-slide.md             # Adiciona slide a deck existente
│   │   ├── revisar-deck.md           # Roda reviewer em deck existente
│   │   ├── organizar.md              # Roda folder-organizer
│   │   ├── pendencia.md              # CRUD de pendências táticas
│   │   ├── backlog.md                # CRUD/refinement de backlog estratégico
│   │   ├── reuniao.md                # Registra nota de reunião (em pasta datada)
│   │   ├── analise.md                # Cria análise em Gestao/Analises/<dd-mm-aaaa>/
│   │   ├── relatorio.md              # Cria relatório em Analises/<dd-mm-aaaa>/Relatorio/
│   │   ├── atualizar-board.md        # Força resync do BOARD.html com Gestao/
│   │   └── status.md                 # Gera status semanal do squad
│   ├── skills/                       # Conhecimento canônico (4)
│   │   ├── finza-design-system/      # Paleta, tipografia, padrões visuais
│   │   ├── finza-tom-voz/            # Guia de redação dos slides
│   │   ├── finza-contexto/           # Resumo do negócio Finza
│   │   └── po-backlog/               # INVEST, Given/When/Then, 7 frentes, RICE
│   └── settings.local.json
│
├── CLAUDE.md                         # ← Este arquivo
├── BOARD.html                        # Board perpétuo — projeção visual de Gestao/ (auto-alimentado pelo board-updater)
├── backlog.html                      # Visualizador do Backlog/ — JSON inline com 30+ itens em 7 frentes (regenerado por /backlog regenerate)
│
├── Docs/                             # Base de contexto (fonte da verdade)
│   ├── BRIEFING.md                   # Spec viva do deck principal (atualizar a cada iteração)
│   └── finza/                        # Docs canônicos de negócio
│       ├── CONTEXTO-FINZA.md
│       ├── PLATAFORMAS.md
│       ├── regua_de_cobranca.png
│       └── repasse-joao-vinicius-iaf.html
│
├── Apresentacoes/
│   ├── executando/                   # Decks em construção (HTML editáveis)
│   ├── entregues/                    # Decks já apresentados (read-only de fato)
│   │   └── apresentacao_cto_13-05-2026.html
│   └── referencias/                  # PDFs/PPTX de referência (Boas-vindas Finza, Roadmap, Régua)
│
├── Backlog/                          # Backlog ESTRATÉGICO do squad IAF (7 frentes)
│   ├── README.md
│   ├── BACKLOG.md                    # Relatório mestre (regenerado por /backlog regenerate)
│   ├── frentes/
│   │   ├── bitrix-automacoes/        # BBT## (Bitrix) + BAU## (Automações) — frente unificada
│   │   ├── torre/                    # BTR## — Torre de Controle (multi-org, refatoração)
│   │   ├── clara/                    # BCL## — agente Clara (formalização)
│   │   ├── esperanza/                # BES## — agente Esperanza (renegociação)
│   │   ├── valentina/                # BVA## — agente Valentina (SAC)
│   │   ├── livia/                    # BLV## — agente Lívia (jurídico/distrato)
│   │   └── estrategica/              # BST## — transversal (NPS, narrativa, processo)
│   ├── solicitacoes/                 # Docs formalizados pelo negócio (.txt, .pdf)
│   ├── prints/                       # Screenshots de consulta
│   └── contexto/                     # Docs de apoio (Torre overview, Esperanza overview)
│
└── Gestao/                           # Painel TÁTICO do supervisor
    ├── Reunioes/                     # DATADA — Reunioes/<dd-mm-aaaa>/<arquivo>.md
    ├── Analises/                     # DATADA — Analises/<dd-mm-aaaa>/<arquivo>.md
    │   └── <dd-mm-aaaa>/
    │       └── Relatorio/            # Relatórios derivados das análises do dia
    └── 1on1s/                        # DATADA — 1on1s/<dd-mm-aaaa>/<arquivo>.md
```

> **Pasta datada** = `dd-mm-aaaa/` (ex: `18-05-2026/`). **Arquivos internos** seguem ISO `YYYY-MM-DD_<slug>.md` (ex: `2026-05-18_demandas-cobranca.md`). Cada análise pode gerar 1 ou mais relatórios em `Relatorio/`.

> **Backlog vs Gestao/** — `Backlog/` é estratégico (histórias por frente, RICE, sponsor); `Gestao/` é tático (reuniões, análises, 1on1s do dia a dia). Pendência tática (Gestao/Pendencias) foi absorvida pelo Backlog em 22/05/2026 — quando voltar a ser necessário tracking tático individual, recriar `Gestao/Pendencias/` e usar `pendencia-tracker` em paralelo ao backlog.

---

## 2 · Pipeline de criação de slides

Um slide Finza nasce de 5 etapas. Cada uma tem um sub-agente dedicado em `.claude/agents/`:

```
1. RESEARCH      finza-researcher   →  fatos + referências dos docs em Docs/
2. ARCHITECT     slide-architect    →  outline (slide N de M, conceito, encaixe no deck)
3. WRITE         slide-writer       →  texto no tom Finza (frases curtas, números, sem jargão)
4. DESIGN        slide-designer     →  layout (cards/grid/banner/hero) + tokens do design system
5. BUILD         slide-builder      →  HTML/CSS/JS vanilla single-file
6. REVIEW        slide-reviewer     →  checklist (paleta, navegação, semântica, acessibilidade)
```

O comando `/novo-deck` orquestra as 6 etapas em sequência. `/novo-slide` injeta um slide num deck existente e roda 3→6. `/revisar-deck` roda só a etapa 6 em qualquer HTML.

**Skills carregadas em todo agente de slide:**
- `finza-design-system` — paleta, tipografia, padrões visuais (cards dotted, ◆ iaf, numeração olho)
- `finza-tom-voz` — voz neutra técnico-executiva, frases curtas, números visíveis em azul
- `finza-contexto` — resumo do negócio Finza para evitar fabricação de fatos

---

## 3 · Princípios não-negociáveis

Quando estiver em dúvida, consulte estes princípios antes de produzir conteúdo.

**Conteúdo:**
- Não invente. Marque `<!-- TODO: confirmar com gestor -->` em vez de fabricar fato.
- Cite a fonte. Toda afirmação técnica deve poder ser ancorada em algum doc em `Docs/` ou `Backlog/contexto/`.
- Atualize `Docs/BRIEFING.md` a cada mudança estrutural do deck principal.
- Toda operação que cria/edita arquivo em `Gestao/` deve disparar `board-updater` ao final. O board é projeção da realidade — defasagem é bug.
- **Backlog é estratégico, pendência é tática.** Item de backlog (`Backlog/frentes/`) tem história + critérios de aceite + subtarefas + RICE — dura semanas/meses. Pendência (`Gestao/Pendencias/`) é tarefa atômica do supervisor — dura dias. Não confunda os dois.

**Visual:**
- Paleta Finza exata. Sem cores fora dos tokens em `.claude/skills/finza-design-system/`.
- Cards com `2px dotted var(--finza-blue)`. Marcador `◆ iaf` no canto superior direito.
- Sem emojis decorativos. Emojis funcionais (✓ → 🎯 📅 📍) só quando carregam significado.

**Voz:**
- Frases curtas SVO. Sem jargão de consultoria ("sinergia", "alavancar").
- Números em destaque visual (azul, peso 700).
- Sem "ótima notícia", "boas perspectivas". Quando incerto, declarar incerteza.

**Stack:**
- HTML5 + CSS3 + JS vanilla. Single-file. Inter via Google Fonts.
- Sem React, Vue, Reveal.js, libs de ícone, imagens externas.

---

## 4 · Como usar

### Criar deck novo do zero
```
/novo-deck <tema>
```
Você descreve o objetivo, público, duração. O comando roda o pipeline completo e entrega um `.html` em `Apresentacoes/executando/`.

### Adicionar um slide a um deck existente
```
/novo-slide <arquivo.html> <conceito>
```

### Revisar um deck
```
/revisar-deck <arquivo.html>
```
Roda checklist Finza e devolve relatório.

### Registrar pendência (tarefa tática)
```
/pendencia add <título>
/pendencia list
/pendencia close <id>
```

### Gerenciar backlog estratégico
```
/backlog                                  # lista itens ativos agrupados por frente
/backlog add "<título>"                   # cria item bruto em uma das 7 frentes
/backlog refine <id>                      # quebra subtarefas, escreve CA Given/When/Then, calcula RICE
/backlog review <id>                      # auditoria INVEST (só aponta, não edita)
/backlog prioritize                       # recalcula ranking RICE
/backlog analyze                          # gaps, sobreposições, dependências, deadlines críticos
/backlog regenerate                       # reescreve Backlog/BACKLOG.md mestre + JSON inline do backlog.html
/backlog from <P##>                       # atalho — cria item a partir de pendência tática
/backlog from-solicitacao <arquivo>       # lê doc do negócio em Backlog/solicitacoes/ e propõe N itens
```
Cada item vira `.md` em `Backlog/frentes/<frente>/B<prefix><nn>_<slug>.md` com história, CA, subtarefas, RICE. Prefixos: `BBT` (Bitrix), `BTR` (Torre), `BCL` (Clara), `BES` (Esperanza), `BVA` (Valentina), `BAU` (Automações), `BLV` (Lívia), `BST` (Estratégica).

**Refinement-pass canônico (introduzido 25/05/2026):** todo item refinado carrega seção `## Observações PO` com voz cética — gates não-negociáveis, contrapropostas concretas, sugestões de quebra, riscos políticos. Marcações `⚠️ PO:` em subtarefas críticas para sinalização visual. Princípio: "não tudo que o negócio pede vai pra frente — backlog é proposta de valor avaliada, não fila de pedidos."

**Visualizador `backlog.html`:** projeção visual do `Backlog/` análoga ao `BOARD.html` (que projeta `Gestao/`). JSON inline em `<script id="backlog-data">` reflete os `.md` de `Backlog/frentes/`. Fonte da verdade: os `.md`. Para regerar o JSON: `/backlog regenerate`.

### Registrar reunião
```
/reuniao <título>
```
Cria template em `Gestao/Reunioes/<dd-mm-aaaa>/YYYY-MM-DD-<slug>.md` (pasta do dia criada automaticamente).

### Criar análise
```
/analise <título>
```
Cria documento individual em `Gestao/Analises/<dd-mm-aaaa>/YYYY-MM-DD_<slug>.md`. Cada pergunta de investigação vira uma análise separada.

### Criar relatório derivado
```
/relatorio from <análise.md>      # deriva de análise existente
/relatorio new <título>           # cria do zero
```
Grava em `Gestao/Analises/<dd-mm-aaaa>/Relatorio/YYYY-MM-DD_<slug>.md`. Cada destinatário/recorte vira um relatório individual.

### Manter arquitetura organizada
```
/organizar
```
Roda `folder-organizer`: detecta arquivos fora do lugar, duplicatas, READMEs desatualizados.

### Board perpétuo (BOARD.html)

`BOARD.html` na raiz do Repasse é a **projeção visual de todo `Gestao/`**. Abre com duplo-clique (single-file, sem servidor). Tem 6 visões via sidebar: Overview, Pendências, Reuniões, Análises, Relatórios, 1on1s — com KPIs, gráficos SVG e filtros.

**Como é alimentado:** todos os comandos que mexem em `Gestao/` (`/pendencia`, `/reuniao`, `/analise`, `/relatorio`) invocam o agente `board-updater` ao final, que reescaneia `Gestao/` inteiro e regrava o JSON inline (`<script type="application/json" id="board-data">`) do `BOARD.html`. Para forçar resync manual:

```
/atualizar-board
```

**Fonte da verdade:** `Gestao/`. O `BOARD.html` é projeção descartável — apagá-lo não perde dado, basta rodar `/atualizar-board` para regenerá-lo a partir dos `.md`.

**Não edite o JSON manualmente.** Mude o `.md` em `Gestao/` e rode `/atualizar-board`. Para mudar layout/cores/views, edite o HTML/CSS/JS do `BOARD.html` direto — o `board-updater` só toca no bloco JSON, o resto fica preservado.

### Status semanal
```
/status
```
Lê `Gestao/` e gera resumo executivo: pendências em curso, reuniões da semana, análises produzidas.

---

## 5 · Convenções de arquivo

**Pastas datadas (Analises, Reunioes, 1on1s):**
- Formato da **pasta de dia**: `dd-mm-aaaa/` (ex: `18-05-2026/`).
- Formato dos **arquivos dentro**: ISO `YYYY-MM-DD_<slug>.md` ou `YYYY-MM-DD-<slug>.md`.
- Dentro de `Gestao/Analises/<dd-mm-aaaa>/` existe `Relatorio/` para relatórios derivados.

**Nomes de arquivo:**
- Decks: `<tema>_<destinatario>_DD-MM-YYYY.html` (ex: `apresentacao_cto_13-05-2026.html`)
- Notas de reunião: `Gestao/Reunioes/<dd-mm-aaaa>/YYYY-MM-DD-<slug>.md`
- 1on1s: `Gestao/1on1s/<dd-mm-aaaa>/YYYY-MM-DD-1on1-<pessoa>.md`
- Análises: `Gestao/Analises/<dd-mm-aaaa>/YYYY-MM-DD_<slug>.md`
- Relatórios: `Gestao/Analises/<dd-mm-aaaa>/Relatorio/YYYY-MM-DD_<slug>.md`
- Pendências: `Gestao/Pendencias/Pnn_<slug>.md` (ex: `P07_ambientes_teste.md`) ou `custom_<slug>.md` — **plana, sem pasta datada**.
- Itens de backlog: `Backlog/frentes/<frente>/B<prefix><nn>_<slug>.md` (ex: `Backlog/frentes/esperanza/BES03_volume_transferencias.md`). Prefixes: BBT (Bitrix), BAU (Automações) — ambos em `bitrix-automacoes/`; BTR (Torre); BCL (Clara); BES (Esperanza); BVA (Valentina); BLV (Lívia); BST (Estratégica).
- Solicitações formalizadas: `Backlog/solicitacoes/YYYY-MM-DD_<autor>_<assunto>.<ext>`.
- Prints: `Backlog/prints/YYYY-MM-DD_<sistema>_<assunto>.<ext>`.

**Datas:**
- Sempre absolutas no conteúdo (`2026-05-15`, não "hoje" nem "Thursday").
- Briefing usa formato BR (`12/05/2026`); demais docs usam ISO (`2026-05-12`).
- Pasta de dia usa `dd-mm-aaaa` (legível em PT-BR); arquivo interno usa ISO (ordena cronologicamente).

**Frontmatter de pendência:**
```yaml
---
id: P07
title: Definir 3 ambientes (dev, hml, prd)
status: aberta            # aberta | em-curso | bloqueada | fechada
prioridade: alta          # alta | media | baixa
origem: Slide 5 do deck CTO 13/05
owner: João Vinícius
criada: 2026-05-15
deadline: 2026-07-10
---
```

**Frontmatter de item de backlog:**
```yaml
---
id: BES03                                  # prefix da frente + nn (BBT/BAU/BTR/BCL/BES/BVA/BLV/BST)
title: Título conciso e acionável
frente: esperanza                          # bitrix-automacoes|torre|clara|esperanza|valentina|livia|estrategica
status: refinado                           # a-refinar | em-refinamento | refinado | em-curso | bloqueado | cancelado | entregue | arquivado
prioridade: alta                           # urgente | alta | media | baixa (derivada do RICE)
rice: { reach: 8, impact: 7, confidence: 6, effort: 5, score: 6.7 }
esforco: M                                 # XS | S | M | L | XL (camisetas)
valor_negocio: alto                        # alto | medio | baixo
origem:
  pendencias: [P19]                        # IDs de pendências táticas (se houver)
  reunioes: [...]
  solicitacoes: [...]
  analises: [...]
roadmap_vinculado: RM03                    # null se não materializa iniciativa do roadmap
owner: João Vinícius
implementador: Joao Lucas                  # null se não atribuído
sponsor: Jéssica
criada: 2026-05-22
refinada: 2026-05-22                       # null se status=bruto
deadline_alvo: 2026-Q3                     # trimestre OU data específica
dependencias: [BES01]                      # itens que precisam terminar antes
bloqueia: [BVA02]                          # itens parados aguardando este
riscos: [...]
premissas: [...]
tags: [esperanza, tabulacoes]
---
```

---

## 6 · Quando atualizar este arquivo

- Adicionou novo agente, command ou skill → adicione na seção 1.
- Mudou o pipeline de slides → atualize seção 2.
- Mudou convenção de nome ou frontmatter → atualize seção 5.
- Não atualize por mudança de conteúdo (uso normal) — só por mudança estrutural.

---

## 7 · Memória do agente

A `auto-memory` em `~/.claude/projects/c--Users-Jo-o-Vinicius-Documents-Finza-Repasse/memory/` é onde o Claude armazena perfil do usuário, feedback acumulado, contexto de projeto. Não duplique aqui o que já vive lá — este arquivo é a **arquitetura**, a memória é a **história**.
