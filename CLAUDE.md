# CLAUDE.md — Workspace gerencial do Supervisor IAF

Esta pasta é o **workspace gerencial** do João Vinícius (Supervisor IAF, Finza). Ela serve a dois propósitos centrais, apoiados por uma base de contexto viva:

1. **Gestão do backlog do squad IAF** — backlog estratégico por frente (`Backlog/`), alimentado por reuniões/análises (`Backlog/reunioes/`, `Backlog/analises/`) e pelos sistemas de tickets (Quimera interno + Jira/Confluence Atlassian via MCP).
2. **Produção de decks/apresentações** no padrão visual Finza — pipeline de agentes especializados.
3. **Operação técnica via subprojetos acoplados** — os repositórios `N8N-AGENT/` (conhecimento de n8n da empresa) e `cobranca-finza/` (Torre de Controle) vivem aqui dentro. O agente principal opera em **modelo roteador + leitura**: reconhece a tarefa, faz leituras read-only seguras e, para trabalho pesado, manda entrar no subprojeto (`/n8n`, `/torre`).

Apoio: **base de contexto viva** — `Docs/finza/` e `Backlog/contexto/` são a fonte da verdade sobre IAF, Torre, Esperanza e plataformas Finza.

Conforme o contexto crescer, a arquitetura aqui descrita evolui. Este arquivo é vivo — atualize sempre que mudar a estrutura.

---

## 0 · Roteamento automático (LER ANTES DE QUALQUER RESPOSTA)

**Antes de responder qualquer prompt, o Claude DEVE avaliar quais skills, agentes ou comandos deste workspace se aplicam — sem o usuário marcar.**

Sequência obrigatória no início de cada turno:

1. Ler a lista de skills disponíveis no `<system-reminder>` (11 skills de conhecimento: finza-contexto, finza-design-system, finza-dossie, finza-tom-voz, po-backlog, finza-mapas, quimera, quimera-nova-demanda, jira, n8n-projeto, torre-projeto + skills de comando `backlog`, `reuniao`, `analise`, `relatorio`, `sync`, `mapa`, `contexto`, `quimera`, `jira`, `equipe`, `n8n`, `torre`, etc.).
2. Considerar os **14 agentes** em `.claude/agents/` e os **17 comandos** em `.claude/commands/`.
3. Se o pedido do usuário se encaixar em um comando/skill, **invoque-o automaticamente** via a ferramenta Skill — não execute manualmente nem peça pro usuário digitar o comando.

### Gatilhos diretos

