---
id: BTR10
title: Provisionar Supabase DEV self-hosted (GCP) com dados de prod anonimizados
frente: torre
fonte: backlog
status: em-refinamento
prioridade: alta
rice:
  reach: 7
  impact: 7
  confidence: 6
  effort: 6
  score: 4.9
esforco: L
valor_negocio: alto
origem:
  pendencias: []
  reunioes: []
  solicitacoes: []
  analises: []
  quimera: [4786]
roadmap_vinculado: null
owner: João Vinícius
implementador: João Vinícius Dessimoni Fernandes
sponsor: João Vinícius
criada: 2026-08-07
refinada: 2026-08-07
deadline_alvo: 2026-Q3
dependencias: []
bloqueia: []
riscos:
  - Anonimização de PII incompleta — se algum email/telefone real de cliente vazar para o dev, é exposição de dado sensível. A regra "muda só email/telefone/cnpj/cpf" precisa de um mapa exaustivo das colunas que carregam PII, não só as óbvias.
  - pg_dump/pg_restore via pooler pode falhar por "parâmetro não suportado" (alerta do próprio João no card) — plano B é rodar de dentro da VM.
  - Router de EF (main/index.ts) no self-hosted é ponto de falha silenciosa — errar o verify_jwt abre EF sem auth (buraco de segurança) ou quebra crons/webhooks que não mandam JWT.
  - Lista dos 38 overrides desatualiza sozinha — EF nova criada sem atualizar o router se comporta errado sem alarme.
  - Escopo do card cresceu de "clonar dados" (descrição original, 5 SP) para "clonar dados + resolver auth self-hosted" (comentário de 20/07) — é provavelmente 2 itens.
premissas:
  - Acesso ao banco DEV via túnel IAP já foi liberado para o João (confirmado no card em 28/07).
  - Servidor DEV é PG 17 — pg_dump/pg_restore precisam ser v17.
  - O config.toml do repo continua sendo a fonte de verdade única do verify_jwt (38 funções com override).
  - Existe script mapear-webhooks.py que parseia o config.toml e pode gerar o router.
tags: [torre, supabase, self-hosted, gcp, dev, anonimizacao, pii, edge-functions, verify-jwt, infra]
---

# BTR10 — Provisionar Supabase DEV self-hosted (GCP) com dados de prod anonimizados

> **Origem:** Quimera #4786 "Supabase Dev" (TI · 5 SP). Cancelado no Quimera em 2026-08-05 e reatribuído ao João Vinícius — a execução migra para esta spec de backlog. O card original foi aberto pelo João e endereçado ao Marcos; os dois comentários técnicos (28/07 e 20/07) são do próprio João e viram o insumo desta spec.

## História de usuário

Como **time de desenvolvimento da Torre**,
quero **um ambiente Supabase DEV self-hosted no GCP com a estrutura e os dados de produção replicados, porém com toda a PII anonimizada**,
para **desenvolver e testar contra dados realistas sem risco de vazar dado sensível de cliente e sem depender do ambiente de produção**.

## Contexto

A demanda tem duas frentes de trabalho que nasceram no mesmo card:

### Frente A — Clonar prod → dev com PII anonimizada (escopo original)

Replicar tabelas, schemas e dados do Supabase de **produção** para o novo Supabase **dev**, mantendo tudo **idêntico ao prod**, exceto:

- **Email e telefone** → substituídos pelos do **time de desenvolvimento**.
- **CNPJ e CPF** → substituídos por valores **fictícios**.

O banco DEV **não é exposto à internet de propósito** (firewall deny-all; só IAP-SSH e o Load Balancer liberados). As portas 5432/6543 dando timeout é comportamento esperado — o acesso é por **túnel IAP + localhost**. O acesso do João já foi liberado.

Fluxo técnico (do comentário de 28/07):

```
# 1. Abrir túnel IAP (deixe rodando — publica o DEV em localhost:5433)
gcloud compute ssh torre-dev-supabase --zone=us-central1-a \
  --project=finza-torre-de-controle-dev --tunnel-through-iap \
  -- -L 5433:localhost:5432 -N

# 2. Testar (outro terminal) — usuário postgres.torre-dev, banco postgres
psql "postgresql://postgres.torre-dev:SENHA@localhost:5433/postgres" -c '\conninfo'

# 3. Clonar estrutura + fatia do PROD
pg_dump "STRING_DO_PROD" -Fc -f torre_slice.dump
pg_restore -d "postgresql://postgres.torre-dev:SENHA@localhost:5433/postgres" torre_slice.dump

# 4. MCP (opcional) aponta para localhost:5433 com a mesma string.
#    NÃO usar o /mcp remoto (403 é bloqueio proposital no Kong).
```

