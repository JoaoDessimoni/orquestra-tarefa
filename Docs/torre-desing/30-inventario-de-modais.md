# 30 · Inventário Mestre de Modais, Diálogos e Painéis

> **Levantamento direto do código-fonte**, por varredura de `<DialogContent>`, `<AlertDialogContent>` e `<SheetContent>` em `cobranca-finza/src/**/*.tsx`, excluindo testes e os primitivos de `src/components/ui/`.
> Este documento é a **lista de verificação** do redesenho: nenhuma dessas superfícies pode desaparecer sem decisão explícita. O detalhamento de cada uma (campos, botões, validações, estados) está no documento do domínio correspondente.

---

## 1. Números

| Tipo | Quantidade | Papel |
|---|---|---|
| `Dialog` (modal) | **84** | Formulário focado, detalhe, prévia, wizard. |
| `AlertDialog` (confirmação bloqueante) | **39** | Confirmação de ação destrutiva ou de alto impacto. |
| `Sheet` (painel lateral) | **4** | Inspetor/edição contextual ao lado do conteúdo. |
| **Total de superfícies modais** | **127** | distribuídas em **99 arquivos**. |

Além dessas, existem **pseudo-modais** — telas que trocam o conteúdo inteiro por `early return` (ex.: os 8 estados da rota de aceite de convite). Estão catalogados no documento 10.

**Leitura:** 39 confirmações bloqueantes é um número alto. Boa parte delas usa o mesmo padrão copiado com textos diferentes — é a maior oportunidade de consolidação do redesenho (um componente `DangerConfirm` parametrizado).

---

## 2. Inventário por domínio

Legenda de tipo: **D** = Dialog · **A** = AlertDialog · **S** = Sheet.
A coluna "Doc" aponta o documento com a especificação completa.

### 2.1 Autenticação e Organização — Doc 10

| Arquivo | D | A | S |
|---|---|---|---|
| `pages/SelectOrganizationPage.tsx` | 1 | 2 | — |

### 2.2 Ações — Doc 12

| Arquivo | D | A | S |
|---|---|---|---|
| `components/actions/ActionDetailDialog.tsx` | 1 | — | — |
| `components/actions/FailureReasonsDialog.tsx` | 1 | — | — |
| `components/actions/PauseSendingModal.tsx` | 1 | — | — |
| `components/reports/ReportExportDialog.tsx` | 1 | — | — |

### 2.3 Gestão de Carteira — Doc 13

| Arquivo | D | A | S |
|---|---|---|---|
| `components/portfolio/detail/ContactDetailSheet.tsx` | 1 | — | — |
| `components/portfolio/detail/ManualActionDialog.tsx` | 1 | — | — |
| `components/portfolio/PortfolioCreateWizard.tsx` | 1 | — | — |
| `components/portfolio/PortfolioEditDialog.tsx` | 1 | — | — |
| `components/portfolio/ContractEditDialog.tsx` | 1 | — | — |
| `components/portfolio/TitleEditDialog.tsx` | 1 | — | — |
| `components/portfolio/SupplyEditDialog.tsx` | 1 | — | — |
| `components/portfolio/SupplyTitleEditDialog.tsx` | 1 | — | — |
| `components/portfolio/DeleteContactDialog.tsx` | — | 1 | — |
| `components/contacts/ContactDialog.tsx` | 1 | — | — |
| `components/contacts/ContactDetailDialog.tsx` | 1 | — | — |
| `components/contracts/ContractDialog.tsx` | 1 | — | — |
| `components/contracts/ContractDetailDialog.tsx` | 1 | — | — |
| `components/seals/SealDialog.tsx` | 1 | — | — |
| **Lista de bloqueio** | | | |
| `components/portfolio/BlocklistDialog.tsx` | 1 | — | — |
| `components/portfolio/BlocklistManualDialog.tsx` | 1 | — | — |
| `components/portfolio/BlocklistBulkDialog.tsx` | 1 | — | — |
| `components/portfolio/BlocklistFilterRuleDialog.tsx` | 1 | — | — |
| `components/portfolio/BlocklistRuleDetailDialog.tsx` | 1 | — | — |
| `components/portfolio/BlocklistTab.tsx` | — | 1 | — |
| `components/portfolio/BlocklistTabV2.tsx` | — | **4** | — |

> `BlocklistTabV2` concentra **4 confirmações bloqueantes** em um único arquivo — é o ponto mais denso de confirmação do produto.

