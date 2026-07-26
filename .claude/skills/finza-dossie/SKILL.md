---
name: finza-dossie
description: Padrão canônico dos DOCUMENTOS/RELATÓRIOS HTML de rolagem única da Finza — o "dossiê" de scroll (topbar + scrollspy, hero com métricas animadas, seções, cards pontilhados, callouts, diagrama de fluxo, tabelas, pílulas de status, mockup de WhatsApp, tema claro/escuro), no estilo de clara.html e alerta-ccb-dossie.html. Carregue sempre que for produzir um documento, relatório ou dossiê de uma IA/agente Finza (Clara, Valentina, Esperanza, Lívia, etc.) ou de uma automação/sistema, "no padrão da Clara" / "igual ao dossiê". NÃO é para slides (isso é finza-design-system + /novo-deck) nem para relatório markdown de backlog (isso é /relatorio).
---

# Finza Dossiê — documentos HTML de rolagem única

Padrão visual canônico dos **documentos/relatórios de página única** da Finza: um único `.html` self-contained que se lê rolando (não passando slides). É o formato do **`clara.html`** (dossiê da agente Clara) e do **`alerta-ccb-dossie.html`** (console de operações da automação de Alerta CCB) na raiz do repositório.

Use para: dossiê de uma IA/agente Finza, relatório técnico navegável de um sistema/automação, "one-pager" executivo rico. O produto é sempre **um arquivo HTML que abre em qualquer navegador, sem dependências, sem build**.

---

## 0 · Quando usar (e quando NÃO)

| Situação | Ferramenta |
|---|---|
| "Faz um documento/dossiê da Valentina igual o da Clara" · "relatório navegável do agente X" · "one-pager visual desse sistema" | **esta skill** → produz `.html` de rolagem |
| Slides / deck / apresentação passada slide-a-slide | `finza-design-system` + `/novo-deck` (formato 1920×1080, deck-stage) |
| Relatório `.md` para o backlog/gestão (devolutiva, status para terceiros) | `/relatorio` (markdown em `Backlog/analises/.../relatorios/`) |
| Converter um deck de slides existente em dossiê de rolagem | esta skill (foi assim que `clara.html` nasceu de `apresentacao-clara/`) |

**Diferença-chave para o design system de slides:** slides são `finza-design-system` (Inter, seções fixas 1920×1080, navegação por teclado). O dossiê é **rolagem vertical responsiva**, tema claro/escuro, com uma biblioteca de componentes própria (abaixo). Não misture os dois.

---

## 1 · Contrato do formato (não-negociável)

- **Single-file HTML5 + CSS + JS vanilla.** Zero build, zero framework, zero CDN de script.
- **100% self-contained.** Sem imagens externas. Marca textual `◆ iaf` + ícones **SVG inline**. Nada de `<img src>` para arquivo externo.
- **Fonte Montserrat embutida em base64** (`@font-face` data URI) — é a fonte das IAs Finza e mantém o arquivo autônomo. Ver §5. *(Alternativa leve, se 1,7 MB incomodar: Inter via Google Fonts como o `alerta-ccb-dossie.html` — some o self-contained, precisa de internet.)*
- **Tema claro/escuro** via `data-theme` no `<html>` + botão toggle. Tokens dos dois temas já no template.
- **Reveal on scroll + count-up + scrollspy** — máquinas JS já prontas no template.
- **Responsivo** (grids colapsam em ≤980px e ≤640px).
- **Acessibilidade:** contraste AA, `aria-label` no toggle, foco visível, `prefers-reduced-motion` respeitado.

**Regra de conteúdo (a mais importante):** **não invente nada** sobre a IA/sistema. Todo fato vem do material-fonte (deck, transcrição, doc, código, resposta do gestor). Sem fonte confiável → marque `<!-- TODO: confirmar -->` em vez de fabricar. Números aparecem em destaque azul. Quando incerto, declare a incerteza (ex.: pílula "validada em teste", estado "Stub em teste").

---

## 2 · Como construir (fluxo)

