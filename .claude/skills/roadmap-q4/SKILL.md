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
2b. **A data de entrega prevista verdadeira é a do Quimera.** Para todo item com `key`, `fp` = `expected_delivery_date` do ticket (`get_ticket` — o `list_tickets` **não** traz esse campo). Se o Quimera tem data, ela vence qualquer `fp` do db (sugerida, confirmada, editada na tela). Se o Quimera não tem data, mantém o `fp` atual. A página também aplica isso sozinha na leitura (`qoverlay`, §3.4).
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

**Janela fixa: 01/10/2026 → dia atual.** Todo reconcile cobre o time `ia_automacao_finza` nesse período — sempre recalcular "hoje" pela data do sistema, nunca reaproveitar a janela de um reconcile anterior.

1. **Abertos (qualquer data de criação):** `list_tickets` nos 6 status não-terminais (1 chamada por status, `limit` 100).
2. **Fechados na janela:** `list_tickets status=finalizado only_parents=true limit=200` (resultado grande — sai em arquivo; processar com `node`) e `status=cancelado`. Filtrar `resolved_at >= 2026-10-01` (cancelado: `updated_at >= 2026-10-01`). Se o mais antigo da página ainda for ≥ 01/10, paginar com `offset`.
3. Cruzar com o quadro (`ArtifactData get roadmap/demandas` com `out_dir` dentro do projeto — o scratchpad é recusado — anotar `version`; contar só `!deleted`). Aplicar §2: aberto que falta → entra; finalizado na janela que falta → **perguntar** ao João (exceto operacionais/templates, que vão para o agregador).
4. **`get_ticket` + `list_ticket_status_history`** de todo ticket do quadro que está aberto, que mudou desde o último reconcile (`updated_at` ≥ data do último `qmeta.at`) ou que ainda não está no `qmirror`. Para 20+ tickets, delegar a um agente `general-purpose` (só leitura) que grava um JSON `{n:{t,s,d,edd,res,sca,asg,sp,c[],h[]}}` em `Backlog/referencias/json/2026-11-09_roadmap-q4/<data>_quimera-fetch.json`.
5. Montar um único `update` em `roadmap/demandas` com `{ atualizado_em, items: { <id>: {campos} } }` e `if_version` — o db fica igual ao Quimera mesmo sem a página.

Campos-espelho (mudam sozinhos no reconcile):

| Campo | De onde vem |
|---|---|
| `qs` | `ticket.status` (mesmo vocabulário) |
| `dev` | `assigned_to` → Leandro `857575b1` · Marcos `409661f3` · João Pedro `f403707d` · Joao Lucas `b90f482e` · João Vinícius `34a15ef4` (UUID desconhecido → não preencher, perguntar) |
| `sp` | `story_points` (nulo mantém o atual) |
| `ir` | data de entrada em `em_andamento` (`status_changed_at` quando o ticket acabou de ir para lá) — só se ainda vazio |
| `fr` | `resolved_at` (finalizado) ou data de ida para `em_validacao` |
| `fp` + `df:"quimera"` | `expected_delivery_date` **sempre que existir** (vence o que estiver no db, inclusive `confirmada`); sem data no Quimera mantém o atual (se estava `sugerida`, continua `sugerida`) |
| `h0` | ao virar `finalizado`: `{s:"aprovada", n:"Finalizado no Quimera em dd/mm/aaaa."}` só se não houver `homolog/<id>`; `cancelado`: `nao_aplica` |

Item novo (§2): `id:"q<nº>"`, `key`, `tipo:"demanda"`, `ord` maior que o atual, `titulo` curto e limpo (sem prefixos tipo `[Bitrix ID-…]`, sem typos), `frente` (`torre|agentes|hyperflow|bitrix|juridico|compliance|estrategica|sustentacao`), `desc` 1–3 frases fiéis à descrição, `ac` se houver critério, `sol`, `prio`, `fonte:"Quimera (ia_automacao_finza), leitura de AAAA-MM-DD"`, `h0:{s:"nao_iniciada",n:""}`, `rel:[]`.

Cancelado no Quimera → `qs:"cancelado"` e `h0:{s:"nao_aplica", n:"<motivo do comentário>"}` (só se não houver `homolog/<id>`).