| Quando o usuário menciona... | Use |
|---|---|
| tarefa, bloqueio, "preciso lembrar de…", demanda, história, épico, item, refinar, priorizar, solicitação da Jéssica | `/backlog` (skill `backlog`) ou agente `po-backlog`. **Pendências táticas foram aposentadas** — tudo vira item ou subtarefa de backlog. |
| anexo formalizado, doc do gestor, transcrição de reunião com demandas | `/backlog from-solicitacao <arquivo>` |
| reunião, ata, alinhamento (2+ pessoas) | `/reuniao` (skill `reuniao`) → grava em `Backlog/reunioes/` |
| 1:1, 1on1, conversa individual com pessoa do squad | `/reuniao` com tipo `1on1` → grava em `Backlog/1on1s/` |
| análise, investigação, comparativo, RFC, post-mortem | `/analise` (skill `analise`) → grava em `Backlog/analises/` |
| relatório, report, status para terceiros, devolutiva | `/relatorio` (skill `relatorio`) → grava em `Backlog/analises/<dd>/relatorios/` |
| status semanal, resumo da semana, "como tá o squad" | `/status` |
| deck, slide, apresentação | pipeline `/novo-deck`, `/novo-slide`, `/revisar-deck` |
| dossiê, documento/relatório HTML de rolagem, "one-pager", "documento da IA X igual ao da Clara", "no padrão do clara.html/dossiê" | skill `finza-dossie` → produz `.html` single-file de scroll (topbar+spy, hero, cards, tabelas, tema claro/escuro). **Não confundir** com slides (`/novo-deck`) nem relatório `.md` de backlog (`/relatorio`). |
| mapa mental, mapa do agente, "história da Esperanza", narrativa de uma frente | `/mapa <assunto>` (textual) ou `/mapa regenerar` (visual) — agente `context-curator` / `mapa-updater` |
| atualizar contexto, doc de negócio defasado, overview de sistema, "documenta isso" | `/contexto` (agente `context-curator`) |
| "atualiza tudo", sincronizar projeções, backlog+mapa de uma vez | `/sync` |
| pasta fora do lugar, README desatualizado, organização | `/organizar` (agente `folder-organizer`) |
| fato técnico Finza, IAF, Torre, Esperanza, backlog | agente `finza-researcher` antes de redigir |
| visualizar backlog, ver itens, kanban backlog | abrir `backlog.html` na raiz (projeção do Backlog/, regenerado por `/backlog regenerate`) |
| ver dependências/conexões do backlog em canvas | abrir `mapa-mental.html` na raiz (projeção do Backlog/, regenerado por `/mapa regenerar`) |
| Quimera, ticket interno, card, demanda (no sistema interno), chamado, indicadores do squad (Conclusão/Cycle Time/Intruders/CSAT), "o que tá aberto no Quimera" | `/quimera` (skill `quimera`) → agente `quimera-ops` via MCP `quimera`. **Não confundir com `/backlog`** (estratégia `.md`) **nem com `/jira`** (Atlassian externo). Default = time `ia_automacao_finza`. |
| "demandas do time/da equipe", "o que cada um tá fazendo", status do time inteiro, carga da equipe, visão de gestor sobre o Quimera | `/equipe` (skill `equipe`) → agente `quimera-ops`. Recorte fixo da equipe direta (João Lucas, João Pedro, Leandro, Marcos + supervisor), agrupado por pessoa → status. **Só leitura.** Para agir num ticket, `/quimera`. |
| Jira, issue, JQL, projeto Jira, Confluence, página/espaço, "abre a issue ABC-123", "busca no Jira/Confluence" | `/jira` (skill `jira`) → agente `jira-ops` via MCP `claude_ai_Atlassian`. **Convive com o Quimera** (são sistemas distintos). Descobre site/projetos ao vivo — não inventa cloudId/key/accountId. |
| n8n, workflow, automação, node, execução com falha, "o que esse workflow faz", workflow do Bitrix/Hyperflow, métrica/erro de n8n, auditar instância n8n | `/n8n` (skill `n8n-projeto`) → agente `n8n-bridge` via MCP dos 6 ambientes n8n + grafana. **Somente leitura daqui** — criar/alterar workflow é DENTRO do subprojeto `N8N-AGENT/` (`/n8n entrar`). Não confundir com `/quimera`/`/jira`. |
| Torre **código** (campanha/ETL/filtro implementação, Supabase/edge function/migration/RPC, bug da Torre, schema multi-tenant, `vw_titles_live`, Pipeline v2), "como a Torre faz X", consultar o banco da Torre | `/torre` (skill `torre-projeto`) → agente `torre-bridge`. **Contexto + leitura daqui** (Supabase read-only); dev pesado é DENTRO do subprojeto `cobranca-finza/` (`/torre entrar`, 8 agentes próprios). **Não confundir** com a frente de backlog **BTR** (`/backlog`) nem com o overview narrativo (`/contexto`). |

### Encadeamento

Quando o pedido cruza 2+ domínios (ex: "analisa essas demandas e gera relatório"), encadeie comandos em sequência: `/analise` → `/relatorio from <análise>` → `/backlog add` para cada ação estratégica derivada. Depois de mexer em vários `.md` de backlog, feche com `/sync` para reconciliar as projeções.

### Quando NÃO usar comando

- Pergunta puramente informativa ("o que é a Torre?") — responda direto, citando docs em `Docs/finza/` se necessário.
- Conversa exploratória sem artefato a gerar — responda direto, ofereça transformar em comando depois.

---

## 1 · Arquitetura

