---
name: finza-design-system
description: Especificação canônica do design system Finza para slides HTML. Use sempre que precisar aplicar paleta, tipografia, layout ou componentes visuais (cards dotted, marcador iaf, numeração olho, hero dark, pílulas) em qualquer apresentação. Carregue esta skill antes de definir layout ou escrever CSS.
---

# Finza Design System — slides HTML

Sistema visual canônico extraído da apresentação corporativa Finza (`Apresentacoes/referencias/Boas Vinda FINZA - Tech - 2026.pdf`) e refinado no deck CTO 13/05/2026. **Não negociável**: cada slide produzido neste workspace segue este sistema.

---

## 1 · Tokens de cor

Declare como CSS variables em `:root`. Não use cores fora desta lista.

| Token | Hex | Uso |
|---|---|---|
| `--finza-blue` | `#1A1AFF` | Primária. Fundo splash, accent em títulos, números grandes, bordas dotted, ícones-chave. |
| `--finza-blue-deep` | `#0F0F8C` | Hover, accents secundários. |
| `--finza-blue-soft` | `#E8E8FF` | Fundo de pílulas, stack tags, cards "featured". |
| `--finza-dark` | `#0A0A2E` | Fundo splash dark, "olhos" de numeração, texto principal. |
| `--bg` | `#F2F2F2` | Fundo cinza claro dos slides de conteúdo. |
| `--surface` | `#FFFFFF` | Fundo de cards sobre o cinza. |
| `--ghost` | `#C8C8D4` | Cor dos títulos "fantasma" (peso 300). |
| `--text` | `#0A0A2E` | Texto principal. |
| `--text-muted` | `#5C5C7A` | Texto secundário, metadados, legendas. |
| `--border` | `#D8D8E5` | Linhas finas separadoras. |
| `--success` | `#10B981` | Status concluído. Verde. |
| `--warning` | `#F59E0B` | Status em curso ou gap. Laranja. |
| `--danger` | `#EF4444` | Riscos críticos. Vermelho. |

---

## 2 · Mix de fundos por slide

| Tipo de slide | Fundo | Texto base | Uso |
|---|---|---|---|
| **Capa** (splash azul) | `--finza-blue` | branco | Slide 1. Big bang. |
| **Conteúdo** | `--bg` (`#F2F2F2`) | `--text` | Maioria dos slides. |
| **Fechamento** (splash dark) | `--finza-dark` | branco | Último slide ou hero interno. |

A classe `splash-blue` no `<section>` ativa fundo azul; `splash-dark` ativa fundo dark. O JS adiciona `body.slide-is-dark` quando o slide ativo é splash — setas e contador adaptam cor para fundo escuro.

---

## 3 · Tipografia

**Família única**: Inter (Google Fonts), pesos `300, 400, 500, 600, 700, 800`.

```html
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
```

| Elemento | Tamanho | Peso | Cor | Notas |
|---|---|---|---|---|
| `h1` (título de slide) | 56–64px | **300** em `--ghost` + `.accent` 700 em `--finza-blue` | — | Padrão **ghost title** (ex: "Squad IAF — **Estado e Direção**"). |
| `h2` (subtítulo) | 22–24px | 500 | `--text-muted` | Linha imediatamente abaixo do h1. |
| `h3` (sub-cabeçalho) | 17–22px | 600–700 | `--text` | Cabeçalho de card ou seção. |
| Corpo | 13–17px | 400–500 | `--text` | `line-height: 1.5`. |
| Caption/meta | 10–13px | 600–700 | `--text-muted` ou `--finza-blue` | `letter-spacing: 0.14–0.20em`, `text-transform: uppercase`. |

**Ghost title** (assinatura Finza):
```html
<h1>Squad IAF — <span class="accent">Estado e Direção</span></h1>
```
```css
h1 { font-weight: 300; color: var(--ghost); font-size: 60px; line-height: 1.1; }
h1 .accent { font-weight: 700; color: var(--finza-blue); }
```

---

## 4 · Padrões visuais (não-negociáveis)

### 4.1 Marcador "◆ iaf"
Canto superior direito de **todo** slide. Em slides splash, vira branco translúcido.
```html
<span class="iaf-mark">◆ iaf</span>
```
```css
.iaf-mark { position: absolute; top: 32px; right: 40px; font-size: 12px; font-weight: 700;
            color: var(--finza-blue); letter-spacing: 0.08em; }
.splash-blue .iaf-mark, .splash-dark .iaf-mark { color: rgba(255,255,255,0.7); }
```

### 4.2 Cards com borda dotted
Assinatura visual mais marcante da Finza. Use para qualquer agrupamento de informação.
```css
.card { border: 2px dotted var(--finza-blue); border-radius: 12px; background: var(--surface);
        padding: 24px; }
```

### 4.3 Numeração tipo "olho"
Círculo dark com número branco centralizado. Usar em listas/cards numerados (slides de plataformas, etapas).
```html
<div class="eye">3</div>
```
```css
.eye { width: 32px; height: 32px; border-radius: 50%; background: var(--finza-dark);
       color: #fff; display: flex; align-items: center; justify-content: center;
       font-weight: 700; font-size: 14px; }
```

