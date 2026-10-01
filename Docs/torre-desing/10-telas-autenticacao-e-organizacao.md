# 10 · Telas de Autenticação e Organização

> Documento de referência de UX/produto do **frontend ATUAL** da Torre de Controle (SaaS multi-tenant de cobrança da Finza), domínio **telas de entrada e de organização**.
> Objetivo: permitir um **redesenho completo da interface sem perder nenhuma funcionalidade**. Tudo aqui foi extraído por leitura do código-fonte do repositório `cobranca-finza`. Onde o código não permite concluir com certeza, há uma marcação `⚠️ A confirmar:`.
>
> Convenções deste documento:
> - Textos entre aspas duplas (“…”) são **strings literais** que aparecem na tela, copiadas do código.
> - Caminhos `src/...` são relativos à raiz do repositório `cobranca-finza`.
> - “Variante” de botão refere-se ao design system shadcn/ui em uso (`src/components/ui/button.tsx`): `default`, `destructive`, `outline`, `secondary`, `ghost`, `link`; tamanhos `default` (h-10), `sm` (h-9), `lg` (h-11), `icon` (10×10).
> - Ícones citados são do pacote **lucide-react**, salvo indicação contrária.

---

## 0. Resumo do domínio

Quatro telas compõem este domínio. Todas as quatro são **full-screen** — nenhuma delas roda dentro do `AppLayout` (sidebar + topbar do app), que só existe depois de organização selecionada.

| Tela | Rota | Arquivo-fonte | Guard / permissão | Layout |
|---|---|---|---|---|
| Login | `/login` | `src/pages/LoginPage.tsx` | Nenhum (rota pública) | Full-screen, card centralizado `max-w-md` sobre `bg-muted/30` |
| Criar Conta | `/signup` | `src/pages/SignUpPage.tsx` | Nenhum (rota pública) | Full-screen, card centralizado `max-w-md` sobre `bg-muted/30` |
| Aceitar Convite | `/accept-invite?token=<uuid>` | `src/pages/AcceptInvitePage.tsx` | Nenhum guard de rota; o **token** na query string é o gate real | Full-screen, card centralizado `max-w-md` sobre `bg-background` |
| Selecionar Organização | `/select-organization` | `src/pages/SelectOrganizationPage.tsx` | `ProtectedRoute` (exige sessão autenticada). Blocos internos exigem `isSuperAdmin` | Full-screen, container `max-w-6xl` sobre `bg-muted/30`; grid de cards |

Arquivos de apoio (sem rota própria, mas que governam o comportamento das telas acima):

| Arquivo | Papel |
|---|---|
| `src/contexts/AuthContext.tsx` | Sessão Supabase Auth, `signIn`, `signInWithGoogle`, `signUp`, `signOut`, `resetPassword` |
| `src/contexts/OrganizationContext.tsx` | Lista de orgs do usuário, org corrente, papel corrente, **matriz RBAC (`ROLE_PERMISSIONS`)**, `isSuperAdmin`, `orgClient`, perfil de pipeline |
| `src/components/organization/OrgProfileSelector.tsx` | Seletor visual “Tipo de organização” (Cobrança / Formalização), usado no modal de criação de org e na aba de configuração |
| `src/hooks/usePendingInvitations.ts` | Aceite **automático e silencioso** de convites pendentes do e-mail logado |
| `src/hooks/useOrgPipelineProfile.ts` | Rótulos canônicos das opções de perfil (`ORG_PROFILE_CHOICES`) e leitura/escrita do perfil |
| `src/hooks/useConsolidatedStats.ts` | KPIs agregados de todas as orgs (painel do Super Admin) |
| `src/App.tsx` | Guards de rota: `ProtectedRoute`, `RequireOrg`, `RequirePermission`, `RequireDocs`, `PageLoader` |

Guias de negócio já escritos dentro do próprio app (Central de Docs — pilar Negócio), usados aqui como fonte de objetivo/fluxo:

- `src/pages/central-docs/negocio/data/login.ts`
- `src/pages/central-docs/negocio/data/criar-conta.ts`
- `src/pages/central-docs/negocio/data/aceitar-convite.ts`
- `src/pages/central-docs/negocio/data/selecionar-organizacao.ts`

### 0.1 Mapa de navegação entre as telas

```
                 (sem sessão, deep-link preservado em state.from)
qualquer rota  ───────────────────────────────────────────────►  /login
protegida                                                          │
                                                                   │ signIn OK
                                                                   ▼
/signup ◄── link "Criar conta" ── /login ── signInWithGoogle ──►  /  (raiz)
   │                                                   │           │
   │ signUp OK                                         │           │ RequireOrg
   ▼                                          redirectTo:          ▼ (needsOrgSelection)
"Conta criada!" ── "Ir para Login" ──► /login   /select-organization ◄─┘
                                                        │
/accept-invite?token=… ── sucesso (2 s) ──► /login      │ selectOrganization()
                                                        ▼
                                              redirectTo (deep-link) ou "/"
```

### 0.2 Observações estruturais que o redesign precisa respeitar

1. **Deep-link (`state.from`) atravessa três telas.** `ProtectedRoute` guarda a rota original em `location.state.from`; `LoginPage` repassa esse state ao navegar para `/`; `RequireOrg` o preserva ao redirecionar para `/select-organization`; `SelectOrganizationPage` o consome em `redirectTo`. Quebrar essa cadeia faz o usuário que deu F5 em `/etl` cair sempre no dashboard.
2. **Duas imagens de logo diferentes** são usadas no domínio: `@/assets/logo-torre-controle.png` (Login, SignUp, SelectOrganization) e `@/assets/torre-controle-logo.png` (AcceptInvite). São arquivos distintos no repositório. ⚠️ A confirmar: se a divergência é intencional ou resíduo — o redesign deveria unificar.
3. **Existe `resetPassword` no `AuthContext`** (`supabase.auth.resetPasswordForEmail`, com `redirectTo: <origin>/reset-password`), mas **não há rota `/reset-password` registrada em `App.tsx` nem nenhum botão “Esqueci minha senha” em nenhuma das telas**. É funcionalidade morta no frontend — oportunidade de redesign (ver §2.11).
4. **Toasts são globais e limitados a 1 por vez** (`TOAST_LIMIT = 1` em `src/hooks/useToast.ts`), com remoção após `TOAST_REMOVE_DELAY = 3000` ms. Toast novo **descarta** o anterior.

---

## 1. Matriz RBAC (5 papéis × permissões)

**Arquivo-fonte:** `src/contexts/OrganizationContext.tsx` (constante `ROLE_PERMISSIONS`, linhas 71–144).

### 1.1 Os cinco papéis

Tipo: `type UserRole = "owner" | "admin" | "manager" | "operator" | "viewer"`.

Hierarquia declarada no `CLAUDE.md` do projeto: `owner > admin > manager > operator > viewer`. Na prática **não há herança automática** — cada papel tem uma lista literal, exceto `owner`, que recebe o curinga `["*"]`.

| `role` (valor técnico) | Rótulo PT-BR na UI | Cor do selo (classe) | Nº de permissões |
|---|---|---|---|
| `owner` | Proprietário | `bg-amber-100 text-amber-800` | Todas (curinga `*`) |
| `admin` | Administrador | `bg-blue-100 text-blue-800` | 44 |
| `manager` | Gerente | `bg-green-100 text-green-800` | 33 |
| `operator` | Operador | `bg-gray-100 text-gray-800` | 19 |
| `viewer` | Visualizador | `bg-gray-100 text-gray-600` | 11 |

Os rótulos e cores vivem em `ROLE_LABELS` dentro de `src/pages/SelectOrganizationPage.tsx` (linhas 57–81) — **não** no contexto. Papel desconhecido cai no fallback `ROLE_LABELS.viewer`.

### 1.2 Função de verificação

```ts
hasPermission(permission: string): boolean
// 1. currentRole ausente  -> false
// 2. ROLE_PERMISSIONS[currentRole] contém "*" -> true
// 3. senão -> includes(permission) exato, sem wildcard parcial
```

Consequência para o redesign: **não existe `campaigns:*`**. O casamento é string exata.

### 1.3 Matriz completa (47 permissões × 5 papéis)

Legenda: `✔` = concedida; `—` = negada; `(*)` = concedida apenas pelo curinga do `owner`.

| Permissão | owner | admin | manager | operator | viewer |
|---|:---:|:---:|:---:|:---:|:---:|
| `contacts:read` | ✔ (*) | ✔ | ✔ | ✔ | ✔ |
| `contacts:write` | ✔ (*) | ✔ | ✔ | — | — |
| `contacts:delete` | ✔ (*) | ✔ | — | — | — |
| `contracts:read` | ✔ (*) | ✔ | ✔ | ✔ | ✔ |
| `contracts:write` | ✔ (*) | ✔ | ✔ | — | — |
| `contracts:delete` | ✔ (*) | ✔ | — | — | — |
| `campaigns:read` | ✔ (*) | ✔ | ✔ | ✔ | ✔ |
| `campaigns:write` | ✔ (*) | ✔ | ✔ | ✔ | — |
| `campaigns:delete` | ✔ (*) | ✔ | — | — | — |
| `workflows:read` | ✔ (*) | ✔ | ✔ | ✔ | ✔ |
| `workflows:write` | ✔ (*) | ✔ | ✔ | — | — |
| `workflows:delete` | ✔ (*) | ✔ | — | — | — |
| `filters:read` | ✔ (*) | ✔ | ✔ | ✔ | — |
| `filters:write` | ✔ (*) | ✔ | ✔ | ✔ | — |
| `filters:delete` | ✔ (*) | ✔ | — | — | — |
| `actions:read` | ✔ (*) | ✔ | ✔ | ✔ | ✔ |
| `actions:write` | ✔ (*) | ✔ | ✔ | ✔ | — |
| `actions:override_blocklist` | ✔ (*) | ✔ | — | — | — |
| `disparos:write` | ✔ (*) | ✔ | ✔ | ✔ | — |
| `disparos:override_blocklist` | ✔ (*) | ✔ | — | — | — |
| `integrations:read` | ✔ (*) | ✔ | ✔ | — | — |
| `integrations:write` | ✔ (*) | ✔ | ✔ | — | — |
| `etl:read` | ✔ (*) | ✔ | ✔ | — | — |
| `etl:write` | ✔ (*) | ✔ | ✔ | — | — |
| `etl:delete` | ✔ (*) | ✔ | — | — | — |
| `users:read` | ✔ (*) | ✔ | ✔ | — | — |
| `users:invite` | ✔ (*) | ✔ | ✔ | — | — |
| `settings:read` | ✔ (*) | ✔ | ✔ | — | — |
| `settings:write` | ✔ (*) | ✔ | — | — | — |
| `reports:read` | ✔ (*) | ✔ | ✔ | ✔ | ✔ |
| `reports:export` | ✔ (*) | ✔ | ✔ | — | — |
| `templates:read` | ✔ (*) | ✔ | ✔ | ✔ | ✔ |
| `templates:write` | ✔ (*) | ✔ | ✔ | ✔ | — |
| `templates:delete` | ✔ (*) | ✔ | ✔ | — | — |
| `agent-ia:read` | ✔ (*) | ✔ | ✔ | — | — |
| `agent-ia:write` | ✔ (*) | ✔ | — | — | — |
| `broadcasts:read` | ✔ (*) | ✔ | ✔ | ✔ | ✔ |
| `broadcasts:write` | ✔ (*) | ✔ | ✔ | — | — |
| `broadcasts:delete` | ✔ (*) | ✔ | — | — | — |
| `seals:read` | ✔ (*) | ✔ | ✔ | ✔ | ✔ |
| `seals:apply` | ✔ (*) | ✔ | ✔ | ✔ | — |
| `seals:manage_catalog` | ✔ (*) | ✔ | ✔ | ✔ | — |
| `docs:negocio` | ✔ (*) | ✔ | ✔ | ✔ | ✔ |
| `docs:changelog` | ✔ (*) | ✔ | ✔ | ✔ | ✔ |
| `docs:servico` | ✔ (*) | — | — | — | — |
| `docs:tecnica` | ✔ (*) | — | — | — | — |
| `docs:topicos` | ✔ (*) | — | — | — | — |

### 1.4 Notas de leitura da matriz

1. **`docs:servico`, `docs:tecnica` e `docs:topicos` não aparecem em nenhuma lista de `ROLE_PERMISSIONS`.** São consumidas em rotas e componentes (`src/App.tsx`, `src/pages/CentralDocsPage.tsx`, `src/pages/central-docs/...`), portanto só passam por duas vias: papel `owner` (curinga `*`) ou **`isSuperAdmin`** via o guard `RequireDocs`, que é god-mode (`!isSuperAdmin && !hasPermission(permission)` → redireciona para `/central-docs`). O comentário no próprio código declara isso: admin/manager/operator/viewer veem apenas Negócio + Novidades.
2. **`seals:manage_catalog` é concedida até para `operator`** — mais permissiva do que a curva geral das outras `:manage`/`:delete`. ⚠️ A confirmar: se é intencional.
3. **`operator` tem `campaigns:write` mas não `workflows:write`** — pode criar/editar campanha, mas não editar a régua que ela executa.
4. **`viewer` não tem `filters:read`**, embora tenha `campaigns:read` e `workflows:read`. Efeito colateral visível: telas que dependem de filtro ficam parcialmente vazias para o visualizador.
5. **`manager` tem `settings:read` mas não `settings:write`** — vê Configurações em modo leitura.
6. **RBAC é frontend-only.** O `CLAUDE.md` do projeto afirma isso explicitamente (“RBAC (Frontend-Only)”). A matriz **esconde e bloqueia UI**; a barreira real de dados é RLS/policies no Supabase. Para o redesign isso significa: **não presuma que esconder o botão é a proteção**, mas **sim** que esconder o botão é a UX esperada.
7. **`isSuperAdmin` é ortogonal aos 5 papéis.** Vem da RPC `is_super_admin(user_id)` (tabela `public.super_admins`), não de `organization_users.role`. Default é `false` até a RPC responder. Um super admin pode ter papel baixo em uma org e ainda assim ver os blocos de administração da tela de seleção de organização.
8. **Nenhuma das quatro telas deste domínio usa `hasPermission()`.** Login, SignUp e AcceptInvite são pré-organização (não há `currentRole`); SelectOrganization usa exclusivamente o booleano `isSuperAdmin`. A matriz RBAC está documentada aqui porque **vive** neste domínio (`OrganizationContext`) e porque é o contrato que o resto do app consome.

---

## 2. Login

### 2.1 Identidade

| Item | Valor |
|---|---|
| Rota | `/login` |
| Arquivo | `src/pages/LoginPage.tsx` |
| Export | `export function LoginPage()` (named export) |
| Registro da rota | `src/App.tsx`, linha 178: `<Route path="/login" element={<LoginPage />} />` |
| Guard | **Nenhum.** Rota pública, fora de `ProtectedRoute` e de `RequireOrg` |
| Layout | **Full-screen**, fora do `AppLayout`. Sem sidebar, sem topbar, sem breadcrumb |
| Contextos consumidos | `useAuth()` → `signIn`, `signInWithGoogle` |
| Bibliotecas de formulário | `react-hook-form` + `zodResolver` + `zod` |

Container raiz:

```
<div className="flex min-h-screen items-center justify-center bg-muted/30 p-4">
  <Card className="w-full max-w-md"> … </Card>
</div>
```

Ou seja: fundo `muted/30` ocupando a viewport inteira, card branco (token `--card`) centralizado vertical e horizontalmente, largura máxima 28rem (`max-w-md`), padding externo de 16px (`p-4`) para respiro em telas pequenas.

### 2.2 Objetivo e persona

**Objetivo (conforme o guia de negócio `login.ts`):** “A porta de entrada da Torre. É onde você se identifica com e-mail e senha (ou com a conta Google) para acessar o sistema. Sem passar por aqui, nenhuma outra tela fica disponível.”

**Persona:** qualquer pessoa da operação de cobrança — do operador que entra todo dia às 8h ao super admin da Finza. A tela **não** distingue perfis: o papel só é resolvido depois, ao escolher a organização.

**Modelo mental declarado no guia:** “Pense no Login como a recepção do prédio: você se apresenta (e-mail e senha) e, confirmada a identidade, recebe a chave para circular.”

**Permissões:** `["pública"]` (declarado no guia). Qualquer pessoa pode abrir; só entra quem já tem conta.

### 2.3 Anatomia visual

Ordem vertical dentro do `Card` (todos os elementos são centralizados no header e full-width no corpo):

1. **`CardHeader`** com `className="text-center"`:
   1. **Logo** — `<img src={logo-torre-controle.png} alt="Torre de Controle" className="h-16 w-auto mx-auto" />`, dentro de um wrapper `mx-auto mb-4`. Altura fixa de 64px, largura automática.
   2. **`CardTitle`** — texto “Torre de Controle”, classe `text-2xl`.
   3. **`CardDescription`** — “Entre com suas credenciais para acessar o sistema”.
