# Frente — Bitrix & Automações

Frente unificada que cobre o CRM Bitrix24 da Finza (raias kanban, automações, integrações operacionais) e a infraestrutura de automação técnica (HyperFlow, MCPs, integrações inter-plataformas).

**Sponsor padrão:** Jéssica (Gerente Cobrança) — apoio do Time Plataformas para itens de infra
**ID prefixes aceitos:** `BBT##` (Bitrix) · `BAU##` (Automações)

## Por que fundir Bitrix e Automações

Operacionalmente as duas frentes se sobrepõem: configuração de raia no Bitrix muitas vezes depende de gatilho HyperFlow para entrar/sair; MCPs de plataforma alimentam tanto agentes IA quanto operações Bitrix. Manter como duas frentes separadas criava fricção desnecessária na priorização e dependências cruzadas.

## Escopo

### Bitrix (prefix BBT)
- Configuração de raias kanban para visibilidade operacional
- Automações internas do Bitrix Cobrança 4.0
- Integração com outras plataformas Finza (entrada da Clara → raia de reembolso)
- Histórico contínuo nos campos de atendimento

### Automações (prefix BAU)
- Revisão e expansão de gatilhos HyperFlow
- Criação de MCPs (Model Context Protocol) das plataformas Finza
- Integrações infra entre Módulo Financeiro · Bitrix · Torre · HyperFlow
- Padronização de canais de comunicação automatizados

## Diferenciação interna

- **BBT##** — toca diretamente o CRM Bitrix (interface operadora).
- **BAU##** — toca a infra técnica abaixo (orquestradores, APIs, MCPs).

Quando um item cruza os dois mundos (ex: raia Bitrix que depende de gatilho HyperFlow), a prática é abrir como BBT se a entrega final é configuração no Bitrix e marcar dependência para o BAU correspondente.

## Fora de escopo

- Funcionalidades dentro de cada agente IA (vão para frentes específicas — Clara, Esperanza, Valentina, Lívia)
- Dashboards e relatórios (vão para Torre de Controle)
- Decisões de processo de squad (vão para Estratégica)
