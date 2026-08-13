---
titulo: "Por que o filtro de Suprimento casa contratos — o campo target_entity que a UI nunca preenche"
data: 2026-08-10
autor: João Vinícius (Supervisor IAF)
tipo: analise-tecnica
sistema: Torre de Controle (cobranca-finza)
origem: investigação org_blips — filtro "Suprimentos teste"
relacionado: IAF-4795 (Suprimentos)
status: diagnóstico concluído — correção pendente (frontend)
---

# Filtro de Suprimento que casa Contrato — diagnóstico completo

## 1. Resumo executivo

O filtro **"Suprimentos teste"** (org `blips`) mostra na tela a condição **"Suprimento · Valor Total · maior que · 1"**, mas na prática **casa contatos que não têm suprimento algum** — casa quem tem *contrato/equipamento* legado. Na base: o filtro retorna **5.716 contatos**, quando só **2.216** têm suprimento de verdade. Por isso contatos como *Josiane Costa de Oliveira* e *Rodrigo Bergmann* aparecem no filtro, mas ao abrir a carteira → aba **Suprimentos** vêm "Nenhum suprimento encontrado" (a carteira está **certa**; eles realmente têm zero suprimento).

**A causa não é a condição que você vê.** Existem **dois campos diferentes** que decidem "isto é filtro de Suprimento ou de Contrato":

1. **`table` da condição** — o que o dropdown "Suprimento" da tela grava (`table: "supplies"`). **A UI seta este.**
2. **`target_entity` do filtro** — o *escopo-raiz* que o motor de fato usa para decidir contra qual partição da base avaliar. **A UI nunca seta este** — fica sempre `'contracts'`.

O motor de filtros (banco) usa **só o `target_entity`** para recortar suprimento × contrato — **ignora** o `table` da condição para esse recorte. Como o `target_entity` ficou `'contracts'`, o filtro avalia contra contratos.

Quando você **re-salvou** o filtro, a condição (`table='supplies'`) persistiu e continuou mostrando "Suprimento", mas o `target_entity` **nem entrou no UPDATE** — continuou `'contracts'`. Daí a divergência ter sobrevivido ao reload.

**Front ou back?** O erro é **no frontend** (fluxo de salvar o filtro). O backend (compilador) está correto para o dado que recebe. Falta, além disso, uma trava de banco que reconcilie os dois campos — hoje nada impede um filtro "Suprimento" nascer com `target_entity='contracts'`.

---

## 2. O sintoma, em números (evidência de banco — read-only, prod `org_blips`)

| Medida | Valor |
|---|---|
| Contatos que o filtro casa (como está salvo) | **5.716** (cache) / 6.125 (recontagem) |
| Contatos com suprimento real (`supplies.total_value > 1`) | **2.216** |
| Diferença (falsos-positivos) | **~3.500** |
| Total de contatos na org | 6.998 |

Nos dois contatos do print:

| | Josiane | Rodrigo |
|---|---|---|
| `supplies` reais | 0 | 0 |
| `supply_titles` reais | 0 | 0 |
| Linhas em `vw_titles_live` | 31 (todas `entity_kind='contract'`) | 20 (idem) |
| Casa o predicado salvo (`…entity_kind='contract'`) | **Sim** (31) | **Sim** (20) |
| Casaria o predicado correto (`…entity_kind='supply'`) | Não (0) | Não (0) |

Após seu re-save (`updated_at` = 2026-08-11 01:40Z, cache recalculado): **`target_entity` continua `'contracts'`**, `conditions.table` continua `'supplies'`. O banco não os reconciliou.

---

## 3. Os dois campos — o que cada um significa

O sistema de filtros da Torre avalia tudo contra a view **`vw_titles_live`**, que desde o IAF-4795 é um **`UNION ALL`** de duas partições, distinguidas pela coluna **`entity_kind`**:

- `entity_kind = 'contract'` → o mundo legado (contratos/equipamentos/títulos) — 56.161 linhas
- `entity_kind = 'supply'` → o mundo novo (suprimentos) — 5.908 linhas

Sobre essa view existem **dois níveis de "qual entidade"**:

### 3.1 `conditions[].table` — nível da CONDIÇÃO (por regra)
É o dropdown que você vê ("Contato / Contrato / Título / **Suprimento** / Título de Suprimento / …"). Ele define **de qual tabela vem a coluna** daquela regra. "Suprimento" grava `table: "supplies"`, `field: "total_value"`.
Vive no objeto da condição (tipo `FilterRule.table`).