2. **`CardContent`**:
   1. **Banner de erro** (condicional) — `div` com `rounded-md bg-destructive/10 p-3 text-sm text-destructive`. Renderiza a mensagem de erro crua devolvida pelo Supabase. Aparece **acima** dos campos, dentro do `<form>`.
   2. **Campo E-mail** (bloco `space-y-2`: Label + Input + erro inline).
   3. **Campo Senha** (mesmo padrão).
   4. **Botão “Entrar”** — full-width, variante `default`, `type="submit"`.
   5. **Divisor “OU”** — `Separator` horizontal com um rótulo sobreposto centralizado: `<span className="bg-card px-2 text-muted-foreground">ou</span>`, dentro de um container `text-xs uppercase`. Visualmente aparece como **“OU”** por causa do `uppercase`; a string literal no código é `ou`. Margem vertical `my-4`.
   6. **Botão “Continuar com Google”** — full-width, variante `outline`, com ícone SVG do Google inline.
   7. **Rodapé de troca de tela** — `text-center text-sm mt-4`: `<span>` “Não tem uma conta? ” (cor `muted-foreground`) + `<Link to="/signup">` “Criar conta” (cor `primary`, `hover:underline`, `font-medium`).

Proporções: formulário com `space-y-4` entre blocos; cada bloco de campo com `space-y-2` entre label, input e mensagem de erro. O card não tem `CardFooter`.

### 2.4 Campos e inputs

Schema de validação (`zod`), definido nas linhas 37–40:

```ts
const loginSchema = z.object({
  email: z.string().email("Email inválido"),
  password: z.string().min(6, "A senha deve ter pelo menos 6 caracteres"),
});
```

| # | Label exato | `id` / `name` | Tipo de input | Placeholder | Obrigatório | Validação | Valor default | Mensagem de erro |
|---|---|---|---|---|---|---|---|---|
| 1 | `E-mail` | `email` | `<Input type="email">` | `seu@email.com` | Sim (implícito: `z.string().email()` rejeita vazio) | Formato de e-mail válido | vazio | “Email inválido” |
| 2 | `Senha` | `password` | `<Input type="password">` | `••••••••` (8 caracteres bullet U+2022) | Sim | Mínimo 6 caracteres | vazio | “A senha deve ter pelo menos 6 caracteres” |

Notas:
- Não há `autoComplete`, `autoFocus`, `inputMode` nem `required` HTML declarados. A validação é 100% client-side via `zodResolver`, disparada no submit (modo padrão do react-hook-form: `onSubmit`, revalidação `onChange` após o primeiro erro).
- Não há botão de “mostrar senha” (olho).
- Não há campo “Lembrar-me”.
- A mensagem de erro de campo é um `<p className="text-sm text-destructive">` renderizado **abaixo** do input, dentro do mesmo bloco `space-y-2`.

### 2.5 Botões e ações

| Label exato | Variante / tamanho | Ícone | `type` | Ação | Disabled quando | Confirmação |
|---|---|---|---|---|---|---|
| `Entrar` (→ `Entrando...` em loading) | `default`, `w-full` | — | `submit` | `handleSubmit(onSubmit)` → `signIn(email, password)` → em sucesso `navigate("/", { state: { from } })` | `isLoading \|\| isGoogleLoading` | Não |
| `Continuar com Google` (→ `Conectando...` em loading) | `outline`, `w-full` | SVG inline do Google (componente local `GoogleIcon`, **não** é lucide), `className="mr-2 h-4 w-4"`, 4 paths com `fill="currentColor"` | `button` | `signInWithGoogle()` → `supabase.auth.signInWithOAuth({ provider: "google", options: { redirectTo: <origin>/select-organization } })` | `isLoading \|\| isGoogleLoading` | Não |
| `Criar conta` | Link de texto (`<Link>` do react-router), classe `text-primary hover:underline font-medium` | — | — | Navega para `/signup` | Nunca | Não |

Detalhe do OAuth (`src/contexts/AuthContext.tsx`, linhas 59–79): há uma **whitelist de origens** para o `redirectTo`:

```
https://cobranca-finza.lovable.app
https://id-preview--3c31f868-b0d6-43c2-8e9f-64cda77a9cdc.lovable.app
http://localhost:8080
```

Se `window.location.origin` não estiver na lista, o fallback é a primeira entrada (produção Lovable). O destino sempre é `<origin>/select-organization` — **o Google pula a raiz e vai direto para a seleção de organização**, ao contrário do login por senha, que passa por `/`.

### 2.6 Modais, sheets e popovers

**Nenhum.** A tela de Login não abre nenhum `Dialog`, `AlertDialog`, `Sheet`, `Popover`, `DropdownMenu` ou `Tooltip`. Todo feedback é inline (banner de erro + mensagens de campo) — inclusive não há toast nesta tela (o `useToast` não é importado).

### 2.7 Estados da tela

| Estado | Como é disparado | O que o usuário vê |
|---|---|---|
| **Inicial (idle)** | Carga da rota | Card completo, campos vazios, ambos os botões habilitados |
| **Loading — credenciais** | `isLoading = true` após submit | Botão primário com texto “Entrando...” e desabilitado; botão Google também desabilitado. **Não há spinner** — só troca de texto |
| **Loading — Google** | `isGoogleLoading = true` | Botão Google com texto “Conectando...”; ambos os botões desabilitados. Ícone do Google permanece visível |
| **Erro de autenticação** | `signIn` retorna `error` | Banner vermelho no topo do formulário com `error.message` **cru do Supabase** (em inglês, ex.: “Invalid login credentials”). `isLoading` volta a `false`, campos permanecem preenchidos |
| **Erro de validação** | Zod reprova | Mensagem vermelha abaixo do campo; **nenhuma** chamada de rede é feita |
| **Erro no OAuth** | `signInWithGoogle` retorna `error` | Mesmo banner vermelho; `isGoogleLoading` volta a `false` |
| **Sucesso** | `signIn` sem erro | Navegação imediata para `/`. Não há tela de sucesso nem toast |
| **Vazio** | Não aplicável | — |
| **Sem permissão** | Não aplicável (rota pública) | — |

Observação importante: **a tela não detecta sessão já ativa.** Um usuário logado que digitar `/login` verá o formulário normalmente — não há `<Navigate>` de saída. ⚠️ A confirmar se isso é desejado no redesign.

### 2.8 Mensagens, validações e toasts (texto real)

Mensagens de validação (Zod, PT-BR):
- `Email inválido`
- `A senha deve ter pelo menos 6 caracteres`

Textos de estado dos botões:
- `Entrando...`
- `Conectando...`

Textos fixos:
- Título: `Torre de Controle`
- Subtítulo: `Entre com suas credenciais para acessar o sistema`
- Divisor: `ou` (renderizado em maiúsculas por CSS)
- Rodapé: `Não tem uma conta? ` + `Criar conta`
- Placeholders: `seu@email.com`, `••••••••`
- Alt da imagem: `Torre de Controle`

Erros de servidor: **não traduzidos**. A tela exibe `error.message` como veio do `supabase-js`. O guia de negócio confirma: “uma faixa vermelha aparece no topo do formulário com a mensagem do erro”.

**Toasts:** nenhum.

### 2.9 Fluxos de uso passo a passo

**Fluxo A — login por senha, caminho feliz**
1. Usuário abre `/login` (diretamente ou redirecionado por `ProtectedRoute`).
2. Preenche “E-mail” e “Senha”.
3. Clica em “Entrar” (ou pressiona Enter dentro do form — submit nativo).
4. Zod valida. Ambos os botões ficam desabilitados; o primário mostra “Entrando...”.
5. `supabase.auth.signInWithPassword` responde sem erro.
6. A tela navega para `/`, repassando `state.from` se ele existir.
7. Em `/`, o `RequireOrg` avalia: se há orgs e nenhuma selecionada, redireciona para `/select-organization` preservando o `from`.

**Fluxo B — login por senha, credencial errada**
1. Passos 1–4 iguais.
2. O Supabase devolve erro. `setError(error.message)`; `setIsLoading(false)`.
3. Banner vermelho aparece no topo do formulário com a mensagem (em inglês).
4. Campos permanecem preenchidos; usuário corrige e repete.

**Fluxo C — validação local reprova**
1. Usuário digita e-mail sem “@” ou senha com 3 caracteres.
2. Clica em “Entrar”.
3. Nada é enviado. Mensagens em PT-BR aparecem sob os campos reprovados.

**Fluxo D — Google OAuth**
1. Usuário clica em “Continuar com Google”.
2. Botão passa a “Conectando...”; ambos desabilitados.
3. O navegador é redirecionado para a tela de consentimento do Google.
4. Autorizado, o Google devolve o usuário para `<origin>/select-organization`.
5. Se a origem atual não estiver na whitelist, o retorno é para `https://cobranca-finza.lovable.app/select-organization` — **o usuário troca de domínio**.
6. Em caso de falha antes do redirecionamento, a tela volta a idle com banner de erro.

**Fluxo E — deep-link preservado**
1. Usuário com sessão expirada dá F5 em `/etl`.
2. `ProtectedRoute` redireciona para `/login` com `state={{ from: location }}`.
3. Login bem-sucedido → `navigate("/", { state: { from } })`.
4. `RequireOrg` detecta `needsOrgSelection` e manda para `/select-organization` com o mesmo `from`.
5. Ao escolher a org, `SelectOrganizationPage` navega para `/etl`.

**Fluxo F — usuário sem conta**
1. Clica em “Criar conta” no rodapé.
2. Vai para `/signup` (§3).

### 2.10 Responsividade e acessibilidade observadas

Responsividade:
- Card `w-full max-w-md` com `p-4` no container: em telas estreitas, o card ocupa a largura disponível menos 32px.
- `min-h-screen` + `items-center justify-center`: em telas muito baixas (landscape de celular), o card pode **transbordar sem scroll confortável** — o container não tem `overflow-auto` nem `py-8`. ⚠️ A confirmar em teste real.
- Nenhum breakpoint específico (`sm:`, `md:`, `lg:`) é usado nesta tela.

Acessibilidade:
- Cada `Label` tem `htmlFor` correspondente ao `id` do input — associação correta.
- A imagem tem `alt="Torre de Controle"`.
- O banner de erro **não** tem `role="alert"` nem `aria-live`. Leitores de tela não anunciam a falha de login.
- As mensagens de erro de campo **não** têm `id` referenciado por `aria-describedby`, nem os inputs recebem `aria-invalid`.
- O SVG do Google **não** tem `aria-hidden="true"` nem `<title>` — pode ser lido como conteúdo gráfico sem rótulo.
- Estado de loading é comunicado apenas por texto no botão (“Entrando...”), sem `aria-busy`.
- Ordem de foco: e-mail → senha → Entrar → Continuar com Google → Criar conta. Lógica e correta.
- Contraste: texto `destructive` sobre `destructive/10` — ⚠️ A confirmar contraste contra WCAG AA nos tokens atuais.

### 2.11 Dores e oportunidades para o redesign

1. **Não existe “Esqueci minha senha”.** O `AuthContext` expõe `resetPassword`, mas nenhuma tela chama, e a rota `/reset-password` (destino do e-mail de recuperação) **não existe em `App.tsx`**. Usuário que esquece a senha fica sem caminho de autosserviço — o guia de negócio chega a sugerir “peça ajuda a um administrador”. É a maior lacuna funcional do domínio.
2. **Erros do backend em inglês.** “Invalid login credentials”, “Email not confirmed” etc. aparecem crus. Um dicionário de tradução por código/mensagem resolveria.
3. **Loading sem spinner.** Login e SignUp comunicam carregamento só por texto; AcceptInvite usa `Loader2` animado. Inconsistência visível dentro do mesmo domínio.
4. **Sem indicação de “e-mail não confirmado”.** Quem se cadastrou e não confirmou recebe apenas a mensagem crua do Supabase, sem ação de reenvio.
5. **Sem toggle de visibilidade da senha.**
6. **Sem feedback de caps lock / teclado.**
7. **O banner de erro empurra o formulário para baixo** (não é overlay), deslocando os campos entre tentativas.
8. **Sessão ativa não é detectada:** quem já está logado vê o formulário de login.
9. **`redirectTo` do Google ignora o deep-link.** O login por senha preserva `state.from`; o Google força `/select-organization` e **perde** a rota original — assimetria entre os dois caminhos.
10. **Whitelist de origens hardcoded no frontend** com URLs de preview do Lovable. Ambiente novo (ex.: domínio próprio) cai no fallback de produção sem aviso.
11. **Sem variação de marca por organização.** O logo é sempre o da Torre; como a plataforma é multi-tenant com `primary_color` e `logo_url` por org, há espaço para white-label na entrada (hoje impossível: antes do login não se sabe a org).

---

## 3. Criar Conta

### 3.1 Identidade

| Item | Valor |
|---|---|
| Rota | `/signup` |
| Arquivo | `src/pages/SignUpPage.tsx` |
| Export | `export function SignUpPage()` (named export) |
| Registro da rota | `src/App.tsx`, linha 179 |
| Guard | **Nenhum.** Rota pública |
| Layout | **Full-screen**, card centralizado `max-w-md` sobre `bg-muted/30` — idêntico ao Login |
| Contextos consumidos | `useAuth()` → `signUp`, `signInWithGoogle` |
| Formulário | `react-hook-form` + `zodResolver` |

### 3.2 Objetivo e persona

**Objetivo (guia `criar-conta.ts`):** “A tela de cadastro de uma nova conta na Torre. Você informa nome, e-mail e senha; ao confirmar, recebe um e-mail de verificação e, depois de confirmado, já pode fazer login.”

**Persona:** pessoa que ainda não tem identidade na plataforma e chegou por conta própria (não por convite). O guia é explícito: “Quem já recebeu um convite normalmente não precisa passar por aqui: o link do convite já cria a conta e dá acesso de uma vez.”

**Ponto crítico de produto documentado no guia:** “Ter conta não significa, sozinho, ter acesso a dados de cobrança — isso depende de você fazer parte de alguma organização.” Ou seja, o cadastro entrega uma conta **órfã**, que cairá no estado vazio da tela de seleção de organização (§5.7).

**Permissões:** `["pública"]`.

### 3.3 Anatomia visual

A tela tem **dois layouts mutuamente exclusivos**, controlados pelo state booleano `success`.

#### 3.3.1 Layout padrão (formulário) — `success === false`

Mesma casca do Login. Ordem:

1. **`CardHeader`** `text-center`:
   1. Logo `logo-torre-controle.png`, `h-16 w-auto mx-auto`, wrapper `mx-auto mb-4`.
   2. `CardTitle` `text-2xl` — “Criar Conta”.
   3. `CardDescription` — “Crie sua conta para acessar o Torre de Controle”.
2. **`CardContent`**:
   1. Banner de erro condicional (mesmo estilo do Login: `rounded-md bg-destructive/10 p-3 text-sm text-destructive`).
   2. Campo “Nome Completo”.
   3. Campo “E-mail”.
   4. Campo “Senha”.
   5. Campo “Confirmar Senha”.
   6. Botão “Criar Conta” (full-width, `default`, submit).
   7. Divisor “ou” (`Separator` + rótulo `uppercase` sobre `bg-card`), `my-4`.
   8. Botão “Continuar com Google” (full-width, `outline`, ícone SVG local).
   9. Rodapé: “Já tem uma conta? ” + link “Fazer login” → `/login`.

#### 3.3.2 Layout de sucesso — `success === true`

O formulário inteiro **desaparece** e é substituído por um card menor:

1. **`CardHeader`** `text-center`:
   1. Mesmo logo, mesmas dimensões.
   2. `CardTitle` `text-2xl text-primary` — “Conta criada!” (note: título colorido com a cor primária, único caso do domínio).
   3. `CardDescription` — “Verifique seu email para confirmar a conta e depois faça login.”
2. **`CardContent`** `text-center`:
   1. Botão único “Ir para Login”, full-width, variante `default`.

Não há ícone de sucesso (diferente do AcceptInvite, que usa `CheckCircle`).

### 3.4 Campos e inputs

Schema (`signUpSchema`, linhas 37–45):

```ts
z.object({
  fullName: z.string().min(2, "Nome deve ter pelo menos 2 caracteres"),
  email: z.string().email("Email inválido"),
  password: z.string().min(6, "A senha deve ter pelo menos 6 caracteres"),
  confirmPassword: z.string(),
}).refine(d => d.password === d.confirmPassword, {
  message: "As senhas não coincidem",
  path: ["confirmPassword"],
})
```

| # | Label exato | `id` / `name` | Tipo | Placeholder | Obrigatório | Validação | Default | Mensagem de erro |
|---|---|---|---|---|---|---|---|---|
| 1 | `Nome Completo` | `fullName` | `text` | `Seu nome completo` | Sim | Mínimo 2 caracteres | vazio | “Nome deve ter pelo menos 2 caracteres” |
| 2 | `E-mail` | `email` | `email` | `seu@email.com` | Sim | Formato de e-mail | vazio | “Email inválido” |
| 3 | `Senha` | `password` | `password` | `Mínimo 6 caracteres` | Sim | Mínimo 6 caracteres | vazio | “A senha deve ter pelo menos 6 caracteres” |
| 4 | `Confirmar Senha` | `confirmPassword` | `password` | `Digite a senha novamente` | Sim | Igual a `password` (refine no schema) | vazio | “As senhas não coincidem” (exibida sob o campo 4) |