```
orquestra-tarefa/
├── .claude/                          # Configuração do agente
│   ├── agents/                       # Sub-agentes especializados (14)
│   │   ├── finza-researcher.md       # Pesquisa fatos com citação (Docs/, Backlog/contexto)
│   │   ├── slide-architect.md        # Estrutura outline do deck
│   │   ├── slide-writer.md           # Redige texto no tom Finza
│   │   ├── slide-designer.md         # Define layout/visual do slide
│   │   ├── slide-builder.md          # Implementa HTML/CSS/JS vanilla
│   │   ├── slide-reviewer.md         # QA: checklist Finza
│   │   ├── folder-organizer.md       # Mantém arquitetura organizada
│   │   ├── po-backlog.md             # Product Owner do squad — Backlog/ (ESTRATÉGICO)
│   │   ├── mapa-updater.md           # Reescreve JSON de mapa-mental.html (projeção do Backlog/)
│   │   ├── context-curator.md        # Cura mapas textuais + Docs/finza + overviews
│   │   ├── quimera-ops.md            # Opera o Quimera (tickets internos Finza) via MCP — squad IAF
│   │   ├── jira-ops.md               # Opera o Jira & Confluence (Atlassian) via MCP — convive c/ Quimera
│   │   ├── n8n-bridge.md             # Ponte read-only p/ subprojeto N8N-AGENT (6 ambientes n8n + grafana)
│   │   └── torre-bridge.md           # Ponte contexto+leitura p/ subprojeto cobranca-finza (Torre)
│   ├── commands/                     # Slash commands (17)
│   │   ├── novo-deck.md              # Orquestra deck completo
│   │   ├── novo-slide.md             # Adiciona slide a deck existente
│   │   ├── revisar-deck.md           # Roda reviewer em deck existente
│   │   ├── organizar.md              # Roda folder-organizer
│   │   ├── backlog.md                # CRUD/refinement de backlog estratégico
│   │   ├── reuniao.md                # Registra nota de reunião (em pasta datada)
│   │   ├── analise.md                # Cria análise em Backlog/analises/<dd-mm-aaaa>/
│   │   ├── relatorio.md              # Cria relatório em Analises/<dd-mm-aaaa>/Relatorio/
│   │   ├── status.md                 # Gera status semanal do squad
│   │   ├── sync.md                   # Regenera as projeções do backlog (backlog + mapa)
│   │   ├── mapa.md                   # Mapas mentais — visual (regenerar) + textual (<assunto>)
│   │   ├── contexto.md               # Curadoria da base de contexto viva
│   │   ├── quimera.md                # Opera tickets Quimera via MCP (consultar/criar card, indicadores)
│   │   ├── equipe.md                 # Visão de gestor: demandas de toda a equipe no Quimera (só leitura)
│   │   ├── jira.md                   # Opera Jira & Confluence (Atlassian) via MCP
│   │   ├── n8n.md                    # Ponte read-only p/ N8N-AGENT (workflows, execuções, métricas)
│   │   └── torre.md                  # Ponte contexto+leitura p/ cobranca-finza (Torre)
│   ├── skills/                       # Conhecimento canônico (11)
│   │   ├── finza-design-system/      # Paleta, tipografia, padrões visuais (slides)
│   │   ├── finza-dossie/             # Documentos/relatórios HTML de rolagem única (template.html + fontes Montserrat)
│   │   ├── finza-tom-voz/            # Guia de redação dos slides
│   │   ├── finza-contexto/           # Resumo do negócio Finza, frentes
│   │   ├── po-backlog/               # INVEST, Given/When/Then, frentes, RICE
│   │   ├── finza-mapas/              # Estrutura do mapa textual + contrato do mapa visual
│   │   ├── quimera/                  # Catálogo MCP Quimera, status, times, membros, indicadores
│   │   ├── quimera-nova-demanda/     # Fluxo de abertura de demanda no padrão refinado (Descrição Refinada·Observação·Objetivo) + remove assinatura MCP
│   │   ├── jira/                     # Catálogo MCP Atlassian (Jira+Confluence), JQL/CQL, descoberta
│   │   ├── n8n-projeto/              # Mapa do subprojeto N8N-AGENT (ambientes, skills locais, read-only, setup MCP)
│   │   └── torre-projeto/            # Mapa do subprojeto cobranca-finza (stack, 8 agentes, invariantes, guardrails)
│   ├── hooks/                        # Hooks do harness (registrados em settings.json)
│   │   └── check-backlog-sync.ps1    # PostToolUse: lembra de regenerar projeções do backlog
│   ├── settings.json                 # Config do projeto — registra o hook PostToolUse
│   └── settings.local.json           # Overrides locais (permissions)
│
├── CLAUDE.md                         # ← Este arquivo
│
│   ─── CONFIG MCP DO PARENT (gitignored o real; commitado só o .example) ───
├── .mcp.json.example                 # Template: 6 n8n + grafana + supabase (copiar p/ .mcp.json e preencher)
├── .env.example                      # Template das chaves (copiar p/ .env e preencher) — guia na skill n8n-projeto
├── .gitignore                        # Protege .mcp.json/.env e ignora os subprojetos aninhados
│
│   ─── PROJEÇÕES (raiz, single-file, descartáveis — fonte é sempre o .md) ───
├── backlog.html                      # Projeção do Backlog/ em kanban (po-backlog regenerate · id="backlog-data")
├── mapa-mental.html                  # Projeção do Backlog/ em canvas (mapa-updater · /mapa regenerar · id="map-data")
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
│   │   ├── apresentacao_cto_13-05-2026.html
│   │   └── status-demandas-cobranca_time-negocio_18-05-2026.html
│   └── referencias/                  # PDFs/PPTX de referência (Boas-vindas Finza, Roadmap, Régua)
│
└── Backlog/                          # Backlog + histórico tático unificado do squad IAF
    ├── README.md
    ├── BACKLOG.md                    # Relatório mestre (regenerado por /backlog regenerate)
    ├── frentes/
    │   ├── bitrix-automacoes/        # BBT## (Bitrix) + BAU## (Automações) — frente unificada
    │   ├── torre/                    # BTR## — Torre de Controle (multi-org, refatoração)
    │   ├── clara/                    # BCL## — agente Clara (formalização)
    │   ├── esperanza/                # BES## — agente Esperanza (renegociação)
    │   ├── valentina/                # BVA## — agente Valentina (SAC)
    │   ├── livia/                    # BLV## — agente Lívia (jurídico/distrato)
    │   ├── estrategica/              # BST## — transversal (NPS, narrativa, processo)
    │   └── sustentacao/              # Bugs/infra/correções operacionais (itens QMR#### do Quimera)
    ├── solicitacoes/                 # Docs formalizados pelo negócio (.txt, .pdf)
    ├── contexto/                     # Referência viva do backlog
    │   ├── mapa_esperanza.md         # MAPA TEXTUAL (narrativa: de onde veio/onde estamos/pra onde vamos)
    │   ├── torre_de_controle_overview.md   # overview da Torre
    │   └── esperanza_agent_overview.md     # overview da Esperanza
    │
    │   ─── HISTÓRICO TÁTICO (reuniões, análises, 1on1s, referências) ───
    ├── reunioes/                     # DATADA — reunioes/<dd-mm-aaaa>/YYYY-MM-DD_<slug>.md
    ├── analises/                     # DATADA — analises/<dd-mm-aaaa>/YYYY-MM-DD_<slug>.md
    │   └── <dd-mm-aaaa>/
    │       └── relatorios/           # Relatórios derivados das análises do dia
    ├── 1on1s/                        # DATADA — 1on1s/<dd-mm-aaaa>/YYYY-MM-DD-1on1-<pessoa>.md
    └── referencias/                  # Artefatos não-markdown (sql/, csv/, json/, prints/, pdf/, docx/)

─── SUBPROJETOS ACOPLADOS (repos git próprios — NÃO são parte deste repo) ───

N8N-AGENT/                            # Repo github.com/blips-ai/N8N-AGENT — conhecimento de n8n da empresa
├── .claude/                          #   .claude PRÓPRIO (5 skills, 1 comando, 0 agentes) — só ativo rodando claude DE DENTRO
│   └── skills/                       #   bitrix24-api, hyperflow-blips, n8n-db, n8n-metrics-grafana, fantasmas-blips
├── .mcp.json.example                 #   6 ambientes n8n + grafana (read-only estrito)
├── patterns/ · workflows/ · bitrix/  #   padrões, exemplos reais, cache de schema Bitrix
└── CLAUDE.md                         #   lei read-only + heurística de ambiente

cobranca-finza/                       # Repo github.com/blips-ai/cobranca-finza — Torre de Controle v2
├── .claude/                          #   .claude PRÓPRIO (8 agentes, 4 comandos, 24 skills) — só ativo rodando claude DE DENTRO
├── src/ · supabase/ · docs/          #   React+Vite ; Edge Functions+migrations ; 13 guias
├── .mcp.example.json                 #   supabase-prod/dev (read-only ; escrita via CI/CD)
└── CLAUDE.md · ARCHITECTURE.md        #   21 invariantes críticas + C4/ADRs
```

