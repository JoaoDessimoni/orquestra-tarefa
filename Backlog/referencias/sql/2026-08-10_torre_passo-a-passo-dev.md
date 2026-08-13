# Passo a passo — provisionar o Supabase DEV self-hosted (GCP)

> **Item:** BTR10 · origem Quimera #4786
> **Data:** 2026-08-10
> **Executor:** João Vinícius
> **Escopo desta execução:** estrutura completa + 100 clientes anonimizados por org + ambiente segregado de prod. O router `verify_jwt` saiu para o **BTR11**.

Este roteiro assume **zero familiaridade com Supabase self-hosted**. Cada passo diz o que rodar, o que esperar e como saber que deu certo.

---

## Antes de tudo — o modelo mental

Você vai produzir **dois arquivos SQL** e rodar cada um uma vez:

| Arquivo | Vem de onde | Roda onde | O que faz |
|---|---|---|---|
| `01_estrutura.sql` | `pg_dump --schema-only` do **prod** | DEV | Cria schemas, tabelas, views, funções, RPCs, RLS, triggers, índices. Nenhum dado. |
| `02_dados.sql` | gerado pelo `gerar-seed-dev.sql` rodando no **prod** | DEV | INSERTs já anonimizados: catálogos + 100 clientes por org. |

E um terceiro, só de conferência: `03_validacao.sql` (é o `2026-08-10_torre_validacao-dev.sql`).

**Três princípios que este desenho respeita:**

1. **Nada é apagado.** As tabelas de log e de segredo existem no DEV com a estrutura completa — só não recebem INSERT.
2. **Segregação por omissão.** O DEV não alcança a prod porque coisas simplesmente *não foram levadas*, não porque foram deletadas depois.
3. **Reprodutível.** A amostra dos 100 clientes é determinística. Rodar de novo dá os mesmos 100 — um bug encontrado hoje continua reproduzível no próximo refresh.

---

## ⚠️ Confirmar antes de começar: o nome da VM

Há duas informações em conflito:

- O comentário no Quimera #4786 (28/07) usa `torre-dev-supabase`
- O doc de pipeline do DevOps usa `supabase-dev`

Rode isto para descobrir o nome real — é rápido e evita erro em todos os comandos seguintes:

```bash
gcloud compute instances list --project=finza-torre-de-controle-dev
```

Nos comandos abaixo, substitua `<VM>` pelo nome que aparecer.

---

## Passo 0 · Pré-requisitos

```bash
# 0.1 · gcloud instalado e logado
gcloud auth login
gcloud config set project finza-torre-de-controle-dev

# 0.2 · versão do pg_dump — TEM de ser 17.x
pg_dump --version
psql --version
```

**Por que a versão importa:** o servidor é PostgreSQL 17. Um `pg_dump` 15 ou 16 recusa dumpar um servidor mais novo com a mensagem `server version: 17.x; pg_dump version: 16.x — aborting`. Se a sua estiver desatualizada:

- **Windows:** instale o PostgreSQL 17 (só o *Command Line Tools* basta) e use o binário de `C:\Program Files\PostgreSQL\17\bin\`.
- **Alternativa:** rode o dump **de dentro da VM** (ela já tem o cliente 17) — é o plano B que você mesmo previu no card.

```
[ ] gcloud logado
[ ] pg_dump 17.x confirmado
[ ] senha do Postgres do DEV em mãos (canal privado)
[ ] string de conexão do PROD em mãos
```

---

## Passo 1 · Abrir o túnel IAP

O banco DEV **não é exposto à internet de propósito** — firewall deny-all, só IAP-SSH e Load Balancer liberados. Timeout nas portas 5432/6543 é o comportamento correto, não um problema.

**Terminal 1** (deixe aberto durante todo o trabalho):

```bash
gcloud compute ssh <VM> --zone=us-central1-a \
  --project=finza-torre-de-controle-dev --tunnel-through-iap \
  -- -L 5433:localhost:5432 -N