Notas:
- **O placeholder da senha é diferente do Login**: aqui é o texto-guia `Mínimo 6 caracteres`; no Login é `••••••••`.
- Não há medidor de força de senha, nem regra de complexidade (maiúscula/número/símbolo). Seis caracteres quaisquer bastam.
- `fullName` é enviado ao Supabase como metadata: `signUp(email, password, { full_name: data.fullName })` → `options.data.full_name`.
- Não há aceite de termos de uso / política de privacidade. ⚠️ A confirmar se há exigência legal para a Finza.
- Não há campo de telefone, cargo ou organização.

### 3.5 Botões e ações

| Label exato | Variante | Ícone | `type` | Ação | Disabled quando | Confirmação |
|---|---|---|---|---|---|---|
| `Criar Conta` (→ `Criando conta...`) | `default`, `w-full` | — | `submit` | `signUp(email, password, { full_name })`; em sucesso `setSuccess(true)` | `isLoading \|\| isGoogleLoading` | Não |
| `Continuar com Google` (→ `Conectando...`) | `outline`, `w-full` | `GoogleIcon` local (SVG), `mr-2 h-4 w-4` | `button` | `signInWithGoogle()` — **exatamente a mesma função do Login**, redirecionando para `<origin>/select-organization` | `isLoading \|\| isGoogleLoading` | Não |
| `Fazer login` | Link (`text-primary hover:underline font-medium`) | — | — | `/login` | Nunca | Não |
| `Ir para Login` (só na tela de sucesso) | `default`, `w-full` | — | `button` | `navigate("/login")` | Nunca | Não |

Observação de produto: o botão Google nesta tela **não cria conta separadamente** — é o mesmo fluxo OAuth do login. O Supabase cria a conta na primeira autorização. Portanto “Criar conta com Google” e “Entrar com Google” são a mesma coisa; o label diverge só pelo contexto da tela (“Continuar com Google” em ambas — ok).

### 3.6 Modais, sheets e popovers

**Nenhum.** O “sucesso” não é um modal: é uma **troca completa de tela** (early return no componente). Isso importa para o redesign: não há como voltar ao formulário depois do sucesso sem recarregar a página.

### 3.7 Estados da tela

| Estado | Disparo | O que o usuário vê |
|---|---|---|
| **Idle** | Carga | Formulário com 4 campos vazios |
| **Loading — cadastro** | `isLoading = true` | Botão primário “Criando conta...” e desabilitado; Google desabilitado |
| **Loading — Google** | `isGoogleLoading = true` | Botão Google “Conectando...”; ambos desabilitados |
| **Erro — e-mail já cadastrado** | `error.message.includes("already registered")` | Banner vermelho com o texto **traduzido**: “Este email já está cadastrado. Faça login ou use outro email.” |
| **Erro — outros** | qualquer outro erro | Banner vermelho com `error.message` cru (inglês) |
| **Erro de validação** | Zod reprova | Mensagens PT-BR sob os campos; nenhuma chamada de rede |
| **Sucesso** | `signUp` sem erro | Tela inteira substituída pelo card “Conta criada!” |
| **Vazio / sem permissão** | Não aplicável | — |

### 3.8 Mensagens, validações e toasts (texto real)

Validação:
- `Nome deve ter pelo menos 2 caracteres`
- `Email inválido`
- `A senha deve ter pelo menos 6 caracteres`
- `As senhas não coincidem`

Erro tratado:
- `Este email já está cadastrado. Faça login ou use outro email.`

Estados de botão:
- `Criando conta...`
- `Conectando...`

Textos fixos:
- `Criar Conta` (título e botão)
- `Crie sua conta para acessar o Torre de Controle` (note a concordância: “o Torre de Controle”)
- `ou`
- `Já tem uma conta? ` + `Fazer login`
- `Conta criada!`
- `Verifique seu email para confirmar a conta e depois faça login.`
- `Ir para Login`

**Toasts:** nenhum.

Alerta do guia de negócio (bloco `warning`): “Você precisa abrir o e-mail enviado e confirmar a conta. Só depois disso o login funciona. Não recebeu? Verifique a caixa de spam e o endereço que digitou.” — **esse texto está no guia, não na tela.** A tela só diz “Verifique seu email...”. Oportunidade de redesign: trazer a orientação de spam/reenvio para a própria tela de sucesso.

### 3.9 Fluxos de uso passo a passo

**Fluxo A — cadastro comum, caminho feliz**
1. Usuário abre `/signup` (link do Login ou URL direta).
2. Preenche Nome Completo, E-mail, Senha e Confirmar Senha.
3. Clica em “Criar Conta”.
4. Zod valida os 4 campos e a igualdade das senhas.
5. Botões desabilitam; o primário mostra “Criando conta...”.
6. `supabase.auth.signUp` responde sem erro.
7. A tela troca para o card “Conta criada!”.
8. Usuário abre o e-mail, confirma, volta e clica em “Ir para Login”.
9. Faz login em `/login` → cai na seleção de organização.
10. Como ainda não pertence a nenhuma org, vê o estado vazio “Você ainda não faz parte de nenhuma organização” (§5.7).

**Fluxo B — e-mail já cadastrado**
1. Passos 1–5 iguais.
2. O Supabase devolve erro contendo “already registered”.
3. Banner traduzido aparece: “Este email já está cadastrado. Faça login ou use outro email.”
4. `isLoading` volta a `false`; os campos permanecem preenchidos (inclusive as senhas).
5. Usuário clica em “Fazer login”.

**Fluxo C — senhas divergentes**
1. Usuário digita senhas diferentes e submete.
2. “As senhas não coincidem” aparece sob “Confirmar Senha”.
3. Nada é enviado.

**Fluxo D — Google**
1. Clica em “Continuar com Google”, mesmo comportamento do Login (Fluxo D de §2.9).
2. Retorna direto para `/select-organization` — **sem passar pela tela “Conta criada!”** e **sem exigir confirmação de e-mail**.

**Fluxo E — erro genérico**
1. Falha de rede ou erro do Supabase não reconhecido.
2. Banner com a mensagem crua. Usuário repete.

### 3.10 Responsividade e acessibilidade observadas

- Mesma casca do Login: `max-w-md`, `p-4`, `min-h-screen`. Com 4 campos + 2 botões + rodapé, o card fica **mais alto** que o do Login — em viewports curtas o risco de corte é maior (mesma ressalva de overflow do §2.10).
- Labels associados por `htmlFor`/`id` — correto.
- `alt` da imagem presente.
- Sem `role="alert"` / `aria-live` no banner de erro.
- Sem `aria-invalid` / `aria-describedby` nos campos.
- Sem `autoComplete` (o ideal seria `name`, `email`, `new-password`, `new-password`) — impede o gerenciador de senhas de sugerir senha forte.
- Sem `aria-busy` nos botões em loading.
- Tela de sucesso não move o foco para o novo conteúdo nem anuncia a mudança — leitor de tela pode não perceber que o formulário sumiu.

### 3.11 Dores e oportunidades para o redesign

1. **Só um dos erros do backend é traduzido.** O tratamento é por `includes("already registered")` — frágil (quebra se o Supabase mudar a string ou usar outro idioma).
2. **Regra de senha fraca e sem feedback.** 6 caracteres, sem medidor, sem exigência de complexidade, sem `autoComplete="new-password"`.
3. **Tela de sucesso é um beco:** não há reenvio de e-mail de confirmação, não há “abrir meu e-mail”, não há contador. Se o e-mail não chegar, o usuário não tem ação.
4. **Confirmação de e-mail é assimétrica entre caminhos.** Cadastro comum exige confirmação; convite (§4) auto-confirma via Edge Function; Google não exige. Três experiências diferentes para o mesmo objetivo.
5. **Conta órfã é o desfecho padrão.** O cadastro por conta própria quase sempre termina em “Você ainda não faz parte de nenhuma organização”. Falta um caminho de “solicitar acesso” — hoje o texto apenas manda aguardar convite.
6. **Sem aceite de termos/privacidade.**
7. **Sem indicação de qual e-mail usar** (corporativo vs pessoal), embora o convite seja nominal por e-mail.
8. Duplicação de código com o Login: o componente `GoogleIcon` está **copiado integralmente** nos dois arquivos (`LoginPage.tsx` e `SignUpPage.tsx`, linhas 14–35 em ambos). O redesign deveria extrair um componente compartilhado.

---

## 4. Aceitar Convite

### 4.1 Identidade

| Item | Valor |
|---|---|
| Rota | `/accept-invite` (parâmetro obrigatório `?token=<uuid>`) |
| Arquivo | `src/pages/AcceptInvitePage.tsx` |
| Export | `export default function AcceptInvitePage()` (default export) |
| Registro da rota | `src/App.tsx`, linha 180 |
| Guard | **Nenhum guard de rota.** O gate real é o `token` na query string, validado pela RPC `get_invitation_by_token` (executável por `anon`) |
| Layout | **Full-screen**, card centralizado `max-w-md` sobre `bg-background` (note: **`bg-background`**, não `bg-muted/30` como Login/SignUp) |
| Logo | `@/assets/torre-controle-logo.png` (arquivo **diferente** do usado nas outras telas), `className="h-12 mx-auto mb-4"`, `alt="Logo"` |
| Dependências | `supabase` direto (não usa `useAuth`), `useToast`, `logError`, ícones lucide `Loader2`, `CheckCircle`, `XCircle` |

### 4.2 Objetivo e persona

**Objetivo (guia `aceitar-convite.ts`):** “A tela que recebe quem foi convidado para uma organização. A partir do link do convite, ela identifica sua situação e mostra o caminho certo para entrar e passar a fazer parte da organização — criando conta, fazendo login ou apenas confirmando.”

**Persona:** convidado por um administrador de uma organização. Pode ser alguém totalmente novo na Torre, alguém que já tem conta, ou alguém que já está logado (com a conta certa ou com outra).

**Modelo mental do guia:** “Pense no convite como um crachá de visitante já preparado com o seu nome e a sua função. Esta tela valida esse crachá e, conforme a sua situação, pede o mínimo necessário: às vezes só um clique, às vezes a senha, às vezes um cadastro completo. O e-mail vem travado no convite — você não escolhe outro.”

**Permissões:** `["token de convite"]`.

### 4.3 Anatomia visual

Esta é a tela mais complexa do domínio: **uma rota, oito renderizações possíveis**, resolvidas por early returns em cascata.

Ordem de avaliação no componente (a primeira condição verdadeira vence):

| Ordem | Condição | Renderização |
|---|---|---|
| 1 | `isLoading` | Tela de carregamento (só spinner) |
| 2 | `error` | Card “Convite Inválido” |
| 3 | `success` | Card “Convite Aceito!” |
| 4 | `alreadyMemberMsg` | Card “Você já é membro” |
| 5 | `mode === "wrong-session"` | Card “Conta diferente” |
| 6 | `mode === "session-match"` | Card “Aceitar Convite” + botão único |
| 7 | `mode === "login"` | Card “Aceitar Convite” + form de senha |
| 8 | (default) `mode === "signup"` | Card “Aceitar Convite” + form completo |

#### 4.3.1 Máquina de estados `Mode`

```ts
type Mode = "signup" | "login" | "session-match" | "wrong-session";
```

Decisão inicial, feita no `useEffect` de validação do token (linhas 124–138):

```
há sessão ativa?
├── sim, e-mail da sessão == e-mail do convite  → "session-match"
├── sim, e-mails diferentes                     → "wrong-session"
└── não
    ├── account_exists === true (vindo da RPC)  → "login"
    └── account_exists !== true                 → "signup"
```

A comparação de e-mails usa `emailsMatch()` (linhas 32–34): `trim()` + `toLowerCase()` nos dois lados, com fallback `""` para `null`/`undefined`.

#### 4.3.2 Tela 1 — Carregando

```
<div className="min-h-screen flex items-center justify-center bg-background">
  <Loader2 className="h-8 w-8 animate-spin text-primary" />
</div>
```

Sem card, sem logo, sem texto. Apenas o spinner lucide `Loader2` girando, 32×32, cor primária, centralizado na viewport.

#### 4.3.3 Tela 2 — Convite Inválido

Card `max-w-md`, `CardHeader text-center`:
1. Ícone lucide **`XCircle`**, `h-12 w-12 text-destructive mx-auto mb-4`.
2. `CardTitle className="text-destructive"` — “Convite Inválido”.
3. `CardDescription` — o texto de `error` (um dos três, ver §4.8).
4. `CardContent text-center` com botão “Ir para Login” (variante `default`, **não** full-width — largura natural, centralizado).

Note: **não há logo** nesta tela.

#### 4.3.4 Tela 3 — Convite Aceito

Card `max-w-md`, apenas `CardHeader text-center`:
1. Ícone lucide **`CheckCircle`**, `h-12 w-12 text-primary mx-auto mb-4`.
2. `CardTitle` — “Convite Aceito!”.
3. `CardDescription` — “Você agora faz parte da organização. Você será redirecionado para o login...”.

**Não há `CardContent` nem botão.** O redirecionamento para `/login` acontece por `setTimeout(..., 2000)` — 2 segundos.

#### 4.3.5 Tela 4 — Você já é membro

Card `max-w-md`:
1. Ícone lucide **`CheckCircle`**, `h-12 w-12 text-primary mx-auto mb-4`.
2. `CardTitle` — “Você já é membro”.
3. `CardDescription` — a mensagem dinâmica: `Você já faz parte de <nome da organização>.` (fallback: “esta organização”).
4. `CardContent text-center` com botão “Ir para Login”.

#### 4.3.6 Tela 5 — Conta diferente (`wrong-session`)

1. **Logo** (`torre-controle-logo.png`, `h-12 mx-auto mb-4`, `alt="Logo"`).
2. `CardTitle` — “Conta diferente”.
3. `CardDescription` com **texto rico**: “Você está logado como **`<sessionEmail>`**, mas este convite é para **`<invitation.email>`**. Saia da conta atual para continuar.” Os dois e-mails são renderizados em `<span className="font-semibold text-foreground">`.
4. `CardContent className="space-y-3"` com **dois botões empilhados**, ambos `w-full`:
   - “Sair e continuar” (variante `default`) — com `Loader2` girando + “Saindo...” em loading.
   - “Ir para Login” (variante `outline`).

#### 4.3.7 Tela 6 — Já logado com o e-mail certo (`session-match`)

1. Logo.
2. `CardTitle` — “Aceitar Convite”.
3. `CardDescription` rica: “Você foi convidado para **`<orgName>`** como **`<role>`**. Você já está logado como **`<sessionEmail>`**.”
4. `CardContent` com **um único botão** `w-full`: “Entrar na organização” (→ `Loader2` + “Entrando...” em loading).

**Nenhum campo a preencher.** É a variante mais curta da tela.

#### 4.3.8 Tela 7 — Conta já existe (`login`)

1. Logo.
2. `CardTitle` — “Aceitar Convite”.
3. `CardDescription`: “Esse e-mail já tem conta na Torre. Entre com sua senha para aceitar o convite para **`<orgName>`** como **`<role>`**.”
4. `CardContent` com `<form className="space-y-4">`:
   - Campo “E-mail” — **desabilitado**, `className="bg-muted"`, valor = e-mail do convite.
   - Campo “Senha” — editável, `required`.
   - Botão submit `w-full`: “Entrar e Aceitar Convite” (→ `Loader2` + “Entrando...”).

#### 4.3.9 Tela 8 — Conta nova (`signup`, default)

1. Logo.
2. `CardTitle` — “Aceitar Convite”.
3. `CardDescription`: “Você foi convidado para **`<orgName>`** como **`<role>`**” (sem ponto final).
4. `CardContent` com `<form className="space-y-4">`:
   - Campo “E-mail” — desabilitado, `bg-muted`.
   - Campo “Nome Completo” — `required`.
   - Campo “Senha” — `required`, `minLength={6}`.
   - Campo “Confirmar Senha” — `required`.
   - Botão submit `w-full`: “Criar Conta e Aceitar Convite” (→ `Loader2` + “Criando conta...”).

### 4.4 Campos e inputs

Esta tela **não usa react-hook-form nem Zod** — usa `useState` com um objeto único:

```ts
const [formData, setFormData] = useState({ fullName: "", password: "", confirmPassword: "" });
```

Validação é **imperativa**, dentro dos handlers, e o feedback é por **toast** (não inline).