### 3.2 `filter_definitions.target_entity` — nível do FILTRO (raiz)
É o **escopo-raiz** do filtro inteiro. Ele decide **qual partição de `entity_kind`** o filtro avalia. É uma coluna própria da tabela `filter_definitions`, **separada** das condições.
Vive no tipo `FilterDefinition.target_entity` — e **não existe** dentro do objeto `conditions` (o `FilterGroup` não tem esse campo).

### 3.3 Por que eles "significam a mesma coisa" mas não são o mesmo
Para um filtro de suprimento, **os dois deveriam dizer "supply"**: a condição (`table='supplies'`) e a raiz (`target_entity='supplies'`). Eles são **redundantes por design** na dimensão suprimento×contrato. O problema é que **ninguém os reconcilia**: a UI seta a condição, mas não a raiz. E o motor usa **só a raiz**.

> Resposta direta à sua pergunta: **sim, são dois campos distintos que, na comunicação via API, codificam a mesma decisão (suprimento vs contrato).** A tela preenche o *visível* (`conditions[].table`), e o motor obedece o *invisível* (`target_entity`). Quando eles discordam, vence o `target_entity` — e ele nunca foi preenchido.

---

## 4. Como o motor decide (backend — está correto)

O compilador `public.compile_filter_to_sql_v2(conditions, schema, target_entity)` (versão atual em `supabase/migrations/20260805115000_iaf4795_suprimentos.sql`) faz duas coisas:

**(a) Recorte-raiz por `entity_kind`** — derivado **do `target_entity`**, não da condição:
```sql
v_root_kind := CASE
    WHEN LOWER(COALESCE(p_target_entity,'contracts')) IN ('supplies','supply_titles')
        THEN 'supply' ELSE 'contract' END;
RETURN '(' || v_root_inner || ') AND entity_kind = ' || quote_literal(v_root_kind);
```

**(b) Normalização de coluna** — uma condição sobre `supplies` lê as **mesmas colunas** de `contracts` (o ramo supply do UNION projeta o dado do suprimento ali):
```sql
IF v_table = 'supplies'      THEN v_table := 'contracts';
ELSIF v_table = 'supply_titles' THEN v_table := 'titles'; END IF;
```
Comentário do próprio código: *"o recorte por suprimento vem do `entity_kind='supply'` (root scoping acima), **não do mapeamento de coluna**."*

Ou seja, para o filtro "Suprimentos teste" (target_entity `'contracts'`, condição `supplies.total_value>1`), o SQL gerado é:
```sql
((contract_original_value)::NUMERIC > 1) AND entity_kind = 'contract'
```
→ "qualquer contato com contrato legado de valor > 1" — quase a base inteira. **Nunca olha `entity_kind='supply'`.**

Os consumidores (`evaluate_filters_batch` = contagem do card; `get_filter_contacts_paginated` = lista do drawer; `get_filter_contact_ids`, `get_portfolio_contact_ids`, `get_filter_target_ids` = elegibilidade) **todos leem `target_entity` do registro e repassam ao compilador**. Verificado no banco vivo: todos já são supply-aware. **O motor está certo — só obedeceu um `target_entity` errado.**

> Nota: um agente de exploração chegou a apontar um "segundo bug" (o RPC da lista seria contract-scoped fixo). Isso vinha de **ler migrations antigas** já superadas. Conferido no estado **vivo** do banco: esse RPC e os demais já foram atualizados. **Não há segundo bug de runtime.**

---

## 5. Por que o `target_entity` nunca vira "supplies" (frontend — a raiz do erro)

O caminho de salvar filtro (`cobranca-finza`, escrita direta na tabela via hook CRUD + `orgClient`, sem edge function):

### 5.1 A UI não tem controle de `target_entity`
Modal "Editar Filtro" = `src/components/filters/filter-builder/index.tsx`. O schema Zod do formulário tem **só**:
```ts
z.object({ name, description, color, icon, usage_scope })  // linhas 29-37 — sem target_entity
```
Os campos na tela: Nome, Cor, Descrição, Ícone, "Escopo: comum (todos os lugares)" — este é o **`usage_scope`** (common/agent), **outra coisa** — e as condições. **Não há seletor de "entidade-alvo".**