```

O comando não devolve prompt — ele fica "pendurado". Isso é o esperado: enquanto estiver rodando, `localhost:5433` na sua máquina é o banco DEV.

**Terminal 2** — confirmar:

```bash
psql "postgresql://postgres.torre-dev:SUA_SENHA@localhost:5433/postgres" -c '\conninfo'
```

✅ **Gate G1:** aparece `You are connected to database "postgres" as user "postgres.torre-dev" on host "localhost" ... port "5433"`.

Se der `connection refused`, o túnel do Terminal 1 caiu. Se der erro de autenticação, a senha está errada — não insista, confirme no canal privado.

### Guarde as duas strings de conexão

```bash
# no Terminal 2, para não repetir a string toda hora
export DEV_URL="postgresql://postgres.torre-dev:SUA_SENHA@localhost:5433/postgres"
export PROD_URL="postgresql://...prod..."   # a string do Supabase Cloud
```

No PowerShell:

```powershell
$env:DEV_URL  = "postgresql://postgres.torre-dev:SUA_SENHA@localhost:5433/postgres"
$env:PROD_URL = "postgresql://...prod..."
```

---

## Passo 2 · Gerar o `01_estrutura.sql`

```bash
pg_dump "$PROD_URL" \
  --schema-only \
  --no-owner --no-privileges \
  --schema=public \
  --schema='org_*' \
  -f 01_estrutura.sql
```

### Por que exatamente estes schemas

| Schema | Entra? | Motivo |
|---|---|---|
| `public` | ✅ | control plane + funções/RPCs do sistema |
| `org_blips`, `org_finza` | ✅ | os dois tenants com dado real |
| `auth`, `storage`, `realtime`, `vault`, `graphql`, `extensions`, `net` | ❌ | criados pelo bootstrap do self-hosted (GoTrue, Storage API…). Sobrescrever gera conflito de versão. |
| **`cron`** | ❌ | **é assim que o DEV nasce com zero cron ativo.** Nada foi desligado — os jobs simplesmente não foram levados. Você habilita depois, quando quiser. |
| `supabase_migrations` | ❌ | histórico de migration do Cloud; o DEV terá o próprio |

**Confira o tamanho e dê uma olhada:**

```bash
ls -lh 01_estrutura.sql
grep -c "CREATE TABLE" 01_estrutura.sql
```

Espere algo na casa de poucos MB e ~230 `CREATE TABLE` (97 + 97 + 36).

> **Se `--schema='org_*'` não pegar as duas orgs** (depende da versão/shell), use explícito:
> `--schema=public --schema=org_blips --schema=org_finza`

---

## Passo 3 · Aplicar a estrutura no DEV

```bash
psql "$DEV_URL" -v ON_ERROR_STOP=1 -f 01_estrutura.sql
```

**Erros que são normais e podem ser ignorados** (aparecem porque o bootstrap já criou parte do ambiente):

- `role "..." does not exist` — mitigado por `--no-owner`, mas pode escapar em algum `GRANT`
- `extension "..." already exists`
- `schema "public" already exists`

**Erros que NÃO são normais e exigem parar:** falha em `CREATE TABLE`, `CREATE FUNCTION` ou `CREATE POLICY`. Aí o schema ficou incompleto.

> Se você usou `ON_ERROR_STOP=1` e o script parou num `GRANT` inofensivo, rode de novo **sem** essa flag e depois confira o resultado pelo gate G2.

✅ **Gate G2 parcial:** rode a primeira consulta do `03_validacao.sql` e compare com o prod. Os números do prod em 10/08/2026 eram:

| Schema | Tabelas |
|---|---|
| `org_blips` | 97 |
| `org_finza` | 97 |
| `public` | 36 |

E no banco todo: **4 matviews**, **23 views**.

---

## Passo 4 · Gerar o `02_dados.sql`

Aqui entra o script que eu escrevi. Ele **roda no PROD** e **não altera nada lá** — só cria objetos temporários de sessão e imprime texto.

```bash
psql "$PROD_URL" -X -A -t -q -v ON_ERROR_STOP=1 \
  -f 2026-08-10_torre_gerar-seed-dev.sql > 02_dados.sql
