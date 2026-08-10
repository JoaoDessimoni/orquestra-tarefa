---
name: quimera-nova-demanda
description: Abre uma demanda (ticket) no Quimera seguindo o padrão canônico de descrição refinada — layout fixo "Descrição Refinada · Observação · Objetivo" — e SEMPRE remove a assinatura de MCP que o servidor anexa (o rodapé `--- _Created via MCP (source: mcp)_`). Carregue sempre que for criar/abrir uma demanda no Quimera (ex.: "abre a demanda X no quimera", "cria a R13 no quimera", "nova demanda no padrão refinado"). NÃO substitui a skill `quimera` (catálogo de tools, times, UUIDs, indicadores) — depende dela; é só o fluxo de abertura padronizado.
---

# Skill — Abrir demanda no Quimera (padrão refinado + sem assinatura MCP)

Fluxo canônico para **criar um ticket pai** no Quimera com descrição bem refinada e **sem** o rodapé de MCP. Opera via `mcp__quimera__*`. Para catálogo de ferramentas, times, categorias, UUIDs e regras anti-fabricação, a fonte é a skill **`quimera`** — carregue-a junto; esta skill só define **o padrão de descrição e a limpeza da assinatura**.

> Escopo default = time **`ia_automacao_finza`** (squad IAF). Não confunda com `/backlog` (estratégia `.md`) nem com `/jira` (Atlassian).

---

## 1 · Layout obrigatório da descrição

Toda demanda aberta por esta skill usa **exatamente** estas três seções, nesta ordem, em Markdown:

```markdown
**Descrição Refinada**
<O quê + causa provável + escopo do trabalho. Frases curtas, SVO, sem jargão.
 Quando houver escopo com passos, use uma lista:>

Escopo:
- <ação 1>
- <ação 2>
- <ação 3>

**Observação**
<Ressalvas técnicas, riscos, o que validar antes, dependências, contexto político.
 É a voz cética — o que pode dar errado / o que investigar antes de agir.>

**Objetivo**
<O resultado esperado em uma ou duas frases. O "pronto quando…" em linguagem de negócio.>
```

Regras de redação (herdadas do tom Finza):
- Frases curtas, sujeito-verbo-objeto. Sem "sinergia", "alavancar", "ótima notícia".
- Não inventar fato. Se algo precisa de confirmação, marcar no texto (ex.: "a confirmar com o gestor") em vez de fabricar.
- A seção **Observação** carrega a voz de refinamento (gates, riscos, o que validar) — não deixá-la vazia quando houver risco técnico.
- **Nunca** incluir assinatura, rodapé de ferramenta, "gerado por", nome de IA ou qualquer marca de origem no corpo. A descrição é do negócio, não da ferramenta.

---

## 2 · Assinatura de MCP — SEMPRE remover (passo não-negociável)

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

> Não pule o passo 3. A limpeza só está garantida quando verificada — a descrição correta termina no texto do **Objetivo**, sem linha `---` de rodapé de ferramenta.

---

## 3 · Checklist de campos (antes de criar)

Confirme/preencha com o usuário antes de abrir. Campos de `create_ticket`:

| Campo | Regra |
|---|---|
| `title` | Conciso e acionável. |
| `description` | As **3 seções** da §1, sem assinatura. |
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

`create_ticket` cria registro visível ao time/solicitante e pode disparar notificação/e-mail. **Confirme o rascunho com o usuário antes de criar** (título, descrição nas 3 seções, categoria, prioridade, responsável, solicitante, tags), salvo autorização explícita na mesma conversa. Leituras (`get_ticket`, `list_*`) são livres.

---

## 5 · Receita (resumo executável)

```
1. Reunir dados da demanda (fonte: roadmap, reunião, pedido do usuário).
2. Redigir descrição nas 3 seções (§1). Sem assinatura.
3. Resolver assigned_to (UUID) e requester_email (e-mail) — skill `quimera`.
4. Mostrar rascunho + confirmar com o usuário (§4).
5. create_ticket(...)  → guarda { id, ticket_number }.
6. update_ticket_description(id, <descrição limpa>)   ← remove o rodapé de MCP.
7. get_ticket(ticket_number) → confirmar que termina no Objetivo, sem assinatura.
8. Reportar: nº do ticket + campos aplicados.
```
