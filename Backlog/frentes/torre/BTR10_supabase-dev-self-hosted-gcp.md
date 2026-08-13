---
id: BTR10
title: Provisionar Supabase DEV self-hosted (GCP) com 100 clientes anonimizados e ambiente segregado
frente: torre
fonte: backlog
status: em-curso
prioridade: alta
rice:
  reach: 7
  impact: 7
  confidence: 8
  effort: 4
  score: 9.8
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
implementador: João Vinícius Dessimoni Fernandes
sponsor: João Vinícius
criada: 2026-08-07
refinada: 2026-08-10
deadline_alvo: 2026-Q3
dependencias: []
bloqueia: [BTR11]
riscos:
  - "Janela de exposição: entre o restore e a anonimização o DEV tem PII real. Mitigado por anonimizar na mesma sessão de trabalho, antes de liberar acesso a terceiros — mas a janela existe e é aceita explicitamente."
  - "PII enterrada em JSONB (custom_fields, metadata, request_payload) não tem esquema fixo. O gerador aplica varredura por regex; o gate G6 é o que prova. Se G6 falhar, apertar o anon_text."
  - "Matview mv_titles_base (223 MB) materializa PII: anonimizar as tabelas-base sem refrescar deixa vw_titles_live servindo dado real, e o app inteiro lê a MV. Gate G7 cobre."
  - "session_replication_role=replica exige superusuário. Se o pooler recusar, o seed precisa de ordem topológica de INSERTs (FKs circulares em workflows↔workflow_versions e workflow_steps→si mesma)."
  - "Nome da VM em conflito entre fontes: torre-dev-supabase (Quimera #4786, 28/07) vs supabase-dev (doc de pipeline do DevOps). Confirmar com gcloud compute instances list antes de rodar qualquer comando."
premissas:
  - Acesso ao banco DEV via túnel IAP liberado para o João em 28/07 (confirmado no card).
  - Servidor DEV é PG 17 — pg_dump/pg_restore precisam ser v17.
  - Banco DEV é fechado de propósito (firewall deny-all; só IAP-SSH e Load Balancer). Timeout em 5432/6543 é esperado, não bug. 403 no /mcp é bloqueio proposital no Kong.
  - Deploy das Edge Functions já resolvido pelo DevOps (GitHub Actions + scp via IAP + restart do container) — fora do escopo deste item.
tags: [torre, supabase, self-hosted, gcp, dev, anonimizacao, pii, segregacao, infra]
---

# BTR10 — Provisionar Supabase DEV self-hosted (GCP) com 100 clientes anonimizados

> **Origem:** Quimera #4786 "Supabase Dev" (TI · 5 SP), cancelado no Quimera em 2026-08-05 e reatribuído ao João Vinícius.
> **Quebra:** em 2026-08-10 a Frente D (router `verify_jwt` no self-hosted) foi extraída para o **[[BTR11]]**. Este item cobre clone + anonimização + segregação.
> **Plano executável:** `Apresentacoes/executando/supabase-dev-selfhosted-gcp_plano_10-08-2026.html`
> **Roteiro operacional:** `Backlog/referencias/sql/2026-08-10_torre_passo-a-passo-dev.md`

## História de usuário

Como **time de desenvolvimento da Torre**,
quero **um Supabase DEV self-hosted no GCP com a estrutura completa de produção e uma amostra de 100 clientes por org totalmente anonimizada, num ambiente que não alcança produção nem cliente real**,
para **desenvolver e testar contra dados realistas sem risco de vazamento de PII e sem risco de disparo indevido**.

## Contexto e escopo

O card original pedia "replicar exatamente o prod, mudando apenas e-mail, telefone, CNPJ e CPF". A leitura do banco de produção (10/08/2026) mostrou que essa frase esconde três trabalhos e que o risco maior não é a PII.

### Frente A — Clone estrutural com recorte

Estrutura **completa** (schemas, tabelas, views, matviews, funções, RPCs, RLS, triggers, índices) via `pg_dump --schema-only` de `public` + `org_blips` + `org_finza`. Dado: **somente o essencial** — catálogos de configuração por org e **100 clientes por org**, escolhidos de forma determinística.

Fora: todo log e histórico operacional (`etl_source_snapshots`, `skipped_actions_log`, `actions` histórico, `campaign_logs`, `etl_batch_jobs`, `title_status_history`, `ai_conversations`/`ai_messages`, `audit_logs`, `edge_function_call_logs`, `n8n_chat_histories`, etc.). As tabelas existem vazias, com estrutura completa — **nada é apagado, apenas não é carregado**.

### Frente B — Anonimização

Mocks definidos pelo João:

