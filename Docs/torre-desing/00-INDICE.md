# Torre de Controle — Especificação Completa de Frontend para Redesenho

> **Propósito:** este pacote descreve, de forma exaustiva, **todo o frontend atual** da Torre de Controle, para que o redesenho feito no Claude Design não deixe nenhuma funcionalidade para trás.
> **Método:** leitura direta do código-fonte em `cobranca-finza/src/` (26 páginas, ~450 componentes, ~130 hooks), cruzada com os guias de negócio que o próprio produto mantém em `src/pages/central-docs/negocio/data/`.
> **Regra:** nada foi inventado. Onde o código não permitiu concluir, há uma marcação `⚠️ A confirmar:`.

**21 documentos · 30.079 linhas · 2,6 MB**

---

## Como usar este pacote

| Etapa | O que fazer |
|---|---|
| 1. Contexto | Leia os documentos **01 a 05**. São a fundação: o que é o produto, como o frontend é montado, a paleta, os componentes base e os padrões de interação. |
| 2. Abertura no Claude Design | Cole o bloco **A** do documento **99**. Ele carrega todo o contexto de uma vez e define o modo de trabalho (fundação primeiro, telas depois). |
| 3. Tela a tela | Para cada tela, cole o bloco **B** do documento 99 com o conteúdo do documento correspondente (10 a 22). |
| 4. Conferência | Use o bloco **C** do documento 99 e o checklist do documento **30** para verificar que nada sumiu. |
| 5. Aplicação no código | Siga a seção **D** do documento 99. |

---

## Fundação

| Doc | Título | Linhas | O que traz |
|---|---|---|---|
| **01** | [Visão geral, entidades e vocabulário](01-visao-geral-produto-e-entidades.md) | 158 | O que o produto faz, personas, todas as entidades do domínio, a esteira macro, e as três armadilhas de vocabulário (os três sentidos de "status", e "etapa" ≠ status). |
| **02** | [Arquitetura de frontend, shell e rotas](02-arquitetura-frontend-e-rotas.md) | 220 | Stack, árvore de providers, anatomia do shell, mapa completo de rotas, guardas, multi-tenant, restrições do Lovable. |
| **03** | [Design system e paleta](03-design-system-e-paleta.md) | 316 | Todos os tokens em HSL e hex, claro e escuro, tipografia, forma, elevação, camadas, ícones, movimento, impressão, responsividade, acessibilidade. |
| **04** | [Biblioteca de componentes](04-biblioteca-de-componentes.md) | 233 | Os 40 primitivos, variantes de cada um, e as **10 dívidas do design system** a quitar. |
| **05** | [Padrões de UI/UX transversais](05-padroes-ui-ux.md) | 211 | Carregamento híbrido, estados vazio/erro, toasts, ajuda estruturada, filtros, tabelas, formulários, confirmação de risco. |

---

## Telas, por domínio

| Doc | Domínio | Rotas | Linhas |
|---|---|---|---|
| **10** | [Autenticação e Organização](10-telas-autenticacao-e-organizacao.md) | `/login`, `/signup`, `/accept-invite`, `/select-organization` | 1.310 |
| **11** | [Dashboard](11-tela-dashboard.md) | `/` | 1.363 |
| **12** | [Ações](12-telas-acoes.md) | `/actions`, `/actions/report`, `/actions/payment-analysis` | 1.118 |
| **13** | [Gestão de Carteira](13-tela-gestao-carteira.md) | `/portfolio` | 1.663 |
| **14** | [Filtros e Portfólios](14-tela-filtros-e-portfolios.md) | `/filters` | 3.074 |
| **15** | [Campanhas e Broadcast](15-telas-campanhas.md) | `/campaigns`, `/broadcasts/:id/editor` | 2.535 |
| **16** | [Réguas de Cobrança](16-telas-reguas-de-cobranca.md) | `/reguas-cobranca`, `/reguas-cobranca/:id/editor` | 2.044 |
| **17** | [Disparos e Templates](17-telas-disparos-e-templates.md) | `/disparos`, `/templates` | 2.514 |
| **18** | [Agentes de IA](18-telas-agentes-ia.md) | `/agent-ia`, `/agent-ia/:agentId`, `/agent-ia/tags` | 3.265 |
| **19** | [Fonte de Dados (ETL)](19-tela-fonte-de-dados-etl.md) | `/etl` | 2.449 |
| **20** | [Integrações e Configurações](20-telas-integracoes-e-configuracoes.md) | `/integrations`, `/settings` | 3.809 |
| **21** | [Telas de Documentação](21-telas-documentacao.md) | `/central-docs/*`, `/docs`, `/docs/fonte-de-dados`, `/docs-especial` | 1.810 |
| **22** | [Painel Maestro e elementos globais](22-painel-maestro-e-elementos-globais.md) | transversal | 1.304 |

Cada documento de tela cobre: identidade e permissão · objetivo e persona · anatomia visual · todos os campos (rótulo, tipo, validação, default, opções) · todos os botões (rótulo, variante, ícone, ação) · todas as colunas de tabela · todos os filtros · todos os modais · todos os estados · fluxos de uso · responsividade e acessibilidade · dores e oportunidades · inventário de modais.

---

## Transversais e entrega

| Doc | Título | Linhas | Para quê |
|---|---|---|---|
| **30** | [Inventário mestre de modais](30-inventario-de-modais.md) | 231 | As **127 superfícies modais** do produto, levantadas por varredura do código. É o checklist de conferência do redesenho. |
| **31** | [Fluxos ponta a ponta](31-fluxos-ponta-a-ponta.md) | 209 | Os 10 fluxos reais que atravessam várias telas, com os atritos de cada um e a matriz de pontes entre telas. |
| **99** | [**Prompt para o Claude Design**](99-PROMPT-CLAUDE-DESIGN.md) | 243 | O prompt de abertura, o prompt por tela, o prompt de revisão e as instruções para aplicar o HTML no código. |

