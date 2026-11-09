---
name: quimera-nova-demanda
description: Abre uma demanda (ticket) no Quimera seguindo o padrão canônico de descrição refinada — layout fixo "Descrição Refinada · Observação · Objetivo" — com GATE ANTI-DUPLICATA bloqueante antes de qualquer criação (varre todas as demandas do time e dos desenvolvedores, cruza por título E descrição, e não cria se já existir em qualquer status) e SEMPRE remove a assinatura de MCP que o servidor anexa (o rodapé `--- _Created via MCP (source: mcp)_`). Carregue sempre que for criar/abrir uma demanda no Quimera (ex.: "abre a demanda X no quimera", "cria a R13 no quimera", "cria essas 6 demandas", "nova demanda no padrão refinado"). NÃO substitui a skill `quimera` (catálogo de tools, times, UUIDs, indicadores) — depende dela; é só o fluxo de abertura padronizado.
---

# Skill — Abrir demanda no Quimera (padrão refinado + sem assinatura MCP)

Fluxo canônico para **criar um ticket pai** no Quimera com descrição bem refinada e **sem** o rodapé de MCP. Opera via `mcp__quimera__*`. Para catálogo de ferramentas, times, categorias, UUIDs e regras anti-fabricação, a fonte é a skill **`quimera`** — carregue-a junto; esta skill define **o gate anti-duplicata, o padrão de descrição e a limpeza da assinatura**.

> Escopo default = time **`ia_automacao_finza`** (squad IAF). Não confunda com `/backlog` (estratégia `.md`) nem com `/jira` (Atlassian).

**Ordem não-negociável:** §1 (gate anti-duplicata) → §2 (descrição) → §3 (campos) → §4 (confirmação) → criação → §5 (limpeza da assinatura). O gate vem **antes** de tudo. Redigir descrição bonita para uma demanda que já existe é trabalho jogado fora — e cria lixo no sistema de registro do time.

---

## 1 · Gate anti-duplicata (PASSO ZERO — bloqueante)

**Regra dura: nenhum `create_ticket` acontece antes da varredura completa do Quimera.** Se a demanda já existe — **em qualquer status, inclusive `finalizado` e `cancelado`** — **não crie**. Reporte o ticket existente e pare.

> **Incidente que originou esta regra (registro factual).** Em uma criação em lote, demandas que já existiam e **já tinham sido executadas** foram recriadas como cards novos. Já executadas: **#6014, #6013, #6016** (João) e **#5702, #5703** (Marcos). Duplicatas criadas depois, não executadas: **#6015, #6017, #6018** (João) e **#6175, #6176, #6177** (Marcos). O pareamento 1:1 não está registrado — o que está registrado é que o lote nasceu sem varredura prévia. Causa raiz: criar direto a partir do pedido, sem inventariar o que já estava com os desenvolvedores.

### 1.1 · Inventário (uma varredura por sessão de criação)

Leitura é livre — rode sem pedir permissão:

1. **Time inteiro, sem filtro de status:**
   `list_tickets(team="ia_automacao_finza", only_parents=true, limit=200)` — pagine com `offset` (+200) até vir menos que `limit`. **Não passe `status`**: o gate cobre todos os estados.
2. **O que está com cada desenvolvedor** (o pedido explícito do supervisor — "consultar todas as demandas que estão com os desenvolvedores"): um `list_tickets(team="ia_automacao_finza", assigned_to=<UUID>, limit=200)` por membro do roster da skill `quimera` §1 — João Lucas, João Pedro, Leandro, Marcos e João Vinícius. Dispare os 5 em paralelo.
3. Guarde de cada ticket: `#número · título · status · assignee · início da descrição (~300 chars)`.

### 1.2 · Sondas por palavra-chave (por candidata)

O `search` do `list_tickets` casa em **título e descrição**. Rode **2 a 4 sondas por candidata**, com termos diferentes e **sem `only_parents`** (uma duplicata pode viver como subtarefa de outro pai):

- **sonda de entidade** — sistema/agente/tabela (ex.: `Hyperflow`, `Esperanza`, `vw_titles_live`, `Bitrix`).
- **sonda de ação/sintoma** — o verbo real ou o erro (ex.: `duplicidade`, `timeout`, `repasse`, `tabulação`).
- **sonda de identificador** — nome de campanha, nº de workflow, nome de EF, ticket citado.

