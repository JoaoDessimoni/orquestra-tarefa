---
id: BTR11
title: Router de autenticação das Edge Functions no self-hosted (verify_jwt) + reconciliar config.toml com a prod
frente: torre
fonte: backlog
status: a-refinar
prioridade: alta
rice:
  reach: 5
  impact: 8
  confidence: 5
  effort: 5
  score: 4.0
esforco: M
valor_negocio: alto
origem:
  pendencias: []
  reunioes: []
  solicitacoes: []
  analises: []
  quimera: [4786]
roadmap_vinculado: null
owner: João Vinícius
implementador: null
sponsor: João Vinícius
criada: 2026-08-10
refinada: null
deadline_alvo: 2026-Q3
dependencias: [BTR10]
bloqueia: []
riscos:
  - "Falha silenciosa: gerar o router a partir do config.toml hoje produz um DEV que difere da prod em 22 funções — você acredita ter testado paridade e não testou. É o pior dos modos de falha porque não dispara alarme."
  - "Router exigindo JWT de tudo quebra os crons e webhooks (pg_cron, sistema de pagamento e HyperFlow não mandam JWT). Falha ruidosa, mas derruba a operação."
  - "Router não exigindo JWT de nada deixa as EFs de frontend abertas sem autenticação. É buraco de segurança, não bug de ambiente."
  - "Lista desatualiza sozinha: EF nova criada sem regenerar o router se comporta errado sem alarme. Daí a exigência de geração automática (CA-4)."
  - "O script mapear-webhooks.py citado como base do gerador não foi localizado em nenhum repositório do workspace. Pode viver em máquina pessoal — o que é problema para uma peça que se torna dependência de build."
premissas:
  - "No Supabase self-hosted o supabase/config.toml NÃO é lido. Quem decide autenticação por função é volumes/functions/main/index.ts, o router que o edge-runtime executa antes de cada função."
  - "O pipeline de deploy das EFs preserva o diretório main/ na VM (o passo usa find ... ! -name \"main\"), logo o router não é sobrescrito pelo deploy do monolito."
  - "Prod em 10/08/2026: 62 EFs deployadas, 53 com verify_jwt=false e 9 com true. O config.toml declara 31 overrides."
tags: [torre, supabase, self-hosted, edge-functions, verify-jwt, seguranca, router, infra]
---

# BTR11 — Router de autenticação das Edge Functions no self-hosted (`verify_jwt`)

> **Origem:** extraído do **[[BTR10]]** em 2026-08-10 (era a "Frente D"). Nasceu do comentário de 20/07 no Quimera #4786 e é o mesmo ponto levantado pelo DevOps na §6 do doc de pipeline das EFs.
> **Dependência dura:** o **[[BTR10]]** precisa entregar o DEV de pé — sem ambiente não há onde testar o router.

## História de usuário

Como **responsável pela Torre no ambiente self-hosted**,
quero **um router de Edge Functions que replique fielmente a política de autenticação por função que hoje vive no Supabase Cloud, e que se regenere sozinho quando uma EF nova aparecer**,
para **não quebrar crons e webhooks nem deixar funções de frontend abertas sem autenticação**.

## Contexto

No Supabase Cloud, o `supabase/config.toml` do monolito controla o `verify_jwt` de cada função. No **self-hosted esse arquivo não é lido** — quem decide é o `volumes/functions/main/index.ts`, um router que o edge-runtime executa antes de cada função. Sem ele: ou **todas** as EFs exigem JWT (quebra webhook e cron), ou **nenhuma** exige (buraco de segurança).

A proposta do card — e do DevOps — é **gerar o router a partir do `config.toml`**, mantendo uma fonte de verdade única em vez de lista duplicada mantida à mão. **A ideia está certa. A premissa não.**

### O achado que muda a ordem do trabalho

Medição em prod, 10/08/2026:

| Métrica | Valor |
|---|---|
| EFs deployadas | **62** |
| Rodando com `verify_jwt = false` | **53** |
| Rodando com `verify_jwt = true` | 9 |
| Overrides declarados no `config.toml` | **31** |
| **Divergentes** | **22** |

O comentário no topo do `config.toml` diz *"sync com 47 EFs (atualizado 2026-05-27)"* — há 62 hoje. Tanto o card quanto o doc do DevOps citam "38 overrides"; o arquivo tem 31.

**As 22 divergentes** — todas rodando **sem JWT em produção agora**, e todas tratadas pelo `config.toml` como Categoria 1 ("frontend exclusivo, `verify_jwt = true` por default"):

`create-org-schema` · `daily-sync-orchestrator` · `ai-config` · `ai-assistant` · `ai-orchestrator` · `ai-playground` · `ai-proposal-executor` · `workflow-orchestrator` · `send-message-v2` · `manage-orphan-schemas` · `unexpose-org-schema` · `send-invitation-email` · `export-portfolio` · `get-dashboard-kpis` · `get-attribution-kpis` · `get-monthly-evolution` · `get-repique-dashboard` · `generate-actions-report` · `populate-contract-summaries` · `rag-documents` · `rag-download` · `dispatch-a2a-open-protocols`

Gerar o router do `config.toml` **antes** de reconciliar produz um DEV que difere da prod em 22 funções — e como o `config.toml` diz uma coisa e a prod faz outra, ninguém percebe.

## Critérios de aceite

- **CA-1** — Given as 22 divergências, When cada uma é auditada, Then existe registro explícito de qual estado é o correto (config.toml desatualizado **ou** prod com override indevido) e quem é o caller de cada EF.
- **CA-2** — Given a auditoria concluída, When o `config.toml` é corrigido, Then ele declara explicitamente a política de **todas** as 62 EFs (sem depender de default implícito) e o comentário de cabeçalho reflete a contagem real.
- **CA-3** — Given o `config.toml` reconciliado, When o `main/index.ts` é gerado, Then o router aplica exatamente a mesma política que a prod aplica, função por função.
- **CA-4** — Given o processo de geração, When uma EF nova é adicionada ao monolito, Then o router se regenera a partir do `config.toml` sem edição manual de lista duplicada — e o build falha se houver EF sem política declarada.
- **CA-5** — Given o router publicado no DEV, When um cron ou webhook sem JWT chama sua EF, Then a chamada passa.
- **CA-6** — Given o router publicado no DEV, When uma EF de frontend é chamada sem JWT válido, Then é rejeitada com 401.
- **CA-7** — Given o deploy das EFs, When o pipeline roda, Then o diretório `main/` sobrevive (não é apagado pelo `find ... ! -name "main"`) e o router continua vigente.

## Subtarefas

- [ ] **ST-1 — Auditar as 22 divergências.** ⚠️ PO: este é o gate. Para cada EF, identificar o caller real (frontend / cron / EF→EF / externo via x-api-key / webhook) e decidir a política correta. É auditoria de segurança, não configuração.
- [ ] **ST-2 — Localizar o `mapear-webhooks.py`.** Citado no card e no doc do DevOps como base do gerador, não encontrado em nenhum repo do workspace. Se não existir versionado, escrever o parser do zero.
- [ ] **ST-3 — Reconciliar o `config.toml`.** Declarar as 62 EFs explicitamente; atualizar o comentário de cabeçalho e as contagens (Regra 21 do CLAUDE.md da Torre: doc e contagem acompanham o código).
- [ ] **ST-4 — Escrever o gerador do `main/index.ts`.** A partir do `config.toml` reconciliado. Determinístico, versionado, com falha de build para EF sem política.
- [ ] **ST-5 — Decidir onde o router vive** (Q3): monolito junto das EFs, ou `infra-torre-controle`. Se é gerado do `config.toml`, o argumento pesa para o monolito.
- [ ] **ST-6 — Responder a Q2.** Além do `verify_jwt`, o self-hosted precisa replicar mais do `config.toml`? Indício de que sim: as 62 EFs usam `import_map.json` e o `mcp-server` usa `deno.json` próprio.
- [ ] **ST-7 — Testar no DEV.** Cron/webhook sem JWT passam; EF de frontend sem JWT bloqueada (CA-5, CA-6).
- [ ] **ST-8 — Validar sobrevivência no deploy.** Rodar o pipeline de EFs e confirmar que `main/` não foi sobrescrito (CA-7).