| Campo | Label exato | `id` | Tipo | Placeholder | Aparece em | Obrigatório | Validação | Default |
|---|---|---|---|---|---|---|---|---|
| E-mail | `E-mail` | `email` | `email`, **`disabled`**, `className="bg-muted"` | — (sem placeholder) | modos `login` e `signup` | N/A (não editável) | N/A | `invitation.email` (vindo da RPC) |
| Senha (login) | `Senha` | `password` | `password` | `Sua senha` | modo `login` | Sim (`required` HTML) | Não-vazio, checado no handler | `""` |
| Nome Completo | `Nome Completo` | `fullName` | `text` | `Seu nome completo` | modo `signup` | Sim (`required`) | Apenas `required` HTML — **não há checagem de tamanho mínimo** | `""` |
| Senha (signup) | `Senha` | `password` | `password` | `Mínimo 6 caracteres` | modo `signup` | Sim (`required`, `minLength={6}`) | `password.length >= 6` no handler | `""` |
| Confirmar Senha | `Confirmar Senha` | `confirmPassword` | `password` | `Digite a senha novamente` | modo `signup` | Sim (`required`) | `password === confirmPassword` no handler | `""` |

Diferenças relevantes vs. `/signup` (§3.4):
- Aqui **não há** validação de tamanho mínimo do nome (lá são 2 caracteres).
- Aqui a mensagem de erro é **toast**, não texto sob o campo.
- Aqui o e-mail é **travado** — o guia explica: “O convite é nominal: vale para o endereço de e-mail que o administrador indicou… assim ninguém aceita um convite no lugar de outra pessoa.”
- Após trocar de `signup` para `login` por detecção de conta existente, os campos `password` e `confirmPassword` são **limpos** (`setFormData(prev => ({...prev, password: "", confirmPassword: ""}))`).

### 4.5 Botões e ações

| Label exato | Aparece em | Variante | Ícone em loading | Ação | Disabled quando |
|---|---|---|---|---|---|
| `Entrar na organização` (→ `Entrando...`) | `session-match` | `default`, `w-full` | `Loader2 animate-spin mr-2 h-4 w-4` | `handleSessionMatchAccept()` → lê a sessão → `finalizeAcceptance(userId)` | `isSubmitting` |
| `Entrar e Aceitar Convite` (→ `Entrando...`) | `login` | `default`, `w-full`, `type="submit"` | `Loader2` | `handleLoginSubmit()` → `signInWithPassword(invitation.email, password)` → `finalizeAcceptance` | `isSubmitting` |
| `Criar Conta e Aceitar Convite` (→ `Criando conta...`) | `signup` | `default`, `w-full`, `type="submit"` | `Loader2` | `handleSignupSubmit()` → `signUp` → EF `confirm-invited-user` → (se preciso) `signInWithPassword` → `finalizeAcceptance` | `isSubmitting` |
| `Sair e continuar` (→ `Saindo...`) | `wrong-session` | `default`, `w-full` | `Loader2` | `handleSignOut()` → `supabase.auth.signOut()` → volta ao modo `login` ou `signup` conforme `accountExists` | `isSubmitting` |
| `Ir para Login` | `wrong-session` | `outline`, `w-full` | — | `navigate("/login")` | Nunca |
| `Ir para Login` | `error` (Convite Inválido) | `default`, largura natural | — | `navigate("/login")` | Nunca |
| `Ir para Login` | `alreadyMember` | `default`, largura natural | — | `navigate("/login")` | Nunca |

Nenhuma ação pede confirmação explícita (não há `AlertDialog` nesta tela).

### 4.6 Modais, sheets e popovers

**Nenhum modal, sheet ou popover.** Todos os desfechos são **telas inteiras** (early returns). O único componente flutuante é o **toast** (ver §4.8), que é global e vive no `Toaster` montado no `App`.

Isso é uma decisão de design importante: a tela nunca empilha camadas. O redesign pode manter (mais simples em mobile) ou migrar para um wizard com steps — mas precisa preservar as 8 renderizações.

### 4.7 Estados da tela

| Estado | Disparo | Renderização |
|---|---|---|
| **Loading inicial** | `isLoading = true` (carga da rota até a RPC responder) | Spinner `Loader2` sozinho na viewport |
| **Erro — sem token** | `!token` na query string | “Convite Inválido” + “Token de convite não encontrado” |
| **Erro — token inexistente** | RPC devolve erro ou zero linhas | “Convite Inválido” + “Convite inválido ou não encontrado” |
| **Erro — já aceito** | `row.status === "accepted"` | “Convite Inválido” + “Este convite já foi aceito” |
| **Erro — expirado** | `new Date(row.expires_at) < new Date()` | “Convite Inválido” + “Este convite expirou” |
| **Erro — exceção na validação** | `catch` do try do `useEffect` | “Convite Inválido” + “Erro ao validar convite” |
| **Modo signup** | deslogado + `account_exists !== true` | Form completo |
| **Modo login** | deslogado + `account_exists === true` (ou fallback pós-422) | Form só com senha |
| **Modo session-match** | logado com o e-mail do convite | Botão único |
| **Modo wrong-session** | logado com e-mail diferente | Aviso + dois botões |
| **Submetendo** | `isSubmitting = true` | Botão principal desabilitado, com `Loader2` + texto de progresso |
| **Já é membro** | `checkAlreadyMember()` retorna `true` | Tela “Você já é membro” |
| **Sucesso** | `accept_invitation` sem erro | Tela “Convite Aceito!” + toast + redirect em 2 s |
| **Sem permissão** | Não aplicável | — |

Fluxo de backend por trás dos estados (relevante porque **explica** a tela):
1. `rpc("get_invitation_by_token", { p_token })` — executável por `anon` (a RLS de `user_invitations` bloquearia leitura direta). Devolve `RETURNS TABLE`, então o código pega `data[0]`. Campos usados: `id`, `email`, `organization_id`, `role`, `expires_at`, `status`, `organization_name`, `account_exists`.
2. `checkAlreadyMember(userId, organizationId)` — `select id from organization_users where user_id, organization_id, is_active = true` com `.maybeSingle()`.
3. `rpc("accept_invitation", { p_invitation_token })` — cria a membership idempotentemente e marca o convite como aceito.
4. No modo signup, antes do passo 3: `supabase.functions.invoke("confirm-invited-user", { userId, invitationToken })` — **auto-confirma o e-mail**, o que dispensa a verificação por e-mail do cadastro comum. Falha aqui é **não-fatal** (o código apenas loga).

### 4.8 Mensagens, validações e toasts (texto real)

**Mensagens de erro de tela inteira (`error`):**
- `Token de convite não encontrado`
- `Convite inválido ou não encontrado`
- `Este convite já foi aceito`
- `Este convite expirou`
- `Erro ao validar convite`

**Mensagem dinâmica de “já é membro”:**
- `Você já faz parte de <nome da organização>.` — fallback quando o nome não vem: `Você já faz parte de esta organização.` (⚠️ Concordância quebrada no fallback: “de esta organização”. Bug de copy.)

**Erros lançados internamente e exibidos via toast:**
- `Sessão expirada. Faça login novamente.`
- `E-mail ou senha inválidos.` (quando a mensagem do Supabase contém “invalid”)
- `Não foi possível autenticar. Tente novamente.`
- `Erro ao criar usuário`
- `Convite inválido, expirado ou email não confere` (quando a RPC `accept_invitation` devolve código `P0001` ou mensagem contendo “invitation”)
- `Erro ao aceitar convite` (fallback genérico da RPC)

**Toasts (texto real, com variante):**

| Título | Descrição | Variante | Quando |
|---|---|---|---|
| `Convite aceito com sucesso!` | `Você já pode acessar a organização.` | default | Após `accept_invitation` bem-sucedida |
| `Erro` | `Informe sua senha.` | `destructive` | Modo login, submit com senha vazia |
| `Erro` | `As senhas não coincidem` | `destructive` | Modo signup, senhas divergentes |
| `Erro` | `A senha deve ter pelo menos 6 caracteres` | `destructive` | Modo signup, senha curta |
| `Conta já existe` | `Esse e-mail já tem conta na Torre. Entre com sua senha para aceitar o convite.` | default | Signup devolveu 422 / “already registered” → troca para modo login |
| `Erro ao aceitar convite` | `<mensagem do erro>` ou `Tente novamente` | `destructive` | Falha em `session-match` ou em `login` |
| `Erro ao criar conta` | `<mensagem do erro>` ou `Tente novamente` | `destructive` | Falha no fluxo de signup |
| `Erro ao sair` | `<mensagem do erro>` ou `Tente novamente` | `destructive` | Falha no `signOut` |

**Textos fixos por modo:**

| Modo | Título | Descrição |
|---|---|---|
| `signup` | `Aceitar Convite` | `Você foi convidado para <org> como <role>` |
| `login` | `Aceitar Convite` | `Esse e-mail já tem conta na Torre. Entre com sua senha para aceitar o convite para <org> como <role>.` |
| `session-match` | `Aceitar Convite` | `Você foi convidado para <org> como <role>. Você já está logado como <email>.` |
| `wrong-session` | `Conta diferente` | `Você está logado como <email>, mas este convite é para <email do convite>. Saia da conta atual para continuar.` |
| erro | `Convite Inválido` | `<error>` |
| sucesso | `Convite Aceito!` | `Você agora faz parte da organização. Você será redirecionado para o login...` |
| já membro | `Você já é membro` | `Você já faz parte de <org>.` |

**Ponto crítico de copy documentado no próprio guia de negócio:** o `role` é exibido **cru, em inglês** — “O papel aparece na tela com o nome técnico em inglês (por exemplo, operator, admin, manager ou viewer), exatamente como veio no convite.” Ou seja, o convidado lê “Você foi convidado para Blips como operator”. Os rótulos PT-BR (`ROLE_LABELS`) existem, mas **só na tela de seleção de organização**.

O fallback do nome da org é `"a organização"` (`const orgName = invitation?.organization?.name || "a organização"`), gerando “Você foi convidado para a organização como admin”.

### 4.9 Fluxos de uso passo a passo

**Fluxo A — convidado novo, deslogado (modo `signup`)**
1. Recebe o e-mail e clica no link `/accept-invite?token=…`.
2. Tela mostra o spinner enquanto a RPC valida.
3. Renderiza o formulário completo. O e-mail vem travado e cinza.
4. Preenche Nome Completo, Senha e Confirmar Senha.
5. Clica em “Criar Conta e Aceitar Convite”. Botão vira `Loader2` + “Criando conta...”.
6. `signUp` cria o usuário.
7. A EF `confirm-invited-user` confirma o e-mail automaticamente (falha aqui não bloqueia).
8. Se `signUp` não devolveu sessão, faz `signInWithPassword` com o mesmo e-mail/senha.
9. `checkAlreadyMember` retorna `false`.
10. `accept_invitation` cria a membership.
11. Tela troca para “Convite Aceito!”; toast “Convite aceito com sucesso!”.
12. Após 2 s, redireciona para `/login`.
13. ⚠️ Fricção conhecida: o usuário **acabou de autenticar** e mesmo assim é mandado para o Login.

**Fluxo B — convidado que já tem conta, deslogado (modo `login`)**
1. Abre o link. A RPC devolve `account_exists: true`.
2. A tela já abre com o formulário curto (só senha) — **decisão proativa** para evitar o “toast fugaz” do 422.
3. Digita a senha e clica em “Entrar e Aceitar Convite”.
4. `signInWithPassword` com o e-mail do convite.
5. `finalizeAcceptance` → membership → tela de sucesso → `/login` em 2 s.

**Fluxo C — já logado com o e-mail do convite (modo `session-match`)**
1. Abre o link estando logado com o mesmo e-mail.
2. Vê a descrição com org, papel e o próprio e-mail, e um único botão.
3. Clica em “Entrar na organização” → “Entrando...”.
4. `getSession()` pega o `userId`. Se não houver, lança “Sessão expirada. Faça login novamente.” (toast).
5. `finalizeAcceptance` → sucesso → `/login` em 2 s.

**Fluxo D — logado com outra conta (modo `wrong-session`)**
1. Abre o link logado como outra pessoa.
2. Vê “Conta diferente” com os dois e-mails em negrito.
3. Clica em “Sair e continuar” → “Saindo...”.
4. `signOut()` limpa a sessão; `sessionEmail` vira `null`.
5. O modo muda para `login` (se `accountExists`) ou `signup`.
6. Segue pelo Fluxo A ou B.
7. Alternativa: clica em “Ir para Login” e abandona o convite (o link continua válido até expirar).

**Fluxo E — link antigo de quem já é membro**
1. Abre o link; autentica por qualquer caminho.
2. `checkAlreadyMember` retorna `true`.
3. **`accept_invitation` NÃO é chamada.**
4. Tela “Você já é membro” com o nome da org e botão “Ir para Login”.
5. Nenhum toast de sucesso é disparado.

**Fluxo F — convite expirado / já aceito / token inválido**
1. Abre o link.
2. Após o spinner, tela “Convite Inválido” com o motivo específico.
3. Único caminho: “Ir para Login”.

**Fluxo G — rede de segurança do 422**
1. Está no modo `signup`, mas o e-mail na verdade já tem conta (a RPC não sinalizou).
2. `signUp` devolve 422 / “already registered”.
3. O código detecta (`status === 422` ou mensagem contendo “already registered” / “already been registered” / “user already”).
4. `setMode("login")`, limpa as senhas, toast “Conta já existe”.
5. A tela se recompõe no formulário curto.

**Fluxo H — senha errada no modo login**
1. Digita senha errada.
2. Toast destrutivo “Erro ao aceitar convite” / “E-mail ou senha inválidos.”.
3. O formulário permanece; o convite continua válido.

**Fluxo I — aceite automático paralelo (`usePendingInvitations`)**
Independente desta tela: assim que qualquer usuário autentica no app, o `OrganizationContext` monta o hook `usePendingInvitations`, que busca convites `pending`, não expirados, para o e-mail da sessão e chama `accept_invitation` para **cada um**, em silêncio. Ver §6.2 — isso significa que um convite pode ser aceito **sem o usuário jamais abrir esta tela**.

### 4.10 Responsividade e acessibilidade observadas

- Casca `min-h-screen flex items-center justify-center bg-background p-4`; card `w-full max-w-md`. Sem breakpoints específicos.
- O modo `signup` é o mais alto (4 campos + botão); mesma ressalva de viewport curta das telas anteriores.
- Logo com `alt="Logo"` — **alt genérico e pouco informativo** (as outras telas usam “Torre de Controle”).
- Ícones `XCircle`, `CheckCircle` e `Loader2` **não têm `aria-hidden`** nem rótulo textual alternativo; o significado depende do título ao lado.
- O spinner de carregamento inicial é **puramente visual**: não há texto “Carregando...” nem `aria-live` — leitor de tela encontra uma página vazia.
- Inputs desabilitados (`E-mail`) têm `disabled` nativo — corretamente fora da ordem de foco, mas **não há explicação textual do porquê** na tela (o guia explica; a UI, não).
- Validações por toast: o toast do shadcn/ui usa `ToastViewport` com semântica de região — porém, como `TOAST_LIMIT = 1`, dois erros seguidos se sobrescrevem.
- Transições entre os 8 estados não movem o foco nem anunciam mudança de contexto.
- `required` e `minLength` HTML estão presentes nos campos do signup — isso ativa a validação nativa do browser, que **compete** com as checagens por toast (a nativa dispara primeiro e mostra o balão do browser, em idioma do SO).

### 4.11 Dores e oportunidades para o redesign

1. **O papel é exibido em inglês.** “convidado para X como `operator`”. Os rótulos PT-BR existem (`ROLE_LABELS` em `SelectOrganizationPage`) mas não são compartilhados. Extrair para um módulo comum é ganho imediato.
2. **Redirecionar para `/login` após aceitar é contraintuitivo.** O usuário acabou de autenticar (nos modos `signup`, `login` e `session-match` há sessão válida). O natural seria ir para `/select-organization` — ou direto para a org recém-aceita.
3. **Espera fixa de 2 segundos sem controle.** Não há botão “Continuar agora” na tela de sucesso, nem contador visível.
4. **Fallback de copy quebrado:** “Você já faz parte de esta organização.” e “Você foi convidado para a organização como admin”.
5. **Duas linguagens de validação na mesma tela:** `required`/`minLength` nativos do browser + checagens manuais com toast. Mensagens podem aparecer em dois idiomas e dois formatos.
6. **Inconsistência de validação com `/signup`:** aqui o nome não tem mínimo de 2 caracteres; lá tem.
7. **Inconsistência de logo e de fundo:** arquivo de logo diferente (`torre-controle-logo.png` vs `logo-torre-controle.png`), altura diferente (`h-12` vs `h-16`), fundo diferente (`bg-background` vs `bg-muted/30`), `alt` diferente.
8. **Telas de erro sem logo** — quebram a identidade visual justamente no momento de frustração.
9. **Sem informação sobre o que o papel concede.** O convidado aceita “como admin” sem saber o que isso permite. Um resumo das permissões (a matriz da §1) seria valor real.
10. **Sem “quem convidou”.** O convite não mostra o remetente, o que é um vetor de desconfiança/phishing.
11. **Sem data de expiração visível.** O código lê `expires_at` mas só o usa para bloquear; poderia exibir “Este convite expira em <data>”.
12. **Não há caminho de recuperação de senha no modo `login`.** Quem tem conta e esqueceu a senha fica preso (agravado pela ausência global de reset — §2.11).
13. **O aceite automático (`usePendingInvitations`) torna esta tela parcialmente redundante** e cria ambiguidade: o usuário pode ver “Você já é membro” sem nunca ter clicado em nada.
14. **Falha silenciosa da EF `confirm-invited-user`:** se ela falhar, o usuário é criado sem confirmação e pode não conseguir logar depois — e nada na tela avisa.

