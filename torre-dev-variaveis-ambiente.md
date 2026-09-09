# Torre de Controle DEV (self-hosted GCP) — variáveis de ambiente

> **Atualizado:** 2026-08-17 · **Ambiente:** DEV self-hosted · **Repo:** `finza-org/finza-torre-controle-ia`, branch `dev`
> Referência: `Apresentacoes/executando/torre-dev-roadmap.html` · itens `BTR10` e `BTR11`

---

## ⚠️ Regra de segurança deste arquivo

**Este arquivo é rastreado pelo git** (repo `JoaoDessimoni/orquestra-tarefa`, branch `main`) e `.md` não está no `.gitignore`. Portanto:

- **Valor não-secreto** (ID de projeto, nome de site, URL, nome de VM) → pode anotar aqui.
- **Valor secreto** (chave, senha, token, JSON de service account) → **nunca** escreva aqui. Marque só `[x]` na coluna de status. O valor vive no GitHub Secrets ou no `.env` da VM, e em nenhum outro lugar.

Se você anotar um segredo aqui e commitar, ele vai para o GitHub e precisa ser rotacionado.

---

## Onde cada coisa vive, e por quê

São **cinco destinos diferentes**. Confundi-los é a causa mais comum de deploy que falha sem mensagem clara.

| Destino | O que guarda | Quem lê | Por que não pode ser outro lugar |
|---|---|---|---|
| **GitHub → Secrets** | Credenciais que o CI/CD usa | GitHub Actions, em tempo de execução | Cifrado, não aparece em log, não sai do GitHub |
| **GitHub → Variables** | Config não-secreta do CI/CD | GitHub Actions | É valor público (aparece na URL do site); virar secret só atrapalharia a leitura do log |
| **GitHub → Environments** | Agrupamento de deploy | GitHub Actions | Registra a implantação na aba *Deployments* e é onde entra reviewer obrigatório |
| **`.env` da VM** | Config das Edge Functions | container `supabase-edge-functions`, via `Deno.env.get()` | A EF roda **dentro da VM**, não no Actions. Secret do GitHub não chega lá |
| **Arquivo versionado** (`.firebaserc`) | ID de projeto e site do Firebase | Firebase CLI durante o deploy | Não é segredo, e o CLI precisa ler do disco |

**A distinção que mais confunde:** um secret do GitHub serve para o *pipeline*; o `.env` da VM serve para a *aplicação em execução*. `SUPABASE_ANON_KEY_DEV` existe nos dois lugares por motivos diferentes — no GitHub para o build do frontend, na VM para as EFs.

---

## 1 · GitHub → Secrets

`Settings → Secrets and variables → Actions → Secrets → New repository secret`

| Nome | Por que precisa | Como pegar o valor | Status |
|---|---|---|---|
| `FIREBASE_SERVICE_ACCOUNT_DEV` | Autoriza o Actions a publicar no Firebase Hosting. Sem ele o job `frontend` não publica. | Console Firebase → ⚙️ **Project settings** → aba **Service accounts** → **Generate new private key**. Baixa um `.json`; cole o **conteúdo inteiro** (com as chaves `{}`). | `[ ]` |
| `SUPABASE_ANON_KEY_DEV` | Vai em `VITE_SUPABASE_ANON_KEY` no build (é como o frontend fala com a API) e no `Authorization` do smoke test das EFs. | Do `.env` da VM. Comando abaixo em *Como ler o `.env` da VM*. **Use a do self-hosted, não a do Cloud.** | `[ ]` |
| `POSTGRES_PASSWORD_DEV` | Aplicar migrations e refrescar matviews pelo túnel IAP. | Você já tem — é a mesma do seu `%APPDATA%\postgresql\pgpass.conf`. Também está no `.env` da VM como `POSTGRES_PASSWORD`. | `[ ]` |
| `WIF_PROVIDER_DEV` | Deixa o Actions autenticar no GCP **sem chave JSON**. Bloqueia `migrate`, `functions` e `verify`. | **Não existe ainda — pedir ao sysops.** Formato: `projects/<número>/locations/global/workloadIdentityPools/<pool>/providers/<provider>`. | `[ ]` |
| `WIF_SA_DEV` | A identidade que abre o túnel IAP e o SSH para copiar as Edge Functions. | **Não existe ainda — pedir ao sysops.** É o e-mail de uma service account com `roles/iap.tunnelResourceAccessor` + `compute.instances.get` + **OS Login** habilitado. | `[ ]` |
| `GOOGLE_CHAT_CICD_WEBHOOK_URL` | Notifica resultado de deploy e rollback. **Opcional** — sem ele o step é pulado, não falha. | Google Chat → espaço → **Apps e integrações** → **Webhooks** → criar. | `[ ]` |

