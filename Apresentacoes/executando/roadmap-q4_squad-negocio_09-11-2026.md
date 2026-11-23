# Roadmap IAF Q4 2026 — contexto do artefato

> Documento de manutenção do artefato **Roadmap IAF Q4 2026** (set → dez/2026). Leia antes de ajustar visual, dados, metas ou regras de acesso.
> Criado em 2026-11-09 · dono: João Vinícius (Supervisor IAF) · versão publicada: v3.

| | |
|---|---|
| **Link (claude.ai)** | https://claude.ai/artifact/QJTo6HkZdGMxVPevdJVGfk |
| **Fonte da página** | `Apresentacoes/executando/roadmap-q4_squad-negocio_09-11-2026.html` |
| **Seed e scripts** | `Backlog/referencias/json/2026-11-09_roadmap-q4/` |
| **Público** | time técnico do squad IAF + time de negócio/produto (Cobrança, Jurídico, Crédito, Compliance) |
| **Objetivo** | acompanhar as entregas do trimestre e **formalizar** homologação, observações e decisões entre desenvolvimento e negócio |
| **Compartilhamento** | privado por padrão. O dono compartilha pelo botão **Share**: **Colaborador** para quem registra homologação/observação, **Editor** para quem muda o planejamento |

---

## 1. O que o artefato faz

Página única (HTML + CSS + JS vanilla, sem libs) com 3 itens no menu lateral e uma tela de detalhe:

| Rota (`#hash`) | Tela | Conteúdo |
|---|---|---|
| `#painel` | **Painel** | 3 anéis de meta do Quimera (Conclusão, Cycle time, Intruders) com seletor Outubro / Novembro / Trimestre; KPIs do roadmap (entregue %, execução, atrasadas, bloqueadas, fora do Quimera); barra de homologação; próximas entregas (21 dias); pede atenção; entregas por mês; status por frente; carga por responsável; marcos; atividade recente |
| `#cronograma` | **Cronograma** | toggle **Calendário** (mês estilo Google Agenda, entrega na data prevista/real) ↔ **Gantt** (trimestre ou mês, agrupado por frente, frentes recolhíveis). Ocupa a altura da tela, sem rolar a página |
| `#quadro` | **Quadro** | colunas = status do Quimera (1ª coluna = "Não criado no Quimera"). Colunas rolam por dentro |
| `#demanda-<id>` | **Demanda** | cabeçalho (ticket, frente, status, responsável, datas, SP) · Sobre a demanda + critério de aceite · Planejamento (previsto × real, origem das datas, fonte) · **Homologação** (card largo: estado + etapas + responsável/parecer + Aprovar / Pedir ajustes) · Observações do negócio (autosave) / Registro formal · Histórico |

Filtros globais (exceto na tela de demanda): busca, **Frentes** (multi-seleção), responsável, homologação, "só atrasadas". Preferências de visão (frentes filtradas, calendário/gantt, período dos anéis, frentes recolhidas) ficam em `localStorage` com prefixo `rq4_` — só conveniência por pessoa.

Responsividade: abaixo de 900 px o menu vira barra no topo e o modo "tela cheia" desliga; abaixo de 700 px o calendário vira **agenda** (lista por dia).

---

## 2. Onde estão os dados (db do artefato)

**Nada de demanda fica no HTML.** A página lê e escreve no banco compartilhado do artefato (capability `db` + `user` com escopo `profile`).

| Caminho | Tipo | Quem escreve | Conteúdo |
|---|---|---|---|
| `roadmap/demandas` | 1 doc | **Editor** (rule `roadmap` write `admin`) e Claude | `{ items: { <id>: Demanda }, atualizado_em, fonte }` |
| `roadmap/config` | 1 doc | **Editor** e Claude | metas, períodos dos anéis, extras (CSAT, espera/ativo) |
| `homolog/<id>` | 1 doc por demanda | Colaborador+ | `{ status, parecer, resp, por, em }` — ausente = usa `h0` da demanda |
| `obs/<id>` | 1 doc por demanda | Colaborador+ | `{ texto, rev, por, em }` — observação atual (autosave ~1,2 s após parar de digitar e ao sair do campo) |
| `historico/<auto>` | 1 doc por evento | Colaborador+ | `{ demanda, tipo: obs|homolog|registro|demanda, texto, de, para, resp, categoria, rev, por, em }` — **toda** edição de observação vira uma versão aqui |

