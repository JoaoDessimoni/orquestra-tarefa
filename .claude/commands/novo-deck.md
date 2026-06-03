---
description: Cria um deck Finza do zero rodando o pipeline completo (research → architect → writer → designer → builder → reviewer). Use quando o usuário quiser iniciar apresentação nova. Entrega .html single-file em Apresentacoes/executando/.
---

# /novo-deck — orquestração do pipeline de slides

Você vai criar um deck Finza completo. O usuário forneceu um tema (em `$ARGUMENTS`) ou vai descrever em seguida. Siga este pipeline em ordem.

## Passo 0 — Carregar contexto

Antes de qualquer agente, carregue mentalmente:
- `.claude/skills/finza-design-system/SKILL.md`
- `.claude/skills/finza-tom-voz/SKILL.md`
- `.claude/skills/finza-contexto/SKILL.md`

(Use Read se ainda não foi carregado nesta sessão.)

## Passo 1 — Briefing

Se o usuário não forneceu tudo, pergunte numa única chamada `AskUserQuestion`:

1. **Tema** (em uma frase). Ex: "Estado da Torre para o time de produto."
2. **Público.** Ex: "Diretora de produto + 3 PMs."
3. **Duração prevista.** Ex: "15 minutos."
4. **Tom específico**? (default: técnico-executivo Finza). Opções: técnico-executivo / técnico-detalhado / comercial / cerimônia.
5. **Nome do arquivo**. Sugira `<tema-slug>_<destino-slug>_DD-MM-YYYY.html` baseado na data de hoje. Confirme.

Se `$ARGUMENTS` veio preenchido, use como tema inicial e pergunte só o que falta.

## Passo 2 — Research

Invoque o agente `finza-researcher` em foreground com o tema + público. Ele retorna fatos verificáveis com citação.

Brief para o researcher:
```
Tema do deck: <tema>
Público: <público>
Preciso de fatos sobre: <enumere tópicos do tema>
Retorne lista de FATOS com citação rastreável a Docs/.
```

Aguarde o resumo do researcher antes de continuar.

## Passo 3 — Architect

Invoque `slide-architect` com:
- Tema, público, duração.
- Fatos do researcher.

Recebe outline com sequência de slides, conceito por slide, encaixe narrativo, marcação splash.

Se o architect levantar pontos abertos que dependem de decisão do usuário, pause e pergunte via `AskUserQuestion`. Não chute.

## Passo 4 — Writer

Invoque `slide-writer` com:
- Outline do architect.
- Fatos do researcher.

Recebe texto pronto de cada slide em markdown estruturado (h1, h2, corpo, fontes, TODOs).

## Passo 5 — Designer

Invoque `slide-designer` com:
- Texto do writer.
- Tipo de cada slide do architect.

Recebe spec visual de cada slide (fundo, componentes, classes, hierarquia).

## Passo 6 — Builder

Invoque `slide-builder` com:
- Texto do writer.
- Spec visual do designer.
- Nome do arquivo confirmado no passo 1.

Builder grava o `.html` em `Apresentacoes/executando/<nome>.html`.

## Passo 7 — Reviewer

Invoque `slide-reviewer` no arquivo gerado.

Se o reviewer apontar bloqueadores, volte ao builder com a lista (Edit, não Write). Re-revisar.

Se só houver observações, reporte e siga.

## Passo 8 — Atualizar artefatos

1. Se este é deck principal (CTO / repasse / boas-vindas), atualize `Docs/BRIEFING.md`:
   - Incremente versão no header e no histórico.
   - Reflita mudanças estruturais (nº de slides, novos tipos).
2. Se o deck deixou `<!-- TODO: confirmar -->` ou gerou ações estratégicas, registre-as no Backlog via `/backlog add` (uma por item).

## Passo 9 — Encerramento

Reporte ao usuário em texto curto:

```
✓ Deck gerado: Apresentacoes/executando/<nome>.html
  - N slides
  - Reviewer: aprovado [sem observações | com K observações]
  - TODOs preservados: J (lista linkada)
  - BRIEFING atualizado: [sim | n/a]

Para abrir: clique em [nome.html](Apresentacoes/executando/<nome>.html).
Para revisar de novo: /revisar-deck <nome>.html
Para iterar: peça mudança e eu rodo só os agentes necessários.
```

## Regras de orquestração

- **Não pule etapas.** Pipeline existe para garantir qualidade canônica.
- **Pause para confirmação** apenas quando o passo 1 ou architect levantar ambiguidade real. Não pergunte por preferência cosmética.
- **Em loops de correção (reviewer → builder)**, use Edit (não Write) para não regerar arquivo inteiro.
- **Não invente.** Se researcher disse `NÃO ENCONTRADO`, o builder preserva `<!-- TODO -->`.
