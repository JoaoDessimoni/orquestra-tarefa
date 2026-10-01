# 31 · Fluxos de Uso Ponta a Ponta

> Fonte: `cobranca-finza/docs/guides/fluxo-cobranca.md`, `docs/guides/visao-geral.md`, e os documentos de tela 10–22 deste pacote.
> Os documentos 10–22 descrevem **cada tela isoladamente**. Este descreve como o usuário **atravessa** várias telas para completar um trabalho real. É o insumo para desenhar a navegação e as pontes entre telas.

---

## 0. Por que este documento existe

A Torre é uma esteira. Quase nenhuma tarefa real começa e termina na mesma tela. Hoje, as pontes entre telas são fracas: o usuário precisa saber de cor que "Filtros alimenta Carteira, que alimenta Campanha, que gera Ação".

**Oportunidade central do redesenho:** tornar a esteira visível e navegável — cada tela deveria dizer de onde veio o que ela mostra e para onde leva.

---

## 1. A esteira do produto (referência)

```
FONTE EXTERNA
   │  ETL agendado (importação + reconciliação)
   ▼
CONTATOS · CONTRATOS · TÍTULOS
   │  refresh agendado da view materializada
   ▼
BASE PRÉ-CALCULADA  ← Dashboard, Carteira e Relatórios leem daqui
   │
   ├─► FILTROS → PORTFÓLIOS (carteiras)
   │
   └─► CAMPANHA (gatilho) ─► RÉGUA (passos) ─► execução em 6 etapas
                                                 │
                                                 ▼
                                              AÇÕES (Pendente)
                                                 │  janela de envio
                                                 ▼
                                              ENVIO via integração
                                                 │
                                    ┌────────────┼────────────┐
                                    ▼            ▼            ▼
                              status por    agente de IA   pagamento
                               webhook       (protocolo)   (atribuição 48h)
```

---

## 2. Fluxo A — Primeiro acesso e entrada

**Persona:** qualquer usuário novo. **Telas:** 10.

1. Recebe convite por e-mail → abre `/accept-invite?...`.
2. O sistema decide entre quatro caminhos: criar conta, entrar, sessão já correta, ou sessão errada.
3. Cria conta ou entra.
4. Cai em `/select-organization`. Se tem só uma organização, ⚠️ ainda assim passa pela tela.
5. Escolhe a organização → vai para o Dashboard, **ou** para o destino original se tinha um link profundo preservado.

**Atritos mapeados:**
- Não existe "Esqueci minha senha" na interface (a função existe no código, sem rota nem botão).
- Erro de rede ao listar organizações aparece como "nenhuma organização" — o usuário acha que perdeu acesso.
- Papel do convite exibido em inglês (`operator`, `admin`).
- Usuário interno sem organização fica sem saída na tela de seleção.

**O que o redesenho deve entregar:** recuperação de senha; estado de erro distinto de estado vazio; papéis em português com descrição do que cada um pode fazer; e pular a tela de seleção quando há uma única organização.

---

## 3. Fluxo B — Rotina diária do analista de cobrança

**Persona:** analista/operador. **Telas:** 11 → 12 → 13.

1. Abre o **Dashboard** e olha os KPIs do dia.
2. Vê uma queda de envio ou um pico de falha.
3. Vai para **Ações**, filtra por status de falha e pelo período.
4. Abre o **detalhe da ação** para ver o motivo da falha.
5. Se o problema é do cliente, clica para o **detalhe do contato** na Carteira.
6. No detalhe, olha histórico, parcelas e conversas; corrige telefone, aplica selo, ou cria uma **ação manual**.
7. Se o problema é sistêmico, **pausa o envio** e avisa o time.

**Atritos mapeados:**
- A tabela de Ações não tem ordenação nem seleção múltipla nem ações em massa — o analista trata caso a caso.
- Ir da ação para o contato não é uma ponte explícita em toda linha.
- O motivo da falha aparece em vocabulário técnico.

