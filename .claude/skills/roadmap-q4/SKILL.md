---
name: roadmap-q4
description: Regras canônicas para atualizar ou ajustar o artefato "Roadmap IAF Q4 2026" (claude.ai/artifact/QJTo6HkZdGMxVPevdJVGfk · Apresentacoes/executando/roadmap-q4_squad-negocio_09-11-2026.html) — reconcile do quadro com o Quimera, escopo do que entra no quadro, campos do db, metas, republicação e validação. Carregue SEMPRE antes de mexer nesse artefato (dados, telas, metas ou documentação), para não inventar demandas, datas ou números e não colocar no quadro o que não pertence a ele.
---

# Roadmap IAF Q4 2026 — skill de manutenção

Contexto completo: `Apresentacoes/executando/roadmap-q4_squad-negocio_09-11-2026.md` (ler antes da 1ª alteração da sessão).

| | |
|---|---|
| Artefato | https://claude.ai/artifact/QJTo6HkZdGMxVPevdJVGfk |
| Página | `Apresentacoes/executando/roadmap-q4_squad-negocio_09-11-2026.html` |
| Seed / config / harness | `Backlog/referencias/json/2026-11-09_roadmap-q4/` |
| Dados vivos | db do artefato: `roadmap/demandas` (doc único `items.<id>`), `roadmap/config`, `homolog/<id>`, `obs/<id>`, `historico/*` |
| Time Quimera | `ia_automacao_finza` |

## 1. Leis (não negociáveis)

1. **O quadro tem dono e escopo.** Só entra no quadro o que está na regra da §2. Nada de "achei relevante". Na dúvida, **pergunte** ao João antes de adicionar.
2. **Não invente.** Toda demanda tem `fonte`. Data que não veio do Quimera ou de um documento leva `df:"sugerida"` e é dita ao João como sugestão. Número de meta só do Quimera (§4).
3. **O negócio é dono de `homolog/`, `obs/` e `historico/`.** Claude **nunca** escreve, apaga ou "corrige" esses caminhos. Claude escreve só em `roadmap/demandas` e `roadmap/config`.
4. **Quimera é só leitura daqui.** Reconcile lê o Quimera (`mcp__quimera__list_tickets`/`get_ticket` ou agente `quimera-ops`) e escreve no artefato. Nunca muda ticket.
5. **Texto curado não é sobrescrito** pelo texto cru do ticket (`titulo`, `desc`, `ac`). Só o reconcile de campos-espelho (§3) é automático.
6. **Escrita no db sempre com `if_version`** (ler o doc, anotar a versão, `update` com merge). Nunca `set` em `roadmap/demandas` com o seed — apaga edições feitas na tela.
7. **Republicar a página só para mudança de tela/estilo**, com o **mesmo `file_path`** e **sem** `capabilities` (mantém as regras do db). Dados mudam via `ArtifactData`, não republish.

## 2. O que pertence ao quadro

| Entra | Regra |
|---|---|
| Ticket **não-terminal** do time (`backlog`, `backlog_futuro`, `fila_exec`, `em_andamento`, `bloqueado`, `em_validacao`) | entra, **exceto** os operacionais abaixo |
| Ticket **já no quadro** que finalizou ou cancelou | fica, com `qs` atualizado (cancelado não sai do quadro) |
| Ticket finalizado que **nunca esteve** no quadro | **não entra** sem pedido do João |
| Planejada sem ticket (`pl-*`) | só a partir de documento/artefato citado em `fonte`; vira o ticket quando ele for criado (preencher `key`/`qs` no mesmo item, não duplicar) |
| Marco (`mk-*`) | só data citada em documento ou pedida pelo João |

**Operacionais — não viram item próprio:**
- Pedidos `Template WhatsApp: torre_tp_*` (tag `template-whatsapp`): somam no item agregador **`q12588`** ("Templates WhatsApp da Torre"). Atualizar `desc` (lista e divisão por dev), `rel` (`#nnnn`), `sp` (soma) e `qs` (o menos avançado dos abertos; todos finalizados → `finalizado`). Lote novo em outro dia pode virar novo agregador `q<menor nº do lote>` — perguntar.
- `Vincular Número Hyperflow` / reconexões de linha, liberação de acesso (Hyperflow, e-mail, Builder), cópias/duplicatas de ticket.