- **E-mail** → os do time no Quimera, distribuídos de forma estável: `joao.dessimoni@blips.com.br`, `marcos.oliveira@finza.com.br`, `leandro.gontijo@blips.com.br`, `joaopedro@blips.com.br`
- **Telefone** → `999999999` para todos
- **CPF/CNPJ** → fictício, **válido no dígito verificador**, determinístico por id
- **Nome / endereço / texto livre / JSONB** → substituídos (não apagados)

Constraint verificada em prod: **não existe unique no valor de e-mail nem de telefone** (o unique é `(contact_id, priority)`), portanto repetir o mesmo contato é seguro. **`contacts.document` É unique** (dois índices) — daí a exigência de documento fictício único.

### Frente C — Segregação de ambientes

Por **omissão**, não por delete:

- schema `cron` fora do dump → **DEV nasce com zero cron ativo** (dos 26 ativos em prod)
- `public.project_config` não semeada → `invoke_edge_function()` sem alvo → **DEV não chama EF de prod**
- `api_keys`, `integration_secrets`, `organization_secrets` não semeadas
- `auth.users` não clonado (32 logins reais) — time criado no Studio do DEV

Duas exceções em que um **valor** é substituído para permitir "visível mas desligado": `integrations` (`is_active=false`, `config='{}'`) e `report_schedules` (`is_active=false`, destinatário do time). Mais `mv_refresh_config.enabled=false` (paused-by-default, padrão do projeto).

## Critérios de aceite

- **CA-1** — Given o túnel IAP aberto, When conecto em `localhost:5433` como `postgres.torre-dev`, Then `\conninfo` confirma o banco DEV. *(gate G1)*
- **CA-2** — Given a estrutura aplicada, When comparo contagem de tabelas/views/matviews/funções/policies por schema, Then há paridade com prod (97 · 97 · 36 tabelas; 4 matviews; 23 views). *(G2)*
- **CA-3** — Given o seed aplicado, When varro toda coluna de e-mail de toda tabela-base, Then nenhum valor está fora da allowlist do time. *(G3)*
- **CA-4** — Given o seed aplicado, When varro toda coluna de telefone, Then todo valor é `999999999`. *(G4)*
- **CA-5** — Given o seed aplicado, When inspeciono `contacts.document`, Then todo documento é único e tem 11 ou 14 dígitos, e nenhum existe em prod. *(G5, G5b)*
- **CA-6** — Given o seed aplicado, When busco padrão de e-mail dentro de colunas JSONB, Then não há ocorrência estranha. *(G6)*
- **CA-7** — Given as matviews refrescadas, When repito CA-3/CA-4 **contra `vw_titles_live`**, Then zero PII real e a view **não** está vazia. *(G7)*
- **CA-8** — Given o DEV pronto, When consulto `cron.job`, Then zero job ativo. *(G8)*
- **CA-9** — Given o DEV pronto, When conto `project_config`, `api_keys`, `integration_secrets`, integrações ativas e `report_schedules` ativos, Then todos zero. *(G9)*
- **CA-10** — Given a documentação, When outra pessoa do time roda o refresh do DEV sozinha, Then conclui sem consultar o João. *(G10)*

## Subtarefas

- [x] **ST-1 — Levantar o terreno.** Medir prod: volume, schemas, orgs, crons, EFs, constraints. *(feito 10/08 — 13 GB, 2 orgs, 26 crons ativos, 62 EFs)*
- [x] **ST-2 — Mapa de PII.** Inventário exaustivo por nível (coluna dedicada · JSONB/texto livre · fora dos schemas de org). *(feito 10/08 — resolve a Q1)*
- [x] **ST-3 — Definir o recorte.** Critério: exclusão de tabelas de log, não amostragem de linhas. *(feito 10/08 — resolve a Q4)*
- [x] **ST-4 — Escrever o gerador de seed.** `Backlog/referencias/sql/2026-08-10_torre_gerar-seed-dev.sql` — roda em prod, só objetos temporários, emite INSERTs anonimizados lendo o catálogo (não lista fixa).
- [x] **ST-5 — Escrever os gates.** `Backlog/referencias/sql/2026-08-10_torre_validacao-dev.sql` — G2 a G9 + checagem de órfãos de FK.
- [x] **ST-6 — Escrever o roteiro.** `Backlog/referencias/sql/2026-08-10_torre_passo-a-passo-dev.md`.
- [ ] **ST-7 — Confirmar o nome da VM.** `gcloud compute instances list` — conflito entre `torre-dev-supabase` e `supabase-dev`.
- [ ] **ST-8 — Passo 0-1: pré-requisitos e túnel.** gcloud logado, pg_dump 17, senha, túnel IAP de pé (CA-1).
- [ ] **ST-9 — Passo 2-3: estrutura.** `pg_dump --schema-only` e aplicação no DEV (CA-2).
- [ ] **ST-10 — Passo 4-5: dados.** Gerar e aplicar o seed dos 100 clientes (CA-3 a CA-6).
- [ ] **ST-11 — Passo 6: validar.** Rodar os gates; refrescar matviews (CA-7 a CA-9).
- [ ] **ST-12 — Passo 7: liberar.** Usuários do time no Studio, API key de dev, documentar (CA-10).