```

**Confira antes de aplicar** — é texto puro, você consegue ler:

```bash
head -40 02_dados.sql          # cabeçalho + contagem da amostra
grep -c "^INSERT INTO" 02_dados.sql
grep -i "@" 02_dados.sql | grep -v "blips.com.br\|finza.com.br" | head   # deve sair vazio
```

O último comando é o mais importante: **se sair qualquer linha, tem e-mail não anonimizado** e você não deve aplicar.

### O que o arquivo contém

- **Catálogos completos** por org: `standard_values`, `tag_catalog`, `custom_field_definitions`, `data_sources`, `etl_pipelines`, `filter_definitions` (53), `portfolios`, `campaigns` (68), `workflows` (78), `workflow_steps` (938), `message_templates`, config de IA (`ai_prompts` 352, `ai_guidelines` 620, `ai_business_rules` 269), RAG
- **100 clientes por org** com contatos, e-mails, telefones, contratos, títulos e selos — anonimizados
- **As `actions` estritamente referenciadas** pelos títulos selecionados (para as FKs `attributed_action_id`, `negativation_action_id`, `notification_action_id` não ficarem órfãs) — não o histórico de 469 mil linhas
- **`integrations` presentes mas com `is_active = false` e `config = '{}'`** — aparecem na UI, não têm credencial, não disparam
- **`report_schedules` com `is_active = false`** e destinatário trocado pelo time
- **`mv_refresh_config` com `enabled = false`** — paused-by-default, igual ao padrão do projeto para org nova

### O que o arquivo NÃO contém (de propósito)

`etl_source_snapshots` · `skipped_actions_log` · `actions` (histórico) · `campaign_logs` · `campaign_execution_*` · `etl_batch_jobs` · `etl_job_*` · `title_status_history` · `ai_conversations` · `ai_messages` · `conversation_tags` · `audit_logs` · `workflow_audit_logs` · `inbound_webhooks` · `webhook_retry_queue` · `edge_function_call_logs` · `n8n_chat_histories` · `chat_messages` · `socorro_*` · `luna_*` · **`project_config`** · **`api_keys`** · **`integration_secrets`** · **`organization_secrets`** · `user_invitations` · `organization_users`

As tabelas existem, com estrutura completa. Estão vazias.

---

## Passo 5 · Aplicar os dados no DEV

```bash
psql "$DEV_URL" -v ON_ERROR_STOP=1 -f 02_dados.sql
```

O script já vem embrulhado em `BEGIN; … COMMIT;` com `SET session_replication_role = replica`, que **desliga temporariamente os triggers de FK durante a carga**. Isso é o que torna a ordem dos INSERTs irrelevante e resolve as FKs circulares (`workflows` ↔ `workflow_versions`, e `workflow_steps` apontando para si mesma). No fim ele volta ao normal e refresca as matviews.

**Se falhar no meio:** a transação inteira é revertida (é o ponto de usar `BEGIN`). Você lê o erro, ajusta e roda de novo. Nada fica pela metade.

> `session_replication_role = replica` exige superusuário. Como o `postgres.torre-dev` é o dono do banco self-hosted, deve funcionar. Se der `permission denied to set parameter`, me avise — a alternativa é ordenar os INSERTs topologicamente, que eu gero.

---

## Passo 6 · Validar

```bash
psql "$DEV_URL" -X -f 2026-08-10_torre_validacao-dev.sql
```

Leia os vereditos. **Todos precisam dizer OK.**

| Gate | O que prova |
|---|---|
| G2 | Paridade estrutural com prod |
| G3 | Zero e-mail fora da allowlist do time |
| G4 | Todo telefone é `999999999` |
| G5 | Documentos únicos e com 11/14 dígitos |
| G6 | Nenhum e-mail escondido dentro de JSONB |
| **G7** | **`vw_titles_live` mostra dado anonimizado** — pega o caso de matview não refrescada |
| G8 | Nenhum cron ativo |
| G9 | Nenhuma credencial de prod |

### G7 é o gate que quase todo mundo esquece

`vw_titles_live` é passthrough de `mv_titles_base`, uma **materialized view**. O app inteiro (dashboard, filtros, campanhas, relatórios) lê ela. Se você validar só as tabelas-base, dá falso positivo: a MV pode estar servindo dado antigo.

O `02_dados.sql` já termina com `REFRESH MATERIALIZED VIEW`. Se o G7 disser **"vw_titles_live está VAZIA"**, o refresh não rodou — execute manualmente:

```sql
REFRESH MATERIALIZED VIEW org_blips.mv_titles_base;
REFRESH MATERIALIZED VIEW org_finza.mv_titles_base;
```

Se disser **"FALHOU — N linhas com PII real"**, a MV materializou antes da anonimização. Refresque de novo e revalide.

---

## Passo 7 · Liberar o ambiente

Só depois de todos os gates verdes:

1. **Criar os usuários do time** no Studio do DEV (`auth.users` não foi clonado de propósito — 32 logins reais de prod num ambiente menos protegido é superfície sem ganho).
2. **Gerar uma API key de dev**: `SELECT public.create_api_key('dev-local');` — a de prod não desceu, e pela arquitetura atual uma key vale para todas as orgs, então nunca reaproveite.
3. **Documentar** para o time repetir o refresh sem você. Sem isso, o item entrega um ambiente, não uma capacidade.

### Quando você quiser ligar os crons (depois, com consciência)

O DEV nasceu sem nenhum. Para habilitar:

```sql
-- 1. apontar o invoke_edge_function para o PRÓPRIO dev (nunca para prod)
INSERT INTO public.project_config(key, value, description)
VALUES ('project_url', 'https://api.dev.torredecontrole.finza.com.br', 'URL do DEV'),
       ('service_role_key', '<a chave do DEV>', 'service_role do DEV');

