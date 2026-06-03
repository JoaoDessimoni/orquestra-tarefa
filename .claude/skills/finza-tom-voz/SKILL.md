---
name: finza-tom-voz
description: Guia canônico de redação para slides Finza. Aplique quando estiver escrevendo qualquer texto destinado a slide — títulos, subtítulos, bullets, captions, banners. Define voz, ritmo, vocabulário proibido, padrões de número e citação. Carregar junto com finza-design-system em todo agente de slide.
---

# Finza Tom & Voz — guia de redação

Voz canônica para qualquer texto que vai aparecer num deck Finza. Refinada nas v1→v8 do deck CTO 13/05/2026. **Quando em dúvida sobre como escrever um trecho, releia este arquivo antes de produzir.**

---

## 1 · Voz base

**Técnico-executivo.** Quem lê é CTO, gerente sênior, lead de squad. Já conhece a Finza, a stack, o negócio. Não precisa de tutorial.

- **Frases curtas.** Sujeito + verbo + objeto. Pouca subordinação.
- **Voz neutra descritiva** no geral. Primeira pessoa só em slides de ação/fechamento do supervisor.
- **Densidade alta, palavras baratas.** Cada palavra puxa peso. Sem encheção.
- **Sem auto-elogio.** Não escreva "estamos comprometidos", "ótima notícia", "boas perspectivas". Esse tom não passa em frente de CTO.

---

## 2 · Vocabulário proibido

Jargão de consultoria que perde respeito:

- ❌ "sinergia", "alavancar", "deep dive", "framework de execução"
- ❌ "ótima notícia", "estamos comprometidos", "boas perspectivas"
- ❌ "rapidinho", "tranquilo", "show", "massa"
- ❌ "iremos buscar", "estaremos atuando" (gerundismo)
- ❌ "100% focado", "totalmente alinhado" (hiperbólico)

**Em vez de:**
| Não | Sim |
|---|---|
| "Vamos buscar alavancar sinergias" | "Vamos conectar Torre e Falcon via API" |
| "Ótima notícia: o roadmap está saindo do papel" | "Plano aprovado em 28/abr, 6 sprints até 10/jul" |
| "Estamos comprometidos com a qualidade" | "QA pelo solicitante a partir do Sprint 3" |
| "Resultados expressivos" | "37 issues fechadas" (use o número) |

---

## 3 · Números

Números são protagonistas em deck técnico-executivo.

- **Sempre absolutos quando existirem.** "6 sprints", "10/jul", "37 issues", "27 ferramentas MCP", "1.000 a 100.000+ contatos".
- **Sem "vários", "muitos", "alguns".** Se você não sabe quantos, declare incerteza.
- **Em destaque visual.** Quando o número for o ponto do slide, ele aparece grande, em `--finza-blue`, peso 700. (Skill `finza-design-system` cobre o como.)
- **Datas em formato falado.** "10/jul", "28/abr", "11 de maio" — não "10/07/2026" exceto em metadados.

---

## 4 · Declaração de incerteza

Quando você não tem dado, **declare**. Nunca invente para preencher.

✅ "Ainda não temos métrica consolidada para isso."  
✅ "Não há baseline antes do plano herdado — primeira medição prevista para Sprint 3."  
✅ `<!-- TODO: confirmar com Jéssica -->` no HTML, no lugar do número fabricado.

❌ "Métricas mostram melhoria significativa." (inventou)  
❌ "Aproximadamente 30%" (chutou)

---

## 5 · Títulos de slide (h1)

Padrão **ghost + accent**: parte em cinza claro peso 300 + uma palavra-chave em azul peso 700.

✅ `Squad IAF — **Estado e Direção**`  
✅ `Torre de **Controle**`  
✅ `Esperanza, **em produção**`  
✅ `Plataformas Finza, **em uma linha**`