## Observações PO

1. **A ordem correta é reconciliar → corrigir → gerar.** Não gerar → descobrir depois. Inverter a ordem produz exatamente a falha silenciosa que o item existe para evitar.

2. **Router auto-gerado > lista manual.** Concordo com a proposta do card e do DevOps: gerar do `config.toml` elimina a classe de bug "EF nova esquecida". Vale investir na regeneração automática (CA-4) mesmo custando mais que hardcodar hoje.

3. **A ST-1 é o verdadeiro item.** Escrever o gerador é trabalho mecânico de meia tarde. Decidir a política de autenticação de 22 funções que hoje rodam abertas em produção é decisão de segurança, e provavelmente revela problema em prod, não só em dev. Se a auditoria concluir que alguma das 22 está com override indevido, **isso é um achado de produção** e pode virar item próprio.

4. **Escopo de deploy está fechado.** O mecanismo (GitHub Actions → tar → `gcloud compute scp` via IAP → extrai em `/opt/supabase/data/project/volumes/functions` → `docker compose restart functions` → smoke test) já foi decidido pelo DevOps. Não reabrir. O que este item entrega é o **conteúdo de `main/`**, não o pipeline.

5. **Este item não bloqueia o BTR10.** O DEV fica utilizável para desenvolvimento de banco, frontend e SQL sem o router. O router é pré-requisito para **testar Edge Functions** no self-hosted.

## Questões em aberto

- **Q2** *(herdada do BTR10)* — Além do `verify_jwt`, o `main/index.ts` / self-hosted precisa replicar outra coisa do `config.toml`? Import maps? Secrets por função? Pergunta explícita do card, ainda sem resposta.
- **Q3** *(herdada do BTR10)* — Onde o router vive: monolito (junto das EFs) ou `infra-torre-controle`? O DevOps deixou como "discutir com João".
- **Q7** — Se a auditoria da ST-1 revelar override indevido em prod, isso vira item de correção de produção separado ou entra aqui?

## Itens relacionados

- **[[BTR10]]** — Provisionar o DEV self-hosted. **Dependência dura** (bloqueia este).
- Doc do DevOps: `infra-torre-controle/docs/pipeline-edge-functions.md` — §6 levanta este mesmo ponto.
- `cobranca-finza/supabase/config.toml` — a fonte a reconciliar.

## Definição de pronto

- [ ] As 22 divergências auditadas, com política decidida e registrada (CA-1).
- [ ] `config.toml` declarando explicitamente as 62 EFs, com contagens corretas (CA-2).
- [ ] `main/index.ts` gerado automaticamente, em paridade com a prod (CA-3, CA-4).
- [ ] Testes de caller no DEV passando: cron/webhook entram, frontend sem JWT é bloqueado (CA-5, CA-6).
- [ ] Router sobrevive a um ciclo de deploy das EFs (CA-7).

## Histórico

- **2026-08-10** — Item criado por extração da Frente D do **[[BTR10]]**, conforme recomendação do plano de execução. Motivo da quebra: a frente depende de auditar 22 divergências entre `config.toml` e o estado deployado em prod — trabalho de segurança, não de provisionamento — e amarrá-la ao clone atrasaria a entrega do DEV utilizável. Herdou as questões Q2 e Q3. Status inicial `a-refinar`.
