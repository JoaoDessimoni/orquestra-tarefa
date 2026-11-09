---
id: QMR12266
title: Mapa de Áreas Finza — base e estrutura para o levantamento de carência de automação
frente: estrategica
status: refinado
prioridade: media
fonte: quimera
quimera: 12266
jira: null
categoria: Processos
deliverable_type: Aplicação/Sistema
story_points: 5
tipo_origem: ticket
responsavel: Leandro Marques Gontijo Jersé
implementador: Leandro Marques Gontijo Jersé
criada: 2026-11-06
refinada: 2026-11-06
rice: null
esforco: M
valor_negocio: alto
owner: João Vinícius
sponsor: João Vinícius
origem:
  quimera: [QMR12266]
dependencias: []
bloqueia: []
tags: [fonte-quimera, cat-processos, mapa_areas, estrategica]
---

# QMR12266 — Mapa de Áreas Finza (Etapa 1: base e estrutura)

> Origem: Quimera #12266 · categoria: Processos · status fonte: `backlog`
> Artefato de trabalho: "Mapa de áreas Finza" (claude.ai artifact, montado pelo Leandro)

## Contexto

Primeira etapa da jornada **Mapa de Áreas**: descobrir quem é cliente do squad de IA & Automação na Finza. O mapa vira o registro vivo das áreas que o squad vai atender ao longo do tempo.

Jornada prevista:
1. **Etapa 1 (este item):** base de áreas + estrutura do mapa pronta para entrevista.
2. **Etapa 2:** entrevistas com cada área e responsáveis (sentimento, trabalho manual, responsabilidades). Vai ter demanda própria.
3. **Etapa 3:** propostas de automação por área, priorizadas pelo índice de carência.

Estado do artefato em 2026-11-06 (lido do bundle):
- Fonte: exportação CSV dos departamentos do Hyperflow, com 30 registros e as colunas Departamento e Responsáveis. Não é organograma.
- Por área: situação do levantamento (`a_pesquisar`, `em_levantamento`, `mapeado`, `sem_automacao`), observações e data de verificação.
- Cadastro de automações: tipo (IA, workflow, integração), status operacional e confirmação. Nenhuma automação registrada ainda.
- Armazenamento: só no navegador de quem preenche, com exportação e importação em JSON.
- Não tem: ranking de carência, sentimento ou ficha de entrevista.

## História

**Como** supervisor do squad IAF,
**quero** um mapa único e compartilhado de todas as áreas da Finza com carência de automação, sentimento e ficha de entrevista,
**para** decidir quem é cliente do squad e priorizar o atendimento pela carência real de cada área.

## Critérios de aceite

- **Dado** o mapa publicado, **quando** abro a lista de áreas, **então** vejo todas as áreas da Finza, inclusive as que não têm departamento no Hyperflow. Registros de teste, filas de bot, "Erro" e "Todos" aparecem separados ou não aparecem.
- **Dado** uma área, **quando** abro o detalhe, **então** vejo gestor ou ponto focal, número de pessoas e a quantidade de automações e IAs que atendem a área.
- **Dado** uma entrevista em curso, **quando** preencho a ficha da área, **então** registro objetivo, responsabilidades, principais processos (frequência, volume, tempo gasto, se é manual), sistemas, dores, data e entrevistador.
- **Dado** uma área entrevistada, **quando** registro o sentimento, **então** salvo a nota de 1 a 5 do peso do trabalho manual, a nota de 1 a 5 da relação com o squad de IA e uma frase em destaque. Tudo no nível da área, nunca de uma pessoa.
- **Dado** os campos preenchidos, **quando** o índice de carência é calculado, **então** a área recebe a classificação cliente prioritário, cliente potencial ou não-cliente no momento.
- **Dado** dois membros do squad editando, **quando** um salva, **então** o outro vê a mesma versão (armazenamento compartilhado, não local).

## Subtarefas

- [ ] Completar a base de áreas além do Hyperflow e validar a lista com o gestor ou o RH. ⚠️ PO: a confirmar quem valida.
- [ ] Limpar a base: testes, filas "IA - …", "Erro", "Todos".
- [ ] Registrar as automações e IAs existentes por área e levar a contagem para a visão geral.
- [ ] Criar a ficha de entrevista por área.
- [ ] Criar o campo de sentimento da área (2 notas de 1 a 5 + frase).
- [ ] Criar o índice de carência e a classificação de cliente.
- [ ] Trocar o armazenamento local por compartilhado. ⚠️ PO: bloqueante para a Etapa 2.

## Observações PO

- **Base não é organograma.** O CSV do Hyperflow só mostra quem atende cliente no Hyperflow. Áreas sem departamento lá ficam invisíveis, e são justamente as que mais podem ter trabalho manual escondido.
- **Sentimento por área, nunca por pessoa.** Nota associada a um colaborador nomeado vira avaliação individual. Isso gera risco político e fecha as portas da entrevista.
- **Pesos do índice são hipótese.** Recalibrar depois das 3 primeiras entrevistas. Sem recalibração, o ranking reflete a opinião do squad, não a carência da área.
- **Armazenamento compartilhado é gate da Etapa 2.** Sem ele, cada entrevistador mantém uma cópia diferente e o mapa deixa de ser fonte única.
- **Trabalho começou sem card.** O Leandro já montava o artefato antes da demanda existir. Este ticket formaliza o trabalho.
- **Fora do escopo:** realizar as entrevistas e propor automações. Seguram a Etapa 1 enxuta (5 pts).

## Rastreabilidade

- **Responsável:** Leandro Marques Gontijo Jersé
- **Solicitante:** João Vinícius
- **Quimera:** #12266 (status fonte `backlog` → mapeado `refinado`)
- **Categoria fonte:** Processos
- **Criada:** 2026-11-06

## Histórico

- 2026-11-06 — Demanda refinada e criada no Quimera (#12266) com descrição no padrão Descrição Refinada · Observação · Objetivo. Item registrado no backlog estratégico.
- 2026-11-06 — Descrição no Quimera regravada em HTML (o editor do Quimera achatou o Markdown após edição manual). Removida a frase sobre as entrevistas terem demanda própria; as próximas etapas serão tratadas em outras demandas.