Uma sonda só nunca basta: o caso comum é **título diferente descrevendo o mesmo trabalho**.

### 1.3 · Critério de casamento — cruze título **E** descrição

Normalize os dois lados antes de comparar: minúsculas, sem acento, sem pontuação, espaços colapsados, fora stopwords e verbos genéricos (`ajustar`, `corrigir`, `criar`, `verificar`, `analisar`, `revisar`, `implementar`).

Extraia a **assinatura** de cada demanda: `<sistema/entidade> + <ação> + <objeto/identificador>`. Compare assinaturas, não strings.

| Veredito | Quando | O que fazer |
|---|---|---|
| **DUPLICADA** | Assinatura igual (mesmo sistema + ação + objeto), mesmo com título totalmente diferente; ou a descrição do ticket existente descreve o mesmo trabalho | **Não crie.** Reporte `#número`, título e status do existente. |
| **SUSPEITA** | Mesmo sistema/objeto com ação possivelmente distinta; casa só um dos dois eixos (título ou descrição); já existe como **subtarefa**; ou é continuação/fase 2 de algo existente | **Pare e pergunte.** Mostre candidata × ticket existente lado a lado e deixe o usuário decidir. Nunca resolva sozinho a favor de criar. |
| **NOVA** | Nenhum ticket compartilha sistema + objeto | Segue para §2. |

**Default de segurança: na dúvida, não cria.** O custo de uma duplicata no sistema de registro é maior que o de uma pergunta.

### 1.4 · Lote — dedup contra o inventário **e** dentro do próprio lote

Quando o pedido traz N demandas de uma vez (a situação exata do incidente):

1. Rode a varredura §1.1 **uma vez** e reaproveite o inventário para todas as candidatas.
2. Compare cada candidata contra o inventário **e contra as outras candidatas do lote** — pedidos costumam repetir a mesma demanda em palavras diferentes.
3. Monte a **tabela de veredito do lote inteiro** e mostre ao usuário **antes de criar qualquer coisa**:

   | # | Candidata | Veredito | Ticket existente |
   |---|---|---|---|
   | 1 | … | DUPLICADA | #6014 (finalizado) |
   | 2 | … | NOVA | — |

4. Crie **somente** as `NOVA`. Após cada criação, **acrescente o ticket recém-criado ao inventário em memória**, para a candidata seguinte do mesmo lote já enxergá-lo.
5. No relatório final, liste explicitamente as **bloqueadas** com o número do ticket existente. Nunca omita o que não foi criado.

### 1.5 · O gate não é dispensável

- **"Cria essas 6 demandas" não autoriza pular a varredura.** Autorização de escrita ≠ dispensa de checagem.
- **Status não isenta.** `finalizado` e `cancelado` bloqueiam igual. Se o usuário quiser retomar algo encerrado, o caminho é `change_ticket_status` ou comentário **no ticket existente** — não card novo.
- **Reabrir/refazer só com vínculo declarado.** Se o usuário decidir criar mesmo havendo similar, registre na seção **Observação** da descrição a referência ao ticket anterior (`ref. #6014`).
- **Se a varredura falhar** (erro de tool, permissão, timeout): **não crie**. Reporte a falha e pergunte como proceder — criar às cegas é o que gerou o incidente.

---

## 2 · Layout obrigatório da descrição

Toda demanda aberta por esta skill usa **exatamente** estas três seções, nesta ordem, **em HTML** (não Markdown).