### 2.4 Filtros e Portfólios — Doc 14

| Arquivo | D | A | S |
|---|---|---|---|
| `pages/FiltersPage.tsx` | — | 2 | — |
| `components/filters/filter-builder/index.tsx` | 1 | — | — |
| `components/filters/FilterPortfolioModal.tsx` | 1 | — | — |
| `components/filters/FilterPreviewDialog.tsx` | 1 | — | — |
| `components/portfolios/PortfolioDialog.tsx` | 1 | — | — |
| `components/portfolios/PortfolioIntegrationsPanel.tsx` | 1 | — | — |

### 2.5 Campanhas e Broadcast — Doc 15

| Arquivo | D | A | S |
|---|---|---|---|
| `components/campaigns/CampaignDialog.tsx` | 1 | — | — |
| `components/campaigns/CampaignDetailDialog.tsx` | 1 | — | — |
| `components/campaigns/CampaignPreviewModal.tsx` | 1 | — | — |
| `components/campaigns/CampaignDryRunDialog.tsx` | 1 | — | — |
| `components/campaigns/CampaignLogDetailDialog.tsx` | 1 | — | — |
| `components/campaigns/CancelCampaignActionsDialog.tsx` | — | 1 | — |
| `components/campaigns/ExecuteOutsideWindowDialog.tsx` | — | 1 | — |
| `components/campaigns/BroadcastAddStepDialog.tsx` | 1 | — | — |

### 2.6 Réguas de Cobrança — Doc 16

| Arquivo | D | A | S |
|---|---|---|---|
| `pages/ReguasCobrancaPage.tsx` | — | 1 | — |
| `components/reguas-cobranca/ReguaDialog.tsx` | 1 | — | — |
| `components/reguas-cobranca/StepConfigDialog.tsx` | 1 | — | — |
| `components/reguas-cobranca/BulkIntegrationDialog.tsx` | 1 | — | — |
| `components/reguas-cobranca/wizard/StepWizard.tsx` | 1 | — | — |
| `components/reguas-cobranca/timeline/EditCaudaDialog.tsx` | 1 | — | — |
| `components/reguas-cobranca/timeline/StepCard.tsx` | — | 1 | — |
| `components/reguas-cobranca/versioning/PublishDialog.tsx` | 1 | — | — |
| `components/reguas-cobranca/versioning/VersionHistoryPanel.tsx` | — | 1 | 1 |
| `components/reguas-cobranca/audit/AuditLogPanel.tsx` | — | — | 1 |
| `components/reguas-cobranca/config-forms/SharedComponents/TemplateHSMSelector.tsx` | 1 | — | — |

### 2.7 Disparos e Templates — Doc 17

| Arquivo | D | A | S |
|---|---|---|---|
| `pages/MessageTemplatesPage.tsx` | 1 | 2 | — |
| `components/message-templates/TemplateDialog.tsx` | 1 | — | — |
| `components/message-templates/TemplateUsageDialog.tsx` | 1 | — | — |
| `components/message-templates/RcsImagePicker.tsx` | 1 | — | — |

> ⚠️ A tela de **Disparos** não aparece nesta varredura — ela não usa `DialogContent`/`AlertDialogContent`. As confirmações de envio são implementadas de outra forma. Ver doc 17, parte A.

### 2.8 Agentes de IA — Doc 18

| Arquivo | D | A | S |
|---|---|---|---|
| `pages/AgentWorkspace.tsx` | 1 | 1 | — |
| `components/ia/AgentFormDialog.tsx` | 1 | — | — |
| `components/ia/AgentDeleteDialog.tsx` | 1 | — | — |
| `components/ia/AgentActionsMenu.tsx` | — | 1 | — |
| `components/ia/AgentAllowedTagsConfig.tsx` | — | 1 | — |
| `components/ia/PromptEditor.tsx` | 1 | — | — |
| `components/ia/GuidelinesEditor.tsx` | 1 | — | — |
| `components/ia/BusinessRulesBuilder.tsx` | 1 | — | — |
| `components/ia/FunnelStagesConfig.tsx` | **2** | — | — |
| `components/ia/TransferTagsConfig.tsx` | **2** | **3** | — |
| `components/ia/VersionManager.tsx` | 1 | — | — |
| `components/ia/AIPlayground.tsx` | — | 1 | — |
| `components/ia/PlaygroundSettingsDialog.tsx` | 1 | 1 | — |
| `components/ia/ConversationLogs.tsx` | 1 | — | — |
| `components/ia/TransferDrilldownPanel.tsx` | 1 | — | 1 |
| `components/agent-ia/RagDocumentList.tsx` | — | 1 | — |