Pré-requisitos: `gcloud` CLI logado (`gcloud auth login`), `pg_dump`/`pg_restore` **v17** (servidor é PG 17), senha do Postgres (canal privado). Se o dump/restore travar com erro de parâmetro não suportado (é o pooler), rodar de dentro da VM contra o banco.

### Frente B — Router de autenticação das EF no self-hosted (verify_jwt)

O mecanismo de **deploy** das Edge Functions no GCP já está decidido e é infra (GitHub Actions copia arquivos pra VM e reinicia o container — doc: `infra-torre-controle/docs/pipeline-edge-functions.md`) — **não faz parte desta spec**.

O que precisa ser resolvido é **autenticação por função**. No Supabase Cloud, o `supabase/config.toml` controla o `verify_jwt` de cada função — hoje há **38 funções com `verify_jwt = false`** (crons, webhooks como `webhook-receiver`/`ai-conversation-webhook`, EFs de API externa como `api`, `mcp-server`, `rag-query`, `ai-config`).

No **self-hosted o `config.toml` não é lido**. Quem decide é um `main/index.ts` — um router que o edge-runtime executa antes de cada função. Esse router precisa replicar a lógica dos 38 overrides.

O que quebra se errar:
- Router exige JWT de tudo → crons e webhooks quebram (pg_cron, pagamento, HyperFlow não mandam JWT).
- Router não exige JWT de nada → as ~24 funções do frontend ficam abertas sem auth (buraco de segurança).
- Lista dos 38 desatualiza → EF nova se comporta errado silenciosamente.

**Proposta (do card):** gerar o `main/index.ts` **automaticamente a partir do `config.toml`** usando o script `mapear-webhooks.py`, mantendo o `config.toml` como fonte de verdade única (ninguém mantém lista duplicada na mão).

## Critérios de aceite

- **CA-1** — Given o túnel IAP aberto, When o João conecta em `localhost:5433` com o usuário `postgres.torre-dev`, Then `\conninfo` confirma conexão ao banco DEV.
- **CA-2** — Given estrutura de prod, When o `pg_restore` roda no DEV, Then todas as tabelas, schemas e objetos existem no DEV com paridade estrutural de prod.
- **CA-3** — Given os dados de prod restaurados, When qualquer registro é inspecionado, Then **nenhum email/telefone real de cliente** existe no DEV (substituídos pelos do time de dev) e **nenhum CPF/CNPJ real** existe (substituídos por fictícios válidos em formato).
- **CA-4** — Given o mapa de colunas com PII, When a anonimização roda, Then a lista de colunas tratadas é explícita e revisada (não só as colunas óbvias) — ver questão aberta Q1.
- **CA-5** — Given o `config.toml` com os 38 overrides, When o `main/index.ts` é gerado, Then o router aplica `verify_jwt=false` exatamente para essas 38 funções e `verify_jwt=true` para as demais.
- **CA-6** — Given o router publicado no self-hosted, When um cron/webhook sem JWT chama sua EF, Then a chamada passa; e When uma EF de frontend é chamada sem JWT válido, Then é rejeitada.
- **CA-7** — Given o processo de geração do router, When uma EF nova é adicionada, Then o router se atualiza a partir do `config.toml` (regeneração automática) sem edição manual de lista duplicada.

## Subtarefas

- [ ] **ST-1 — Acesso e pré-reqs.** Confirmar túnel IAP funcionando, `gcloud` logado, `pg_dump/pg_restore` v17 instalados, senha em mãos. (parcialmente feito — acesso liberado 28/07)
- [ ] **ST-2 — Clone estrutural.** `pg_dump -Fc` do prod + `pg_restore` no DEV; validar paridade de schemas/tabelas. Ter plano B "rodar de dentro da VM" caso o pooler recuse parâmetros.
- [ ] **ST-3 — Mapa de PII.** ⚠️ PO: levantar **exaustivamente** as colunas que carregam email, telefone, CPF e CNPJ (em todas as tabelas/schemas, incluindo JSONB e campos livres), não só as óbvias. Este mapa é o gate de segurança do item.
- [ ] **ST-4 — Rotina de anonimização.** Script que substitui email/telefone pelos do time de dev e gera CPF/CNPJ fictícios (válidos em formato). Idempotente e re-executável a cada refresh do dev.
- [ ] **ST-5 — Validação de anonimização.** Query de auditoria que prova ausência de PII real pós-anonimização (CA-3/CA-4).
- [ ] **ST-6 — Router de EF (verify_jwt).** Escrever/gerar o `main/index.ts` a partir do `config.toml` via `mapear-webhooks.py`; validar os 38 overrides. ⚠️ PO: candidato a item próprio (ver Observações).
- [ ] **ST-7 — Testes do router.** Cron/webhook sem JWT passam; EF de frontend sem JWT são bloqueadas (CA-6).
- [ ] **ST-8 — Documentar.** Registrar o processo (túnel, clone, anonimização, regeneração do router) para o time repetir sem o João.