---

## 5. Selecionar Organização

### 5.1 Identidade

| Item | Valor |
|---|---|
| Rota | `/select-organization` |
| Arquivo | `src/pages/SelectOrganizationPage.tsx` (1053 linhas — três componentes no mesmo arquivo) |
| Export | `export function SelectOrganizationPage()` + componentes internos `ConsolidatedDashboard`, `StatCard`, `OrphanSchemasManager` |
| Registro da rota | `src/App.tsx`, linhas 182–189 |
| Guard | `<ProtectedRoute>` — exige sessão. **Não** usa `RequireOrg` (seria loop) nem `RequirePermission` |
| Layout | **Full-screen**, fora do `AppLayout`. Container `mx-auto max-w-6xl` sobre `bg-muted/30`, padding `p-4 md:p-8` |
| Contextos | `useAuth()` → `user`, `signOut`; `useOrganization()` → `organizations`, `userOrgRoles`, `isLoading`, `selectOrganization`, `isSuperAdmin`, `refreshOrganizations` |
| Hooks | `useConsolidatedStats()`, `useToast()` |

### 5.2 Objetivo e persona

**Objetivo (guia `selecionar-organizacao.ts`):** “Depois do login, é onde você escolhe em qual organização vai trabalhar. Cada cartão mostra a organização e o seu papel nela. Para o Super Admin, a tela ganha um painel consolidado de todas as organizações e ferramentas de administração.”

**Modelo mental do guia:** “Pense nela como o saguão de elevadores: cada botão leva a um andar (uma organização) diferente, e ao lado de cada botão está escrito o seu cargo naquele andar.”

**Duas personas em uma tela:**
1. **Usuário comum** — vê só a saudação, os cards das suas organizações, o cartão desabilitado “Criar nova organização (Em breve)” e o botão Sair.
2. **Super Admin (Finza)** — vê tudo acima **mais** a faixa de Super Admin, o cartão de criação ativo, ícones de lixeira nos cards, o painel “Visão Consolidada” e o painel “Gerenciar Schemas”. Na prática esta é **a tela de administração da plataforma**.

**Permissões:** `["autenticado"]` (guia). Blocos administrativos: exclusivamente `isSuperAdmin`.

### 5.3 Anatomia visual

#### 5.3.1 Layout principal (com organizações)

Container: `min-h-screen bg-muted/30 p-4 md:p-8` → `mx-auto max-w-6xl`.

Ordem vertical:

1. **Header** (`flex items-center justify-between mb-8`):
   - Esquerda (`flex items-center gap-4`): logo `logo-torre-controle.png` `h-12 w-auto` + um bloco de texto que contém **uma `<div>` vazia** (linha 534 — resíduo de um título removido) e o parágrafo `Olá, <user.email antes do @>!` em `text-muted-foreground`.
   - Direita: botão “Sair”, variante `outline`, com ícone lucide `LogOut` `h-4 w-4 mr-2`.
2. **Faixa de Super Admin** (condicional `isSuperAdmin`) — `mb-6 flex items-center gap-2 text-amber-600`: ícone lucide `Crown` `h-5 w-5` + texto “Você é Super Admin (owner em todas as organizações)” em `font-medium`.
3. **Card “Selecione uma organização”** (`mb-8`):
   - `CardHeader`: `CardTitle` com ícone lucide `Building2` `h-5 w-5` + texto “Selecione uma organização”; `CardDescription` “Escolha a organização que deseja acessar”.
   - `CardContent`: grid `grid gap-4 md:grid-cols-2 lg:grid-cols-3` com:
     - **N cards de organização** (um por org).
     - **1 card de criação** (ativo se super admin, desabilitado caso contrário) — sempre o último.
4. **Separador + “Visão Consolidada (Super Admin)”** — só se `isSuperAdmin && organizations.length > 0`. Precedido de `<Separator className="my-8" />`.
5. **Separador + “Gerenciar Schemas (Super Admin)”** — só se `isSuperAdmin`. Precedido de `<Separator className="my-8" />`.
6. **Modais** (montados no final, controlados por state).

#### 5.3.2 Card de organização (anatomia detalhada)

`<Card className="cursor-pointer transition-all hover:border-primary hover:shadow-md relative group" onClick={selecionar}>` → `<CardContent className="p-4">`:

1. **Linha superior** (`flex items-start justify-between mb-3`):
   - **Avatar da org**: `div` 48×48 (`h-12 w-12`), `rounded-lg`, `flex items-center justify-center`, texto branco `font-bold text-lg`, **cor de fundo dinâmica** = `org.primary_color` (fallback `#3B82F6`). Conteúdo: a **primeira letra do nome**, em maiúscula.
   - **Grupo à direita** (`flex items-center gap-2`):
     - **Badge de papel** — `<Badge className={roleInfo.color}>{roleInfo.label}</Badge>`, usando `ROLE_LABELS`.
     - **Botão de lixeira** (condicional) — `variant="ghost" size="icon"`, `h-7 w-7`, com `opacity-0 group-hover:opacity-100 transition-opacity`, cor `text-destructive hover:text-destructive hover:bg-destructive/10`, ícone lucide `Trash2` `h-4 w-4`. Só renderiza se `isSuperAdmin && !isProtectedOrgSlug(org.slug)`.
2. **Nome da org** — `<h3 className="font-semibold mb-1">`.
3. **Slug** — `<p className="text-sm text-muted-foreground mb-3">`.
4. **Botão “Acessar”** — `className="w-full" size="sm"`, variante `default`.

Comportamento de clique: **o card inteiro é clicável**; o botão “Acessar” é redundante (não tem `onClick` próprio — o clique borbulha para o card). A lixeira chama `e.stopPropagation()` para não selecionar a org ao excluir.

#### 5.3.3 Card “Criar nova organização”

Duas variantes mutuamente exclusivas:

| Variante | Condição | Aparência |
|---|---|---|
| **Ativa** | `isSuperAdmin` | `Card` `cursor-pointer border-dashed hover:border-primary hover:shadow-md hover:bg-muted/50`; conteúdo centralizado com `min-h-[180px]`: quadrado 48×48 `rounded-lg bg-primary/10` com ícone lucide `Plus` `h-6 w-6 text-primary`, e o texto `Criar nova organização` (`text-sm font-medium text-center`). Clique abre o modal |
| **Desabilitada** | demais usuários | `Card` `cursor-not-allowed border-dashed opacity-50`; quadrado `bg-muted` com `Plus` `text-muted-foreground`; texto `Criar nova organização` em `text-muted-foreground` e, abaixo, `(Em breve)` em `text-xs text-muted-foreground mt-1`. **Sem `onClick`** |

Nota de produto: o rótulo “(Em breve)” é enganoso — não é uma funcionalidade futura, é uma restrição permanente de papel.

#### 5.3.4 Painel “Visão Consolidada (Super Admin)”

Componente `ConsolidatedDashboard` (linhas 777–839). Card com:
- `CardTitle` com ícone lucide `TrendingUp` `h-5 w-5` + texto “Visao Consolidada (Super Admin)” (**sem acento em “Visao”** — texto real do código).
- `CardDescription`: `KPIs agregados de todas as {N} organizacoes` (**sem cedilha/acento em “organizacoes”**).
- Corpo:
  - **Loading**: `Loader2 h-8 w-8 animate-spin text-muted-foreground` centralizado com `py-8`.
  - **Carregado**: grid `grid gap-4 md:grid-cols-2 lg:grid-cols-4` com 4 `StatCard`.

`StatCard` (linhas 846–860): `rounded-lg border bg-card p-4` → linha com ícone (16×16) + título (`text-sm font-medium`, cor `muted-foreground`), valor em `text-2xl font-bold`, descrição em `text-xs text-muted-foreground mt-1`.

| # | Título | Valor | Ícone lucide | Descrição |
|---|---|---|---|---|
| 1 | `Total de Contatos` | `formatNumber(stats.totalContacts)` (pt-BR) | `Users` | `Em todas as organizacoes` |
| 2 | `Contratos Ativos` | `formatNumber(stats.activeContracts)` | `FileText` | `Com parcelas pendentes` |
| 3 | `Campanhas Ativas` | `formatNumber(stats.activeCampaigns)` | `Target` | `Em execucao` |
| 4 | `Taxa de Recuperacao` | `${stats.recoveryRate.toFixed(1)}%` | `TrendingUp` | `Media geral` |

⚠️ Divergência entre código e guia de negócio: a descrição do card 2 no código é “Com parcelas pendentes”, mas o guia (`selecionar-organizacao.ts`) descreve “Status ativo”. A query real (`useConsolidatedStats`) faz `contracts` com `.eq("status", "active")` — ou seja, **o guia está certo e a descrição na tela está errada**.

**Breakdown “Por Organizacao”** — renderiza só quando `stats.orgStats.length > 1`:
- `<h4 className="text-sm font-medium mb-3">Por Organizacao</h4>` (sem cedilha no código).
- Lista `space-y-2`; cada linha é `flex items-center justify-between p-3 rounded-lg bg-muted/50`:
  - Esquerda: nome da org (`font-medium`) + `{contatos} contatos | {contratos} contratos` (`text-sm text-muted-foreground`).
  - Direita (alinhada à direita): `{taxa}%` (`font-medium`) + `{recuperado} / {total}` em moeda BRL compacta (`Intl.NumberFormat("pt-BR", { style:"currency", currency:"BRL", notation:"compact", maximumFractionDigits:1 })`).

#### 5.3.5 Painel “Gerenciar Schemas (Super Admin)”

Componente `OrphanSchemasManager` (linhas 863–1052). Card com:
- `CardTitle` em `flex items-center justify-between`: à esquerda ícone lucide `Database` `h-5 w-5` + “Gerenciar Schemas (Super Admin)”; à direita o botão “Atualizar” (`variant="outline" size="sm"`, ícone lucide `RefreshCw` `h-4 w-4` ou `Loader2` girando quando carregando, com `<span className="ml-2">Atualizar</span>`).
- `CardDescription`: “Gerencie schemas órfãos (schemas de organizações excluídas)”.
- Corpo, três configurações:
  1. **Estado inicial (nada carregado)** — `text-center py-8 text-muted-foreground`: ícone `Database` `h-12 w-12 mx-auto mb-3 opacity-50` + texto `Clique em "Atualizar" para carregar a lista de schemas`.
  2. **Schemas Órfãos** (se houver) — `<h4 className="text-sm font-medium mb-3 flex items-center gap-2 text-destructive">` com ícone lucide `AlertCircle` `h-4 w-4` + `Schemas Órfãos ({n})`. Cada item: `flex items-center justify-between p-3 rounded-lg bg-destructive/10 border border-destructive/20`, com nome em `font-mono text-sm`, subtexto “Sem organização correspondente” (`text-xs text-muted-foreground`) e botão “Remover” (`variant="destructive" size="sm"`, ícone `Trash2 h-4 w-4 mr-1`).
  3. **Schemas Ativos** (se houver) — `<h4 className="text-sm font-medium mb-3 text-muted-foreground">Schemas Ativos ({n})</h4>` e uma nuvem de `Badge variant="secondary" className="font-mono"` (`flex flex-wrap gap-2`).
  4. **Sem órfãos, com ativos** — parágrafo centralizado `✓ Nenhum schema órfão encontrado` (`text-center text-sm text-muted-foreground py-4`). Note o caractere `✓` literal no texto.

#### 5.3.6 Layout de estado vazio (sem organizações)

Quando `organizations.length === 0`, a tela inteira é substituída (early return, linhas 491–526):

- Container `min-h-screen bg-muted/30 p-4 md:p-8` → `mx-auto max-w-xl` (**não** `max-w-6xl`).
- Card único:
  - `CardHeader text-center`: logo `h-12 w-auto mx-auto mb-4`; `CardTitle text-xl` “Bem-vindo ao Torre de Controle”; `CardDescription text-base` `Olá, <usuário>!`.
  - `CardContent text-center space-y-6`:
    - Bloco `py-6`: ícone lucide `Building2` `h-16 w-16 mx-auto text-muted-foreground/50 mb-4`; `<h3 className="font-medium text-lg mb-2">` “Você ainda não faz parte de nenhuma organização”; parágrafo `text-muted-foreground` “Aguarde um convite de um administrador ou entre em contato com sua empresa para solicitar acesso.”.
    - `<Separator />`.
    - Bloco `pt-2` com botão “Sair da conta” (`variant="outline"`, `w-full`, ícone `LogOut h-4 w-4 mr-2`).

**Importante:** nesse estado o super admin **não vê** o cartão de criar organização, nem o painel consolidado, nem o gerenciador de schemas — o early return acontece antes de qualquer checagem de `isSuperAdmin`. Um super admin que não pertença a nenhuma org fica sem saída pela UI. Ver §5.11.

### 5.4 Campos e inputs

A tela principal **não tem nenhum campo**. Todos os inputs vivem nos três modais.

| Modal | Label / texto do campo | `id` | Tipo | Placeholder | Obrigatório | Validação | Default |
|---|---|---|---|---|---|---|---|
| Criar Organização | `Nome da Organização` | `org-name` | `text` | `Ex: Minha Empresa` | Sim | Não-vazio após `trim()` | `""` |
| Criar Organização | `Slug (identificador único)` | `org-slug` | `text` | `Ex: minha_empresa` | Sim | `/^[a-z][a-z0-9_]{0,62}$/` + não pode ser reservado (`isReservedSlug`) | **auto-gerado** a partir do nome (editável depois) |
| Criar Organização | `Tipo de organização` (RadioGroup) | — | radio (2 cards) | — | Sim (sempre há uma seleção) | Valores `cobranca` \| `formalizacao` | `cobranca` |
| Criar Organização | `Email de outro owner` + `(opcional)` | `org-owner-email` | `email` | `cliente@empresa.com` | Não | Se preenchido: `/^[^\s@]+@[^\s@]+\.[^\s@]+$/` | `""` |
| Excluir Organização | (sem `<Label>`; instrução em `<p>`) | — | `text` | `Digite o nome da organização` | Sim | Igualdade exata com `orgToDelete.name` | `""` |
| Excluir Organização | (sem `<Label>`) | — | `text` | `Digite o slug da organização` | Sim | Igualdade exata com `orgToDelete.slug`; input em `font-mono` | `""` |
| Excluir Schema | (sem `<Label>`) | — | `text` | `Digite o nome do schema` | Sim | Igualdade exata com o nome do schema; `font-mono` | `""` |

**Auto-geração do slug** (`generateSlug`, linhas 269–271):
```
lowercase → NFD → remove diacríticos → [^a-z0-9]+ vira "_" → remove "_" das pontas
```
Roda a cada tecla digitada no campo Nome (`handleNameChange`), **sobrescrevendo** qualquer edição manual anterior do slug.

**Texto de ajuda sob o slug:** “Usado para identificar a organização no sistema. Apenas letras minúsculas, números e underscores.” (`text-xs text-muted-foreground`).

**Texto de ajuda sob o e-mail do owner:** “Se preenchido, este email tambem sera owner desta org (orgs podem ter multiplos owners). Voce continua como owner.” (sem acentos no código).

**Regras de slug reservado** (`isReservedSlug`, linhas 36–44) — bloqueia se:
- Está na lista `RESERVED_SLUGS`: `admin, auth, pg_temp, public, storage, vault, information_schema, supabase, supabase_auth, supabase_functions, pg_catalog, extensions, graphql, graphql_public, realtime, pgsodium, pgsodium_masks, cron, net, api, www, app, dev, staging, test, prod, production, null, undefined, default`
- Começa com `pg_`, `_`, `org_` ou `supabase_`
- Tem menos de 3 ou mais de 40 caracteres
- Não casa com `/^[a-z0-9]([a-z0-9_]*[a-z0-9])?$/`

**Orgs protegidas** (`PROTECTED_ORG_SLUGS`): apenas `blips`. Slug protegido **não mostra** o ícone de lixeira e é rejeitado em dois pontos adicionais de guarda.

### 5.5 Botões e ações

#### Tela principal