**O que o redesenho deve entregar:** seleção múltipla e ações em massa em Ações; ponte explícita ação ↔ contato ↔ título nos dois sentidos; motivos de falha em linguagem humana com "o que fazer agora".

---

## 4. Fluxo C — Montar uma nova estratégia de cobrança

**Persona:** configurador. **Telas:** 14 → 17 → 16 → 15. É o fluxo mais longo do produto.

1. **Filtros** — cria o recorte da base (ex.: "clientes PF com parcela entre 15 e 45 dias e valor acima de R$ 300"). Testa na **prévia**, vê contagem e amostra.
2. Transforma o filtro em **portfólio/carteira**.
3. **Templates** — escreve as mensagens por canal, insere variáveis, confere a prévia com dados reais. Para WhatsApp, seleciona ou solicita um modelo aprovado pela Meta.
4. **Réguas** — cria a régua e adiciona passos no editor em tela cheia:
   - escolhe o tipo do passo;
   - define **quando** dispara (faixa de dias de atraso, ou janela de dias na etapa);
   - escolhe o conteúdo e a integração;
   - revisa e salva.
5. Vincula a régua às carteiras.
6. **Publica** a versão da régua.
7. **Campanhas** — cria a campanha, associa réguas e carteiras, define gatilho e janela de envio.
8. Roda a **prévia/ensaio**: vê quantas ações sairiam, por quê, e quais seriam excluídas e por qual motivo.
9. Ajusta o que estiver errado (volta para o passo 4 ou 1).
10. Ativa a campanha.

**Atritos mapeados:**
- Quatro telas diferentes com quatro linguagens visuais diferentes para um único trabalho.
- O usuário só descobre no passo 8 que errou no passo 1.
- Passo de "cauda" (faixa aberta) sem cadência dispara todos os dias — erro real e caro, hoje avisado só por texto.
- Dois passos da mesma etapa com janelas sobrepostas disparam os dois; o sistema **não** barra, só avisa.

**O que o redesenho deve entregar:**
- Um **modo guiado** que atravesse as quatro telas em sequência.
- **Prévia contínua**: mostrar o volume estimado já na criação do filtro e da régua, não só no fim.
- Avisos de risco (cauda sem cadência, janelas sobrepostas) como **bloqueio visual forte**, não nota de rodapé.
- Voltar do ensaio direto para o passo problemático.

---

## 5. Fluxo D — Executar e monitorar uma campanha

**Persona:** configurador/gestor. **Telas:** 15 → 12.

1. Abre a campanha e dispara manualmente (ou espera o gatilho agendado).
2. Acompanha o **painel de monitoramento**: a execução passa por 6 etapas.
3. Vê o **funil de execução**: quantos contatos entraram, quantos títulos foram buscados, quantos casaram com passos, quantos foram excluídos e por qual motivo.
4. Faz **drill-down** em um motivo de exclusão para entender.
5. Quando a execução termina, vai para **Ações** e acompanha o envio.
6. Se algo deu errado, **cancela as ações pendentes** da campanha.

**Atritos mapeados:**
- Os motivos de exclusão (disposições) aparecem com nomes técnicos.
- Uma execução pode travar; a recuperação é automática, mas o estado "travado" é opaco para o usuário.
- Uma operação pesada pode retornar erro **sem ter falhado** (limite de tempo do proxy). A interface precisa de um estado "não sabemos", não só sucesso/erro.

**O que o redesenho deve entregar:** funil com vocabulário humano e explicação estruturada em cada etapa; estado explícito de execução travada, com ação de retomar; e o terceiro estado "resultado indeterminado".

---

## 6. Fluxo E — Disparo pontual

**Persona:** analista. **Telas:** 17 (parte A).

