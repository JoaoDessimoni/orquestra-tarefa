# 07 · Artefato — telas, filtros e segregação

Página única publicada como artefato privado. Capabilities: `db`, `user`, `sample` (só para testar o prompt), `downloads` (exportação) e `assets` (conversas grandes). Tema claro/escuro e largura de celular sem rolagem horizontal.

## 0. Elementos globais

- **Seletor de recorte**, fixo no topo: `FINZA` | `BLIPS · Cobrança` | `Lado a lado`.
  - Cada recorte tem cor e selo próprios, repetidos em todo card, linha e gráfico.
  - O modo "lado a lado" duplica os cards em duas colunas. **Nunca soma os recortes.**
- Período (dentro dos 90 dias), relógio `comercial | corrido` e selo "dados extraídos em <data>".
- Navegação: **Dashboard** · **Protocolos e mensagens** · **Metodologia**.
- **Carregamento:** timer de 10 s. Banco vazio ou indisponível mostra um estado explicativo, nunca uma tela branca.

## 1. Dashboard

1. **Big numbers** (spec 05 §5), com contadores animados e comparação com a semana anterior.
2. **Faixas de espera:** barra empilhada com ate_10, 10_20, 20_30, 30_60, acima_60 🚩 e sem_resposta. Clicar numa faixa abre os Protocolos já filtrados.
3. **Mapa de calor** hora × dia da semana, com a mediana da espera. Revela buraco de escala.
4. **Evolução semanal:** mediana e p90 da 1ª resposta, mais % de red flag.
5. **IA × humano:** volume por tipo (so_ia, ia_humano, so_humano), tempo médio de resposta de cada e score médio de cada.
6. **Tempo para assumir** após transferência IA→humano: distribuição.
7. **Assuntos:** barras com o top de assuntos e, para cada um, score médio e % de frustração.
8. **Temperatura:** matriz início × fim (de −2 a +2) e % com frustração com o atendimento.
9. **Rankings** em abas: Atendimentos (top 10 e bottom 10), Atendentes, Departamentos, com a IA como linha de referência. Clicar leva ao protocolo ou ao filtro.
10. **Fila de red flags:** tabela com os piores protocolos (sem resposta e acima de 60 min), ordenada pela maior espera. É a lista de investigação.

## 2. Protocolos e mensagens (hierarquia cliente → protocolos → mensagens)

**Coluna 1 — Clientes** (lista virtualizada):
- busca por telefone, CNPJ ou nome do CRM;
- cada linha mostra o selo do recorte, o nº de protocolos, o score médio, a pior faixa e ícones de 🚩 e de frustração.

**Coluna 2 — Cliente selecionado:**
- cabeçalho com CNPJ (aviso de "ambíguo" quando for o caso), telefone, recorte, nº de protocolos, score médio e assuntos;
- abaixo, os **protocolos**, cada um num card com data, departamentos, atendentes, tipo, score, faixa pior, temperatura e assunto.

**Coluna 3 — Protocolo selecionado:**
- **Linha do tempo das mensagens** no estilo chat: cliente à esquerda; IA e humano à direita, com cores diferentes; sistema centralizado.
  - Entre os blocos aparece a **espera**, colorida pela faixa.
  - Transferências e atribuições aparecem como divisórias.
  - Áudio mostra a transcrição ou o aviso "áudio não transcrito".
- **Painel da avaliação:** score com a decomposição por critério × peso, tetos e penalidades aplicados, justificativa e evidência de cada critério (clicar na evidência rola até a mensagem), flags, resumo, `versao_prompt` e confiança.

No celular, as 3 colunas viram navegação em pilha.

**Filtros**, combináveis, com contador de resultado:
- recorte, período, departamento, atendente, tipo (só IA, IA→humano, só humano), receptivo × ativo;
- faixa de score, faixa da pior espera, red flag, sem resposta;
- assunto, resolvido, temperatura final, frustração com o atendimento (e intensidade), flags;
- cliente recorrente (≥ 2 protocolos), com/sem CNPJ, CNPJ ambíguo, áudio não transcrito;
- busca de texto nas mensagens do cliente selecionado.

**Exportar** (`downloads`): JSON completo do cliente (metadados + protocolos + mensagens + avaliações) e CSV dos protocolos filtrados.

## 3. Metodologia

- **Prompt do avaliador:** mostra a versão ativa, com histórico de versões e diff entre elas. "Nova versão" abre um editor, e salvar grava `prompts/{v}` como rascunho.
- **Testar prompt** (`sample`): escolha até 5 protocolos. O teste roda a versão em rascunho e mostra, lado a lado, a avaliação atual e a nova, com o score de cada.
- **Pesos:** sliders com soma travada em 100. Mais tabela de agilidade, tetos e penalidades. A aplicação é **imediata**: recalcula scores e rankings na página. "Salvar como versão" grava `pesos/{v}` e marca como ativa.
- **Reprocessar com este prompt:** cria `reprocessamentos/{id}` com status `pendente` e mostra as instruções e o progresso (spec 08).
- **Definições:** faixas, relógios, expediente, recortes, fontes (tabelas da spec 02), limitações conhecidas e data da extração.

## 4. Critérios de aceite da UI

- Nenhuma tela mostra número com FINZA e BLIPS somados.
- Todo número tem o recorte visível no mesmo card.
- Mudar um peso atualiza Dashboard e rankings em menos de 2 s.
- Abrir um cliente com 10 protocolos carrega as mensagens em menos de 3 s.
- Funciona em largura de 375 px.