| Label exato | Local | Variante / tamanho | Ícone lucide | Ação | Disabled / oculto | Confirmação |
|---|---|---|---|---|---|---|
| `Sair` | Header | `outline`, default | `LogOut` `h-4 w-4 mr-2` | `signOut()` → `navigate("/login")` | Nunca | **Não** — sai direto |
| `Acessar` | Card de org | `default`, `sm`, `w-full` | — | (herda o clique do card) `selectOrganization(orgId)` → `navigate(redirectTo)` | Nunca | Não |
| (card inteiro) | Card de org | — | — | Idem “Acessar” | Nunca | Não |
| (lixeira) | Card de org, canto superior direito | `ghost`, `icon`, `h-7 w-7`, `text-destructive` | `Trash2` `h-4 w-4` | `handleOpenDeleteDialog` → abre o AlertDialog de exclusão | **Oculto** se `!isSuperAdmin` ou slug protegido; visualmente `opacity-0` até hover no card | Sim (modal com duplo confirm) |
| `Criar nova organização` | Card tracejado | Card clicável | `Plus` `h-6 w-6 text-primary` | Abre o modal de criação | Inerte (sem `onClick`) para não-super-admin | Não |
| `Sair da conta` | Estado vazio | `outline`, `w-full` | `LogOut` `h-4 w-4 mr-2` | `signOut()` → `/login` | Nunca | Não |
| `Atualizar` | Painel de schemas | `outline`, `sm` | `RefreshCw` `h-4 w-4` (vira `Loader2` girando) | `fetchSchemas()` → EF `manage-orphan-schemas` `{action:"list"}` | `isLoading` | Não |
| `Remover` | Item de schema órfão | `destructive`, `sm` | `Trash2` `h-4 w-4 mr-1` | Abre o AlertDialog de exclusão de schema | Nunca (visível só para super admin, pois o painel inteiro é gated) | Sim (modal com confirm digitado) |

#### Botões dentro dos modais

Ver §5.6, um bloco por modal.

### 5.6 Modais, sheets e popovers

Esta tela tem **três** componentes de sobreposição, todos controlados por state local.

---

#### Modal 1 — “Criar Nova Organização”

| Atributo | Valor |
|---|---|
| Componente | `<Dialog>` do shadcn/ui (`src/components/ui/dialog.tsx`) |
| State de controle | `isCreateDialogOpen` (`useState(false)`) |
| Gatilho de abertura | Clique no card tracejado “Criar nova organização” (só renderizado com `onClick` se `isSuperAdmin`) |
| Permissão | `isSuperAdmin` — não é `hasPermission()` |
| Fechamento | `onOpenChange` (clique fora / ESC), botão “Cancelar”, ou sucesso da criação |
| Largura | Padrão do `DialogContent` (não há override) |

**Cabeçalho:**
- `DialogTitle` `flex items-center gap-2`: ícone lucide `Building2` `h-5 w-5` + “Criar Nova Organização”.
- `DialogDescription`: “Preencha os dados abaixo para criar uma nova organização.”

**Corpo** (`space-y-4 py-4`), na ordem:

1. **Nome da Organização** — `Label htmlFor="org-name"` + `Input id="org-name" placeholder="Ex: Minha Empresa"`. `onChange` chama `handleNameChange`, que também regenera o slug.
2. **Slug (identificador único)** — `Label htmlFor="org-slug"` + `Input id="org-slug" placeholder="Ex: minha_empresa"` + parágrafo de ajuda.
3. **Tipo de organização** (condicional `isSuperAdmin` — redundante, pois só super admin abre o modal) — `<Label>` sem `htmlFor` + `<OrgProfileSelector value={newOrgProfile} onChange={setNewOrgProfile} disabled={isCreating} showCreationNote />`. Ver §6.1 para a anatomia completa do seletor.
4. **Email de outro owner (opcional)** — `Label htmlFor="org-owner-email"` com o texto “Email de outro owner” seguido de `<span className="text-muted-foreground font-normal">(opcional)</span>`; `Input type="email" placeholder="cliente@empresa.com"` + parágrafo de ajuda.

**Rodapé (`DialogFooter`):**

| Botão | Variante | Ícone | Ação | Disabled |
|---|---|---|---|---|
| `Cancelar` | `outline` | — | Fecha o dialog e **reseta** `newOrgOwnerEmail` e `newOrgProfile` (`"cobranca"`). ⚠️ **Não reseta** `newOrgName` nem `newOrgSlug` — reabrir o modal traz o nome/slug antigos | Nunca |
| `Criar Organização` | `default` | `Loader2 h-4 w-4 mr-2 animate-spin` quando `isCreating` | `handleCreateOrganization()` | `isCreating` |

**Validações client-side, na ordem exata do handler** (cada uma dispara um toast destrutivo e **aborta**):

| # | Condição | Título do toast | Descrição |
|---|---|---|---|
| 1 | `!trimmedName \|\| !trimmedSlug` | `Campos obrigatórios` | `Preencha nome e slug.` |
| 2 | `!/^[a-z][a-z0-9_]{0,62}$/.test(slug)` | `Slug inválido` | `Use apenas letras minúsculas, números e underscore. Comece com letra.` |
| 3 | `isReservedSlug(slug)` | `Slug reservado` | `'<slug>' é reservado pelo sistema. Evite nomes como admin, auth, public, storage, dev, prod e prefixos pg_/org_/supabase_.` |
| 4 | e-mail preenchido e inválido | `Email inválido` | `Formato de email do owner adicional é inválido.` |

**Chamada de backend:** `supabase.functions.invoke("create-org-schema", { body })`, onde `body` é `{ slug, name }` mais, opcionalmente, `owner_email` e `pipeline_profile`. O campo `pipeline_profile` é **omitido** quando a escolha é `cobranca` (via `choiceToProfile`, que devolve `null`) — o payload fica byte-idêntico ao comportamento anterior à feature.

**Toast de conclusão — a lógica mais complexa da tela** (linhas 367–428):

O título é `Organização criada — atenção` se houver qualquer warning; senão, `Organização criada`. A descrição é a junção (por espaço) de mensagens acumuladas:

| Origem | Mensagem |
|---|---|
| `data.expose.warning` | (texto do backend) |
| `data.owner.warning` | (texto do backend) |
| `data.owner.mode === "invitation_pending"` | `Convite enviado para <email> (sera owner adicional ao aceitar). Voce continua como owner.` |
| `data.owner.mode === "existing_user"` | `Owner adicional adicionado. Voce continua como owner.` |
| perfil solicitado e `seeded === true` | warning do backend, ou o fallback: `Perfil de formalizacao aplicado. Configure as convencoes em Configuracoes > Perfil da Operacao — ate lá as reguas desta organizacao nao disparam.` |
| perfil solicitado e `seeded !== true` (com objeto presente) | warning do backend, ou: `A organizacao foi criada, mas o perfil de formalizacao NAO foi aplicado: ela nasceu como org de cobranca. Aplique em Configuracoes > Perfil da Operacao.` |
| perfil solicitado e objeto ausente | `Perfil de formalizacao solicitado, mas esta versao do servidor nao confirmou a aplicacao. Confira em Configuracoes > Perfil da Operacao.` |
| nenhuma das anteriores | `<nome> foi criada com sucesso.` |

Note que **todas essas mensagens estão sem acentuação** no código (“organizacao”, “convencoes”, “Voce”), exceto por um “até lá” isolado.

**Pós-criação — o poll (linhas 436–469):**
1. `setPendingSelectOrgId(newOrgId)`.
2. `refreshOrganizations()` em laço, até 8 tentativas, com backoff `min(300 + tentativa*100, 1000)` ms (total < ~5 s).
3. Um `useEffect` observa `organizations` e, quando a org nova aparece, chama `selectOrganization(id)` e navega para `/` (**sempre o dashboard**, nunca o deep-link).

Razão documentada no código: `CREATE SCHEMA` dispara reload do schema-cache do PostgREST, e a query pode voltar stale **sem erro 503**.

**Toast de erro:**

| Título | Descrição |
|---|---|
| `Erro ao criar organização` | `error.message` (extraído do corpo JSON da resposta da EF quando é `FunctionsHttpError`, senão a mensagem do supabase-js) ou `Tente novamente.` |

---

#### Modal 2 — “Excluir Organização”

| Atributo | Valor |
|---|---|
| Componente | `<AlertDialog>` do shadcn/ui |
| State | `isDeleteDialogOpen` + `orgToDelete` (`{id, name, slug}`) |
| Gatilho | Ícone de lixeira no card da organização (`handleOpenDeleteDialog`) |
| Permissão | `isSuperAdmin` **e** slug não protegido — checados **duas vezes** (ao abrir e ao submeter) |
| Fechamento | `onOpenChange`, botão “Cancelar”, ou sucesso |

**Guardas antes de abrir** (`handleOpenDeleteDialog`, linhas 154–183):

| Ordem | Condição | Toast (destrutivo) | Ação |
|---|---|---|---|
| 1 | `isProtectedOrgSlug(org.slug)` | `Organização protegida` / `'<slug>' é protegida e não pode ser deletada pela UI. Use soft-delete via banco se necessário.` | Não abre |
| 2 | `!isSuperAdmin` | `Permissão insuficiente` / `Apenas super admins podem deletar organizações.` | Não abre |

Se passar, limpa os dois campos de confirmação e abre.

**Cabeçalho:**
- `AlertDialogTitle` `flex items-center gap-2 text-destructive`: ícone lucide `Trash2` `h-5 w-5` + “Excluir Organização”.
- `AlertDialogDescription`: “Esta ação é irreversível. Todos os dados da organização serão excluídos permanentemente.”

**Corpo** (`py-4 space-y-4`) — **duplo confirm**:
1. Bloco 1: `<p className="text-sm">` “Para confirmar, digite o nome da organização:” + `<span className="font-semibold ml-1">{orgToDelete?.name}</span>`; abaixo, `Input placeholder="Digite o nome da organização"` com `className="border-destructive/50 focus-visible:ring-destructive"`.
2. Bloco 2: `<p className="text-sm">` “E digite o slug (identificador único):” + `<span className="font-mono font-semibold ml-1">{orgToDelete?.slug}</span>`; abaixo, `Input placeholder="Digite o slug da organização"` com `className="font-mono border-destructive/50 focus-visible:ring-destructive"`.

**Rodapé (`AlertDialogFooter`)** — note que usa `<Button>` normal, **não** `AlertDialogAction`/`AlertDialogCancel`:

| Botão | Variante | Ícone | Ação | Disabled |
|---|---|---|---|---|
| `Cancelar` | `outline` | — | Fecha, limpa `orgToDelete` e os dois campos | Nunca |
| `Excluir Organização` | `destructive` | `Loader2 ... animate-spin` quando `isDeleting` | `handleDeleteOrganization()` | `isDeleting \|\| !orgToDelete \|\| deleteConfirmName !== orgToDelete?.name \|\| deleteConfirmSlug !== orgToDelete?.slug` |

**Execução da exclusão** (`handleDeleteOrganization`, linhas 184–268) — cinco guardas + três passos:

Guardas (re-checagem defensiva):
- Guard 3: slug protegido → toast `Organização protegida` / `'<slug>' é protegida e não pode ser deletada.` e aborta.
- Guard 4: `!isSuperAdmin` → toast `Permissão insuficiente` / `Apenas super admins podem deletar organizações.` e aborta.
- Guard 5: nome ou slug não conferem → **retorna em silêncio, sem toast**.

Passos:
1. EF `unexpose-org-schema` com `{ schema_name: "org_<slug>" }` — falha aqui é **engolida** (logada) e o fluxo continua.
2. `delete from organization_users where organization_id = <id>`.
3. `delete from organizations where id = <id>`.

**Toast de sucesso:**
- Título `Organização excluída`
- Descrição: `<nome> foi excluída com sucesso. O schema permanece no banco para recuperação manual se necessário.`

Depois: fecha o modal, limpa os states e chama `refreshOrganizations()`.

**Toast de erro:**
- Título `Erro ao excluir organização`; descrição `error.message` ou `Tente novamente`.

**Consequência de produto:** a exclusão **não remove o schema** — ele vira órfão e passa a aparecer no painel “Gerenciar Schemas”. Os dois modais são, portanto, um par de mão dupla.

---

#### Modal 3 — “Excluir Schema”

| Atributo | Valor |
|---|---|
| Componente | `<AlertDialog>` (dentro de `OrphanSchemasManager`) |
| State | `schemaToDelete: string \| null` — o `open` é derivado: `open={!!schemaToDelete}` |
| Gatilho | Botão “Remover” de um item da lista de schemas órfãos |
| Permissão | Implícita: o painel inteiro só renderiza para `isSuperAdmin` |
| Fechamento | `onOpenChange` (`open => !open && setSchemaToDelete(null)`), “Cancelar” ou sucesso |

**Cabeçalho:**
- `AlertDialogTitle` `flex items-center gap-2 text-destructive`: `Trash2` `h-5 w-5` + “Excluir Schema”.
- `AlertDialogDescription`: “Esta ação é irreversível. Todos os dados do schema serão excluídos permanentemente, incluindo tabelas, views, funções e dados.”

**Corpo** (`py-4 space-y-4`):
- `<p className="text-sm">` “Para confirmar a exclusão, digite o nome do schema:” + `<span className="font-mono font-semibold ml-1">{schemaToDelete}</span>`.
- `Input placeholder="Digite o nome do schema"` com `className="font-mono border-destructive/50 focus-visible:ring-destructive"`.

**Rodapé:**

| Botão | Variante | Ação | Disabled |
|---|---|---|---|
| `Cancelar` | `outline` | `setSchemaToDelete(null)` + limpa o campo | Nunca |
| `Excluir Schema` | `destructive` (com `Loader2` quando `isDeleting`) | `handleDropSchema()` → EF `manage-orphan-schemas` `{action:"drop", schema_name}` | `isDeleting \|\| deleteConfirmName !== schemaToDelete` |

**Toasts:**

| Título | Descrição | Variante |
|---|---|---|
| `Schema removido` | `data.message` (texto vindo do backend) | default |
| `Erro ao remover schema` | `error.message` ou `Tente novamente` | `destructive` |
| `Erro ao carregar schemas` | `error.message` ou `Tente novamente` | `destructive` (no `fetchSchemas`) |

Após sucesso: limpa o state e chama `fetchSchemas()` de novo.

---

### 5.7 Estados da tela

| Estado | Condição | Renderização |
|---|---|---|
| **Loading** | `isLoading` do `OrganizationContext` | `min-h-screen bg-muted/30` com `Loader2 h-8 w-8 animate-spin text-primary` centralizado. Nada mais |
| **Vazio (sem orgs)** | `organizations.length === 0` | Card “Bem-vindo ao Torre de Controle” com `Building2` grande, texto de espera por convite e botão “Sair da conta” (ver §5.3.6) |
| **Normal** | `organizations.length > 0` | Header + grid de cards + card de criação |
| **Super Admin** | `isSuperAdmin` | Normal **mais** faixa de coroa, lixeiras, card de criação ativo, Visão Consolidada e Gerenciar Schemas |
| **Sem permissão (não-super-admin)** | `!isSuperAdmin` | Card de criação **esmaecido** com “(Em breve)”; sem lixeiras; sem painéis administrativos. Tentativas por outro caminho geram toast `Permissão insuficiente` |
| **Org protegida** | slug em `PROTECTED_ORG_SLUGS` (`blips`) | Lixeira **não renderiza**; tentativa gera toast `Organização protegida` |
| **Consolidado carregando** | `useConsolidatedStats().isLoading` | `Loader2` centralizado dentro do card, `py-8` |
| **Schemas não carregados** | listas vazias antes do primeiro “Atualizar” | Placeholder com ícone `Database` e instrução “Clique em "Atualizar"...” |
| **Sem órfãos** | `orphanSchemas.length === 0 && activeSchemas.length > 0` | `✓ Nenhum schema órfão encontrado` |
| **Criando org** | `isCreating` | Botão do modal com `Loader2`; o `OrgProfileSelector` fica `disabled` (opacidade 50%, `cursor-not-allowed`) |
| **Excluindo** | `isDeleting` | Botão destrutivo com `Loader2` |
| **Erro** | Qualquer falha de rede/backend | **Sempre via toast destrutivo** — a tela nunca mostra estado de erro persistente |

Estado ausente e relevante: **não há tratamento visual para falha ao carregar as organizações**. O `fetchOrganizations` captura a exceção, loga e retorna `[]` — o usuário vê o **estado vazio** (“Você ainda não faz parte de nenhuma organização”) mesmo quando o problema foi uma falha de rede. Erro apresentado como vazio.

### 5.8 Mensagens, validações e toasts (texto real)

**Textos fixos da tela:**
- `Olá, <usuário>!` (usa `user.email.split("@")[0]`)
- `Você é Super Admin (owner em todas as organizações)`
- `Selecione uma organização`
- `Escolha a organização que deseja acessar`
- `Acessar`
- `Criar nova organização`
- `(Em breve)`
- `Sair`
- `Bem-vindo ao Torre de Controle`
- `Você ainda não faz parte de nenhuma organização`
- `Aguarde um convite de um administrador ou entre em contato com sua empresa para solicitar acesso.`
- `Sair da conta`
- `Visao Consolidada (Super Admin)` *(sem acento no código)*
- `KPIs agregados de todas as <N> organizacoes` *(sem cedilha)*
- `Total de Contatos` / `Em todas as organizacoes`
- `Contratos Ativos` / `Com parcelas pendentes`
- `Campanhas Ativas` / `Em execucao`
- `Taxa de Recuperacao` / `Media geral`
- `Por Organizacao`
- `<n> contatos | <n> contratos`
- `Gerenciar Schemas (Super Admin)`
- `Gerencie schemas órfãos (schemas de organizações excluídas)`
- `Atualizar`
- `Clique em "Atualizar" para carregar a lista de schemas`
- `Schemas Órfãos (<n>)`
- `Sem organização correspondente`
- `Remover`
- `Schemas Ativos (<n>)`
- `✓ Nenhum schema órfão encontrado`