1. **Reúna o material-fonte** e liste os fatos (use `finza-researcher` para IAs/sistemas Finza). Nada entra sem origem rastreável.
2. **Copie `template.html`** desta skill para o destino (§7). Ele já traz tokens + toda a biblioteca de componentes + JS + placeholder de fonte.
3. **Preencha do topo pra baixo:** `<title>`, brand do topbar, nav `.spy` (uma âncora por seção), hero (pills + h1 ghost/accent + sub + meta + métricas), seções, footer. Cada seção `<section class="section" id="...">` tem `id` que **precisa bater** com uma âncora do menu.
4. **Escolha os componentes** por tipo de conteúdo (§3). Reaproveite os do template; não invente CSS novo sem necessidade.
5. **Embuta a fonte Montserrat** rodando o script de injeção (§5) — troca o `/*__FONTS__*/` pelos 4 `@font-face` base64.
6. **Valide** (§6) e abra no navegador.

O `clara.html` é a **implementação canônica**: quando em dúvida de como um bloco fica montado, abra-o e copie a estrutura.

---

## 3 · Anatomia + biblioteca de componentes

Ordem da página: `.bg` + `.bggrid` (ambiente) → `.topbar` (brand + `nav.spy` + `◆ iaf` + `#themeBtn`) → `header.hero` → `<main>` com N `.section` → `<footer>`.

Todo bloco de conteúdo dentro de uma `.section` abre com `.eyebrow` (kicker) + `h2` + opcional `.lede`, e ganha classe `.reveal` para animar na rolagem.

**Componentes** (classes já no template):

| Componente | Classe | Quando usar |
|---|---|---|
| Hero com métricas | `.hero` + `.metrics` `.metric` (`data-count="N"`) | Abertura. Pills de status, h1 `ghost + .g accent`, sub, meta mono, 4–5 métricas com count-up (só números literais do material). |
| Card pontilhado | `.card` (`2px dotted`, com `.iaf` "◆ iaf") | "É / não é", listas de bullets com ✓/✕, blocos destacados. |
| Card de feature | `.feat` (`.feat.hl` = azul cheio) | Grades de capacidades/segurança/modos (ícone SVG + título + 1 frase). Use em `.grid3`. |
| Callout | `.callout` (`.ok`/`.warn`/`.crit`) | Aviso, ressalva, nota de segmento (com `.badge`). |
| Arco de estágios | `.arc` `.arcstage` (`.final` = azul) | Linha do tempo / evolução "antes → depois → hoje". |
| Jornada numerada | `.journey` `.jstep` (`.start`/`.end`) | Passo a passo do fluxo do cliente (1→N). |
| Pipeline | `.pipe` `.pnode` (`.io` tracejado, `.accent`) + `.tools`/`.chip` | Diagrama de arquitetura (nós ponta a ponta). **Estático** — só faça nós clicáveis (drawer) se houver "detalhe técnico" real por nó; senão é invenção. |
| Mockup WhatsApp | `.mockrow` `.phone` `.wa` `.wbubble` (`.out`) `.consolidate` | Simular conversa (debounce, exemplo de atendimento). |
| Mecânica + stat tiles | `.mech` `.m` + `.statrow` `.stattile` | Explicar mecanismo (ícone + título + frase) e cravar 2–3 números. |
| Aceita/recusa | `.accept` `.ac` (`.yes`/`.no`) | Contraste do que é aceito × recusado. |
| Tabela + status | `.tablewrap` `table` + `.st` (`.stub`/`.prod`) + `.legend` | Integrações, matriz de estados, comparativos. |
| Cadeia de eventos | `.chain` `.ev` (`.fire` = azul) | Gatilho event-driven "evento → ... → ação". |
| Version steps | `.vsteps` `.vstep` (`.cur`) + `.qstats` `.qstat` (`.hl`) | Evolução de versões + métricas de qualidade grandes. |
| Listas de futuro | `.flist` (mk ✓ ou →) + `.goal` (banner azul) | Estado atual × pendências + frase-meta. |
| Fecho | `.resumo` (dotted + `.iaf`) + `.points` `.p` | Seção final: síntese + pílulas dos pilares. |

Ícones: SVG stroke inline com classe `.ico` (herda `currentColor`). Reaproveite os do template/`clara.html`; não use libs de ícone.

---

## 4 · Tokens (resumo)

Estão em `:root` e `:root[data-theme="dark"]` no template — **não redefina cores fora deles**. Núcleo:

- `--finza-blue #1A1AFF` (claro) / `#6E6EFF` (escuro) — primária: accent do h1, bordas dotted, números, nós accent.
- `--finza-blue-soft` — fundo de pílulas/thead/badges. `--finza-blue-deep` — hover/`.jstep.end`.
- `--ink` texto · `--muted` secundário · `--faint` metadados · `--ghost` título fantasma do hero.
- `--void`/`--deep`/`--panel` superfícies. `--stroke` linhas.
- Acentos de status: `--success` (ok/prod), `--amber` (warn/stub), `--coral` (crit/recusa).
- Fontes: `--f-disp`/`--f-body` = `"Montserrat"` (com fallback sans-serif); `--f-mono` = monoespaçada do sistema (usada em pills, nav, metadados, `.src`).