### 4.4 Pílulas de stack/tag
```css
.pill { display: inline-flex; align-items: center; gap: 6px; padding: 4px 12px;
        background: var(--finza-blue-soft); color: var(--finza-blue);
        border-radius: 999px; font-size: 12px; font-weight: 600; }
```

### 4.5 Banner accent
Destaca prazo, insight, lede.
```css
.banner { background: var(--finza-blue); color: #fff; padding: 18px 24px;
          border-radius: 10px; font-weight: 500; }
.banner.dark { background: var(--finza-dark); }
```

### 4.6 Tag numérica (P01, E01)
Substitui emojis decorativos em cards de problemas/gaps.
```css
.tag-num { display: inline-block; padding: 2px 8px; background: var(--finza-blue);
           color: #fff; border-radius: 4px; font-size: 11px; font-weight: 700;
           letter-spacing: 0.06em; }
```

### 4.7 Hero escuro (`.esp-hero` style)
Bloco destacado dentro de slide de conteúdo. Usado no slide da Esperanza.
```css
.hero-dark { background: var(--finza-dark); color: #fff; padding: 32px;
             border-radius: 14px; box-shadow: 0 8px 24px rgba(10,10,46,0.15); }
```

---

## 5 · Layout do slide

**Container base:**
```css
section.slide { display: none; position: relative; width: 100vw; height: 100vh;
                padding: 80px 96px; box-sizing: border-box;
                background: var(--bg); color: var(--text); }
section.slide.active { display: flex; flex-direction: column; }
section.slide.splash-blue { background: var(--finza-blue); color: #fff; }
section.slide.splash-dark { background: var(--finza-dark); color: #fff; }
```

**Grid de cards** (padrões mais usados):
- 2×3 — slide de problemas (6 cards), gaps (4-6 cards).
- 3×2 — objetivos estratégicos, capacidades.
- 5 horizontais — plataformas.
- 4×1 — gaps compactos (border-left warning).

---

## 6 · Navegação (HUD)

| Elemento | Visível em | Notas |
|---|---|---|
| Setas `‹ ›` clicáveis | Todos exceto slide 1 (esquerda) e último (direita) | Círculo branco com borda azul, hover preenche azul. Em splash escuro, translúcidas. |
| Contador `n / total` | Todos exceto slide 1 | Rodapé direito, peso 600, `--text-muted` ou branco em splash. |
| Hint de teclas | Todos exceto slide 1 | Rodapé esquerdo, opcional. |

**JS mínimo obrigatório:**
- `ArrowRight` / `Space` / `PageDown` → próximo
- `ArrowLeft` / `PageUp` → anterior
- `Home` → primeiro; `End` → último
- `Escape` → abre overview (grid de thumbnails)
- `F` → toggle fullscreen
- Click em `.nav-arrow.left` / `.nav-arrow.right` → prev/next
- Click em thumbnail no overview → `goTo(n)` + fecha overview
- Em cada `goTo(n)`: aplica/remove `body.slide-is-dark` baseado em `splash-blue`/`splash-dark`

---

## 7 · Princípios visuais

- **Um conceito por slide.** Dois conceitos = dois slides.
- **Texto curto.** Bullets de no máximo 1–2 linhas.
- **Sem clipart, sem stock photo, sem emoji decorativo.** Emojis funcionais (✓ → 🎯 📅 📍 📇 📐 📣 🧠 🔄 🔌) OK quando carregam significado.
- **Números visíveis.** Quando houver número (40%, 6 sprints, 10/jul), aparece grande em `--finza-blue` peso 700.
- **Sóbrio.** Branco/cinza dominante. Azul cirúrgico — em títulos, números-chave, bordas, banners.
- **Densidade respirada.** Padding generoso, line-height 1.5+, hierarquia tipográfica clara.

---

## 8 · Stack técnica obrigatória

- HTML5 + CSS3 + JavaScript vanilla. **Single-file** `index.html` ou `<nome>_<destino>_DD-MM-YYYY.html`.
- Tudo inline. Sem build step.
- Sem React, Vue, Reveal.js, Tailwind, libs de ícone.
- Única dependência externa: Google Fonts (Inter).
- Sem imagens externas. SVG inline quando necessário, mínimo.
- Resolução alvo: 1920×1080 projetado. Responsivo o bastante para laptop, não precisa funcionar em mobile.
- Acessibilidade: contraste AA, `<section>` por slide com `aria-labelledby`, foco visível.

---

## 9 · Referência viva

A apresentação `Apresentacoes/entregues/apresentacao_cto_13-05-2026.html` é a **implementação canônica** deste design system. Quando em dúvida sobre como aplicar um padrão, abra esse arquivo e copie a estrutura.

`Docs/BRIEFING.md` documenta a evolução das decisões visuais. Leia-o antes de inovar.
