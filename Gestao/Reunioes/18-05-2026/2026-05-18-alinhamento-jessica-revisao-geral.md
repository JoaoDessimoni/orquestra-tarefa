---
title: Alinhamento Jéssica — revisão geral do Roadmap IA & Automações
data: 2026-05-18
participantes: [Jéssica (Gerente Cobrança), João Vinícius]
duracao: 1h
tipo: alinhamento
tags: [jessica, roadmap, esperanza, valentina, clara, torre, automacoes, cobranca]
pendencias-geradas: [P16, P17, P18, P19, P20, P22, P23, P24, P29, P30, P31, P32, P33, P34, P35]
---

## Pauta

Revisão completa, ponto a ponto, das prioridades do time de cobrança para a IA e Automações no próximo ciclo. Jéssica trouxe o documento "Roadmap Novos Desenvolvimentos - IA e Automações" estruturado em 4 seções: Agentes IA (Esperanza, Valentina, Clara), Torre de Controle, Automações e Regras Operacionais.

## Discussão

Jéssica conduziu a reunião apresentando o roadmap por seção. Tópicos discutidos:

### Esperanza (cobrança)

- **Renegociação de valores vencidos:** já existe implementação parcial. Próximo passo é homologar em fórum específico o fluxo "renegociação com transferência para humano". Após validação operacional, abrir caminho para imputação direta no Módulo Financeiro (sem operador humano no meio).
- **Volume de transferências para humano:** sem visibilidade hoje. Precisa-se de mapeamento por departamento e por agente humano para entender gargalos, dimensionar equipes e identificar oportunidades de automação adicional.
- **Tabulações automáticas:** Esperanza não categoriza as interações sistematicamente. Cria-se um classificador por tipo de tabulação para gerar indicadores operacionais.
- **Discovery Esperanza:** supervisor levantou (do caderno do dia) que falta entendimento operacional sobre quais casos a IA atende, quais não, e qual é o domínio real. Jéssica concordou que esse discovery é pré-requisito para qualquer evolução robusta.
- **Números Finza/Blips:** pendência transversal — precisa-se mapear quais agentes IA estão em quais números oficiais (Finza e Blips) para entender roteamento real.

### Valentina (SAC Finza)

- **Originador automático:** Valentina hoje atende como se houvesse só um originador. Precisa identificar o originador na entrada e personalizar a conversa.
- **Demandas Rhino:** mapear o que o time Rhino tipicamente demanda, para suportar adequadamente.
- (Itens RM10 Base contexto, RM11 MCPs, RM09 Roteamento Rhino vieram da reunião 15/05 com diretoria e foram referenciados aqui — Jéssica está alinhada.)

### Clara (formalização)

Discussão profunda — Jéssica indicou que será o tema central da segunda reunião do dia (14h). Pontos iniciais aqui:
- Solicitação/recebimento de comprovantes de endereço por Clara.
- Tratativa de reprovados em formalização.
- Envio e acompanhamento de biometria.

### Torre de Controle

- **Rhino como novo originador** precisa entrar no ecossistema operacional.
- **Dashboards e relatórios IA** precisam de validação conjunta — cálculos, conceitos, usabilidade.
- **RCS (Rich Communication Services)** como canal adicional.
- **IA por empresa/carteira** — estruturar inteligências específicas por contexto.

### Automações

- **Bitrix Cobrança 4.0 — histórico contínuo:** os campos da seção "Histórico de Atendimento" precisam funcionar em formato de log acumulado, não sobrescrita.
- **Gatilhos Hyper:** revisar inventário existente, identificar lacunas.

### Regras operacionais (referência, não pendência)

Jéssica entregou as 3 regras consolidadas:
- **Comprovação de endereço** — 3 endereços (empresa, residencial, entrega), comprovantes de últimos 30 dias.
- **Construção civil** — foto da fachada + 3 notas fiscais nos últimos 3 meses.
- **Reembolso** — banco/agência/conta/PIX titular CNPJ.

Estas regras viram seção de referência na análise mestre do Roadmap. Não geram pendência direta — são especificações operacionais que orientam a implementação de Clara.

## Decisões

1. **Roadmap aprovado integralmente** como base de trabalho do squad IAF para 2026Q3.
2. **Discovery de Esperanza precede evolução** — o item de discovery (P20) entra antes dos itens de evolução funcional.
3. **Reunião dedicada à formalização** marcada para 14h do mesmo dia (Clara é tema denso).
4. **Documento .txt do Roadmap** fica como fonte original; supervisor estrutura análise formal no dia seguinte (19/05) consolidando + cruzando com anotações pré-reunião e reunião 15/05 com diretoria.

## Pendências geradas

(15 pendências derivadas desta reunião — listadas no `pendencias-geradas` do frontmatter. Detalhe completo em [análise mestre Roadmap](../../Analises/19-05-2026/2026-05-19_roadmap-ia-automacoes-jessica.md).)

## Próximos passos

- Reunião de continuação às 14h do mesmo dia (formalização — Clara em detalhe).
- Supervisor consolida o roadmap em análise estruturada no dia 19/05.
- Início da execução: P20 (discovery Esperanza) com deadline mais curto que os itens de implementação.

## Notas / observações

- Jéssica é gerente da Cobrança Finza e cliente direta do squad IAF. Esta é a interlocução de prioridades.
- Documento Roadmap.txt original está em `Gestao/Pendencias/19-05-2026/Roadmap Novos Desenvolvimentos - IA e Automações.txt` — preservado como fonte primária.
- Reunião não teve sub-deadlines item-a-item — deadlines foram atribuídos pelo supervisor na análise mestre com base em criticidade percebida e dependências internas.
- "Anotações do caderno" do supervisor (sobre Esperanza, números Finza/Blips, formalização, raia Bitrix) complementam e enriquecem os itens do Roadmap formal — todas foram incorporadas como pendências (P20, P21, P22) ou estão na 2ª reunião do dia (Bitrix/raia/formalização).