-- 2. religar a materialização de uma org
UPDATE public.mv_refresh_config
   SET enabled = true, schedule_cron = '30 0 * * *'
 WHERE schema_name = 'org_blips';

-- 3. e só então recriar os cron jobs que interessarem, um a um,
--    a partir das migrations que os definem (setup-*-cron.sql)
```

**Não recrie os 26 de uma vez.** Ligue só o que você vai testar.

---

## Ordem de dependência entre os passos

```
Passo 0 (pré-req)
   └─> Passo 1 (túnel) ──> Passo 2 (dump estrutura, usa PROD)
                              └─> Passo 3 (aplica estrutura no DEV)
                                     └─> Passo 4 (gera dados, usa PROD)
                                            └─> Passo 5 (aplica dados no DEV)
                                                   └─> Passo 6 (valida)
                                                          └─> Passo 7 (libera)
```

Os passos 2 e 4 leem o **prod**; os 3, 5 e 6 escrevem/leem o **DEV**. O túnel do passo 1 precisa estar vivo em todos.

---

## Se algo der errado

| Sintoma | Causa provável | O que fazer |
|---|---|---|
| `server version: 17.x; pg_dump version: 16.x` | pg_dump velho | Instalar cliente 17 ou rodar de dentro da VM |
| `connection refused` no 5433 | túnel caiu | Reabrir o Terminal 1 |
| Timeout ao conectar direto em 5432/6543 | comportamento correto | Usar o túnel; o banco não é exposto |
| `403` no `/mcp` | bloqueio proposital no Kong | Apontar o MCP para `localhost:5433` |
| `unsupported startup parameter` no dump/restore | é o pooler | Rodar de dentro da VM contra o banco direto |
| `permission denied to set parameter "session_replication_role"` | não é superusuário | Me avisar — gero versão com ordem topológica |
| G7 diz "VAZIA" | matview não refrescada | `REFRESH MATERIALIZED VIEW` manual |

---

## Registro

- **2026-08-10** — Roteiro criado a partir do plano `Apresentacoes/executando/supabase-dev-selfhosted-gcp_plano_10-08-2026.html`, com escopo reduzido a 100 clientes por org conforme decisão do João. Frente D (router `verify_jwt`) extraída para o **BTR11**.