---

## Catálogos de referência (onde encontrar cada tabela grande)

Estes são os levantamentos exaustivos extraídos do código. São o material mais caro de reproduzir — consulte antes de pedir algo ao Claude Design.

| Catálogo | Onde | Tamanho |
|---|---|---|
| Matriz RBAC (papéis × permissões) | Doc 10, §1 | 5 papéis × 47 permissões |
| Status de ação (valor × rótulo × cor × ícone × grupo) | Doc 12, §2 | 12 status + 27 apelidos |
| Tipos e canais de ação | Doc 12, §3 | — |
| KPIs e métricas do Dashboard | Doc 11, §11 | 8 KPIs, 14 gráficos, 32 pontos de ajuda |
| Campos filtráveis | Doc 14, §6 | **88 campos** em 8 categorias |
| Operadores de filtro por tipo | Doc 14, §7 | 18 operadores |
| Disposições do pipeline de campanha | Doc 15, §9 | 16 motivos |
| Tipos de passo de régua | Doc 16, §8 | 13 tipos |
| Variáveis de mensagem | Doc 17, §B9 | **73 chaves** em 10 categorias + 4 namespaces |
| Métricas de IA | Doc 18, §20 | 15 métricas + 24 dimensões |
| Tipos de integração | Doc 20, §A8 | 10 tipos |
| Valores padrão de normalização | Doc 20 | 38 valores |
| Blocos visuais de documentação | Doc 21, §8 | 14 blocos |
| Estilos `.fdd-*` | Doc 03, §9 e Doc 21, §11 | 16 estilos |
| Estados de carregamento | Doc 05, §3 e Doc 22, §9 | 12 componentes |
| Inventário de modais | Doc 30 | 127 superfícies |

---

## Os achados que mudam o escopo do redesenho

Durante o levantamento apareceram problemas reais do produto atual. Eles **não são o escopo do redesenho**, mas o redesenho toca em todos eles — e alguns precisam de decisão sua antes.

### Precisam de decisão de produto antes de desenhar

1. **Não existe recuperação de senha na interface.** A função está no código, sem rota nem botão. (Doc 10)
2. **A exportação do Dashboard está desativada** — o componente existe, o import está comentado. (Doc 11)
3. **`/actions/payment-analysis` é 100% mockada** — números constantes, sem link em menu nenhum, com valores internamente contraditórios. (Doc 12)
4. **O Portal (`src/portal/`, ~200 arquivos) não tem rota** e está parado desde 29/07/2026; o próprio README recomenda a Central de Docs como fonte única. Manter ou descartar? (Doc 21)
5. **`condition` e `wait` não podem ser criados pela interface**, embora existam no motor e tenham formulário. (Doc 16)
6. **`Header.tsx` é código morto** — foi substituído pelo rodapé da sidebar. (Doc 02)

### Bugs encontrados na leitura (ver detalhe nos documentos)

- "Salvar Alterações" em Organização e Réguas grava `null` em domínio, cores e logo sem o usuário tocar em nada — `useState(() => ...)` usado como efeito. (Doc 20)
- Webhook em régua grava `integration_id` mas não oferece campo para escolhê-lo: todo webhook criado pela tela nasce "Incompleta" sem forma de corrigir. (Doc 16)
- O formulário de gatilho de IA sobrescreve silenciosamente o gatilho escolhido na fase "Quando". (Doc 16)
- Importar cURL apaga o cabeçalho travado `x-org-slug` e perde usuário/senha do Basic Auth. (Doc 20)
- Datas Bloqueadas e Custos por Canal não têm gate de permissão nenhum. (Doc 20)
- Cancelamento de ação não verifica `actions:write`. (Doc 12)
- "Ver Uso em Réguas" de um template checa só um campo — pode dar falso "não usado" e levar a exclusão indevida. (Doc 17)

### Padrões que se repetem como dívida

- **Erro de rede apresentado como estado vazio** em pelo menos 5 telas (organizações, integrações, templates, filtros de agente, configurações de IA). O usuário acha que não há dados quando na verdade a consulta falhou.
- **Confirmação nativa do navegador** (`window.confirm` / `alert`) em pelo menos 13 pontos, convivendo com o diálogo estilizado do design system.
- **Nenhuma guarda de descarte** nos construtores de filtro e no wizard de passo: ESC apaga trabalho longo.
- **Cor de status improvisada por tela**, porque o Badge não tem variantes semânticas — o mesmo status aparece com cores diferentes em telas diferentes.
- **~45 classes de cor sem variante `dark:`** — partes da interface quebram no tema escuro.
- **Elementos clicáveis como `<div>`** e ações reveladas só no hover — inacessíveis por teclado e no toque.

---

## Fronteiras

- Este pacote é **especificação**, não implementação. Nenhum código da Torre foi alterado.
- A Torre (`cobranca-finza/`) é um repositório próprio. Alteração de código acontece **dentro** dele; commit, push e PR são sempre dos desenvolvedores humanos.
- O redesenho é de **apresentação**. Os hooks de dados não mudam — se uma tela nova precisar de um dado que o hook não devolve, isso vira um item separado de backlog.

---

## Manutenção

Este pacote reflete o código em **17/09/2026**. Sempre que uma tela for redesenhada e aplicada, atualize o documento correspondente — caso contrário o pacote vira ficção e a próxima rodada de redesenho parte de uma base falsa.