> `TransferTagsConfig` sozinho tem **5 superfícies modais** (2 diálogos + 3 confirmações).

### 2.9 Fonte de Dados / ETL — Doc 19

| Arquivo | D | A | S |
|---|---|---|---|
| `components/etl/wizards/DataSourceWizard/index.tsx` | 1 | — | — |
| `components/etl/wizards/PipelineWizard/index.tsx` | 1 | — | — |
| `components/etl/wizards/PipelineWizard/components/CustomValueModal.tsx` | 1 | — | — |
| `components/etl/PipelineDetailDialog.tsx` | 1 | — | — |
| `components/etl/PipelineHistoryDialog.tsx` | 1 | — | — |
| `components/etl/JobErrorsDialog.tsx` | 1 | — | — |
| `components/etl/CustomFieldModal.tsx` | 1 | — | — |
| `components/etl/DataSourceSkillViewer.tsx` | — | 1 | — |
| `components/etl/tabs/MaterializationTab.tsx` | 1 | — | — |

### 2.10 Integrações e Configurações — Doc 20

| Arquivo | D | A | S |
|---|---|---|---|
| **Integrações** | | | |
| `components/integrations/IntegrationBuilderSheet.tsx` | — | — | 1 |
| `components/integrations/ImportCurlModal.tsx` | 1 | — | — |
| `components/integrations/ApiKeysSection.tsx` | 1 | 1 | — |
| **Configurações** | | | |
| `components/settings/RolesPermissionsCard.tsx` | 1 | — | — |
| `components/settings/StandardValuesSettings.tsx` | 1 | 1 | — |
| `components/settings/tabs/UsersTab.tsx` | **2** | — | — |
| `components/settings/tabs/AgingBucketsTab.tsx` | — | 1 | — |
| `components/settings/tabs/BlockedDatesTab.tsx` | 1 | — | — |
| `components/settings/tabs/CustomVariablesTab.tsx` | 1 | 1 | — |
| `components/settings/tabs/PipelineProfileTab.tsx` | — | 1 | — |
| `components/settings/tabs/ReportSchedulesTab.tsx` | 1 | 1 | — |
| `components/settings/tabs/SealAssignmentsList.tsx` | — | 1 | — |
| `components/settings/tabs/SealCatalogTab.tsx` | — | 1 | — |
| `components/settings/tabs/TagCatalogTab.tsx` | **2** | **3** | — |
| `components/settings/tabs/TowerReportRoutineCard.tsx` | 1 | 1 | — |

> `TagCatalogTab` também tem **5 superfícies modais**.

### 2.11 Documentação — Doc 21

| Arquivo | D | A | S |
|---|---|---|---|
| `pages/central-docs/changelog/ChangelogPeoplePopover.tsx` | 2 | — | — |
| `pages/central-docs/shared/DocBlocks.tsx` | 1 | — | — |

### 2.12 Elementos globais — Doc 22

| Arquivo | D | A | S |
|---|---|---|---|
| `components/agent/AgentConfigModal.tsx` | 1 | — | — |
| `components/layout/CustomerSearch.tsx` | 1 | — | — |

---

## 3. Ranking de densidade modal

Arquivos com mais de uma superfície modal — os pontos que mais se beneficiam de consolidação:

| Arquivo | Superfícies | Domínio |
|---|---|---|
| `components/ia/TransferTagsConfig.tsx` | 5 (2D + 3A) | Agentes de IA |
| `components/settings/tabs/TagCatalogTab.tsx` | 5 (2D + 3A) | Configurações |
| `components/portfolio/BlocklistTabV2.tsx` | 4 (4A) | Carteira |
| `pages/MessageTemplatesPage.tsx` | 3 (1D + 2A) | Templates |
| `pages/SelectOrganizationPage.tsx` | 3 (1D + 2A) | Organização |
| `components/ia/FunnelStagesConfig.tsx` | 2 | Agentes de IA |
| `components/ia/PlaygroundSettingsDialog.tsx` | 2 | Agentes de IA |
| `components/ia/TransferDrilldownPanel.tsx` | 2 (1D + 1S) | Agentes de IA |
| `pages/AgentWorkspace.tsx` | 2 | Agentes de IA |
| `components/settings/tabs/UsersTab.tsx` | 2 | Configurações |
| `components/settings/tabs/CustomVariablesTab.tsx` | 2 | Configurações |
| `components/settings/tabs/ReportSchedulesTab.tsx` | 2 | Configurações |
| `components/settings/tabs/TowerReportRoutineCard.tsx` | 2 | Configurações |
| `components/settings/StandardValuesSettings.tsx` | 2 | Configurações |
| `components/integrations/ApiKeysSection.tsx` | 2 | Integrações |
| `pages/FiltersPage.tsx` | 2 (2A) | Filtros |
| `components/reguas-cobranca/versioning/VersionHistoryPanel.tsx` | 2 (1A + 1S) | Réguas |
| `pages/central-docs/changelog/ChangelogPeoplePopover.tsx` | 2 | Documentação |