`GITHUB_TOKEN` é injetado automaticamente pelo Actions. **Não crie.**

### ⚠️ Rotação pendente

`POSTGRES_PASSWORD_DEV` e a senha do Studio foram compartilhadas em conversa e **precisam ser giradas**. Ao girar, atualize nos **três** lugares: o secret do GitHub, o `.env` da VM e o seu `pgpass.conf` local — senão o `psql` passa a falhar com senha velha, silenciosamente.

Também pendente: rotação da chave do service account `data-ai-team-service-account@blips-bigdata` (`private_key_id` iniciando em `2617e321`), exposta em transcript.

---

## 2 · GitHub → Variables

`Settings → Secrets and variables → Actions → Variables`

| Nome | Por que precisa | Valor | Status |
|---|---|---|---|
| `FIREBASE_PROJECT_ID` | Passado ao `action-hosting-deploy`. Não é segredo — aparece na URL pública. | **`finza-dev-481500`** ✅ confirmado | `[ ]` |
| `APP_BASE_URL_DEV` | URL pública do frontend: usada no `environment.url` e no smoke test. Sem ela o deploy usa `https://finza-torre-controle.web.app`. | **`https://dev.cobranca.finza.com.br`** ✅ domínio já *Conectado*, TLS válido | `[ ]` |

---

## 3 · GitHub → Environments

`Settings → Environments → New environment`

| Nome | Por que precisa | Status |
|---|---|---|
| `dev` | O job `frontend` publica nele e registra a URL na aba *Deployments*. É onde entra reviewer obrigatório quando `hml`/`prd` existirem. | `[ ]` |

---

## 4 · Arquivos versionados (não são segredo)

| Arquivo | Conteúdo | Status |
|---|---|---|
| `.firebaserc` | `projects.default` = `finza-dev-481500` · `targets.finza-dev-481500.hosting.dev` = `["finza-torre-controle"]` | ✅ preenchido |
| `firebase.json` | Target `dev`, `public: dist`, rewrite de SPA, headers de cache e segurança | ✅ criado |

**Por que não são secret:** Project ID e Site ID aparecem na URL pública (`finza-torre-controle.web.app`). Guardá-los como secret só tornaria o log do CI ilegível sem ganho nenhum.

### Sobre a confusão do `FIREBASE_PROJECT_ID`

O valor `finza-dev-481500` está correto. A confusão tem uma causa real: no Firebase, **o site padrão recebe o mesmo nome do projeto**. No painel de Hosting do `finza-dev` aparecem 4 sites, e um deles chama-se literalmente `finza-dev-481500` — igual ao Project ID. São coisas diferentes:

| Conceito | Valor | Onde aparece |
|---|---|---|
| **Project ID** | `finza-dev-481500` | URL do console: `console.firebase.google.com/u/1/project/`**`finza-dev-481500`**`/hosting/sites` |
| **Site ID** | `finza-torre-controle` | Seletor "site:" no topo, e prefixo do `.web.app` |

Os 4 sites do projeto `finza-dev`: `finza-backoffice-dev`, `finza-dev-481500` (padrão), `finza-start-dev` e **`finza-torre-controle`** (o nosso).

---

## 5 · `.env` da VM — **não vai para o GitHub**

As Edge Functions leem env do container, não do Actions. O código usa **26** variáveis distintas (`Deno.env.get`).

### Já existem (criadas pelo `bootstrap-supabase.sh`)

| Nome | Serve para |
|---|---|
| `SUPABASE_URL` | 41 usos — base para as EFs chamarem a própria API |
| `SUPABASE_SERVICE_ROLE_KEY` | 39 usos — acesso privilegiado ao banco |
| `SUPABASE_ANON_KEY` | Chave pública |
| `SUPABASE_SECRET_KEYS` | Secret keys aceitas (`sb_secret_…`) — lido só pelo helper `_shared/auth.ts` |
| `JWT_SECRET` | Verificação HS256 no router do edge-runtime |