**Rótulos de papel (`ROLE_LABELS`):** `Proprietário`, `Administrador`, `Gerente`, `Operador`, `Visualizador`.

**Inventário completo de toasts desta tela:**

| # | Título | Descrição | Variante | Gatilho |
|---|---|---|---|---|
| 1 | `Organização protegida` | `'<slug>' é protegida e não pode ser deletada pela UI. Use soft-delete via banco se necessário.` | destructive | Tentar abrir exclusão de org protegida |
| 2 | `Permissão insuficiente` | `Apenas super admins podem deletar organizações.` | destructive | Tentar abrir exclusão sem ser super admin |
| 3 | `Organização protegida` | `'<slug>' é protegida e não pode ser deletada.` | destructive | Re-checagem no submit |
| 4 | `Permissão insuficiente` | `Apenas super admins podem deletar organizações.` | destructive | Re-checagem no submit |
| 5 | `Organização excluída` | `<nome> foi excluída com sucesso. O schema permanece no banco para recuperação manual se necessário.` | default | Exclusão concluída |
| 6 | `Erro ao excluir organização` | `<mensagem>` ou `Tente novamente` | destructive | Falha na exclusão |
| 7 | `Campos obrigatórios` | `Preencha nome e slug.` | destructive | Criação sem nome/slug |
| 8 | `Slug inválido` | `Use apenas letras minúsculas, números e underscore. Comece com letra.` | destructive | Slug fora do regex |
| 9 | `Slug reservado` | `'<slug>' é reservado pelo sistema. Evite nomes como admin, auth, public, storage, dev, prod e prefixos pg_/org_/supabase_.` | destructive | Slug reservado |
| 10 | `Email inválido` | `Formato de email do owner adicional é inválido.` | destructive | E-mail do owner mal formado |
| 11 | `Organização criada` **ou** `Organização criada — atenção` | mensagens compostas (ver §5.6, Modal 1) | default | Criação concluída |
| 12 | `Erro ao criar organização` | `<mensagem>` ou `Tente novamente.` | destructive | Falha na criação |
| 13 | `Erro ao carregar schemas` | `<mensagem>` ou `Tente novamente` | destructive | Falha no `fetchSchemas` |
| 14 | `Schema removido` | `data.message` (backend) | default | Schema excluído |
| 15 | `Erro ao remover schema` | `<mensagem>` ou `Tente novamente` | destructive | Falha ao remover schema |

### 5.9 Fluxos de uso passo a passo

**Fluxo A — seleção simples (usuário comum)**
1. Após login, o `RequireOrg` manda para `/select-organization` (ou o OAuth do Google cai direto aqui).
2. Spinner enquanto `fetchOrganizations` roda.
3. Grid de cards aparece.
4. Usuário clica no card (ou no botão “Acessar”).
5. `selectOrganization(orgId)`:
   - busca `role` em `organization_users` com `.maybeSingle()`;
   - grava `currentOrg`, `currentRole`, cria o `orgClient` para `org_<slug>`;
   - persiste o id em `localStorage["torre-controle-current-org"]`;
   - atualiza o header `X-Active-Org`;
   - **se for troca de org** (já havia uma selecionada), executa `queryClient.removeQueries()` + `invalidateQueries()` para não vazar cache de outro tenant.
6. `navigate(redirectTo)` — o deep-link de `state.from`, ou `/`.

**Fluxo B — restauração automática (F5)**
1. Usuário dá F5 em qualquer rota do app.
2. `fetchOrganizations` lê `localStorage` e, achando a org salva, **restaura sozinho** `currentOrg`/`currentRole`/`orgClient`.
3. `needsOrgSelection` fica `false` e **a tela de seleção nem aparece**.
4. Se o id salvo não existir no banco atual (ex.: localStorage de PROD sendo usado em DEV), o código **remove** a chave e o usuário cai nesta tela.

**Fluxo C — usuário sem organização**
1. Login bem-sucedido, `organizations.length === 0`.
2. Tela de boas-vindas com “Você ainda não faz parte de nenhuma organização”.
3. Única ação disponível: “Sair da conta”.

**Fluxo D — criar organização (super admin)**
1. Clica no card tracejado.
2. Modal abre com tipo “Cobrança” pré-selecionado.
3. Digita o nome — o slug é gerado automaticamente a cada tecla.
4. (Opcional) ajusta o slug, escolhe “Formalização”, informa e-mail de outro owner.
5. Clica em “Criar Organização”.
6. As 4 validações rodam em ordem; a primeira falha vira toast e aborta.
7. EF `create-org-schema` é chamada.
8. Toast de resultado (com ou sem “atenção”).
9. Modal fecha, campos são limpos.
10. Poll de até 8 tentativas por `refreshOrganizations`.
11. Quando a org nova aparece na lista, o `useEffect` a seleciona e navega para `/`.
12. Se o poll esgotar, a org fica em `pendingSelectOrgId` e será selecionada quando o estado atualizar — ou o usuário clica manualmente no card.

**Fluxo E — excluir organização (super admin)**
1. Passa o mouse sobre um card não protegido → a lixeira aparece (fade-in).
2. Clica na lixeira (`stopPropagation` evita selecionar a org).
3. Guards 1 e 2 rodam. Se passarem, o `AlertDialog` abre com os dois campos vazios.
4. Digita o **nome exato** e o **slug exato**. Enquanto qualquer um divergir, o botão fica desabilitado.
5. Clica em “Excluir Organização”.
6. Guards 3, 4 e 5 rodam.
7. EF `unexpose-org-schema` (falha não bloqueia) → delete de `organization_users` → delete de `organizations`.
8. Toast de sucesso explicando que o schema permanece.
9. Modal fecha e a lista é recarregada.
10. O schema agora é órfão e aparecerá no painel de schemas após “Atualizar”.

**Fluxo F — limpar schema órfão**
1. Rola até “Gerenciar Schemas (Super Admin)”.
2. Clica em “Atualizar” (botão vira `Loader2`).
3. EF `manage-orphan-schemas {action:"list"}` devolve `orphan_schemas` e `active_schemas`.
4. Órfãos aparecem em blocos vermelhos com botão “Remover”; ativos aparecem como badges monoespaçados.
5. Clica em “Remover” → `AlertDialog` de confirmação.
6. Digita o nome exato do schema → botão libera.
7. EF `manage-orphan-schemas {action:"drop", schema_name}`.
8. Toast `Schema removido` com a mensagem do backend; a lista é recarregada.

**Fluxo G — sair**
1. Clica em “Sair” (header) ou “Sair da conta” (estado vazio).
2. `signOut()` → `navigate("/login")`.
3. **Sem confirmação.** O `OrganizationContext` limpa orgs, `orgClient` e o header `X-Active-Org`.

**Fluxo H — membership revogada / race**
1. Usuário clica num card cuja membership não existe mais (ou ainda não propagou).
2. `.maybeSingle()` devolve `null`.
3. O código loga um `console.warn` sem PII, **não** seta `currentOrg`, e remove a chave do `localStorage` se ela apontar para essa org.
4. **Nenhum feedback visual é dado** — a tela simplesmente não navega. O usuário clica e nada acontece.

### 5.10 Responsividade e acessibilidade observadas

Responsividade:
- Container `p-4 md:p-8` e `max-w-6xl`.
- Grid de orgs: `grid gap-4 md:grid-cols-2 lg:grid-cols-3` — 1 coluna no mobile, 2 em ≥768px, 3 em ≥1024px.
- Grid de KPIs: `md:grid-cols-2 lg:grid-cols-4`.
- `OrgProfileSelector`: `grid gap-3 sm:grid-cols-2` — empilha no mobile.
- **Header não colapsa**: `flex items-center justify-between` sem `flex-wrap`. Com logo + saudação + botão “Sair”, telas muito estreitas podem comprimir os elementos.
- As linhas do breakdown por organização são `flex justify-between` sem wrap — nomes longos podem espremer os números.
- Os modais usam o `DialogContent` padrão do shadcn (largura `max-w-lg` com `w-full`), adequado ao mobile.

Acessibilidade:
- **A lixeira só aparece no hover** (`opacity-0 group-hover:opacity-100`). Em **touch** não há hover; e mesmo com `opacity-0` o botão continua na ordem de tabulação, focável mas **invisível**. É a falha de acessibilidade mais séria da tela.
- **Cards clicáveis são `<div>`** (`Card` com `onClick`): sem `role="button"`, sem `tabIndex`, sem handler de teclado. **Não é possível selecionar uma organização usando apenas o teclado** — exceto pelo botão “Acessar” interno, que é um `<button>` real, mas **não tem `onClick` próprio** e depende da propagação do evento. Na prática, focar o botão e pressionar Enter dispara um clique que borbulha até o card, então funciona — porém por acidente, não por desenho.
- O avatar colorido usa **texto branco sobre `org.primary_color` arbitrário** — contraste não garantido.
- O ícone `Trash2` está em um botão **sem `aria-label`** e sem texto — leitor de tela anuncia “botão” sem mais.
- Ícones decorativos (`Crown`, `Building2`, `TrendingUp`, `Database`, `AlertCircle`) sem `aria-hidden`.
- O `OrgProfileSelector` usa `RadioGroup` do Radix (semântica correta), mas o `<Label>` externo que embrulha o `Card` não tem `htmlFor` — o clique funciona por aninhamento.
- Os campos de confirmação dos modais destrutivos **não têm `<Label>`** — só um `<p>` acima e o `placeholder`.
- As listas de schemas são `div`s, não `<ul>/<li>`.
- Loading anunciado só visualmente.
- A `<div>` vazia no header (linha 534) é ruído no DOM.

### 5.11 Dores e oportunidades para o redesign

1. **Super admin sem organização fica sem saída.** O early return do estado vazio acontece **antes** de qualquer checagem de `isSuperAdmin`, então ele não vê o cartão de criar organização nem os painéis administrativos. Bug estrutural de layout.
2. **Erro de rede é apresentado como estado vazio.** `fetchOrganizations` engole a exceção e devolve `[]` → o usuário lê “Você ainda não faz parte de nenhuma organização” quando o problema foi o backend. Deveria haver um estado de erro com “Tentar novamente”.
3. **Clique que não faz nada.** No caso de membership ausente (Fluxo H), a tela não dá **nenhum** retorno visual.
4. **“(Em breve)” é copy enganosa.** Não é roadmap — é restrição de papel. Deveria dizer algo como “Disponível apenas para administradores da plataforma”.
5. **Acessibilidade por teclado quebrada** nos cards e na lixeira oculta por hover (ver §5.10).
6. **Reset incompleto no “Cancelar” do modal de criação:** nome e slug persistem; e-mail e tipo são limpos. Comportamento incoerente.
7. **Auto-geração do slug sobrescreve edição manual** a cada tecla no nome — se o usuário ajusta o slug e depois corrige o nome, perde o ajuste.
8. **Acentuação inconsistente.** Boa parte dos textos administrativos está sem acento (“Visao Consolidada”, “organizacoes”, “Voce continua como owner”, “Media geral”), enquanto o resto da tela é acentuado. Precisa de normalização no redesign.
9. **Descrição do KPI “Contratos Ativos” está errada:** diz “Com parcelas pendentes”, mas a query filtra `status = "active"`.
10. **Painel de schemas não carrega sozinho.** Exige clicar em “Atualizar” — um passo extra sem razão aparente para o usuário.
11. **Três níveis de destrutividade sem hierarquia visual clara:** excluir org (irreversível, duplo confirm), excluir schema (irreversível, confirm simples) e sair (sem confirm) usam a mesma linguagem de botão.
12. **A exclusão de organização não é atômica** — três chamadas sequenciais, e a falha da primeira é ignorada. Se a segunda falhar, a org fica meio excluída, sem rollback nem aviso.
13. **`useConsolidatedStats` faz N×4 requisições em paralelo** (uma por org, 4 queries cada), incluindo um `select` de **todas** as linhas de `titles` sem paginação. Com muitas orgs, a tela de seleção vira a página mais cara do app.
14. **Tela sobrecarregada de responsabilidades.** É simultaneamente: seletor de tenant, console de plataforma, dashboard executivo e ferramenta de manutenção de banco. O redesign deveria separar “escolher org” de “administrar a plataforma”.
15. **A faixa de Super Admin tem texto tecnicamente incorreto** — “(owner em todas as organizações)”. O próprio guia de negócio corrige: “ser Super Admin não decorre de ter papel de Proprietário (owner) em cada organização: é uma marcação global da plataforma”.
16. **Sem busca/filtro na lista de organizações.** Com dezenas de orgs, o grid vira rolagem.
17. **Sem indicação de qual org estava selecionada antes** — nenhum destaque de “última usada”, embora o dado exista no `localStorage`.
18. **Sem confirmação no logout.**
19. **`<div>` vazia no header** — resíduo de um título removido; o card perdeu o título principal e ficou só com a saudação.
20. **Sem branding por organização no card.** `org.logo_url` existe no modelo `Organization` mas **não é usado** — o card mostra apenas a inicial sobre a `primary_color`. Oportunidade direta de white-label.

---

## 6. Componentes e mecanismos transversais deste domínio

### 6.1 `OrgProfileSelector`

**Arquivo:** `src/components/organization/OrgProfileSelector.tsx`
**Usado em:** modal “Criar Nova Organização” (`SelectOrganizationPage`) e aba “Perfil da Operação” de Configurações (`src/components/settings/tabs/PipelineProfileTab.tsx`, fora do escopo deste documento).

**Props:**

| Prop | Tipo | Obrigatória | Efeito |
|---|---|---|---|
| `value` | `OrgProfileChoice` (`"cobranca" \| "formalizacao"`) | Sim | Opção marcada |
| `onChange` | `(value: OrgProfileChoice) => void` | Sim | Callback do RadioGroup |
| `disabled` | `boolean` | Não | Aplica `cursor-not-allowed opacity-50` nos cards e desabilita os radios |
| `showCreationNote` | `boolean` (default `false`) | Não | Exibe a terceira linha de texto (`creationNote`) — usada **só** na criação de org |

**Anatomia:** `RadioGroup` do Radix com `className="grid gap-3 sm:grid-cols-2"`. Cada opção é um `<Label>` (cursor-pointer) envolvendo um `<Card className="h-full p-4 transition-all">`. Card selecionado recebe `border-primary bg-primary/5 ring-1 ring-primary`; não selecionado recebe `hover:bg-muted/50`.

Dentro do card (`flex items-start gap-3`):
1. `RadioGroupItem` com `className="mt-1"`.
2. Bloco de texto (`flex-1`):
   - Linha com ícone (16×16, `text-muted-foreground`) + label (`text-sm font-medium`).
   - Descrição (`mt-1 text-xs text-muted-foreground`).
   - `creationNote` (`mt-2 text-xs text-muted-foreground/90`), condicional.

**Ícones:** `cobranca` → lucide `Banknote`; `formalizacao` → lucide `FileSignature`.

**Conteúdo textual canônico** (fonte única: `ORG_PROFILE_CHOICES` em `src/hooks/useOrgPipelineProfile.ts`):

| `value` | `label` | `description` | `creationNote` |
|---|---|---|---|
| `cobranca` | `Cobrança` | `Réguas disparam por dias de atraso de títulos. É o comportamento de todas as organizações de hoje.` | `Nada a configurar depois: a organização já nasce pronta para cobrar.` |
| `formalizacao` | `Formalização` | `Réguas podem disparar por etapa da negociação e enviar para um destinatário próprio (ex.: o vendedor), sem exigir título em aberto.` | `As convenções (qual campo carrega a etapa, a data de referência e o contato do destinatário) são definidas DEPOIS, em Configurações › Perfil da Operação — a fonte de dados e o pipeline ainda não existem agora. Até lá a organização não dispara régua nenhuma.` |

**Semântica importante:** `"cobranca"` **não é um valor da coluna `profile`** no banco — é a **ausência** de linha em `public.org_pipeline_profile`. A conversão é feita por `choiceToProfile()` (devolve `null` para cobrança) e `profileToChoice()`.

Comentário no código registra a intenção de design: “Forma visual copiada do `EntityKindSelector` (RadioGroup + Card + ícone + descrição), para as duas escolhas estruturais do produto se parecerem.” O redesign deve preservar essa família visual.

### 6.2 `usePendingInvitations` — aceite automático e invisível