A "palavra-chave em accent" é o que o leitor precisa lembrar do slide. Escolha-a com intenção. Não destaque palavras vazias (`o que`, `sobre`, `para`).

---

## 6 · Subtítulos (h2)

Uma linha. Descreve o ângulo do slide.

✅ "Sistema operacional da cobrança Finza. Title-centric, multi-tenant, com IA aprovada por humano."  
✅ "Agente IA que conduz a régua de cobrança Finza no WhatsApp."  
✅ "5 plataformas no funil. A IAF mantém só a última."

Evite subtítulos que repetem o título ("Squad IAF — uma visão geral do squad IAF").

---

## 7 · Bullets

Cada bullet é 1–2 linhas. Sem subitens (se precisa de subitem, vira outro card).

**Padrão:** verbo (ou substantivo forte) + objeto + qualificação curta.

✅ "Distribuir Sprints 2–5 no Jira"  
✅ "Backend dedicado (FastAPI) — substitui Supabase Functions"  
✅ "P02 Backend todo em Supabase Functions — telas 5–10s, regras invisíveis"

❌ "Iremos discutir a viabilidade de uma possível distribuição das sprints"  
❌ "É importante destacar que o backend atual apresenta limitações"

---

## 8 · Cards de problema / gap

**Estrutura padrão** (vide slide 5 do deck CTO):
```
[tag] [título azul peso 700]
[descrição curta — 1-2 linhas — sintoma observado]
─────── (borda dashed) ───────
[→ proposta de mitigação — 1 linha]
```

Exemplo:
> **P01 Ambientes de teste**  
> Só produção + 1 banco dev usado como "homologação". Risco alto de regressão.  
> ─────  
> → 3 ambientes reais: dev, hml, prd.

---

## 9 · Citação de fonte

Toda afirmação técnica precisa poder ser ancorada num doc. Em texto de slide, não exiba a citação — mas mantenha rastreabilidade no comentário HTML.

```html
<!-- Fonte: Backlog/contexto/torre_de_controle_overview.md §2 -->
<li>Maximizar recuperação de inadimplência</li>
```

Quando a info vier de conversa/reunião e não houver doc, marque:
```html
<!-- Fonte: 1:1 com Jéssica 12/05/2026; ainda não documentado -->
```

---

## 10 · Primeira pessoa

Use **só em slides onde o supervisor está se posicionando**: ações que ele vai tomar, fechamento, pedido.

✅ "Vou rodar o plano e ajustar onde a realidade exigir." (slide de fechamento)  
✅ "Em 5 dias dá pra mapear, não pra fechar diagnóstico." (slide de escopo)  
✅ "O que vou rodar — sem pedido formal, só visibilidade do que está sendo destravado." (slide de próximos passos)

No resto do deck, voz neutra descritiva:
✅ "Esperanza identifica devedor por telefone/CPF, consulta dívida..."  
❌ "Eu vejo que a Esperanza identifica..."

---

## 11 · Banners de fechamento

Slide final ou banner accent — frase única que carrega o ponto central. Curta, declarativa, sem floreios.

✅ "O time tem direção. **O plano herdado é sério.** Pendências mapeadas, não escondidas."  
✅ "IAF atua na etapa 5. As 4 plataformas anteriores são vizinhanças sob Marco e Girlan — integramos, não governamos."

Evite finais retóricos ("Vamos juntos transformar a Finza!").

---

## 12 · Checklist antes de fechar um texto

Antes de marcar slide como "writer-done":
- [ ] h1 com ghost + accent? (1 palavra-chave em azul peso 700)
- [ ] h2 com 1 frase descrevendo ângulo?
- [ ] Bullets ≤ 2 linhas?
- [ ] Nenhum termo da seção 2 (vocabulário proibido)?
- [ ] Números absolutos sempre que existirem?
- [ ] Incertezas declaradas, não fabricadas?
- [ ] Primeira pessoa só onde apropriado?
- [ ] Toda afirmação técnica rastreável a um doc?