> **Pasta datada** = `dd-mm-aaaa/` (ex: `18-05-2026/`). **Arquivos internos** seguem ISO `YYYY-MM-DD_<slug>.md` (ex: `2026-05-18_demandas-cobranca.md`). Cada análise pode gerar 1 ou mais relatórios em `relatorios/`.

> **Tudo em Backlog/** — `Backlog/frentes/` é estratégico (histórias, RICE, sponsor); `Backlog/reunioes/`, `analises/`, `1on1s/` são o painel tático (alimentadores do backlog). O que sai de uma reunião/análise vira item de backlog. A pasta `Gestao/` foi **aposentada em 2026-06-15** e seu conteúdo migrado para `Backlog/`. A pendência tática (`Gestao/Pendencias/`) foi **aposentada em 27/05/2026**: virou subtarefa de item de backlog. IDs `Pnn` sobrevivem só como rótulo de origem.

> **Dois esquemas de ID no backlog** — itens **internos** nascem `B<prefix><nn>` (ex.: `BES03`); itens **importados do Quimera** mantêm a key de origem `QMR####` (ex.: `QMR3415`). Ambos vivem em `Backlog/frentes/<frente>/`.

> **Duas projeções, uma fonte** — `backlog.html` e `mapa-mental.html` projetam o **mesmo** `Backlog/frentes/` (kanban vs canvas). Toda projeção é descartável: a verdade está nos `.md`. `/sync` regenera as duas de uma vez. Mapas **textuais** (`Backlog/contexto/mapa_*.md`) são curadoria humana, não projeção — não entram no `/sync`.

> **Hook de coerência do backlog (`PostToolUse`)** — registrado em `.claude/settings.json`, roda `.claude/hooks/check-backlog-sync.ps1` após todo `Edit`/`Write`/`MultiEdit`. Quando o arquivo tocado é fonte de backlog (`Backlog/frentes/**/*.md`), uma das projeções (`backlog.html` / `mapa-mental.html`) ou o mestre (`Backlog/BACKLOG.md`), ele injeta no contexto um lembrete para rodar `/backlog regenerate` (ou `/sync --backlog`) e regravar **as duas** projeções + `BACKLOG.md`. Para fonte de item, lembra ainda de revisar mapas textuais defasados via `/contexto`. O hook **só lembra** — quem regenera é o agente. Ele se cala durante uma regeneração legítima e ignora `README.md` e arquivos fora do backlog. Editar o `.ps1` ou o `settings.json` muda o comportamento.

### 1.1 · Subprojetos acoplados (N8N-AGENT e Torre)

`N8N-AGENT/` e `cobranca-finza/` são **repositórios git independentes** clonados dentro do workspace. Cada um tem seu **próprio `.claude/`** (agentes, skills, comandos) e seu **próprio `.mcp.json`**. No Claude Code, isso **só fica ativo quando se roda `claude` de dentro da pasta** — o parent **não herda** automaticamente os agentes nem os MCP servers de uma subpasta.

Por isso o modelo aqui é **roteador + leitura (híbrido)**:

1. **O parent enxerga os subprojetos via skill-catálogo** (`n8n-projeto`, `torre-projeto`) e os agentes-ponte (`n8n-bridge`, `torre-bridge`), acionados por `/n8n` e `/torre`. As pontes **leem** os arquivos dos subprojetos e fazem **consultas read-only via MCP**.
2. **Os MCP dos subprojetos são replicados no parent** (`.mcp.json` na raiz, a partir do `.mcp.json.example`) para que as leituras funcionem daqui — com as **deny-rules de escrita portadas** para o `.claude/settings.json` do parent (n8n write tools, Supabase migration/deploy/branch, curl POST/PUT/PATCH/DELETE). Sem o `.mcp.json` real preenchido, as tools não aparecem (ver setup nas skills `n8n-projeto`/`torre-projeto`).
3. **Trabalho pesado entra no subprojeto.** Criar/alterar workflow n8n, ou desenvolver na Torre (migration, EF, campanha, UI, bug) → `cd <subprojeto>` e rodar `claude` lá, onde vivem os agentes especialistas e os guardrails completos. As pontes nomeiam qual agente de lá usar.

**Fronteiras read-only:** n8n é **somente leitura** sempre (daqui e de lá — criação é JSON local + import manual pelo usuário). Na Torre, Claude **nunca** commita/push/PR e **nunca** escreve no Supabase (migrations/EF via CI/CD). Os subprojetos continuam versionados nos seus próprios GitHub — o `.gitignore` da raiz os exclui do repo do orquestra-tarefa.

---

## 2 · Pipeline de criação de slides

Um slide Finza nasce de 6 etapas. Cada uma tem um sub-agente dedicado em `.claude/agents/`:

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
- **Acoplamento de projeções é regra dura (hook-enforced).** Toda operação que mexe em `Backlog/frentes/**/*.md` deve disparar `/backlog regenerate` — que reescreve `BACKLOG.md` + `backlog.html` (`id="backlog-data"`, kanban) **e** aciona o `mapa-updater` para o `mapa-mental.html` (`id="map-data"`, canvas). As duas são **projeções da mesma fonte**: nunca atualize uma sem a outra. Um hook `PostToolUse` (`.claude/hooks/check-backlog-sync.ps1`) vigia essas fontes/projeções e injeta lembrete automático quando você esquece — ele **não** regenera (isso exige seu raciocínio). Projeção é espelho da realidade — defasagem é bug.
- **Estratégico vs tático vive em Backlog/.** Item de backlog (`Backlog/frentes/`) tem história + critérios de aceite + subtarefas + RICE — dura semanas/meses. O tático curto é **subtarefa do item** (responsável + status próprios), não artefato separado. Reuniões/análises/1on1s vivem em `Backlog/reunioes/`, `analises/`, `1on1s/`. O subsistema de pendências (`Gestao/Pendencias/`) foi **aposentado em 27/05/2026**; a pasta `Gestao/` foi **aposentada em 2026-06-15** — não recrie sem decisão explícita.
- **Mapa textual ≠ projeção.** `Backlog/contexto/mapa_*.md` é narrativa institucional curada à mão (`context-curator`), com história imutável. `mapa-mental.html` é projeção mecânica do backlog (`mapa-updater`). Nunca edite o JSON de uma projeção à mão — mude o `.md`-fonte e regenere.
- **Três sistemas de demanda distintos.** `Backlog/` (estratégia interna `.md`, RICE) ≠ **Quimera** (tickets internos Finza, MCP `quimera`) ≠ **Jira/Confluence** (Atlassian externo, MCP `claude_ai_Atlassian`). Um item pode *referenciar* um ticket dos outros dois, mas não são a mesma coisa. Não cruze IDs nem confunda os comandos (`/backlog` · `/quimera` · `/jira`).
- **Subprojetos acoplados têm fronteira (read-only).** `N8N-AGENT/` (n8n) e `cobranca-finza/` (Torre) são repos próprios — o parent é **roteador + leitura** (`/n8n` · `/torre`), não cockpit de dev. **n8n é sempre read-only** (daqui e de lá): criar/alterar workflow = JSON local + import manual pelo usuário, nunca escrita via MCP/curl. **Na Torre, Claude nunca commita/push/abre PR e nunca escreve no Supabase** (migrations/EF só via CI/CD); leitura/`SELECT` é livre. Dev pesado entra no subprojeto. Essas proteções estão portadas como `deny` no `.claude/settings.json` — não as remova.
- **Torre tem 3 camadas — não as cruze.** Código (`cobranca-finza/`, via `/torre`) ≠ frente de backlog **BTR** (`Backlog/frentes/torre/`, via `/backlog`) ≠ overview narrativo (`Backlog/contexto/torre_de_controle_overview.md`, via `/contexto`).

**Visual:**
- Paleta Finza exata. Sem cores fora dos tokens em `.claude/skills/finza-design-system/`.
- Cards com `2px dotted var(--finza-blue)`. Marcador `◆ iaf` no canto superior direito.
- Sem emojis decorativos. Emojis funcionais (✓ → 🎯 📅 📍) só quando carregam significado.

**Voz:**
- Frases curtas SVO. Sem jargão de consultoria ("sinergia", "alavancar").
- Números em destaque visual (azul, peso 700).
- Sem "ótima notícia", "boas perspectivas". Quando incerto, declarar incerteza.

**Stack (slides):**
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

### Registrar tarefa / bloqueio (tático)
O subsistema de pendências foi **aposentado**. Tarefa, bloqueio ou "preciso lembrar de X" agora entram no Backlog:
```
/backlog add "<título>"          # item bruto numa das 8 frentes
# tracking curto → subtarefa dentro do item (status próprio)
```

### Gerenciar backlog estratégico
```
/backlog                                  # lista itens ativos agrupados por frente
/backlog add "<título>"                   # cria item bruto em uma das 8 frentes
/backlog refine <id>                      # quebra subtarefas, escreve CA Given/When/Then, calcula RICE
/backlog review <id>                      # auditoria INVEST (só aponta, não edita)
/backlog prioritize                       # recalcula ranking RICE
/backlog analyze                          # gaps, sobreposições, dependências, deadlines críticos
/backlog regenerate                       # reescreve BACKLOG.md + backlog.html + mapa-mental.html (via mapa-updater)
/backlog from-solicitacao <arquivo>       # lê doc do negócio em Backlog/solicitacoes/ e propõe N itens
```
Cada item interno vira `.md` em `Backlog/frentes/<frente>/B<prefix><nn>_<slug>.md` com história, CA, subtarefas, RICE. Prefixos: `BBT` (Bitrix), `BTR` (Torre), `BCL` (Clara), `BES` (Esperanza), `BVA` (Valentina), `BAU` (Automações), `BLV` (Lívia), `BST` (Estratégica). Itens importados do Quimera mantêm a key `QMR####`.