## 3. Reconcile com o Quimera (procedimento)

1. Listar os 6 status não-terminais do time (1 chamada por status, `limit` 100). Para cada `key` do quadro que **não** apareceu, `get_ticket` (está finalizado ou cancelado — ler `status`, `resolved_at`, comentários).
2. `ArtifactData get roadmap/demandas` → `version`.
3. Montar um único `update` com `{ atualizado_em, items: { <id>: {campos} } }` e `if_version`.

Campos-espelho (mudam sozinhos no reconcile):

| Campo | De onde vem |
|---|---|
| `qs` | `ticket.status` (mesmo vocabulário) |
| `dev` | `assigned_to` → Leandro `857575b1` · Marcos `409661f3` · João Pedro `f403707d` · Joao Lucas `b90f482e` · João Vinícius `34a15ef4` (UUID desconhecido → não preencher, perguntar) |
| `sp` | `story_points` (nulo mantém o atual) |
| `ir` | data de entrada em `em_andamento` (`status_changed_at` quando o ticket acabou de ir para lá) — só se ainda vazio |
| `fr` | `resolved_at` (finalizado) ou data de ida para `em_validacao` |
| `fp` | `expected_delivery_date` se existir; senão mantém (se estava `sugerida`, continua `sugerida`) |

Item novo (§2): `id:"q<nº>"`, `key`, `tipo:"demanda"`, `ord` maior que o atual, `titulo` curto e limpo (sem prefixos tipo `[Bitrix ID-…]`, sem typos), `frente` (`torre|agentes|hyperflow|bitrix|juridico|compliance|estrategica|sustentacao`), `desc` 1–3 frases fiéis à descrição, `ac` se houver critério, `sol`, `prio`, `fonte:"Quimera (ia_automacao_finza), leitura de AAAA-MM-DD"`, `h0:{s:"nao_iniciada",n:""}`, `rel:[]`.

Cancelado no Quimera → `qs:"cancelado"` e `h0:{s:"nao_aplica", n:"<motivo do comentário>"}` (só se não houver `homolog/<id>`).

4. Reportar ao João: o que mudou de status, o que entrou, o que ficou de fora e por quê.

## 4. Metas e anéis (`roadmap/config`)

- `metas`: conclusão 100% · cycle time 3,7 d.u. · intruders 14%.
- `periodos[]`: `{id,label,sub,fonte,criadas,concluidas,cycle,cycle_txt,intruders}`. Mês fechado = **print do painel Gestão › Indicadores do Quimera** (pedir ao João). Parcial/trimestre = API, conta `concluidas ÷ criadas`.
- ⚠️ `get_completion_rate` usa outra fórmula (finalizados entre os criados) — **não** usar para preencher `concluidas`.

## 5. Regras de tela (para ajustes de front)

- Visual: só tema claro, branco + Azul Finza `#1A1AFF`, navy `#0A0A2E`, padrão do *Balanço do ciclo*; tokens no `:root`; Inter + JetBrains Mono; ícones SVG inline (sem libs).
- Menu: **Painel · Cronograma (Calendário|Gantt) · Quadro**. Demanda abre tela própria `#demanda-<id>`.
- Cronograma e Quadro não rolam a página (classe `body.fit`); listas rolam por dentro com a barra fina padrão.
- Filtros são `details.dd` customizados (nunca `<select>` nativo na barra); "Só atrasadas" é botão `.tgb`.
- Tela da demanda: Sobre → Planejamento (com Editar + Cancelar) → **Homologação só quando `qs==="em_validacao"`** (etapa 2 "Pronta para homologar" já cumprida) → Registro formal | Histórico. Não há mais "Observações do negócio" na tela (os docs `obs/` antigos continuam no histórico).

## 6. Validar antes de publicar

1. `node --check` no `<script>` extraído da página.
2. `node Backlog/referencias/json/2026-11-09_roadmap-q4/mkharness.js <pagina> <saida> <painel|cronograma|gantt|quadro|demanda-<id>>` e screenshot (Edge headless). Celular: iframe de 400 px.
3. Depois de publicar com dados novos: 1 leitura `ArtifactData` do que foi escrito.
4. Atualizar o histórico de versões no `.md` de contexto e a memória `roadmap-q4-2026-artefato`.