Regras declaradas no publish:
```js
capabilities: { db: { rules: [
  { path: "", read: "view", write: "interact" },
  { path: "roadmap", write: "admin" }
] }, user: { scopes: ["profile"] } }
```
- `por` guarda só o **id opaco** do usuário (`u_…`); o nome é resolvido na hora com `user.profiles()`. Nunca gravar nome/e-mail no db.
- Viewer/Commenter lê tudo e não escreve; a tela mostra aviso de "acesso de leitura".
- O histórico é append pela interface, mas tecnicamente um Colaborador poderia apagar via código — não há regra append-only no `db`.

### 2.1 Campos de uma demanda (`items.<id>`)

| Campo | Significado |
|---|---|
| `id` | chave do doc: `q<ticket>` (ex. `q12357`), `pl-<slug>` (planejada sem ticket) ou `mk-<slug>` (marco) |
| `key` | nº do ticket Quimera ou `null` |
| `titulo`, `desc`, `ac` | título curado, descrição (1–3 frases fiéis à fonte), critério de aceite/próximo passo |
| `frente` | `torre · agentes · hyperflow · bitrix · juridico · compliance · estrategica · sustentacao` |
| `qs` | status no Quimera: `sem_ticket · backlog · backlog_futuro · fila_exec · em_andamento · bloqueado · em_validacao · finalizado · cancelado` (marco = `marco`) |
| `dev`, `sol`, `sp`, `prio` | responsável técnico, solicitante/área, story points, prioridade |
| `ip`, `fp` | início / entrega **previstos** (ISO) |
| `ir`, `fr` | início / entrega **reais** (ISO) |
| `df` | origem das datas: `quimera` · `doc` (documento) · `sugerida` (proposta pelo supervisor, mostra aviso "a confirmar") · `confirmada` (editada na tela por um Editor) |
| `h0` | homologação inicial `{ s, n, resp }` — usada enquanto não existe `homolog/<id>` |
| `fonte`, `rel`, `tipo`, `ord` | fonte textual, relacionadas (`#ticket` ou id), `demanda`/`marco`, ordem |

### 2.2 Regras de derivação (no JS da página)
- **Atrasada**: não está finalizada/cancelada/em validação/backlog futuro **e** (`fp` < hoje, **ou** sem `ir` com `ip` < hoje e status `sem_ticket`/`backlog`).
- **Entregue %** (KPI) = (finalizado + em_validacao) ÷ (demandas − canceladas). Marcos não contam.
- **Barra do Gantt**: `ir||ip` → `fr` (entregue) · em curso com `ir` → `fp` (ou hoje, se `fp` já passou) · senão `ip`→`fp`. Cores: verde entregue, roxo validação, âmbar execução, vermelho atrasada/bloqueada, cinza não iniciada, tracejado = sem ticket, losango = marco.
- **Homologação** — estados: `nao_iniciada → aguardando → em_andamento → aprovada`, mais `ajustes` (exige parecer) e `nao_aplica`.

---

## 3. Metas do Quimera (anéis do painel)

Ficam em `roadmap/config` — **mudar meta ou número não exige republicar a página.**

| Anel | Fórmula na página | Meta |
|---|---|---|
| Conclusão | `concluidas ÷ criadas` do período (escala 0–120%) | `metas.conclusao` = 100 |
| Cycle time | `meta ÷ cycle` → % de atingimento (≤ meta = verde) | `metas.cycle` = 3,7 dias úteis |
| Intruders | `intruders ÷ criadas`; dentro do alvo = 100%, acima = `alvo ÷ real` | `metas.intruders` = 14 (%) |

Cores: verde dentro da meta · âmbar até 20% (conclusão) / 15% (cycle) / 25% (intruders) fora · vermelho além disso.