**Refinement-pass canônico (introduzido 25/05/2026):** todo item refinado carrega seção `## Observações PO` com voz cética — gates não-negociáveis, contrapropostas concretas, sugestões de quebra, riscos políticos. Marcações `⚠️ PO:` em subtarefas críticas para sinalização visual. Princípio: "não tudo que o negócio pede vai pra frente — backlog é proposta de valor avaliada, não fila de pedidos."

**Visualizador `backlog.html`:** projeção visual do `Backlog/`. JSON inline em `<script id="backlog-data">` reflete os `.md` de `Backlog/frentes/`. Fonte da verdade: os `.md`. Para regerar o JSON: `/backlog regenerate`.

### Registrar reunião
```
/reuniao <título>
```
Cria template em `Backlog/reunioes/<dd-mm-aaaa>/YYYY-MM-DD_<slug>.md` (pasta do dia criada automaticamente). Para 1on1, grava em `Backlog/1on1s/<dd-mm-aaaa>/`.

### Criar análise
```
/analise <título>
```
Cria documento individual em `Backlog/analises/<dd-mm-aaaa>/YYYY-MM-DD_<slug>.md`. Cada pergunta de investigação vira uma análise separada.

### Criar relatório derivado
```
/relatorio from <análise.md>      # deriva de análise existente
/relatorio new <título>           # cria do zero
```
Grava em `Backlog/analises/<dd-mm-aaaa>/relatorios/YYYY-MM-DD_<slug>.md`. Cada destinatário/recorte vira um relatório individual.