---

## 5 · Embutir a fonte Montserrat (base64)

O template deixa `<style id="montserrat">/*__FONTS__*/</style>`. Sem injeção, cai no fallback sans-serif do sistema (renderiza, mas não é Montserrat). Para embutir os 4 pesos (Regular 400, Medium 500, SemiBold 600, Bold 700), rode a partir da raiz do repo — os `.ttf` moram em `.claude/skills/finza-dossie/assets/`:

```powershell
$root  = (Get-Location).Path
$doc   = "Apresentacoes\executando\SEU-ARQUIVO.html"   # ajuste
$fonts = ".claude\skills\finza-dossie\assets"
$map = @(@{f="Montserrat-Regular.ttf";w=400},@{f="Montserrat-Medium.ttf";w=500},@{f="Montserrat-SemiBold.ttf";w=600},@{f="Montserrat-Bold.ttf";w=700})
$sb = New-Object System.Text.StringBuilder
foreach($m in $map){
  $b64=[Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $root (Join-Path $fonts $m.f))))
  [void]$sb.Append("@font-face{font-family:'Montserrat';src:url(data:font/ttf;base64,$b64) format('truetype');font-weight:$($m.w);font-style:normal;font-display:swap}")
}
$html=[IO.File]::ReadAllText((Join-Path $root $doc))
$html=$html.Replace('/*__FONTS__*/',$sb.ToString())
[IO.File]::WriteAllText((Join-Path $root $doc),$html,(New-Object System.Text.UTF8Encoding($false)))
```

Resultado: ~+1,7 MB no arquivo, porém 100% autônomo. Faça a injeção **por último** (o base64 é gigante — não o edite à mão; se precisar reformatar o HTML depois, reinjete).

---

## 6 · Checklist de QA

- [ ] Toda âncora do `nav.spy` tem uma `<section id>` correspondente (e vice-versa).
- [ ] Cada `.section` abre com `.eyebrow` + `h2`; blocos animáveis têm `.reveal`.
- [ ] Métricas do hero (`data-count`) usam **só números presentes no material** (sem invenção).
- [ ] Fonte Montserrat embutida (4 `@font-face`; nenhum `/*__FONTS__*/` sobrando) **ou** decisão consciente por Inter/Google Fonts.
- [ ] Sem `<img>` externo, sem `<script src>` de CDN, sem lib.
- [ ] Toggle claro↔escuro sem quebra; nenhuma cor fora dos tokens.
- [ ] Marca `◆ iaf` no topbar (e nos cards `.card`/`.resumo` quando fizer sentido).
- [ ] Cada afirmação rastreável ao material-fonte; incertezas declaradas, não escondidas.
- [ ] Abre e rola limpo no navegador; sem overflow horizontal no mobile.

---

## 7 · Saída e nomenclatura

- **Destino padrão:** `Apresentacoes/executando/` enquanto constrói; mover para `Apresentacoes/entregues/` quando apresentado. Dossiês de referência muito consultados podem ficar na raiz (é o caso de `clara.html` e `alerta-ccb-dossie.html`).
- **Nome:** `<agente-ou-tema>_dossie_DD-MM-YYYY.html` (minúsculo, kebab) — ex.: `valentina_dossie_24-07-2026.html`. Sem espaços.
- Não altere o material-fonte (deck/transcrição/doc). O dossiê é derivado.

---

## 8 · Referências vivas

- **`clara.html`** (raiz) — implementação canônica completa. Copie estruturas daqui.
- **`alerta-ccb-dossie.html`** (raiz) — variante com Inter/Google Fonts, drawer clicável em fluxo, faixas e code blocks (componentes extras não incluídos no template enxuto; herde deles se precisar).
- **`template.html`** (nesta skill) — scaffold pronto (mesma máquina de `clara.html`, fontes como placeholder). Ponto de partida de todo dossiê novo.
- Conteúdo/negócio: `finza-contexto`, `Docs/finza/`, `Backlog/contexto/` (via `finza-researcher`). Voz: os princípios de número/incerteza de `finza-tom-voz` valem aqui.
