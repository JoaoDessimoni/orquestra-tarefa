---
name: jira
description: Conhecimento canônico do Jira/Confluence da Finza, acessível via MCP Atlassian (server "claude_ai_Atlassian"). Define o catálogo de ferramentas Jira + Confluence, a descoberta de site/projetos (cloudId, project keys), o modelo de transições dinâmicas por projeto, noções de JQL e CQL, regras de criação de issue e as ações de escrita que confirmam antes. Carregue antes de qualquer operação no Jira/Confluence para não fabricar cloudId, project key, issue type ou accountId.
---

# Skill — Jira & Confluence (Atlassian via MCP)

O **Jira** é a ferramenta de gestão de issues da Atlassian usada pela Finza; o **Confluence** é a base de páginas/documentação do mesmo ecossistema. Ambos são acessíveis pelo servidor **MCP `claude_ai_Atlassian`** — as ferramentas aparecem como `mcp__claude_ai_Atlassian__<nome>`. **As permissões são as da conta autenticada** (o que o agente lê/escreve é o nível de acesso do João Vinícius no site Atlassian).

> **Jira ≠ Quimera ≠ Backlog/.**
> - **Jira** (esta skill) = ferramenta Atlassian externa (issues + Confluence), via MCP `claude_ai_Atlassian`.
> - **Quimera** (skill `quimera`) = sistema de tickets **interno** da Finza, via MCP `quimera`. **Os dois convivem** — são sistemas distintos; não confunda nem cruze IDs.
> - **`Backlog/`** = backlog **estratégico interno** do squad (`.md`, RICE). Um item de `Backlog/` pode *referenciar* uma issue Jira, mas não são a mesma coisa. Não confunda `/jira` com `/backlog`.

> ⚠️ **Caveat de autenticação.** O MCP Atlassian é autenticado interativamente (via claude.ai). Em execuções **headless/cron** ele pode não estar disponível. Se uma tool `mcp__claude_ai_Atlassian__*` não responder ou retornar erro de auth, reporte como provável ausência/limite de sessão — não como bug. (Análogo à nota de permissão da skill `quimera`.)

---

## 1 · Identidade do site e descoberta (anti-fabricação)

**Nunca hardcode `cloudId`, `projectKey`, `issueKey`, `accountId`, `spaceId` ou `pageId`.** O Jira é multi-site e multi-projeto; todo identificador deve ser **descoberto ao vivo** antes do uso:

| Para descobrir... | Use |
|---|---|
| sites Atlassian acessíveis + `cloudId` | `getAccessibleAtlassianResources` |
| quem é a conta autenticada (accountId, e-mail) | `atlassianUserInfo` |
| projetos Jira visíveis (key, id, nome) | `getVisibleJiraProjects` |
| accountId de uma pessoa pelo nome/e-mail | `lookupJiraAccountId` |
| espaços Confluence | `getConfluenceSpaces` |
| issue types + campos obrigatórios de um projeto | `getJiraProjectIssueTypesMetadata`, `getJiraIssueTypeMetaWithFields` |
| transições válidas de uma issue | `getTransitionsForJiraIssue` |

A maioria das tools exige `cloudId` como primeiro argumento — resolva-o via `getAccessibleAtlassianResources` no início da sessão (se houver um só site, use-o; se houver vários, confirme qual com o usuário). **Se não souber um valor, descubra — não invente.**

## Projetos canônicos

<!-- TODO: preencher na primeira sessão real com o João. Liste aqui os projetos Jira que o squad IAF usa de fato, no formato:
| Project key | Nome | Quando usar |
|---|---|---|
| ABC | ... | ... |
Enquanto vazio, sempre descubra via getVisibleJiraProjects e confirme com o usuário antes de criar issue. -->

Ainda não mapeado. Até preencher esta seção, **sempre** rode `getVisibleJiraProjects` e confirme o projeto-alvo com o usuário antes de qualquer criação. Não assuma um projeto default.

---

## 2 · Workflow de status — transições são dinâmicas

Diferente do Quimera (que tem um enum fixo de status), no Jira **cada projeto/issue type define seu próprio workflow**. Não existe lista canônica de status que sirva para todo projeto.

Regra dura: **antes de `transitionJiraIssue`, chame `getTransitionsForJiraIssue`** para obter os `transition id`/nomes válidos *naquela* issue *naquele* momento. Use o id/nome retornado — nunca um status inventado. Mudar status pode disparar notificações/automações (efeito externo — ver §7).

---

## 3 · Catálogo de ferramentas — Jira

### Descoberta / contexto
- **`getAccessibleAtlassianResources`** — sites acessíveis + `cloudId`. Ponto de partida de toda sessão.
- **`atlassianUserInfo`** — dados da conta autenticada.
- **`getVisibleJiraProjects`** — projetos visíveis (key, id, nome). Aceita busca/paginação.
- **`lookupJiraAccountId`** — resolve `accountId` por nome/e-mail (para `assignee`).
- **`getJiraProjectIssueTypesMetadata`** — issue types de um projeto.
- **`getJiraIssueTypeMetaWithFields`** — campos (e quais são obrigatórios) de um issue type. Use **antes de criar** para montar payload válido.
- **`getIssueLinkTypes`** — tipos de vínculo entre issues (ex.: "blocks", "relates to").