**Fontes dos períodos (atenção):**
- **Outubro** = números do **painel Gestão › Indicadores do Quimera** (print do João, 09/11): 66 concluídas / 47 criadas = 140%; cycle 3,5 d.u. (106%); 6 intruders = 13% (limite 6 de 47).
- **Novembro** (parcial até 09/11) e **Trimestre** (01/09–09/11) = API do Quimera (`mcp__quimera__get_cycle_time`, contagens de finalizados/criados do levantamento), mesma conta concluídas÷criadas do painel.
- ⚠️ A tool `get_completion_rate` usa **outra fórmula** (finalizados *entre os criados* no período: outubro = 43/50 = 86%). Não misturar com a do painel. O cycle time do painel (3,5) também não bate com a média da API (4,67) nem com a mediana (3,63) — para outubro vale o print.

---

## 4. Fontes de informação usadas no seed (09/11/2026)

| Fonte | O que veio |
|---|---|
| **Quimera** (time `ia_automacao_finza`, via MCP) | 17 tickets abertos, finalizados de set–nov com datas reais/SP/responsável, indicadores (conclusão, cycle, intruders, CSAT) |
| `Apresentacoes/executando/roadmap.html` | itens do ciclo jun–set ainda abertos/adiados (R30 Maestro, R31 saúde Meta, R59 permissões, R45, R18, R80, R19…) e regras do Gantt antigo |
| `Apresentacoes/executando/Torre de Controle - Balanço do ciclo.html` | pilares do Q4 (refatoração da Torre, agentes, métricas, pendências) e componentes visuais |
| `Apresentacoes/entregues/entregas_roadmap_torre_dossie.html` | resíduo do bloqueio em massa, entregas de setembro |
| `entregas-q3_lideranca_06-11-2026.html` e roteiro Q3 | link de cobrança (4.735 links, 4,2% abertos), marcos de 07/10, 27/10 e 06/11 |
| `torre-config-agente_dossie_22-10-2026.html`, `metricas-agentes_guia-implementacao_dossie_20-10-2026.html` | governança de agentes, ondas de métricas |
| `Backlog/frentes/` (QMR12357, QMR12372, QMR12266, BTR07, BTR08…) e `Backlog/analises/17-09-2026/` | specs Nova Torre/Veritas/Mapa de Áreas, migração MARKETING→UTILITY |
| Artefatos claude.ai: **Legal Hub** (4DD1MdYs9tRPT1ZkZAYFCd + compartilhados), **Veritas 2.0** (4D3tN2qWeYRRiDG6ojRHZv + discovery T5htEJMzz6viTwntizo5iP), Mapa de áreas, Valentina v2 matriz, IA fora da LiteLLM, Campanha Open Finance, Twenty CRM | fases F1–F3 do Legal Hub (JusCore, LexCalc com critérios de aceite), fases do Veritas (4+8+6+4 semanas), pendências da Valentina v2, piloto Open Finance, migração LiteLLM |