Concentração por domínio:

| Domínio | Superfícies |
|---|---|
| Configurações | 19 |
| Agentes de IA | 19 |
| Gestão de Carteira | 21 |
| Réguas de Cobrança | 11 |
| Fonte de Dados (ETL) | 9 |
| Campanhas | 8 |
| Filtros e Portfólios | 8 |
| Templates | 6 |
| Integrações | 3 |
| Ações | 4 |
| Organização | 3 |
| Documentação | 3 |
| Globais | 2 |

---

## 4. Os 4 painéis laterais (Sheet)

Sheet é raro e, por isso, tem semântica clara no produto: **inspetor/edição contextual ao lado do conteúdo**, sem perder o contexto da lista.

| Painel | Arquivo | O que inspeciona |
|---|---|---|
| Construtor de integração | `components/integrations/IntegrationBuilderSheet.tsx` | A integração HTTP sendo montada. |
| Auditoria de régua | `components/reguas-cobranca/audit/AuditLogPanel.tsx` | Histórico de alterações da régua. |
| Histórico de versões da régua | `components/reguas-cobranca/versioning/VersionHistoryPanel.tsx` | Versões publicadas. |
| Drill-down de transferências | `components/ia/TransferDrilldownPanel.tsx` | Detalhe de uma transferência de IA. |

> O detalhe do contato (`ContactDetailSheet.tsx`) tem "Sheet" no nome mas é implementado como **Dialog**. ⚠️ A confirmar se isso é intencional — conceitualmente ele é um inspetor e deveria ser Sheet.

---

## 5. Padrões de modal a consolidar no redesenho

| Padrão recorrente | Quantas vezes se repete | Proposta |
|---|---|---|
| Confirmar exclusão de item de catálogo (tag, selo, faixa, data bloqueada, variável, agendamento) | ~12 | Um `ConfirmDelete` parametrizado (nome do item, consequências, "onde é usado"). |
| Criar/editar item de catálogo | ~10 | Um `CatalogItemDialog` com campos por esquema. |
| Detalhe/inspeção somente leitura (ação, campanha, pipeline, execução, regra) | ~8 | Um `DetailDialog` com cabeçalho, blocos e linha do tempo. |
| Wizard multi-etapa | 4 (fonte de dados, pipeline, carteira, passo de régua) | Um `Wizard` único com `WizardStepper`, validação por fase e resumo final. |
| Prévia/ensaio com contagem e amostra | 4 (filtro, campanha, disparo, template) | Um `PreviewDialog` com contagem, amostra, colunas escolhíveis e exportação. |
| Confirmação de alto risco com escopo numérico | 5 | Um `DangerConfirm` (verbo, escopo, irreversibilidade, confirmação proporcional). |

**Se essas seis consolidações forem feitas, as 127 superfícies caem para algo em torno de 40 componentes distintos** — sem perder nenhuma funcionalidade.

---

## 6. Checklist de verificação do redesenho

Para cada uma das 127 superfícies:

- [ ] Existe no redesenho, ou tem decisão explícita de remoção registrada.
- [ ] Mantém todos os campos, com os mesmos rótulos.
- [ ] Mantém todos os botões, com a mesma variante semântica.
- [ ] Mantém o nível de confirmação (1, 2 ou 3) ou aumenta — nunca diminui.
- [ ] Tem estado de carregamento, erro e envio em andamento.
- [ ] Funciona no tema escuro.
- [ ] Funciona abaixo de 768px.
- [ ] Fecha por ESC e pelo botão de fechar; foco preso enquanto aberto.
- [ ] Se contém formulário longo, tem guarda de saída com alterações não salvas.
