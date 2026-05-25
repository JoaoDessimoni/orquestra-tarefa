# Command Palette (Cmd+K)

> Overlay global de navegação + ações + busca fuzzy. Estilo Linear. Última atualização: 20/05/2026.

## Fontes

- [REQUISITOS_FUNCIONAIS.md](../01-requisitos/REQUISITOS_FUNCIONAIS.md) §RF-CP
- [COMPONENTES.md](../07-design-system/COMPONENTES.md) §9

---

## 1 · Atalho

- `Cmd+K` (macOS)
- `Ctrl+K` (Windows/Linux)

Disponível em **qualquer tela** (registrado no layout raiz do App Router).

---

## 2 · Layout visual

```
┌────────────────────────────────────────────────────────────────┐
│                                                                │
│  🔍  digitar para filtrar...                             ⌘K   │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  AÇÕES                                                         │
│  ───────────────                                               │
│  + Nova Análise                                          ⌘ N  │
│  + Novo Agente                                                │
│  + Novo Relatório                                             │
│  + Nova Skill                                                 │
│  ▶ Executar Agente: Researcher Finza                          │
│  ▶ Executar Agente: Slide Writer                              │
│                                                                │
│  NAVEGAR                                                       │
│  ───────────────                                               │
│  → Dashboard                                              1   │
│  → Agentes                                                3   │
│  → Execuções                                              2   │
│  → Análises                                               6   │
│  → Settings                                               ,   │
│                                                                │
│  AGENTES                                                       │
│  ───────────────                                               │
│  ◆ researcher-finza                                            │
│  ◆ slide-writer                                                │
│  ◆ drafter                                                     │
│                                                                │
│  ANÁLISES RECENTES                                             │
│  ───────────────                                               │
│  🔍 demandas-cobranca-time-negocio                             │
│  🔍 cruzamento-roadmap-iaf                                     │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 3 · Conteúdo do índice (grupos)

| Grupo | Origem | Limit |
|---|---|---|
| **AÇÕES** | Estático + agentes (para "Executar X") | Top 6 priorizadas |
| **NAVEGAR** | Estático (rotas da sidebar) | Todas |
| **AGENTES** | `GET /api/agents?limit=50` | Top 5 mais recentes (sem query) ou matches da query |
| **ANÁLISES RECENTES** | `GET /api/analyses?limit=10&sort=updated_at:desc` | Top 5 |
| **EXECUÇÕES RECENTES** (V1+) | `GET /api/executions?limit=10` | Top 5 |
| **SKILLS** (V1+) | `GET /api/skills?limit=50` | Top 5 matches |

> Sem query digitada: mostra "recentes" de cada grupo.
> Com query: filtra cada grupo por fuse.js em campos relevantes.

---

## 4 · Comportamento

### Abertura

- `Cmd/Ctrl+K` em qualquer tela → abre overlay
- Foco automático no input
- Animation: scale 0.95 → 1, opacity 0 → 1, 150ms `--ease-spring`

### Navegação

- `↑` / `↓` move seleção entre items (cross-grupo)
- `Tab` / `Shift+Tab` mesmo comportamento
- `Enter` executa item selecionado
- `Esc` fecha (volta foco ao trigger)
- Mouse hover destaca sem mover seleção de teclado

### Busca

- `fuse.js` com threshold 0.4
- Campos por entidade:
  - Agente: `name`, `slug`, `description`
  - Análise: `title`, `slug`, `question`
  - Relatório: `title`, `destinatario`
  - Skill: `name`, `slug`, `tags`
  - Ação: label + alias
- Resultados ordenados por score do fuse
- Empty state: "Nenhum resultado para '..'" com sugestão "Criar ?"

### Ações de criação on-the-fly

Se busca não retorna nada, oferece "+ Criar com '<query>' como nome":
- "+ Criar Agente '<query>'"
- "+ Criar Análise '<query>'"

---

## 5 · Tipos de item

```typescript
type PaletteItem =
  | { kind: 'action'; label: string; icon?: IconType; shortcut?: string; onExecute: () => void }
  | { kind: 'nav'; label: string; href: string; icon?: IconType; shortcut?: string }
  | { kind: 'agent'; slug: string; name: string }
  | { kind: 'analysis'; slug: string; title: string }
  | { kind: 'report'; slug: string; title: string; destinatario: string }
  | { kind: 'skill'; slug: string; name: string };
```

Cada `kind` tem renderer próprio (ícone, badge, descrição).

---

## 6 · Implementação (esqueleto)

```typescript
function CommandPalette() {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const items = useCommandItems();  // memoizado, atualiza on mount
  const filtered = useMemo(() => {
    if (!query) return items.slice(0, 30);  // recentes
    const fuse = new Fuse(items, { keys: ['label','title','name','slug'], threshold: 0.4 });
    return fuse.search(query).map(r => r.item);
  }, [items, query]);

  useHotkeys('mod+k', () => setOpen(o => !o));
  useHotkeys('esc', () => setOpen(false), { enableOnFormTags: true });

  return open ? (
    <Overlay onClose={() => setOpen(false)}>
      <PaletteInput value={query} onChange={setQuery} />
      <PaletteResults items={filtered} onExecute={handleExecute} />
    </Overlay>
  ) : null;
}
```

---

## 7 · Atalhos secundários dentro da palette

| Atalho | Ação |
|---|---|
| `Cmd+Enter` | Executa abrindo em nova aba (V1+) |
| `Ctrl+1..9` | Filtra para grupo específico (1=Ações, 2=Navegar, ...) |
| `Backspace` (input vazio) | Limpa filtro de grupo |

---

## 8 · Acessibilidade

- Overlay: `role="dialog"` `aria-modal="true"` `aria-label="Command Palette"`
- Input: `role="combobox"` `aria-expanded` `aria-controls="palette-list"` `aria-activedescendant`
- Lista: `role="listbox"` `id="palette-list"`
- Items: `role="option"` `aria-selected={isFocused}`

---

## 9 · Performance

- Index de busca rebuild em background quando dados mudam (não bloqueia abertura)
- Limit de 100 results por grupo (evita scroll infinito)
- fuse.js com `includeScore=false` (não usamos), reduz custo
