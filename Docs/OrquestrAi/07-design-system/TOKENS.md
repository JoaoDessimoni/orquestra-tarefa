# Design Tokens — OrquestrAI (canônico Finza)

> Paleta, tipografia, spacing, radius, shadows, motion. **Tokens canônicos Finza** (skill `finza-design-system`). Última atualização: 21/05/2026.

## Fontes

- `.claude/skills/finza-design-system/SKILL.md` (fonte canônica)
- Referência viva: `Apresentacoes/entregues/apresentacao_cto_13-05-2026.html`
- `BOARD.html` (protótipo OrquestrAI v2)

---

## 1 · Princípio

OrquestrAI **não inventa identidade visual** — herda da Finza canônica. O design system é dual:

- **Slides Finza** (`.claude/skills/finza-design-system/`) — fonte autoritativa.
- **OrquestrAI** — aplica os mesmos tokens em contexto enterprise web (sidebar dark + dotted cards + ghost h1 + ◆ iaf marker).

Resultado: o produto se sente como **Finza, profundamente** — não como uma SaaS genérica light.

---

## 2 · Paleta canônica

| Token | Hex | Uso |
|---|---|---|
| `--finza-blue` | `#1A1AFF` | Primária. Accent, números grandes, bordas dotted, botão primário, sidebar item ativo. |
| `--finza-blue-deep` | `#0F0F8C` | Hover do primário, acentos secundários. |
| `--finza-blue-soft` | `#E8E8FF` | Background de pills, tags, badges accent, cards featured. |
| `--finza-dark` | `#0A0A2E` | **Sidebar background**, hero-dark, toast, texto principal. |
| `--bg` | `#F2F2F2` | Background do main do app. |
| `--surface` | `#FFFFFF` | Fundo de cards, modais, inputs. |
| `--surface-hover` | `#FAFAFC` | Hover de linha de tabela. |
| `--ghost` | `#C8C8D4` | Cor dos títulos h1 "ghost" (peso 300). |
| `--text` | `#0A0A2E` | Texto principal. |
| `--text-muted` | `#5C5C7A` | Texto secundário, metadados. |
| `--text-subtle` | `#9090A8` | Captions, timestamps, ícones. |
| `--border` | `#D8D8E5` | Bordas de inputs, divisores fortes. |
| `--border-soft` | `#ECECF2` | Divisores internos sutis. |
| `--success` | `#10B981` | Status concluído/done/publicada. |
| `--success-soft` | `#D1FAE5` | Background de badge success. |
| `--warning` | `#F59E0B` | Status em-curso/revisao/atenção. |
| `--warning-soft` | `#FEF3C7` | Background de badge warning. |
| `--danger` | `#EF4444` | Erros, bloqueada, atrasado, ações destrutivas. |
| `--danger-soft` | `#FEE2E2` | Background de badge danger. |
| `--info` | `#0EA5E9` | Status running, info. |
| `--info-soft` | `#E0F2FE` | Background de badge info. |

### Frentes do Roadmap

| Token | Hex | Frente |
|---|---|---|
| `--frente-esperanza` | `#1A1AFF` | Esperanza (mesmo Finza blue) |
| `--frente-valentina` | `#6B5BFF` | Valentina (roxo) |
| `--frente-clara` | `#00B8D4` | Clara (cyan) |
| `--frente-torre` | `#FF6B35` | Torre (laranja) |
| `--frente-automacoes` | `#10B981` | Automações (verde) |
| `--frente-estrategica` | `#8B5CF6` | Estratégica (roxo profundo) |

---

## 3 · Mix de fundos por superfície