### Faltam configurar

| Nome | Por que precisa | Como pegar | Valor sugerido p/ DEV | Status |
|---|---|---|---|---|
| `OPENAI_API_KEY` | Agentes de IA | Dashboard Supabase Cloud → Edge Functions → Secrets | copiar do Cloud | `[ ]` |
| `GEMINI_API_KEY` | Idem | Idem | copiar | `[ ]` |
| `LOVABLE_API_KEY` | Idem | Idem | copiar | `[ ]` |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Vertex AI | Idem | copiar | `[ ]` |
| `VERTEX_LOCATION` | Região da Vertex | Idem | copiar | `[ ]` |
| `AI_ASSISTANT_MODEL` | Modelo do assistente | Idem | copiar | `[ ]` |
| `AI_ASSISTANT_MODEL_MESSAGE` | Modelo de mensagem | Idem | copiar | `[ ]` |
| `AI_ASSISTANT_THINKING_LEVEL` | Nível de raciocínio | Idem | copiar | `[ ]` |
| `FINZA_API_URL` | Integração com a plataforma Finza | Branch `refactor/parametrize-urls-pre-cutover` — task **#48** | — | `[ ]` |
| `FINZA_TOKEN` | Idem | Idem — task **#54**, ⚠️ **rotacionar após cutover** | — | `[ ]` |
| `FINZA_API_TOKEN` | Idem (nome distinto no código) | Idem | — | `[ ]` |
| `N8N_EMAIL_WEBHOOK_URL` | Envio de e-mail e anexo de relatório | Dashboard Cloud | copiar | `[ ]` |
| `N8N_EMAIL_WEBHOOK_TOKEN` | Idem | Idem | copiar | `[ ]` |
| `GOOGLE_CHAT_WEBHOOK_URL` | Alertas do health-check | Idem | copiar | `[ ]` |
| `PROJECT_REF` | 4 usos. **Conceito de Supabase Cloud** — não existe project ref numa VM | ⚠️ **decidir** o que significa no self-hosted; pode virar no-op | a decidir | `[ ]` |
| `MANAGEMENT_API_KEY` | 4 usos. Idem — Management API é do Cloud | ⚠️ **decidir** | a decidir | `[ ]` |

### Kill-switches — deixe DESLIGADOS no DEV

Impedem que o ambiente de teste dispare comunicação real.

| Nome | Valor no DEV | Por quê |
|---|---|---|
| `WEEKLY_REPORT_ENABLED` | `false` | Kill-switch global do relatório semanal (ID-3820) |
| `A2A_CLOSURE_DISPATCH_ENABLED` | `false` | Fechamento A2A — os dois crons nascem desligados de propósito |
| `AI_REPORT_REQUIRE_N8N_ACK` | `false` | Exigência de ack do n8n |

### Redirecionamento de teste — deixe LIGADO no DEV

| Nome | Valor no DEV | Por quê |
|---|---|---|
| `TEST_REDIRECT_ENABLED` | `true` | Redireciona todo envio para contato de teste |
| `TEST_REDIRECT_PHONE` | um telefone do time | Destino do redirecionamento |
| `TEST_REDIRECT_EMAIL` | um e-mail do time | Idem |

### Opcionais do router novo

| Nome | Default | Por quê |
|---|---|---|
| `EDGE_MEMORY_LIMIT_MB` | `512` | O router do bootstrap usava 150 MB — apertado para `execute-etl` e relatórios |
| `EDGE_WORKER_TIMEOUT_MS` | `400000` | O padrão era 60 s |

### ❌ Não migrar

| Nome | Por quê |
|---|---|
| `RESEND_API_KEY` | Aparece no doc do sysops mas **não existe no código**. Está sendo removido na task **#13**. |
| `VITE_FIREBASE_*` | A Torre **não usa Firebase** — zero dependência `firebase`, zero import, e **30** chamadas `supabase.auth.*`. Autenticação é Supabase Auth (GoTrue). O passo "Domínios Autorizados do Firebase Authentication" **não se aplica**. |

---

## Como ler o `.env` da VM

```bash
gcloud compute ssh torre-dev-supabase \
  --tunnel-through-iap --zone=us-central1-a \
  --project=finza-torre-de-controle-dev \
  --command='sudo grep -E "^(ANON_KEY|SERVICE_ROLE_KEY|POSTGRES_PASSWORD|JWT_SECRET)=" /opt/supabase/data/project/.env'
```