## Observações PO

**Pontos de atenção:**

1. **Isto é provavelmente 2 itens, não 1.** A descrição original (clonar dados anonimizados, 5 SP) e o comentário de 20/07 (router de auth self-hosted) são frentes técnicas distintas, com skills e riscos diferentes. Sugestão: manter BTR10 como o **clone+anonimização** (Frente A) e extrair a **Frente B (router verify_jwt)** como BTR10b/item próprio se o esforço confirmar. Mantidos juntos por ora porque nasceram no mesmo card e compartilham o objetivo "DEV self-hosted utilizável".

2. **Anonimização é o gate não-negociável.** O valor do item é justamente "dados realistas SEM PII real". Se ST-3 (mapa de colunas) for feito de forma incompleta, o item entrega um risco de vazamento disfarçado de ambiente de dev. Nenhum dado real de cliente pode sobreviver ao clone.

3. **"Substituir pelos do time de dev" precisa de definição.** Um único email/telefone do time para todos os registros? Ou distribuído? Definir antes de ST-4 (afeta testes que dependem de unicidade de contato).

4. **Router auto-gerado > lista manual — concordo com a proposta do card.** Gerar do `config.toml` elimina a classe de bug "EF nova esquecida". Vale investir na regeneração automática (CA-7) mesmo que custe mais que hardcodar os 38 hoje.

5. **Deploy das EF está fora de escopo** (já decidido, é infra `infra-torre-controle`). Não reabrir essa discussão aqui.

6. **Ambiente self-hosted GCP ≠ Supabase Cloud dev.** Este item é sobre o self-hosted na VM `torre-dev-supabase` (projeto `finza-torre-de-controle-dev`) — não confundir com o dev Cloud (project_ref `dcedqaatdeobbrlwxzha`) citado em QMR3380/IAF-141/IAF-191.

## Questões em aberto

- **Q1** — Existe inventário de colunas com PII na Torre, ou é preciso derivá-lo do schema? (bloqueia ST-3)
- **Q2** — Além do `verify_jwt`, o `main/index.ts`/self-hosted precisa replicar outra coisa do `config.toml`? (import maps? secrets por função?) — pergunta explícita do card, ainda sem resposta.
- **Q3** — Onde o router `main/index.ts` vive: no repo do monolito (junto das EFs) ou no `infra-torre-controle`? — decisão pendente no card.
- **Q4** — O clone é do banco **inteiro** ou de uma **fatia** ("STRING_DO_PROD" / `torre_slice.dump` sugere fatia)? Definir volume e critério de recorte.

## Itens relacionados (não são dependência dura)

- **QMR3380 / IAF-134** — Migrar fluxo Torre para dev/PR/prod (entregue).
- **IAF-141** — Pipeline/deploy automático ambiente dev (entregue).
- **IAF-191** — Resetar ambiente de dev do supabase (entregue) — dev Cloud, não o self-hosted.
- **QMR3691** — Recriar supabase prod.

## Definição de pronto

- [ ] DEV self-hosted acessível via túnel IAP com estrutura de prod (CA-1, CA-2).
- [ ] Auditoria prova zero PII real no DEV (CA-3, CA-4).
- [ ] Router de EF publicado, com os 38 overrides corretos e regeneração automática (CA-5, CA-6, CA-7).
- [ ] Processo documentado para o time reproduzir.

## Histórico

- 2026-08-07 — Item criado a partir do Quimera #4786 ("Supabase Dev"), que foi cancelado e reatribuído ao João Vinícius (que vai executar). Descrição e os 2 comentários técnicos do card viraram o insumo. Status inicial `em-refinamento`. Sinalizado candidato a quebra em 2 itens (Frente A clone+anonimização · Frente B router verify_jwt).