### Operar tickets — Quimera (interno) e Jira (Atlassian)
```
/quimera [demandas|show|card|status|comentar|indicadores|csat|...]   # sistema interno Finza (MCP quimera)
/equipe                                                              # visão de gestor do squad no Quimera (só leitura)
/jira [issues|show|criar|status|comentar|worklog|projetos|confluence|...]  # Atlassian externo (MCP claude_ai_Atlassian)
```
Leitura é livre nos dois; **escrita confirma antes** (dispara notificação/e-mail). Os dois convivem — não confunda com `/backlog` (estratégia `.md`).

### Operar os subprojetos acoplados — n8n e Torre
```
/n8n [workflows|show|execucoes|validar|auditar|nodes|metricas|padroes|entrar]   # N8N-AGENT (read-only)
/torre [contexto|arquitetura|agentes|skills|db|guia|ef|entrar]                  # cobranca-finza (contexto+leitura)
```
`/n8n` consulta os 6 ambientes n8n + grafana **em somente leitura** (agente `n8n-bridge`); criar/alterar workflow é dentro do `N8N-AGENT/`. `/torre` dá contexto/arquitetura e consulta o Supabase read-only (agente `torre-bridge`); dev pesado é dentro do `cobranca-finza/` (8 agentes próprios). **Pré-requisito:** copiar `.mcp.json.example`→`.mcp.json` e `.env.example`→`.env`, preencher as chaves (guia nas skills `n8n-projeto`/`torre-projeto`) e reiniciar o Claude Code.