1. Abre **Disparos**.
2. Escolhe o público: cola uma lista, aplica um filtro, escolhe uma carteira ou seleciona manualmente.
3. Vê a **lista de destinatários** com badges de problema (sem telefone, bloqueado, variável vazia).
4. Compõe a mensagem: canal, template, variáveis.
5. Navega pela **prévia por destinatário** para conferir como cada mensagem vai sair.
6. Confirma o envio — **operação irreversível**.
7. Acompanha a **tabela de resultados** e, depois, o **histórico de disparos**.

**Atrito central:** é a operação mais irreversível do produto e a confirmação precisa deixar o escopo numérico explícito.

**O que o redesenho deve entregar:** confirmação de nível 3 com contagem ("4.812 mensagens, R$ X estimado, não pode ser desfeito"); resolução de problemas antes do envio (corrigir telefone, remover bloqueado) sem sair da tela.

---

## 7. Fluxo F — Conectar uma nova fonte de dados

**Persona:** administrador de dados. **Telas:** 19 → 20 → 14.

1. **Fonte de Dados** → cria a fonte, escolhe o tipo, informa conexão e credenciais, testa.
2. Cria o **pipeline**: seleciona a fonte, mapeia campos de origem para as entidades da Torre, define normalizações, agenda.
3. Executa e acompanha a primeira carga; trata erros do lote.
4. Cria **campos personalizados** para as colunas extras.
5. Configura a **materialização** (agendamento do refresh).
6. Os campos novos passam a aparecer em **Filtros**, nas colunas da **Carteira** e como **variáveis** de mensagem.

**Atritos mapeados:**
- Dois wizards grandes, cada um com sua própria linguagem.
- O mapeamento de campos é a parte mais difícil e mais crítica.
- A ligação "campo personalizado → aparece em 3 outros lugares" não é explicada em lugar nenhum.

**O que o redesenho deve entregar:** um só padrão de wizard; mapeamento com autodetecção visível e conferência lado a lado (origem × destino × amostra); e, ao criar um campo, mostrar onde ele vai aparecer.

---

## 8. Fluxo G — Configurar e acompanhar um agente de IA

**Persona:** configurador + gestor. **Telas:** 18.

1. **Galeria de agentes** → cria ou abre um agente.
2. Configura personalidade, prompt, diretrizes e regras de negócio.
3. Define **etapas do funil**, **tags permitidas** e **tags de transferência**.
4. Sobe documentos na **base de conhecimento** e testa consultas.
5. Testa a conversa no **playground**, escolhendo um contrato real como contexto.
6. Publica a versão.
7. Liga o agente a um passo de régua (gatilho de IA).
8. Acompanha as **métricas**: volume, funil, transferências, transbordo, acurácia, tags, chamadas entre agentes.
9. Lê **conversas** reais por protocolo.
10. Exporta o **relatório de performance**, ou agenda o envio.

**Atrito central:** as métricas de IA são o assunto mais sofisticado do produto — inclusive porque o sistema **declara quando não sabe** um número em vez de publicar zero. Esse estado precisa de tratamento visual próprio.

**O que o redesenho deve entregar:** padrão "indisponível ≠ zero"; explicação estruturada obrigatória em toda métrica; e distinção visual clara entre **transferência** e **transbordo**.

---

## 9. Fluxo H — Bloquear um cliente

**Persona:** analista. **Telas:** 13.

1. Na **Carteira**, aba de lista de bloqueio.
2. Escolhe a forma: entrada manual, regra por filtro, ou bloqueio em massa.
3. Define o alvo (uma das 8 esferas), o escopo por canal e o prazo.
4. Confirma.
5. Depois, se precisa liberar temporariamente sem apagar o bloqueio, cria uma **exceção**.

**Conceito que a interface precisa comunicar:** a exceção **neutraliza** o bloqueio, não o apaga — a entrada permanece e volta a valer quando a exceção vence. E há **dois prazos diferentes**: o prazo padrão das entradas geradas (por alvo) e o prazo de validade da regra (absoluto).

**O que o redesenho deve entregar:** estado de três níveis (bloqueado / liberado temporariamente / livre) legível em qualquer lugar onde o cliente aparecer, com a data de retorno do bloqueio.