Para editar (e depois `sudo docker compose restart functions` para as EFs relerem):

```bash
gcloud compute ssh torre-dev-supabase --tunnel-through-iap \
  --zone=us-central1-a --project=finza-torre-de-controle-dev
# na VM:
sudo nano /opt/supabase/data/project/.env
cd /opt/supabase/data/project && sudo docker compose restart functions
```

---

## Referência de infraestrutura (confirmado)

| Item | Valor |
|---|---|
| Projeto GCP da VM | `finza-torre-de-controle-dev` |
| VM | `torre-dev-supabase` · zona `us-central1-a` · `e2-standard-2` |
| Postgres | 17.6 · usuário `postgres.torre-dev` · porta local do túnel **55432** |
| API do Supabase | `https://api.dev.torredecontrole.finza.com.br` |
| Frontend | `https://dev.cobranca.finza.com.br` (Firebase, *Conectado*) e `https://finza-torre-controle.web.app` |
| Projeto Firebase | `finza-dev-481500` (nome `finza-dev`) |
| Site Firebase | `finza-torre-controle` |
| DNS | Cloudflare (`clark.ns` / `bonnie.ns.cloudflare.com`) · CNAME `dev.cobranca` → `finza-torre-controle.web.app`, **DNS only** |

---

## Ordem de desbloqueio

**Frontend ao ar — só depende de você (4 itens):**

1. `[ ]` `FIREBASE_SERVICE_ACCOUNT_DEV` (secret)
2. `[ ]` `SUPABASE_ANON_KEY_DEV` (secret)
3. `[ ]` `FIREBASE_PROJECT_ID` = `finza-dev-481500` (variable)
4. `[ ]` environment `dev`

Opcional no mesmo passo: `APP_BASE_URL_DEV` = `https://dev.cobranca.finza.com.br`.

O job `frontend` roda em paralelo, dependendo só do `validate` — não espera o backend.

**Backend — depende do sysops (1 item):**

5. `[ ]` `WIF_PROVIDER_DEV` + `WIF_SA_DEV`

Sem eles, `migrate`, `functions` e `verify` não rodam.

**Depois disso, no `.env` da VM:** as chaves de IA e integração, os kill-switches em `false` e o redirecionamento de teste em `true`.

> ⚠️ Com o frontend no ar mas as Edge Functions ainda não publicadas, o app **carrega e autentica**, mas qualquer tela que chame EF falha. Isso é progresso real, não é "Torre 100%".

---

## Pendências que não são variável

| Item | Descrição |
|---|---|
| **`.gitignore` da raiz** | `finza-torre-controle-ia/` e `infra-torre-controle/` **não estão ignorados** (só `cobranca-finza/` e `N8N-AGENT/` estão). O git da raiz está vendo os dois; se commitar, o repo da Torre inteiro entra no workspace gerencial. |
| **`baseline-schema-PROD-31717808086/`** | Pasta na raiz com o esquema completo de produção (~3 MB). Não deveria ser commitada no workspace gerencial. |
| **Ledger × CI/CD** | O ledger do DEV tem 1 linha (o baseline). O repo tem 441 migrations, 429 delas ≤ baseline. O `apply-migrations.sh` respeita o piso, então está resolvido — mas um `supabase db push` manual tentaria aplicar as 429. |
| **BTR11** | Router `verify_jwt` gerado (50 EFs · 32 públicas · 18 com JWT). Falta auditar em prod as **16** que rodam abertas e o `config.toml` diz que exigem JWT. |
| **12 EFs zumbis em prod** | Deployadas no Cloud mas removidas do código: `admin-reset-actions`, `ai-config`, `analyze-data`, `campaign-preview`, `daily-sync-orchestrator`, `get-integration-secrets`, `get-portfolio-totals`, `populate-contract-summaries`, `save-integration`, `search-portfolio`, `send-message-v2`, `workflow-orchestrator`. |

---

## Histórico

- **2026-08-17** — Documento criado. Domínio `dev.cobranca.finza.com.br` confirmado *Conectado* com TLS válido (404 esperado, nada publicado). Project ID `finza-dev-481500` e Site ID `finza-torre-controle` confirmados por print do console.
