# Personas — OrquestrAI

> Personas e jobs-to-be-done do produto. MVP é single-user. Última atualização: 20/05/2026.

## Fontes

- Conversa de design com o usuário (20/05/2026)
- `memory/user_joao_vinicius.md`, `memory/project_workspace_gerencial.md`

---

## P1 · João Vinícius — Supervisor IAF Finza (única persona MVP)

**Papel:** Supervisor do squad IAF, recém-promovido (em posse há ~7 dias).
**Stack mental:** Engenheiro técnico-direto, prefere documentar decisões em markdown, opera com Claude Code diariamente.
**Tempo de uso esperado:** 30-60 min/dia em janelas de análise; uso pico em períodos de relatório.

### Contexto operacional

- Roda Claude Code CLI local com licença pessoal.
- Workspace principal é `Repasse/` (esta pasta), com `.claude/agents`, `.claude/commands`, `Gestao/`.
- Usa Quimera diariamente para gerir demandas do time.
- Produz semanalmente entre 1-3 análises e 1-2 relatórios para Leonardo (CTO) ou stakeholders.

### Jobs-to-be-done

| ID | Quando... | Eu quero... | Para... |
|---|---|---|---|
| JTBD-01 | Eu identifico uma pergunta a investigar | Criar uma "Análise" com contexto, fontes e pergunta clara | Não esquecer o objetivo e ter rastreio do que produzi |
| JTBD-02 | Tenho uma análise pronta | Derivar relatórios específicos por destinatário | Não reescrever do zero pra cada audiência |
| JTBD-03 | Preciso pesquisar/cruzar fatos do contexto Finza | Criar um Agente Claude Code que tenha as Skills certas | Não copiar/colar prompts de uma sessão pra outra |
| JTBD-04 | Quero reusar um agente que funcionou | Encontrar pelo nome, abrir, executar de novo com input diferente | Não recriar trabalho passado |
| JTBD-05 | Executei um agente complexo (ex: multi-step research) | Ver streaming em tempo real (tokens + tool calls) | Saber se ele está no caminho certo antes de gastar mais tempo/tokens |
| JTBD-06 | Terminei uma execução | Consultar histórico (output, custo, duração, tool calls) | Auditar resultado e citar em relatório |
| JTBD-07 | Preciso compartilhar análise/relatório via .md (Slack, e-mail) | Exportar para `Gestao/` no formato do workspace `.claude` | Aproveitar fluxo atual sem fricção |
| JTBD-08 | Vou começar uma nova sessão de trabalho | Abrir o sistema e ver, no Dashboard, status do squad + execuções recentes + atalhos | Ter uma central única em vez de 5 abas |

### Padrões de comunicação

- Prefere **frases curtas, em português técnico-executivo**.
- Não tolera jargão de consultoria ("sinergia", "alavancar").
- Quando o sistema for incerto, prefere ver **"não confirmado"** em vez de fabricação.
- Atalhos de teclado importam — usa Cmd+K, navegação por números (1-9 nas views do BOARD atual).

### Anti-personas (NÃO são usuárias do MVP)

- **Membros do squad IAF** (Diogo, Camila, Jéssica, João Lucas, Lucas) — não acessam o sistema. Caso recebam algo, é via exportação `.md` ou link.
- **Stakeholders externos** (Leonardo CTO, Felipe Maurer, Roberta Souza) — recebem relatórios finalizados, não usam o app.
- **TI Finza** — não opera o sistema, não tem credencial. Sistema é 100% local.

---

## P2 · Roadmap V1+ (não-MVP, apenas referência)

| Persona futura | Quando entra | Demandas adicionais |
|---|---|---|
| Outros supervisores Finza | V1 | Multi-tenant, auth real, isolamento de dados |
| Membros do squad (read-only) | V1 | RBAC, link público de relatórios |
| Integração Quimera | V2 | Pull de issues como contexto, push de pendência gerada por análise |

Estas personas **não devem influenciar decisões de MVP**. Estão aqui para evitar que escolhas de design quebrem totalmente o futuro.