**Datas sugeridas:** demandas planejadas sem data na fonte receberam `df:"sugerida"` (o supervisor propôs, o time técnico confirma). Finalizados no Quimera entraram com homologação `aprovada` e a nota "sem aceite formal registrado neste roadmap"; exceções com pendência (#7318, #11451, #8609, #8215) entraram como aguardando/ajustes/em homologação.

Composição do seed: **68 demandas + 5 marcos** — 31 entregas set–nov, 17 tickets abertos, 20 planejadas sem ticket.

---

## 5. Como ajustar

### 5.1 Atualizar status/datas a partir do Quimera (reconcile) — sem republicar
1. Puxar tickets do time (`/quimera` ou agente `quimera-ops`, só leitura).
2. `ArtifactData get roadmap/demandas` → anotar `version`.
3. `ArtifactData update roadmap/demandas` com `{ items: { "<id>": { qs, ir, fr, dev, sp } } }` e `if_version` (merge recursivo: só os campos enviados mudam).
4. Ticket novo que entra no roadmap: adicionar `items.q<nº>` completo (ver §2.1). Para trocar `pl-…` por ticket, preencher `key` e `qs` no mesmo item (não recriar).
5. Não sobrescrever `titulo`/`desc` curados com o texto cru do ticket; não mexer em `homolog/`, `obs/` e `historico/` (são do negócio).

### 5.2 Atualizar metas ou números dos anéis
`ArtifactData set roadmap/config` (com `if_version`) a partir de `Backlog/referencias/json/2026-11-09_roadmap-q4/config.json`. Para outubro/meses fechados, preferir os números do print do painel Gestão do Quimera.

### 5.3 Mudar visual/telas
Editar o `.html` (CSS em tokens no `:root`; visual = branco + Azul Finza `#1A1AFF`, navy `#0A0A2E`, padrão do Balanço do ciclo e do design system Finza) e republicar com o **mesmo caminho de arquivo** (Artifact publish) para manter o link. Não passar `capabilities` no republish (mantém as regras); se passar, repetir o bloco da §2.

Teste local sem o claude.ai:
```bash
node Backlog/referencias/json/2026-11-09_roadmap-q4/mkharness.js \
  Apresentacoes/executando/roadmap-q4_squad-negocio_09-11-2026.html <pasta-saida> gantt
# abre <pasta-saida>/h_gantt.html no navegador (db falso com o seed)
```
Visões aceitas: `painel · cronograma · gantt · quadro · demanda-<id>`. Headless do Edge/Chrome tem largura mínima ~500 px — para testar celular, renderizar a página dentro de um `<iframe>` de 400 px.

### 5.4 Regenerar o seed do zero
`node Backlog/referencias/json/2026-11-09_roadmap-q4/seed.js` reescreve `demandas.seed.json`. **Cuidado:** gravar esse seed por cima de `roadmap/demandas` apaga edições de planejamento feitas na tela — prefira o reconcile da §5.1.

---

## 6. Limitações conhecidas
- A página aplica o Quimera sozinha, mas só o do **último reconcile** embutido no `qmirror` (o MCP do Quimera é local do supervisor, não um conector do claude.ai). Para dados novos, rodar o reconcile da skill `roadmap-q4`.
- No Gantt com todas as frentes abertas (~70 linhas) a lista rola por dentro; recolhendo frentes tudo cabe na tela.
- Histórico não é imutável no nível do banco (ver §2).
- Responsáveis de homologação do negócio só foram pré-preenchidos onde eram claros (Sara/Jurídico, Jéssica/métricas, Crédito).

## 7. Histórico de versões
| Versão | Data | Mudança |
|---|---|---|
| v1 | 2026-11-09 | 4 visões (painel, calendário, gantt, kanban) + gaveta lateral; seed de 73 itens no db |
| v2 | 2026-11-09 | tema claro branco + azul (Balanço do ciclo); menu Painel · Cronograma · Quadro; anéis de meta do Quimera; tela própria da demanda |
| v3 | 2026-11-09 | Cronograma e Quadro sem rolar a página; homologação em card largo embaixo; barras de rolagem estilizadas; filtro de frentes em menu; contraste e responsividade (agenda no celular) |
| v4 | 2026-11-10 | Homologação só aparece em demanda **Em validação** (etapa 2 "Pronta para homologar" já cumprida); removidas as Observações do negócio da tela (fica só Registro formal); Sobre e Planejamento empilhados; botão "Cancelar e descartar" no Editar planejamento; filtros de responsável/homologação como dropdowns do padrão; "Só atrasadas" virou botão com contador. Reconcile com o Quimera: #12357 em andamento, #12549 e templates na fila, #7562 e #7322 cancelados, novo #12649, templates do lote de 09/11 agregados em #12588. Criada a skill `.claude/skills/roadmap-q4/` (regra no CLAUDE.md) |
| v5 (versão 17 do artefato) | 2026-11-12 | Base = versão viva editada fora da sessão (espelho `qmirror` com comentários do Quimera, plano `qmig` + botão "Sincronizar com Quimera", filtros Status/Quimera, excluir demanda, tipo melhoria). Nova visão **Visão em 5 minutos** (`#resumo`): hero com números, objetivos por frente com progresso, principais entregas, em curso, o que falta até dezembro, pontos de atenção e metas do trimestre. Reconcile de 12/11: #12266 → em andamento, #12649 → em validação, #12844 → fila (Marcos, 3 SP), #12530 e o lote de templates (#12588/QTPL) → finalizados; entraram #13003 e #12984; #12941 fica fora por pedido do João; metas nov (44/29, cycle 2,66, 1 intruder) e trimestre (221/226, cycle 4,19, 8 intruders) pela API |
| v6 (versão 18 do artefato) + dados | 2026-11-13 | Reconcile com o Quimera: #12549 e #12844 → em validação (13/11); entram #13017 (e-mail com boleto em anexo, Marcos, em andamento) e #13002 (template com meios de pagamento para o preventivo, fila); #13001 é a formalização do mesmo escopo da #13003 e virou relacionada dela; #13054 (Vincular Número) fica fora por ser operacional; #12941 continua fora. Datas: inícios reais pelo histórico de status (#10717 19/10, #10908 20/10, #6871 22/10, #12649 11/11, #12549 10/11), previstas pela `expected_delivery_date` do Quimera (#6871 → 13/11), início sugerido 16/11 para #12372 e #12239 (ainda na fila). `qmirror` com status e comentários novos (#12844, #12009, #12372) e `qmig.dates/recon` alinhados, para o botão Sincronizar não reverter. Metas: nov parcial até 13/11 (46 criadas, 30 concluídas, cycle 2,58, 1 intruder) e trimestre (223/227, cycle 4,17, 8 intruders). Snapshots antes/depois e patch em `Backlog/referencias/json/2026-11-09_roadmap-q4/2026-11-13_*` |
| v7 (versão 24 do artefato) + dados | 2026-11-18 | **Sync automático com o Quimera:** removidos o botão "Sincronizar com Quimera" e o plano `qmig`; a página aplica o espelho `qmirror` sozinha na leitura (`qoverlay`: status, entrega prevista = `expected_delivery_date` do Quimera, entrega real, responsável, SP) e mostra "Quimera sincronizado em …" (`qmeta`). Regra nova: **a data prevista verdadeira é a do Quimera**; janela fixa de reconcile 01/10/2026 → hoje (skill `roadmap-q4` §2b/§3). Reconcile de 18/11 (db v37, 17 demandas): finalizados #12844, #10894, #12009, #12649, #13001, #13017, #13545; #12239 → em validação; #12372 e #13433 → em andamento; #13521 → fila (João Pedro, 8 SP, entrega 02/12); datas de #12239/#12530/#12588 passaram de sugeridas para Quimera; inícios reais pelo histórico. Script `build-qmirror.js`, fetch e patch em `Backlog/referencias/json/2026-11-09_roadmap-q4/2026-11-18_*` |
| v8 (versão 26 do artefato) + dados | 2026-11-23 | Reconcile 01/10 → 23/11 (db v38 → v39, 9 itens): finalizados #12239 (20/11), #12357 (23/11), #13824 (23/11), #13847 (23/11); #13457 → em validação (19/11); #13521 → em andamento (19/11); #13902 → fila (Leandro, 3 SP, entrega 27/11); início real de #13860 (19/11); entra #14087 (Lívia na AWS: credenciais e segredos, Marcos, sem data no Quimera). `qmirror` com 17 tickets e `qmeta` 23/11. Script novo `update-qmirror.js` (só mescla espelho + carimbo; o `build-qmirror.js` era da migração v7). Fetch e patch em `Backlog/referencias/json/2026-11-09_roadmap-q4/2026-11-23_*` |
| dados | 2026-11-12 | A execução da Nova Torre virou duas demandas (arquitetura da #12357: 1 front · 2 APIs · 1 banco Postgres): `pl-torre-marco` = front + API Torre de CRUD e orquestração (Leandro); `pl-torre-motor` = Motor de Disparos universal via mensageria com Temporal (Marcos). As duas vão de 20/11 a 25/12 |

> **Manutenção:** antes de qualquer ajuste, carregar a skill `roadmap-q4` — ela define o escopo do quadro e o procedimento de reconcile. A seção "Observações do negócio" citada acima (§1, §2) foi retirada da tela na v4; os docs `obs/` antigos continuam no banco e aparecem no histórico.

Relacionados: memória `roadmap-q4-2026-artefato`, `roadmap-html-quimera-mirror` (roadmap do ciclo anterior), `Apresentacoes/executando/roadmap.html`.