### Manter arquitetura organizada
```
/organizar
```
Roda `folder-organizer`: detecta arquivos fora do lugar, duplicatas, READMEs desatualizados.

### Status semanal
```
/status
```
Lê `Backlog/frentes/`, `Backlog/reunioes/`, `Backlog/analises/`, `Backlog/1on1s/` e gera resumo executivo: itens de backlog em curso/bloqueados, reuniões da semana, análises produzidas, foco da próxima semana.

### Sincronizar projeções
```
/sync                 # backlog + mapa visual, a partir das fontes .md
/sync --backlog       # só backlog.html (+ mapa-mental.html, encadeado)
/sync --mapa          # só mapa-mental.html
```
Use quando editou vários `.md` de backlog à mão, no fim de uma sessão de refinement, ou antes de apresentar. Mapas textuais **não** entram no `/sync`.

### Mapas mentais
```
/mapa regenerar       # regenera o mapa-mental.html visual (canvas do Backlog)
/mapa <assunto>       # cria/atualiza mapa TEXTUAL Backlog/contexto/mapa_<assunto>.md
/mapa list            # lista mapas textuais + data do mapa visual
/mapa audit           # frentes/agentes sem mapa, mapas defasados
```
Mapa **visual** = projeção do Backlog (agente `mapa-updater`). Mapa **textual** = narrativa institucional curada (agente `context-curator`, estrutura "de onde veio / onde estamos / para onde vamos").

### Curar contexto
```
/contexto                       # = audit (saúde da base de contexto)
/contexto update <assunto>      # atualiza doc existente (preserva história)
/contexto new <assunto>         # cria doc novo
/contexto sync-skill            # re-condensa a skill finza-contexto a partir dos docs
```
Agente `context-curator`. Mantém `Docs/finza/`, `Backlog/contexto/` e a skill `finza-contexto` vivos e sem referência quebrada. Não inventa — colhe do usuário, de `Backlog/reunioes/`, `Backlog/analises/` e do `finza-researcher`.

---

## 5 · Convenções de arquivo

**Pastas datadas (analises, reunioes, 1on1s):**
- Formato da **pasta de dia**: `dd-mm-aaaa/` (ex: `18-05-2026/`).
- Formato dos **arquivos dentro**: ISO `YYYY-MM-DD_<slug>.md`.
- Dentro de `Backlog/analises/<dd-mm-aaaa>/` existe `relatorios/` para relatórios derivados.

**Nomes de arquivo:**
- Decks: `<tema>_<destinatario>_DD-MM-YYYY.html` (ex: `apresentacao_cto_13-05-2026.html`)
- Notas de reunião: `Backlog/reunioes/<dd-mm-aaaa>/YYYY-MM-DD_<slug>.md`
- 1on1s: `Backlog/1on1s/<dd-mm-aaaa>/YYYY-MM-DD-1on1-<pessoa>.md`
- Análises: `Backlog/analises/<dd-mm-aaaa>/YYYY-MM-DD_<slug>.md`
- Relatórios: `Backlog/analises/<dd-mm-aaaa>/relatorios/YYYY-MM-DD_<slug>.md`
- Itens de backlog internos: `Backlog/frentes/<frente>/B<prefix><nn>_<slug>.md` (ex: `Backlog/frentes/esperanza/BES03_volume_transferencias.md`). Prefixes: BBT (Bitrix), BAU (Automações) — ambos em `bitrix-automacoes/`; BTR (Torre); BCL (Clara); BES (Esperanza); BVA (Valentina); BLV (Lívia); BST (Estratégica).
- Itens importados do Quimera: `Backlog/frentes/<frente>/QMR<nnnn>_<slug>.md` (mantêm a key de origem).
- Mapas textuais: `Backlog/contexto/mapa_<assunto>.md` (snake/kebab minúsculo, ASCII — ex: `mapa_esperanza.md`). Overview técnico: `Backlog/contexto/<sistema>_overview.md`.
- Solicitações formalizadas: `Backlog/solicitacoes/YYYY-MM-DD_<autor>_<assunto>.<ext>`.
- Referências (artefatos não-markdown): `Backlog/referencias/<tipo>/YYYY-MM-DD_<sistema>_<assunto>.<ext>`.
- ~~Prints em `Backlog/prints/`~~ → **migrado para `Backlog/referencias/prints/`** (2026-06-15).
- Pendências: ~~`Gestao/Pendencias/Pnn_<slug>.md`~~ — **aposentado em 27/05/2026.** Não criar. Tático = subtarefa de item de backlog.
- ~~`Gestao/`~~ — **aposentado em 2026-06-15.** Não criar. Tudo migrou para `Backlog/`.