### Issues — consulta
- **`searchJiraIssuesUsingJql`** — busca por JQL (ver §5). Principal ferramenta de leitura.
- **`getJiraIssue`** — uma issue por `issueIdOrKey` (ex.: `ABC-123`). Traz campos, comentários, transições recentes.
- **`getJiraIssueRemoteIssueLinks`** — links remotos (ex.: para Confluence, PRs).

### Issues — escrita (efeito externo — §7)
- **`createJiraIssue`** — cria issue. Requer `cloudId`, `projectKey`, `issueTypeName`, `summary`; campos extra conforme metadata. Valide com `getJiraIssueTypeMetaWithFields` antes.
- **`editJiraIssue`** — edita campos de uma issue existente.
- **`transitionJiraIssue`** — muda status (use `getTransitionsForJiraIssue` antes).
- **`addCommentToJiraIssue`** — adiciona comentário (visível conforme permissão da issue).
- **`addWorklogToJiraIssue`** — registra tempo trabalhado.
- **`createIssueLink`** — vincula duas issues por um link type.

---

## 4 · Catálogo de ferramentas — Confluence

### Leitura
- **`getConfluenceSpaces`** — espaços disponíveis (id, key, nome).
- **`getPagesInConfluenceSpace`** — páginas de um espaço.
- **`getConfluencePage`** — conteúdo de uma página por id.
- **`getConfluencePageDescendants`** — sub-árvore de páginas.
- **`getConfluencePageFooterComments`** / **`getConfluencePageInlineComments`** — comentários.
- **`searchConfluenceUsingCql`** — busca por CQL (ver §5).

### Escrita (efeito externo — §7)
- **`createConfluencePage`** — cria página (requer space + título + corpo).
- **`updateConfluencePage`** — edita página existente (requer versão atual).
- **`createConfluenceFooterComment`** / **`createConfluenceInlineComment`** — comenta numa página.

> Uso típico do Confluence no workspace: **puxar specs/docs de negócio** para lastrear itens de backlog e apresentações (leitura). Escrita em Confluence é rara — confirme sempre.

---

## 5 · JQL e CQL — noções rápidas

**JQL** (Jira Query Language) para `searchJiraIssuesUsingJql`:
- `project = ABC` — filtra projeto.
- `assignee = currentUser()` — minhas issues. `assignee was currentUser()` para histórico.
- `status = "In Progress"` / `status in ("To Do","In Progress")`.
- `updated >= -7d` / `created >= startOfWeek()` — recência.
- `text ~ "termo"` — busca textual.
- Ordenação: `ORDER BY updated DESC`.
- Combinação: `project = ABC AND assignee = currentUser() AND status != Done ORDER BY priority DESC`.

**CQL** (Confluence Query Language) para `searchConfluenceUsingCql`:
- `space = "DEV"`, `title ~ "Esperanza"`, `text ~ "renegociação"`, `type = page`, `lastModified >= now("-14d")`.

---

## 6 · Regras de criação de issue (anti-fabricação)

1. **`cloudId` resolvido** via `getAccessibleAtlassianResources` (nunca inventado).
2. **`projectKey` confirmado** via `getVisibleJiraProjects` (e com o usuário, enquanto a seção "Projetos canônicos" estiver vazia).
3. **`issueTypeName` válido** para o projeto (via `getJiraProjectIssueTypesMetadata`).
4. **Campos obrigatórios** montados a partir de `getJiraIssueTypeMetaWithFields` — não chute custom fields.
5. **`assignee` é `accountId`**, não e-mail/nome — resolva via `lookupJiraAccountId`.
6. **`summary` e `description` claros** (descrição com contexto, não só repetição do título).
7. Mostre o payload montado e **confirme antes de criar**.

---

## 7 · Ações com efeito externo (confirme antes)

O Jira/Confluence são sistemas **vivos e compartilhados**. As ferramentas abaixo escrevem neles e podem disparar notificações/automações a terceiros — **confirme com o usuário antes de executar**, salvo autorização explícita na mesma conversa:

- `createJiraIssue`, `editJiraIssue`, `transitionJiraIssue`, `createIssueLink`, `addWorklogToJiraIssue`
- `addCommentToJiraIssue` (comentário visível conforme permissão da issue)
- `createConfluencePage`, `updateConfluencePage`, `createConfluenceFooterComment`, `createConfluenceInlineComment`

Leituras (`get*`, `search*`, `list*`, `getVisible*`, `getAccessible*`) são livres — não pedem confirmação.

---

## 8 · Como esta skill se usa

- Carregada pelo agente **`jira-ops`** e pelo comando **`/jira`**.
- É **índice + regras**, não substitui consultar o estado ao vivo: para issues, campos e transições, sempre chame as tools (o conteúdo muda a cada minuto e o schema varia por projeto).
- Convive com o **Quimera** — se o pedido for sobre o sistema interno de tickets, é caso do `/quimera`; se for sobre `.md` de estratégia, é `/backlog`.
- Se uma tool retornar erro de auth/permissão, reporte ao usuário — pode ser sessão Atlassian expirada ou limite de acesso da conta, não bug.
