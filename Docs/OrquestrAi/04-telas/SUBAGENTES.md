# Tela: Subagentes

> Espelha estrutura de [AGENTES.md](AGENTES.md) com filtragem `is_subagent=true`. Última atualização: 20/05/2026.

## Fontes

- [AGENTES.md](AGENTES.md)
- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md) §RF-AG

## Rotas

- `/subagents` — lista filtrada (`is_subagent=true`)
- `/subagents/new` — form criar (`is_subagent` pré-marcado)
- `/subagents/[slug]` — detalhe
- `/subagents/[slug]/edit` — form editar

---

## 1 · Diferenças vs Agentes

| Aspecto | Agentes | Subagentes |
|---|---|---|
| API query | `?is_subagent=false` | `?is_subagent=true` |
| Form: `is_subagent` checkbox | Visível, default `false` | Pré-marcado, oculto |
| Detalhe: aba extra | — | "Invocado por" (lista agentes que vinculam) |
| Ação primária | "▶ Executar" | (sem — subagentes são invocados por agentes) |
| Sidebar | Ícone Bot | Ícone Network |

---

## 2 · Aba "Invocado por" (detalhe)

```
┌────────────────────────────────────────────────────────────┐
│  [Prompt] [Skills] [Invocado por (3)] [Execuções (0)]      │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Este subagente é vinculado pelos seguintes agentes:       │
│                                                            │
│  ◆ researcher-finza   →                                    │
│  ◆ slide-writer       →                                    │
│  ◆ folder-organizer   →                                    │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### API

`GET /api/subagents/{slug}/used-by` → lista agentes com este vínculo.

---

## 3 · Execuções de subagentes

Subagentes **não são executados diretamente** pelo usuário no MVP — são invocados como parte de uma execução de Agente principal. Portanto a tab "Execuções" mostra:

- Lista de execuções **do agente pai** em que este subagente foi invocado (detecção via `execution_events` que mencionam o subagente).
- V1+: filtrar execuções onde este subagente apareceu via tool use.

> **MVP**: a aba mostra apenas: "Execuções diretas: 0. Para ver invocações como subagente, consulte execuções dos agentes principais que o usam."

---

## 4 · Validação extra

Subagente não pode ter outros subagentes vinculados a si — **MVP só permite 1 nível de hierarquia** (agente → subagente, sem subagente → sub-subagente).

Frontend: campo "Subagentes invocáveis" desabilitado quando `is_subagent=true`.
Backend: valida e rejeita com `nested_subagents_not_allowed`.

V1+: permitir N níveis com detecção de ciclo (já implementada em RN-03).