---

## 10. Fluxo I — Fechamento gerencial

**Persona:** gestor. **Telas:** 11 → 12 → 18.

1. **Dashboard**, define o período e as carteiras.
2. Lê os KPIs e o funil de cobrança.
3. Compara a evolução por passo da régua.
4. Vai para **Relatório de Ações** para o detalhamento.
5. Puxa as **métricas de IA** do período.
6. Exporta / imprime em PDF e leva para a reunião.

**Atritos mapeados:**
- ⚠️ O botão de exportação do Dashboard está implementado mas desativado no código.
- Existem **dois "Funis de Cobrança"** com o mesmo nome e leituras diferentes (um com 4 níveis, outro com 7 estágios).
- A aba de Atribuição ignora a maioria dos filtros, mas a barra de filtros continua visível.
- O carregamento das RPCs pesadas é serializado de propósito — a tela demora e parece travada.

**O que o redesenho deve entregar:** exportação reativada e consistente; nomes distintos para os dois funis; filtros que não se aplicam devem aparecer **desabilitados com explicação**, não ativos e ignorados; e feedback de carregamento em fila ("carregando 2 de 4").

---

## 11. Fluxo J — Operar com o assistente Maestro

**Persona:** qualquer. **Telas:** 22 (painel transversal).

1. Abre o painel lateral pelo botão da sidebar.
2. O assistente recebe o **contexto da tela atual**.
3. O usuário pede algo em linguagem natural.
4. O assistente responde, ou monta um **plano** com itens.
5. Conforme o modo (`plan` / `semi_auto` / `full_auto`), o usuário aprova e o assistente executa.
6. Tudo fica registrado na auditoria.

**O que o redesenho deve entregar:** deixar claro, o tempo todo, **o que o assistente enxerga** e **o que ele pode executar sozinho** — hoje isso depende de um modo escondido em configuração.

---

## 12. Matriz de pontes entre telas

Pontes que **existem** hoje (manter) e pontes que **faltam** (criar):

| De | Para | Existe? |
|---|---|---|
| Dashboard → Ações (por KPI/segmento) | detalhamento | ⚠️ A confirmar |
| Ações → detalhe do contato | contexto | Parcial |
| Ações → campanha de origem | causa | Parcial |
| Carteira → ações do contato | histórico | Sim (aba Histórico) |
| Carteira → criar ação manual | operação | Sim |
| Filtro → prévia com contagem | validação | Sim |
| Filtro → carteiras/réguas que o usam | impacto | **Falta** |
| Template → onde está sendo usado | impacto | Sim (modal de uso) |
| Régua → campanhas que a usam | impacto | **Falta** |
| Campanha → ações geradas | resultado | Parcial |
| Execução → motivo de exclusão → contatos afetados | diagnóstico | Sim (drill-down) |
| Campo personalizado → filtros/colunas/variáveis que o usam | impacto | **Falta** |
| Ação de IA → protocolo/conversa | contexto | Parcial |
| Qualquer tela → documentação da própria tela | ajuda | Sim (Central de Docs, pilar Negócio) |

> **Recomendação forte:** o redesenho deveria adotar "**onde isto é usado**" como padrão universal — todo objeto configurável (filtro, carteira, régua, template, campo, integração, agente) mostra quem depende dele antes de o usuário editar ou excluir.

---

## 13. Fluxos que precisam de atenção especial no redesenho

| Fluxo | Por quê |
|---|---|
| C (montar estratégia) | Atravessa 4 telas; é onde o usuário mais erra e mais tarde descobre. |
| E (disparo pontual) | Operação irreversível de alto volume. |
| D (executar campanha) | Estado opaco; resultado pode ser indeterminado. |
| H (bloqueio) | Conceito de exceção é sofisticado e mal comunicado. |
| G (métricas de IA) | Estados de "não sabemos" precisam de linguagem visual própria. |
| B (rotina diária) | É o fluxo mais repetido — cada clique economizado vale muito. |