| Superfície | Background | Texto |
|---|---|---|
| Sidebar | `--finza-dark` (#0A0A2E) | branco / `rgba(255,255,255,.7)` |
| Topbar | `--surface` (branco) | `--text` |
| Main | `--bg` (#F2F2F2) | `--text` |
| Cards | `--surface` + border `2px dotted --finza-blue` | `--text` |
| Hero-dark (Dashboard) | `--finza-dark` | branco com `--finza-blue-soft` como accent |
| Toast | `--finza-dark` | branco |
| Modal | `--surface` + border `2px dotted --finza-blue` | `--text` |

> A **sidebar dark** + **cards dotted** é a marca visual da Finza dentro do produto.

---

## 4 · Tipografia

**Família primária**: Inter (Google Fonts), pesos `300, 400, 500, 600, 700, 800`.
**Família mono**: JetBrains Mono (IDs, timestamps, KBDs, mono em geral).

### Escala

| Token | Tamanho | Peso | Cor | Uso |
|---|---|---|---|---|
| `.ghost` (h1) | **42px** | **300** | `--ghost` (#C8C8D4) | Título de view. Tem `.accent` 700 em azul Finza. |
| `.sub` | 14px | 400 | `--text-muted` | Subtítulo, max-width 720px. |
| h2 / card h3 | 14–18px | 600 | `--text` | Cabeçalho de card. |
| body | 13.5px | 400 | `--text` | Corpo principal. |
| caption / mono small | 10–11px | 500 | `--text-subtle` | Timestamps, IDs, KBDs. |
| KPI number | 34px | 700 mono | `--finza-blue` | KPI cards. |
| Hero number | 32px | 700 mono | `#fff` | hero-dark stats. |

### Ghost title (assinatura Finza)

```html
<h1 class="ghost">Dashboard — <span class="accent">Produção & Gestão</span></h1>
```

```css
.ghost { font-weight: 300; color: var(--ghost); font-size: 42px; line-height: 1.1; letter-spacing: -.015em; }
.ghost .accent { font-weight: 700; color: var(--finza-blue); }
```

---

## 5 · Spacing, Radius, Shadows, Motion, Z

Escala 4px (`--space-1` = 4px ... `--space-16` = 64px).

| Item | Valor |
|---|---|
| Card padding | 20px |
| Row tabela | 36px |
| Sidebar item | padding 7px 10px |
| Main padding | 36px 48px 96px |
| `--radius-sm/md/lg` | 6 / 10 / 14 px |
| `--shadow-sm/md/lg` | 1/4/20 px elevations |
| `--ring` | 0 0 0 3px rgba(26,26,255,.18) (focus) |
| Motion | fast 100ms · base 150ms · slow 250ms |
| Z | sidebar 10 · topbar 20 · modal 50 · toast 60 · cmdk 70 |

---

## 6 · Tokens completos (copy-paste)

```css
:root {
  --finza-blue:#1A1AFF; --finza-blue-deep:#0F0F8C; --finza-blue-soft:#E8E8FF; --finza-dark:#0A0A2E;
  --bg:#F2F2F2; --surface:#FFFFFF; --surface-hover:#FAFAFC; --ghost:#C8C8D4;
  --text:#0A0A2E; --text-muted:#5C5C7A; --text-subtle:#9090A8;
  --border:#D8D8E5; --border-soft:#ECECF2;
  --success:#10B981; --success-soft:#D1FAE5;
  --warning:#F59E0B; --warning-soft:#FEF3C7;
  --danger:#EF4444;  --danger-soft:#FEE2E2;
  --info:#0EA5E9;    --info-soft:#E0F2FE;
  --frente-esperanza:#1A1AFF; --frente-valentina:#6B5BFF; --frente-clara:#00B8D4;
  --frente-torre:#FF6B35; --frente-automacoes:#10B981; --frente-estrategica:#8B5CF6;
  --font-sans:'Inter',sans-serif; --font-mono:'JetBrains Mono',monospace;
  --radius-sm:6px; --radius-md:10px; --radius-lg:14px;
  --shadow-sm:0 1px 2px rgba(10,10,46,.06);
  --shadow-md:0 4px 12px rgba(10,10,46,.08);
  --shadow-lg:0 20px 40px rgba(10,10,46,.18);
  --ring:0 0 0 3px rgba(26,26,255,.18);
}
```

---

## 7 · Histórico

| Versão | Data | Mudança |
|---|---|---|
| v1 | 2026-05-20 | Tokens iniciais — paleta light Linear-style (descartada) |
| **v2** | **2026-05-21** | Volta à paleta canônica Finza. Sidebar dark, cards dotted, ghost h1, marcador ◆ iaf. Tokens herdados de `finza-design-system`. |