> **Por que HTML (decisão do supervisor, 2026-11-06):** o editor da tela do Quimera grava a descrição em HTML. Descrição enviada em Markdown aparece certa até a primeira edição manual — ao salvar pela tela, o editor achata tudo num único `<p>` com os `**` e `-` como texto literal (incidente no #12266). Em HTML, a estrutura sobrevive à edição manual e o supervisor consegue editar direto na tela.

```html
<p><strong>Descrição Refinada</strong></p>
<p>O quê + causa provável + escopo do trabalho. Frases curtas, SVO, sem jargão.</p>
<p>Segundo parágrafo, se precisar (um <p> por parágrafo).</p>
<p>Escopo:</p>
<ul>
  <li>ação 1</li>
  <li>ação 2 com subitens:
    <ul><li>subitem a;</li><li>subitem b.</li></ul>
  </li>
  <li>ação 3</li>
</ul>
<p><strong>Observação</strong></p>
<ul>
  <li>Ressalva técnica / risco / o que validar antes / dependência / contexto político.</li>
  <li>É a voz cética — o que pode dar errado, o que investigar antes de agir.</li>
</ul>
<p><strong>Objetivo</strong></p>
<p>O resultado esperado em uma ou duas frases. O "pronto quando…" em linguagem de negócio.</p>
```

Regras de marcação:
- Título de seção = `<p><strong>…</strong></p>` (não `<h1..h6>`, não `**`).
- Cada parágrafo no seu próprio `<p>`. Lista = `<ul><li>`; sublista = `<ul>` **dentro** do `<li>` pai. Passos ordenados podem usar `<ol>`.
- Escape `&` como `&amp;` (ex.: `IA &amp; Automação`). Aspas e acentos vão como texto normal.
- Envie o HTML **numa linha só** (sem quebras/indentação entre tags) — o bloco acima está indentado só para leitura.
- **Nada de Markdown** dentro do HTML (`**`, `- `, `#`). Nada de `style`, `class`, `<br>` para simular parágrafo, nem tags fora de `p/strong/em/ul/ol/li/a/code`.

Regras de redação (herdadas do tom Finza):
- Frases curtas, sujeito-verbo-objeto. Sem "sinergia", "alavancar", "ótima notícia".
- Não inventar fato. Se algo precisa de confirmação, marcar no texto (ex.: "a confirmar com o gestor") em vez de fabricar.
- A seção **Observação** carrega a voz de refinamento (gates, riscos, o que validar) — não deixá-la vazia quando houver risco técnico.
- **Nunca** incluir assinatura, rodapé de ferramenta, "gerado por", nome de IA ou qualquer marca de origem no corpo. A descrição é do negócio, não da ferramenta.

---

## 3 · Checklist de campos (antes de criar)

Só chega aqui candidata com veredito **NOVA** no gate §1. Confirme/preencha com o usuário antes de abrir. Campos de `create_ticket`:

| Campo | Regra |
|---|---|
| `title` | Conciso e acionável. |
| `description` | As **3 seções** da §2, **em HTML**, sem assinatura. |
| `team` | Default `ia_automacao_finza`. |
| `category` | ∈ {Cobrança, Crédito, DiretoriaFinza, Formalização, IA, JuridicoFinza, Marketing, Operação, Processos, Recuperação, TI}. Default do squad ≈ TI/Cobrança conforme o tema. |
| `priority` | `low` \| `medium` \| `high`. **`high` exige `justification`** — sem justificativa concreta, não crie como high (pergunte ou rebaixe para medium). |
| `deliverable_type` | Texto livre canônico — ex.: `Aplicação/Sistema` (= "sistemas e aplicação"), `Automação`, `Agente de IA`, `Informação`. |
| `story_points` | Número (ex.: 1, 2, 3, 5, 8). |
| `assigned_to` | **UUID** do responsável (traduza o nome via tabela da skill `quimera` / `list_users`). |
| `requester_email` | **E-mail** do solicitante — deve existir em `profiles`. Solicitante ≠ responsável: pergunte se não estiver claro. |
| `tags` | Array. Convenção do sistema usa prefixo (`tipo_bug`, `tool_hyperflow`); use o que o usuário pedir, respeitando a convenção quando fizer sentido para agrupamento. |
| `status` | Default `backlog`. |

Roster de nomes→UUID/e-mail e regras anti-fabricação: skill **`quimera`** §1 e §4. Não invente UUID nem e-mail.

---

## 4 · Ação com efeito externo — confirmar antes

`create_ticket` cria registro visível ao time/solicitante e pode disparar notificação/e-mail. **Confirme o rascunho com o usuário antes de criar** (título, descrição nas 3 seções, categoria, prioridade, responsável, solicitante, tags), salvo autorização explícita na mesma conversa. Leituras (`get_ticket`, `list_*`) são livres — o gate §1 roda sem pedir permissão.

Em lote, a confirmação inclui **a tabela de veredito** (§1.4): o usuário aprova o que vai ser criado **e** vê o que foi bloqueado por duplicata, com o `#número` do ticket já existente.

> Autorização de escrita dada pelo usuário cobre a **criação**; ela **não** dispensa o gate §1.

---

## 5 · Assinatura de MCP — SEMPRE remover (passo não-negociável)

O servidor Quimera **anexa automaticamente** ao final da descrição, quando o ticket nasce por MCP:

```
\n\n---\n_Created via MCP (source: mcp)_
```

Isso acontece **no `create_ticket`** (o campo `source` cai no default `mcp`). O corpo que você envia não tem o rodapé — o servidor o injeta depois.

**Procedimento obrigatório após criar:**

1. `create_ticket(...)` com a descrição limpa (as 3 seções, sem rodapé).
2. **Imediatamente** `update_ticket_description(id, <mesma descrição limpa>)`.
   O `update_ticket_description` **substitui** a descrição e **não** re-anexa o rodapé — é o que remove a assinatura.
3. `get_ticket(ticket_number)` para **confirmar** que a descrição termina na seção **Objetivo**, sem `--- _Created via MCP (source: mcp)_`.

> Não pule o passo 3. A limpeza só está garantida quando verificada — a descrição correta termina no `</p>` do **Objetivo**, sem linha `---` de rodapé de ferramenta. Confira também que ela continua em HTML (começa com `<p><strong>Descrição Refinada</strong></p>`, sem `**` literal).

> **Mostrar ao usuário:** no rascunho para aprovação (§4) apresente a descrição **legível** (seções/listas renderizadas em texto), não o HTML cru. O HTML é só o que vai no payload.

> **Editar demanda já existente** (`update_ticket_description`): mesmo formato HTML da §2. Se a descrição atual vier achatada (um `<p>` só com `**`/`-` literais), reconstrua a estrutura em HTML preservando o texto que o usuário editou.

---

## 6 · Receita (resumo executável)

```
0. GATE ANTI-DUPLICATA (§1) — bloqueante, antes de redigir qualquer coisa:
   0a. list_tickets(team=ia_automacao_finza, only_parents=true, limit=200)
       → paginar por offset até esgotar. SEM filtro de status.
   0b. list_tickets(team=..., assigned_to=<UUID>) para os 5 do roster (em paralelo)
       → "o que está com os desenvolvedores".
   0c. 2–4 sondas list_tickets(search=...) por candidata (entidade / ação / identificador),
       sem only_parents (pega subtarefas).
   0d. Cruzar por TÍTULO E DESCRIÇÃO via assinatura <sistema+ação+objeto>.
       DUPLICADA → não cria, reporta #número + status.
       SUSPEITA  → para e pergunta.
       NOVA      → segue.
   0e. Em lote: dedup também entre as candidatas do lote; montar tabela de veredito.
   0f. Varredura falhou (erro/permissão)? NÃO CRIA — reporta e pergunta.

1. Reunir dados da demanda (fonte: roadmap, reunião, pedido do usuário).
2. Redigir descrição nas 3 seções (§2) EM HTML (<p><strong>, <ul><li>), numa linha. Sem assinatura, sem Markdown.
3. Resolver assigned_to (UUID) e requester_email (e-mail) — skill `quimera`.
4. Mostrar rascunho + tabela de veredito + confirmar com o usuário (§4).
5. create_ticket(...) SÓ das NOVA → guarda { id, ticket_number }.
   → acrescenta o criado ao inventário em memória (próxima candidata do lote enxerga).
6. update_ticket_description(id, <descrição limpa>)   ← remove o rodapé de MCP.
7. get_ticket(ticket_number) → confirmar que termina no </p> do Objetivo, sem assinatura, ainda em HTML.
8. Reportar: nº dos tickets criados + campos aplicados + LISTA DAS BLOQUEADAS
   por duplicata, com o #número do ticket já existente. Nunca omitir o que não foi criado.
```
