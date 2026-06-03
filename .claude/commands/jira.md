---
description: Opera o Jira & Confluence da Finza via MCP Atlassian. Subcomandos — issues/buscar, show, criar, editar, status, comentar, worklog, vincular, projetos, confluence, eu. Descobre site/projetos ao vivo (não inventa cloudId/key/accountId). Convive com o Quimera. Leitura é livre; escrita confirma antes (dispara notificação/automação).
---

# /jira — operar Jira & Confluence (Atlassian)

Roteia para o agente **`jira-ops`**, que usa as ferramentas MCP `mcp__claude_ai_Atlassian__*`. Conhecimento canônico do domínio na skill `jira`.

> **Jira ≠ Quimera ≠ /backlog.** `/jira` opera o Atlassian externo (issues + Confluence). `/quimera` opera o sistema de tickets **interno** da Finza. `/backlog` opera a estratégia interna do squad (`.md`, RICE). **Os três convivem** — não confunda.

> ⚠️ O MCP Atlassian é autenticado via claude.ai (interativo). Em execução headless/cron pode não estar disponível — se as tools não responderem, é provável sessão expirada, não bug.

`$ARGUMENTS` define o subcomando:

| Forma | O que faz |
|---|---|
| `/jira` (vazio) | Snapshot do usuário — resolve site (`getAccessibleAtlassianResources` + `atlassianUserInfo`) e roda `searchJiraIssuesUsingJql` com `assignee = currentUser() AND status != Done ORDER BY updated DESC`. |
| `/jira issues <jql>` | Busca por JQL livre (`searchJiraIssuesUsingJql`). Ex.: `/jira issues project = ABC AND status = "In Progress"`. Equivale a `buscar`. |
| `/jira show <KEY>` | Detalhe de uma issue (`getJiraIssue`) — status, campos, comentários, transições disponíveis, links. |
| `/jira criar "<resumo>"` | Cria issue (`createJiraIssue`). Resolve cloudId, confirma projeto (`getVisibleJiraProjects`), valida issue type + campos (`getJiraIssueTypeMetaWithFields`). Monta o payload e **confirma antes de criar**. |
| `/jira editar <KEY> <campos>` | Edita campos de uma issue (`editJiraIssue`). Confirma antes. |
| `/jira status <KEY> [<transição>]` | Transiciona. **Sempre roda `getTransitionsForJiraIssue` primeiro**; sem transição informada, lista as válidas e pergunta. Confirma antes — dispara notificação. |
| `/jira comentar <KEY> "<texto>"` | Adiciona comentário (`addCommentToJiraIssue`). Confirma antes. |
| `/jira worklog <KEY> <tempo>` | Registra worklog (`addWorklogToJiraIssue`). Ex.: `2h`, `30m`. Confirma antes. |
| `/jira vincular <KEY> <tipo> <KEY2>` | Cria vínculo entre issues (`createIssueLink`). Resolve tipos via `getIssueLinkTypes`. |
| `/jira projetos` | Lista projetos visíveis (`getVisibleJiraProjects`) + sites (`getAccessibleAtlassianResources`). Útil para descobrir keys. |
| `/jira confluence <busca\|page <id>>` | Busca páginas (`searchConfluenceUsingCql`) ou abre uma (`getConfluencePage`). Útil para puxar specs/docs. |
| `/jira eu` | Conta autenticada (`atlassianUserInfo`) + sites acessíveis. |

## Execução

Invoque `jira-ops` passando o subcomando + args. Brief:
```
Subcomando: <issues|show|criar|editar|status|comentar|worklog|vincular|projetos|confluence|eu>
Args: <args>
Site/cloudId: resolver via getAccessibleAtlassianResources (confirmar com usuário se houver vários)
```

## Quando pedir input adicional (via AskUserQuestion)

- **criar** sem projeto definido (skill sem "Projetos canônicos") → rode `getVisibleJiraProjects` e pergunte qual. Sem issue type → ofereça os do projeto. Campos obrigatórios faltando → pergunte.
- **criar/editar** com assignee por nome → resolva via `lookupJiraAccountId`; se ambíguo, pergunte.
- **status** sem transição → liste as de `getTransitionsForJiraIssue` e pergunte.
- Multi-site (mais de um `cloudId`) → confirme qual antes de qualquer operação.

## Regras duras

- **Leitura livre** (`issues`, `show`, `projetos`, `confluence` busca/leitura, `eu`) — executa direto.
- **Escrita confirma antes** (`criar`, `editar`, `status`, `comentar`, `worklog`, `vincular`, criar/editar página) — apresenta o payload e espera "ok", salvo autorização explícita na mesma conversa.
- Identificadores (`cloudId`, `projectKey`, `issueKey`, `accountId`, `spaceId`, `pageId`, issue type) são **descobertos ao vivo**, nunca inventados.
- `assignee` = **accountId** (resolva nomes via `lookupJiraAccountId`). Transição = valor de `getTransitionsForJiraIssue`.
- Não gera artefato `.md` no workspace — o Jira/Confluence é o sistema de registro. (Se o usuário quiser persistir um recorte como análise/relatório, encadeie com `/analise` ou `/relatorio` depois.)