## Observações PO

1. **O risco número 1 não é PII, é disparo.** O banco da Torre não é repositório passivo: é motor de disparo com pg_cron dentro do Postgres chamando EFs que mandam WhatsApp, e-mail e negativação. Clonar o banco é clonar o motor ligado. Anonimizar sem segregar troca um vazamento por um incidente.

2. **Segregação por omissão é mais segura que por delete.** Não levar o schema `cron` e não semear `project_config` é estruturalmente mais forte que restaurar tudo e desligar depois — não existe janela entre restore e desligamento.

3. **Escopo reduzido a 100 clientes por decisão do João (10/08).** O núcleo de negócio em prod são 6.132 contatos / 56.121 títulos (blips) e 1.309 / 3.230 (finza). 100 por org é suficiente para desenvolvimento e reduz drasticamente a superfície de PII. Amostra determinística → dev reproduzível.

4. **`actions` entra só como dependência de FK.** 16.820 títulos têm `attributed_action_id`, 3.756 `negativation_action_id`, 1.172 `notification_action_id`. Trazer só as actions referenciadas pelos títulos da amostra mantém a integridade sem carregar 469 mil linhas de histórico.

5. **Correção de premissa (10/08):** a ressalva anterior sobre unicidade de e-mail/telefone estava errada — foi inferida dos nomes das migrations (`add_phone_email_unique_constraints`), não da constraint viva. Na prática o unique é `(contact_id, priority)`, então o mock simples pedido pelo João funciona.

6. **Ambiente self-hosted GCP ≠ dev Cloud.** Este item é a VM no projeto `finza-torre-de-controle-dev`, não o dev Cloud (`project_ref dcedqaatdeobbrlwxzha`) de QMR3380 / IAF-141 / IAF-191.

## Questões

- **Q1** — ✅ **Resolvida** (ST-2): inventário de PII derivado do catálogo de prod.
- **Q4** — ✅ **Resolvida** (ST-3): fatia, por exclusão de tabelas de log.
- **Q5** — ⏳ Nome da VM: `torre-dev-supabase` ou `supabase-dev`? (ST-7)
- **Q6** — ⏳ Endereço (`address_*`) e `notes` são anonimizados por decisão minha, embora o card só pedisse e-mail/telefone/CPF/CNPJ. Confirmar que está OK.
- ~~Q2, Q3~~ — migradas para o **[[BTR11]]** (são do router).

## Itens relacionados

- **[[BTR11]]** — Router `verify_jwt` no self-hosted (extraído deste item). Este item o **bloqueia**: sem DEV de pé não há onde testar o router.
- **QMR3380 / IAF-134** — Migrar fluxo Torre para dev/PR/prod (entregue).
- **IAF-141** — Pipeline/deploy automático ambiente dev (entregue).
- **IAF-191** — Resetar ambiente de dev do Supabase (entregue) — dev Cloud, não self-hosted.
- **QMR3691** — Recriar Supabase prod.

## Definição de pronto

- [ ] DEV acessível via túnel IAP com estrutura em paridade com prod (CA-1, CA-2).
- [ ] 100 clientes por org carregados e auditoria provando zero PII real, inclusive em `vw_titles_live` (CA-3 a CA-7).
- [ ] Ambiente segregado: zero cron ativo, zero credencial de prod (CA-8, CA-9).
- [ ] Processo documentado e reproduzido por outra pessoa do time (CA-10).

## Histórico

- **2026-08-07** — Item criado a partir do Quimera #4786, que foi cancelado e reatribuído ao João. Status `em-refinamento`, esforço L, RICE 4,9. Sinalizado candidato a quebra em 2 itens.
- **2026-08-10** — Terreno medido em prod (13 GB, 2 orgs, 26 crons ativos, 62 EFs, 53 sem `verify_jwt`). Três premissas do refinamento anterior caíram: são duas orgs e não uma; o `config.toml` não descreve a prod; o clone herda o motor de disparo ligado. Frente C (segregação) criada. Frente D extraída para **[[BTR11]]**. Escopo reduzido a 100 clientes/org por decisão do João. Gerador de seed, gates e roteiro escritos. Status → `em-curso`; esforço L→M; RICE 4,9 → 9,8 (confiança sobe com o recon feito, esforço cai com o escopo reduzido).