**Arquivo:** `src/hooks/useAcceptPendingInvitations`… (nome real: `src/hooks/usePendingInvitations.ts`)
**Montado em:** `src/contexts/OrganizationContext.tsx` (linhas 340–348) — ou seja, **em toda a aplicação**, sempre que houver usuário autenticado.

**Contrato:**
```ts
usePendingInvitations(onInvitationsAccepted?: () => void)
  : { isProcessing: boolean; processedCount: number; error: string | null }
```

**Comportamento:**
1. Roda num `useEffect` disparado por mudança de `user.id`/`user.email`.
2. Busca em `user_invitations`: `email = user.email`, `status = "pending"`, `expires_at > agora`.
3. Para **cada** convite encontrado, chama `rpc("accept_invitation", { p_invitation_token: token })`.
4. Erros individuais são **logados e pulados** (`continue`) — nunca interrompem o laço.
5. Se ao menos um foi aceito, chama o callback, que dispara `fetchOrganizations()`.
6. Um `useRef` (`invitationsProcessedRef`) garante que o refresh só aconteça **uma vez por sessão**, resetado quando o `user.id` muda.

**Impacto de UX — e é grande:** o hook **não tem nenhuma superfície visual**. Nenhum toast, nenhum badge, nenhuma tela. Um usuário pode:
- fazer login normalmente e, sem nada explicar, encontrar uma organização nova no seletor;
- abrir o link de convite e ver “Você já é membro”, porque o hook já aceitou o convite antes;
- ter **vários** convites aceitos de uma vez, silenciosamente.

Os três valores retornados (`isProcessing`, `processedCount`, `error`) são **descartados** pelo `OrganizationContext`, que passa apenas o callback.

**Oportunidade clara para o redesign:** expor esse processamento. Um toast “Você entrou em 2 novas organizações”, um badge “Novo” nos cards recém-adicionados, ou um indicador de “processando convites” usariam dados que **já existem** e hoje são jogados fora.

### 6.3 Guards de rota

**Arquivo:** `src/App.tsx`.

| Guard | Condição de bloqueio | Destino | Fallback de loading |
|---|---|---|---|
| `ProtectedRoute` | `!user` (após `isLoading` do Auth) | `/login` com `state={{ from: location }}` | `<PageLoader />` |
| `RequireOrg` (memoizado) | `needsOrgSelection` (tem orgs, nenhuma selecionada) | `/select-organization` com `state={{ from }}` (preservando um `from` herdado que não seja `/`) | Spinner inline (borda girando) |
| `RequirePermission` | `!hasPermission(permission)` | `/` (dashboard) — **sem mensagem** | `<PageLoader />` |
| `RequireDocs` | `!isSuperAdmin && !hasPermission(permission)` | `/central-docs` | `<PageLoader />` |

`PageLoader`: `flex h-screen items-center justify-center` com `animate-spin rounded-full h-8 w-8 border-b-2 border-primary` — um círculo de borda, **diferente** do `Loader2` do lucide usado nas outras telas. Terceiro estilo de loading no mesmo produto.

**Ponto de UX relevante:** `RequirePermission` redireciona **em silêncio** para o dashboard. Um `viewer` que recebe o link de `/etl` simplesmente “cai” na home, sem entender por quê. Oportunidade: uma tela “Sem permissão” explicando o papel necessário — usando a matriz da §1.

`effectiveIsLoading` (`OrganizationContext`, linha 457) é o que impede o falso negativo de permissão durante o F5: `isLoading || (!!user?.id && loadedUserId !== user.id)`. O redesign não pode simplificar isso sem reintroduzir o bug de “F5 em rota gated derruba para a home”.

### 6.4 Persistência e efeitos colaterais da seleção de org

| Efeito | Onde | Detalhe |
|---|---|---|
| `localStorage["torre-controle-current-org"]` | `OrganizationContext` | Guarda o `orgId`. Restaurado no `fetchOrganizations`. Removido se o id não existir mais no banco |
| Header HTTP `X-Active-Org` | `setActiveOrgSlug(slug)` | Interceptor de fetch; limpo no logout e quando não há org |
| `orgClient` | `createOrgClient(slug)` | Cliente Supabase apontando para o schema `org_<slug>` |
| Cache do React Query | `queryClient.removeQueries()` + `invalidateQueries()` | **Só na troca real de org** (não na primeira seleção nem no restore). Impede vazamento de dados entre tenants |

Para o redesign: qualquer mudança no “trocar de organização” (por exemplo, um seletor na topbar em vez desta tela) **precisa** manter esses quatro efeitos juntos.

---

## X. Inventário de modais deste domínio

| # | Modal / sobreposição | Arquivo | Aberto por | Tipo (componente) | Permissão | Confirmação destrutiva |
|---|---|---|---|---|---|---|
| 1 | **Criar Nova Organização** | `src/pages/SelectOrganizationPage.tsx` (linhas 644–717) | Clique no card tracejado “Criar nova organização” (só com `onClick` se `isSuperAdmin`) | `Dialog` (shadcn/ui) | `isSuperAdmin` | Não |
| 2 | **Excluir Organização** | `src/pages/SelectOrganizationPage.tsx` (linhas 720–766) | Ícone `Trash2` no card da organização (`handleOpenDeleteDialog`) | `AlertDialog` (shadcn/ui) | `isSuperAdmin` **e** slug não protegido | Sim — **duplo confirm**: digitar nome exato **e** slug exato |
| 3 | **Excluir Schema** | `src/pages/SelectOrganizationPage.tsx` (linhas 1017–1051, dentro de `OrphanSchemasManager`) | Botão “Remover” de um schema órfão | `AlertDialog` (shadcn/ui) | `isSuperAdmin` (o painel inteiro é gated) | Sim — digitar o nome exato do schema |

**Telas que não têm nenhum modal:** `/login`, `/signup`, `/accept-invite`.

**Sobreposições não-modais presentes no domínio:**

| Elemento | Onde | Observação |
|---|---|---|
| Toast (`Toaster` global) | AcceptInvite (8 toasts) e SelectOrganization (15 toasts) | `TOAST_LIMIT = 1`, `TOAST_REMOVE_DELAY = 3000 ms`. Login e SignUp **não** usam toast |
| Balão nativo de validação do browser | AcceptInvite (campos com `required`/`minLength`) | Não é controlado pelo design system; idioma do SO |

**“Pseudo-modais” — trocas de tela inteira que substituem o conteúdo (early returns):**

| # | Tela substituta | Arquivo | Disparada por |
|---|---|---|---|
| 1 | “Conta criada!” | `SignUpPage.tsx` (linhas 99–124) | `success === true` |
| 2 | Carregando (spinner puro) | `AcceptInvitePage.tsx` (424–430) | `isLoading` |
| 3 | “Convite Inválido” | `AcceptInvitePage.tsx` (432–449) | `error` |
| 4 | “Convite Aceito!” | `AcceptInvitePage.tsx` (451–465) | `success` |
| 5 | “Você já é membro” | `AcceptInvitePage.tsx` (467–483) | `alreadyMemberMsg` |
| 6 | “Conta diferente” | `AcceptInvitePage.tsx` (488–521) | `mode === "wrong-session"` |
| 7 | Loading da seleção de org | `SelectOrganizationPage.tsx` (484–488) | `isLoading` |
| 8 | “Bem-vindo ao Torre de Controle” (sem orgs) | `SelectOrganizationPage.tsx` (491–526) | `organizations.length === 0` |

Para o redesign: essas oito trocas de tela **têm o mesmo peso funcional de um modal** (bloqueiam a tarefa e exigem uma ação para sair), mas nenhuma delas é implementada como sobreposição. Qualquer arquitetura nova precisa cobrir as três (modais) **mais** as oito (pseudo-modais) — onze estados bloqueantes no total.

---

## Apêndice A — Inventário completo de strings do domínio

Agrupadas por arquivo, para facilitar a revisão de copy no redesign.

### A.1 `LoginPage.tsx`
`Torre de Controle` · `Entre com suas credenciais para acessar o sistema` · `E-mail` · `seu@email.com` · `Senha` · `••••••••` · `Entrar` · `Entrando...` · `ou` · `Continuar com Google` · `Conectando...` · `Não tem uma conta? ` · `Criar conta` · `Email inválido` · `A senha deve ter pelo menos 6 caracteres`

### A.2 `SignUpPage.tsx`
`Criar Conta` · `Crie sua conta para acessar o Torre de Controle` · `Nome Completo` · `Seu nome completo` · `E-mail` · `seu@email.com` · `Senha` · `Mínimo 6 caracteres` · `Confirmar Senha` · `Digite a senha novamente` · `Criando conta...` · `ou` · `Continuar com Google` · `Conectando...` · `Já tem uma conta? ` · `Fazer login` · `Conta criada!` · `Verifique seu email para confirmar a conta e depois faça login.` · `Ir para Login` · `Nome deve ter pelo menos 2 caracteres` · `Email inválido` · `A senha deve ter pelo menos 6 caracteres` · `As senhas não coincidem` · `Este email já está cadastrado. Faça login ou use outro email.`

### A.3 `AcceptInvitePage.tsx`
`Aceitar Convite` · `Convite Inválido` · `Convite Aceito!` · `Você já é membro` · `Conta diferente` · `Token de convite não encontrado` · `Convite inválido ou não encontrado` · `Este convite já foi aceito` · `Este convite expirou` · `Erro ao validar convite` · `Você já faz parte de <org>.` · `esta organização` · `a organização` · `Você está logado como <email>, mas este convite é para <email>. Saia da conta atual para continuar.` · `Sair e continuar` · `Saindo...` · `Ir para Login` · `Você foi convidado para <org> como <role>. Você já está logado como <email>.` · `Entrar na organização` · `Entrando...` · `Esse e-mail já tem conta na Torre. Entre com sua senha para aceitar o convite para <org> como <role>.` · `E-mail` · `Senha` · `Sua senha` · `Entrar e Aceitar Convite` · `Você foi convidado para <org> como <role>` · `Nome Completo` · `Seu nome completo` · `Mínimo 6 caracteres` · `Confirmar Senha` · `Digite a senha novamente` · `Criar Conta e Aceitar Convite` · `Criando conta...` · `Você agora faz parte da organização. Você será redirecionado para o login...` · `Convite aceito com sucesso!` · `Você já pode acessar a organização.` · `Erro` · `Informe sua senha.` · `As senhas não coincidem` · `A senha deve ter pelo menos 6 caracteres` · `Conta já existe` · `Esse e-mail já tem conta na Torre. Entre com sua senha para aceitar o convite.` · `Erro ao aceitar convite` · `Erro ao criar conta` · `Erro ao sair` · `Tente novamente` · `Sessão expirada. Faça login novamente.` · `E-mail ou senha inválidos.` · `Não foi possível autenticar. Tente novamente.` · `Erro ao criar usuário` · `Convite inválido, expirado ou email não confere` · `Erro ao aceitar convite`

### A.4 `SelectOrganizationPage.tsx`
`Olá, <usuário>!` · `Sair` · `Você é Super Admin (owner em todas as organizações)` · `Selecione uma organização` · `Escolha a organização que deseja acessar` · `Acessar` · `Criar nova organização` · `(Em breve)` · `Bem-vindo ao Torre de Controle` · `Você ainda não faz parte de nenhuma organização` · `Aguarde um convite de um administrador ou entre em contato com sua empresa para solicitar acesso.` · `Sair da conta` · `Proprietário` · `Administrador` · `Gerente` · `Operador` · `Visualizador` · `Visao Consolidada (Super Admin)` · `KPIs agregados de todas as <N> organizacoes` · `Total de Contatos` · `Em todas as organizacoes` · `Contratos Ativos` · `Com parcelas pendentes` · `Campanhas Ativas` · `Em execucao` · `Taxa de Recuperacao` · `Media geral` · `Por Organizacao` · `Gerenciar Schemas (Super Admin)` · `Gerencie schemas órfãos (schemas de organizações excluídas)` · `Atualizar` · `Clique em "Atualizar" para carregar a lista de schemas` · `Schemas Órfãos (<n>)` · `Sem organização correspondente` · `Remover` · `Schemas Ativos (<n>)` · `✓ Nenhum schema órfão encontrado` · `Criar Nova Organização` · `Preencha os dados abaixo para criar uma nova organização.` · `Nome da Organização` · `Ex: Minha Empresa` · `Slug (identificador único)` · `Ex: minha_empresa` · `Usado para identificar a organização no sistema. Apenas letras minúsculas, números e underscores.` · `Tipo de organização` · `Email de outro owner` · `(opcional)` · `cliente@empresa.com` · `Se preenchido, este email tambem sera owner desta org (orgs podem ter multiplos owners). Voce continua como owner.` · `Cancelar` · `Criar Organização` · `Excluir Organização` · `Esta ação é irreversível. Todos os dados da organização serão excluídos permanentemente.` · `Para confirmar, digite o nome da organização:` · `Digite o nome da organização` · `E digite o slug (identificador único):` · `Digite o slug da organização` · `Excluir Schema` · `Esta ação é irreversível. Todos os dados do schema serão excluídos permanentemente, incluindo tabelas, views, funções e dados.` · `Para confirmar a exclusão, digite o nome do schema:` · `Digite o nome do schema` · (mais os 15 toasts listados em §5.8)

### A.5 `OrgProfileSelector` / `useOrgPipelineProfile.ts`
`Cobrança` · `Réguas disparam por dias de atraso de títulos. É o comportamento de todas as organizações de hoje.` · `Nada a configurar depois: a organização já nasce pronta para cobrar.` · `Formalização` · `Réguas podem disparar por etapa da negociação e enviar para um destinatário próprio (ex.: o vendedor), sem exigir título em aberto.` · `As convenções (qual campo carrega a etapa, a data de referência e o contato do destinatário) são definidas DEPOIS, em Configurações › Perfil da Operação — a fonte de dados e o pipeline ainda não existem agora. Até lá a organização não dispara régua nenhuma.`

---

## Apêndice B — Checklist de paridade para o redesign

Marcar cada item significa “a nova interface cobre isso”.

**Autenticação**
- [ ] Login por e-mail + senha, com validação PT-BR (e-mail inválido, senha < 6)
- [ ] Login por Google OAuth com whitelist de origens e `redirectTo` para `/select-organization`
- [ ] Banner de erro com a mensagem do backend
- [ ] Desabilitar ambos os botões durante qualquer loading
- [ ] Cadastro com 4 campos, incluindo confirmação de senha e `full_name` como metadata
- [ ] Tratamento do erro “e-mail já cadastrado” com texto PT-BR
- [ ] Tela de sucesso “Conta criada!” com CTA para o Login
- [ ] Links cruzados Login ↔ Criar conta

**Convite**
- [ ] Validação do token via RPC executável por usuário anônimo
- [ ] Os 4 modos: `signup`, `login`, `session-match`, `wrong-session`
- [ ] Detecção proativa de conta existente (`account_exists`)
- [ ] Rede de segurança do 422 (“Conta já existe” → troca para modo login e limpa senhas)
- [ ] E-mail sempre travado e pré-preenchido
- [ ] Exibição da organização e do papel do convite
- [ ] Checagem de “já é membro” **antes** de chamar `accept_invitation`
- [ ] Auto-confirmação do e-mail via Edge Function no modo signup
- [ ] Os 5 motivos distintos de convite inválido
- [ ] “Sair e continuar” no modo `wrong-session`
- [ ] Redirecionamento pós-sucesso (hoje `/login` após 2 s)

**Organização**
- [ ] Grid de cards com avatar colorido, papel, nome, slug e ação de acessar
- [ ] Card inteiro clicável **e** acessível por teclado
- [ ] Estado vazio “sem organizações” com saída (logout)
- [ ] Faixa e capacidades de Super Admin
- [ ] Criação de organização com nome, slug auto-gerado, tipo (Cobrança/Formalização) e owner adicional
- [ ] As 4 validações de criação, na ordem, com os textos exatos
- [ ] Toast composto de resultado da criação (7 combinações de mensagem)
- [ ] Poll pós-criação com backoff e auto-seleção
- [ ] Exclusão de organização com duplo confirm (nome + slug) e as 5 guardas
- [ ] Proteção do slug `blips`
- [ ] Painel Visão Consolidada com 4 KPIs e breakdown por org
- [ ] Painel Gerenciar Schemas com listagem, órfãos, ativos e exclusão confirmada
- [ ] Botão Sair no header e no estado vazio

**Transversal**
- [ ] Matriz RBAC completa (47 permissões × 5 papéis) preservada em `ROLE_PERMISSIONS`
- [ ] `isSuperAdmin` como eixo ortogonal aos papéis
- [ ] Deep-link `state.from` atravessando Login → `/` → seleção de org → rota original
- [ ] Persistência da org em `localStorage` + header `X-Active-Org` + `orgClient` + limpeza de cache na troca
- [ ] Aceite automático de convites pendentes (hoje invisível — considerar expor)
- [ ] Guards `ProtectedRoute`, `RequireOrg`, `RequirePermission`, `RequireDocs` e o `effectiveIsLoading`