O dropdown "Suprimento" (`FilterRuleItem.tsx:80-108`) só altera `rule.table` na condição — nunca toca o `target_entity` do filtro.

### 5.2 Nenhum código deriva `target_entity` das condições
Varredura no repo: **não existe** nada que leia `conditions.rules[].table` e conclua `target_entity='supplies'`. Comentários no próprio código já admitem o campo como inerte:
```
// BlocklistFilterRuleDialog.tsx:108-109
// ...independente do target_entity gravado no filtro (que hoje é sempre 'contracts').
```

### 5.3 CREATE nasce sempre 'contracts'
`src/hooks/useFilters.ts:124-133`:
```ts
transformCreate: (data) => ({
  ...
  target_entity: data.target_entity || "contracts",   // data.target_entity é SEMPRE undefined vindo da UI
  conditions: data.conditions, ...
})
```

### 5.4 UPDATE nem manda o campo (o que explica o re-save teimoso)
O CRUD do filtro **não tem `transformUpdate`**, e o `onSubmit` monta o payload sem `target_entity`:
```ts
// filter-builder/index.tsx:130-155
const filterData = { name, description, conditions, color, icon };  // sem target_entity
await updateFilter.mutateAsync({ ...filterData, id: filter.id });
```
A fábrica então faz `.update({name,description,conditions,color,icon})` — **`target_entity` não está no SET**, então o Postgres **mantém o valor antigo** (`'contracts'`). É exatamente por isso que **re-salvar não corrige** (e também não pioraria): a coluna simplesmente nunca é tocada no update.

### 5.5 Backend não segura
- Coluna `target_entity VARCHAR(50) DEFAULT 'contracts'`, **sem CHECK**, nullable (`007_org_blips_filters.sql`).
- **Nenhum trigger** deriva/reconcilia `target_entity` (os 5 triggers da tabela cuidam de `updated_at`, imutabilidade de `usage_scope`, auditoria e guarda de blocklist — nada mais).
- A única edge function que escreve filtro (`ai-proposal-executor`) também **omite** `target_entity` → cai no default.

### 5.6 O contrato documentado
`docs/guides/filtros-e-portfolios.md:78`: um filtro de suprimento **é** um `filter_definitions` com `target_entity IN ('supplies','supply_titles')`; os consumidores passam a **ler** esse campo. O design assumido é **"frontend seta `target_entity`, backend deriva `entity_kind` a partir dele"**. O IAF-4795 entregou o **lado da leitura** (compilador + RPCs), mas **o lado da escrita no frontend nunca foi fechado** — e não há trava de banco cobrindo a lacuna.

---

## 6. Veredito front × back

| Camada | Estado | Papel no bug |
|---|---|---|
| **Frontend (save de filtro)** | ❌ **Defeituoso** | Não seta nem deriva `target_entity`; no UPDATE nem manda o campo. **Raiz do erro.** |
| Backend / compilador | ✅ Correto | Deriva `entity_kind` corretamente do `target_entity` recebido. |
| Banco (schema) | ⚠️ Frágil | Default `'contracts'`, sem CHECK/trigger que reconcilie. **Backstop, não origem** — e um hardening desejável. |

**Conclusão:** bug de **frontend**, com uma **lacuna de robustez no banco** como agravante. Não é bug do motor.

---

## 7. Impacto (blast radius)

- Em `org_blips`, **só há 1 filtro** que referencia `supplies` — o "Suprimentos teste". Contido.
- Porém a **falha é sistêmica de produto**: hoje é **impossível** criar pela UI um filtro de suprimento que funcione — todo filtro nasce `target_entity='contracts'`. Qualquer régua/portfolio/campanha que dependa de um filtro de suprimento vai mirar contrato silenciosamente. Conforme o uso de Suprimentos crescer, o problema aparece em qualquer org.

---

## 8. Correção recomendada

### 8.1 Frontend (raiz — obrigatório)
Derivar `target_entity` das condições no momento de salvar (regra: *se alguma folha tem `table ∈ {supplies, supply_titles}` → `target_entity='supplies'`*; senão `'contracts'`) **e incluí-lo tanto no CREATE quanto no UPDATE**:
- Calcular no `onSubmit` (`filter-builder/index.tsx`) e pôr em `filterData`.
- Adicionar `transformUpdate` ao CRUD do filtro em `useFilters.ts` (hoje inexistente) para o campo entrar no `.update()`.
- (Opcional/UX) expor um seletor de "entidade-alvo" quando houver ambiguidade (filtro misto contrato+suprimento).
> Decisão de produto a resolver: um filtro pode misturar condições de contrato **e** de suprimento? Como o recorte-raiz é único (`entity_kind` é ou/ou), **filtro misto não é representável** hoje. A UI deveria impedir misturar `supplies` com `contracts`/`titles` na mesma definição, ou exigir escolha explícita da raiz.