4. **Espelho na página — sync automático (desde 18/11, sem botão).** O botão "Sincronizar com Quimera" e o plano `qmig` foram **removidos**. O HTML embute:
   - `<script id="qmirror">` — por ticket: `t` título, `s` status, `d` descrição, `edd` entrega prevista, `res` resolved_at, `dv` responsável (nome), `sp`, `c[]={a,e,dt,x,i}` comentários, `h[]={de,para,dt,por}` histórico de status.
   - `<script id="qmeta">` — `{at: ISO do reconcile, janela:{de:"2026-10-01", ate}}`; a barra lateral mostra "Quimera sincronizado em …".
   - Na leitura do db, `qoverlay()` aplica o espelho em cada item com `key`: `qs←s`, `fp←edd` (+`df:"quimera"`, trava com aviso "altere no Quimera"), `fr←res` (finalizado), `dev←dv`, `sp`. Ou seja: **o João só atualiza a tela**; o que aparece é o Quimera do último reconcile.
   - Atualizar com `scratchpad/build.js`-equivalente: ler a versão viva (`Artifact read`), mesclar o fetch no `qmirror`, regravar `qmeta.at`, `node --check`, republicar (mesmo `file_path`, **sem** `capabilities`). O script de referência fica em `Backlog/referencias/json/2026-11-09_roadmap-q4/build-qmirror.js`.
   - ⚠️ A página **não** fala com o Quimera em tempo real: o MCP do Quimera é local (host). Atualização "sozinha" exige rodar este reconcile (manual, `/loop` ou rotina agendada).
5. Reportar ao João: o que mudou de status, o que entrou, o que ficou de fora e por quê. Exclusão pedida pelo João: #12941 (Chamadas Finza) não entra no roadmap.

## 4. Metas e anéis (`roadmap/config`)

- `metas`: conclusão 100% · cycle time 3,7 d.u. · intruders 14%.
- `periodos[]`: `{id,label,sub,fonte,criadas,concluidas,cycle,cycle_txt,intruders}`. Mês fechado = **print do painel Gestão › Indicadores do Quimera** (pedir ao João). Parcial/trimestre = API, conta `concluidas ÷ criadas`.
- ⚠️ `get_completion_rate` usa outra fórmula (finalizados entre os criados) — **não** usar para preencher `concluidas`.

## 5. Regras de tela (para ajustes de front)

- Visual: só tema claro, branco + Azul Finza `#1A1AFF`, navy `#0A0A2E`, padrão do *Balanço do ciclo*; tokens no `:root`; Inter + JetBrains Mono; ícones SVG inline (sem libs).
- Menu: **Painel · Visão em 5 minutos (`#resumo`) · Cronograma (Calendário|Gantt) · Quadro**. Demanda abre tela própria `#demanda-<id>`.
- A Visão em 5 minutos (`rResumo`) é calculada do quadro ao vivo; só os textos de objetivo por frente (`OBJ5`) são fixos no HTML — revisar quando o escopo de uma frente mudar.
- Cronograma e Quadro não rolam a página (classe `body.fit`); listas rolam por dentro com a barra fina padrão.
- Filtros são `details.dd` customizados (nunca `<select>` nativo na barra); "Só atrasadas" é botão `.tgb`.
- Tela da demanda: Sobre → Planejamento (com Editar + Cancelar) → **Homologação só quando `qs==="em_validacao"`** (etapa 2 "Pronta para homologar" já cumprida) → Registro formal | Histórico. Não há mais "Observações do negócio" na tela (os docs `obs/` antigos continuam no histórico).

## 6. Validar antes de publicar

1. `node --check` no `<script>` extraído da página.
2. `node Backlog/referencias/json/2026-11-09_roadmap-q4/mkharness.js <pagina> <saida> <painel|cronograma|gantt|quadro|demanda-<id>>` e screenshot (Edge headless). Celular: iframe de 400 px.
3. Depois de publicar com dados novos: 1 leitura `ArtifactData` do que foi escrito.
4. Atualizar o histórico de versões no `.md` de contexto e a memória `roadmap-q4-2026-artefato`.