**Datas:**
- Sempre absolutas no conteúdo (`2026-05-15`, não "hoje" nem "Thursday").
- Briefing usa formato BR (`12/05/2026`); demais docs usam ISO (`2026-05-12`).
- Pasta de dia usa `dd-mm-aaaa` (legível em PT-BR); arquivo interno usa ISO (ordena cronologicamente).

**Frontmatter de item de backlog:**
```yaml
---
id: BES03                                  # prefix da frente + nn (BBT/BAU/BTR/BCL/BES/BVA/BLV/BST) OU QMR####
title: Título conciso e acionável
frente: esperanza                          # bitrix-automacoes|torre|clara|esperanza|valentina|livia|estrategica|sustentacao
status: refinado                           # a-refinar | em-refinamento | refinado | em-curso | bloqueado | cancelado | entregue | arquivado
prioridade: alta                           # urgente | alta | media | baixa (derivada do RICE)
rice: { reach: 8, impact: 7, confidence: 6, effort: 5, score: 6.7 }
esforco: M                                 # XS | S | M | L | XL (camisetas)
valor_negocio: alto                        # alto | medio | baixo
origem:
  pendencias: [P19]                        # IDs de pendências táticas (rótulo de origem, se houver)
  reunioes: [Backlog/reunioes/<dd-mm-aaaa>/<arquivo>.md]
  solicitacoes: [Backlog/solicitacoes/<arquivo>]
  analises: [Backlog/analises/<dd-mm-aaaa>/<arquivo>.md]
  quimera: [QMR3415]                       # ticket(s) Quimera de origem, se importado
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

- Adicionou novo agente, command ou skill → adicione na seção 1 (e atualize as contagens em §0).
- Mudou o pipeline de slides → atualize seção 2.
- Mudou convenção de nome ou frontmatter → atualize seção 5.
- Aposentou/criou um subsistema (como pendências em 27/05, ou a migração de Gestao/ em 2026-06-15) → reflita em §0, §1, §3, §5.
- Adicionou/alterou um hook em `.claude/settings.json` ou `.claude/hooks/` → reflita em §1 (árvore) e §3 (regra que ele enforça).
- Adicionou/mudou um conector MCP (Quimera, Jira, n8n, Supabase) → reflita na tabela de gatilhos §0, na árvore §1, no `.mcp.json.example`/`settings.json` e na regra de fronteiras §3.
- Adicionou/removeu/moveu um **subprojeto acoplado** (ou mudou seu MCP/guardrails) → reflita em §0 (gatilhos), §1.1 (modelo), §3 (fronteiras), no `.gitignore` e nas skills `n8n-projeto`/`torre-projeto`.
- Não atualize por mudança de conteúdo (uso normal) — só por mudança estrutural.

---

## 7 · Memória do agente

A `auto-memory` em `~/.claude/projects/C--Users-Jo-o-Vinicius-Documents-Finza-Projetos-orquestra-tarefa/memory/` é onde o Claude armazena perfil do usuário, feedback acumulado, contexto de projeto. Não duplique aqui o que já vive lá — este arquivo é a **arquitetura**, a memória é a **história**.

---

## 8 · Projeções — regra de edição

`backlog.html` e `mapa-mental.html` na raiz são **projeções mecânicas** do `Backlog/frentes/`:

- São regenerados automaticamente por `/sync`, `/backlog regenerate`, agente `mapa-updater` e o hook `check-backlog-sync.ps1`.
- **Edição manual do bloco de dados é proibida** (`<script id="backlog-data">` / `<script id="map-data">`). Mude o `.md`-fonte e regenere.
- Mudar **layout/cores/views** (HTML/CSS/JS fora do bloco de dados) pode ser feito direto no arquivo — os geradores só tocam no bloco JSON, o resto fica preservado.