### 8.2 Banco (hardening — recomendado)
Adicionar uma trava que reconcilie os dois campos: **trigger** `BEFORE INSERT/UPDATE` que derive/valide `target_entity` a partir do `conditions` (ou ao menos um **CHECK** de coerência). Assim, mesmo um writer desatualizado (ex.: `ai-proposal-executor`) não grava filtro incoerente. Escrita via CI/CD (migration) — nunca manual.

### 8.3 Dado imediato (destrava o teste agora)
Corrigir o registro `baaffc4e-…` para `target_entity='supplies'` e recomputar o cache (`evaluate_filters_batch`). Esperado: cai para **~2.216** e Josiane/Rodrigo saem. **Não sai daqui** (parent é read-only) — via UI corrigida, ou via migration no `cobranca-finza`.

### 8.4 Risco secundário a validar
No ramo `entity_kind='supply'` da view, `contract_original_value` **não** é igual a `supplies.total_value` linha-a-linha (amostra: view 10.046,46 vs supply 6.373,86 — parece agregação por parcelas). Para o limiar `>1` é inócuo, mas um filtro de suprimento **por faixa de valor** pode dar número errado mesmo com o `target_entity` certo. Validar o mapeamento `supplies.total_value → coluna do ramo supply` na definição da view antes de confiar em filtros de valor sobre suprimento.

---

## 9. Verificação (reproduzível, read-only)

1. `SELECT target_entity, conditions FROM org_blips.filter_definitions WHERE name='Suprimentos teste';` → hoje `target_entity='contracts'`, `conditions.table='supplies'`.
2. `SELECT count(DISTINCT contact_id) FROM org_blips.vw_titles_live WHERE (contract_original_value)::numeric>1 AND entity_kind=$k;` para `$k IN ('contract','supply')` → 6.125 vs 2.216.
3. `SELECT count(DISTINCT contact_id) FROM org_blips.supplies WHERE total_value>1;` → 2.216 (bate com o caso `supply`).
4. Após a correção do dado: `evaluate_filters_batch('org_blips', ARRAY['baaffc4e-…'])` → `cached_contact_count ≈ 2216`; Josiane/Rodrigo somem da lista.

---

## 10. Referências (arquivo:linha)

**Backend / banco**
- `supabase/migrations/007_org_blips_filters.sql` — coluna `target_entity VARCHAR(50) DEFAULT 'contracts'`, sem CHECK.
- `supabase/migrations/20260805115000_iaf4795_suprimentos.sql` — compilador v2 (root scoping + normalização), `vw_titles_live` UNION, consumidores lendo `target_entity`.
- `public.compile_filter_to_sql_v2`, `public.evaluate_filters_batch`, `get_filter_contacts_paginated`, `get_filter_contact_ids` (estado vivo verificado — supply-aware).

**Frontend**
- `src/components/filters/filter-builder/index.tsx` — modal; schema Zod (29-37) sem target_entity; onSubmit (130-155).
- `src/components/filters/filter-builder/FilterRuleItem.tsx:80-108` — dropdown `table`.
- `src/hooks/useFilters.ts` — `transformCreate` (124-133) hardcode 'contracts'; sem `transformUpdate`; tipos `FilterDefinition/CreateFilterData`.
- `src/factories/createCrudHooks.ts:237-250` — update sem transform → campo omitido fica intocado.
- `src/types/filters.ts:3-19` — `FilterRule.table`; `FilterGroup` sem `target_entity`.
- `src/components/portfolio/BlocklistFilterRuleDialog.tsx:108-109` — comentário "hoje é sempre 'contracts'".

**Docs / git**
- `docs/guides/filtros-e-portfolios.md:78-79` — contrato: frontend seta `target_entity`.
- IAF-4795: commits `35b7a520`, `b37b0e11`, `3d2a2b76`, `3b7750c4`. Coluna `target_entity` precede (migration `007`). HEAD `a1fe6191`.
