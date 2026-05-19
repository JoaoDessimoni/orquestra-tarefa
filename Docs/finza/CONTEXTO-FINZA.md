# Contexto Finza — Negócio, Organograma, Modelo Operacional

Documento de contexto para fundamentar conversas sobre a IAF. Última atualização: 12/05/2026.

> **Fontes:** `Apresentacoes/Boas Vinda FINZA - Tech - 2026.pdf`, `Apresentacoes/Roadmap Agentes IA — Operações Finza.pdf`, `Docs/repasse-joao-vinicius-iaf.html`, contexto adicional do usuário.

---

## 1 · Quem é a Finza

A **Finza** é uma **fintech de crédito** correspondente bancário com solução própria e multi-org. Nasceu como **spin-off do Grupo Blips em 2025** (separação do mercantil dos juros da operação Blips). Propósito declarado: **conectar fabricantes de equipamentos a micro e pequenos empreendedores brasileiros** que não têm acesso ao crédito tradicional.

### Linha do tempo (FinzaDay pp. 5)
- **2000** — Início da jornada (Meu MVP)
- **2001** — Ideal Cartuchos (independência)
- **2011** — Ideal Distribuidora
- **2013** — Equipamentos
- **2014** — Suprimentos e Peças (importação)
- **2017** — Locação
- **2019** — Blips (virada de chave)
- **2025** — Finza (separar mercantil de juros da operação Blips)
- **2026** — Finza (novas indústrias)

### Missão (declarada, FinzaDay pp. 8)
> Ampliar as possibilidades de crescimento da indústria, oferecendo crédito acessível e inteligente, com tecnologia IoT e análise de dados.

### Visão
> Ser a financeira parceira da indústria produtiva brasileira, oferecendo crédito embutido para aumentar as vendas de equipamentos, viabilizando sonhos e negócios, com gestão, eficiência e inovação.

---

## 2 · Modelo operacional

### Como o dinheiro circula
A Finza é uma **correspondente bancária multi-org**. O modelo:

1. **Clientes Finza** (correspondentes — não confundir com cliente final) são parceiros do mesmo segmento da Blips: vendem ou alugam máquinas para o mercado.
2. **Blips é o cliente Finza principal** — atua nos segmentos fitness, estética, gráficas, etc., através das máquinas IoT que telemetrizam.
3. A Finza **disponibiliza a plataforma (Finza Start)** para que esses clientes liberem crédito ao cliente final deles e aloquem máquinas. Quem aprova o crédito é o Falcon, quem valida é o Veritas, quem gera os títulos é o MF.
4. Como garantia, **o maquinário fica alienado à Finza** caso haja inadimplência — possibilitado pela tecnologia IoT (neurônio) que telemetriza o equipamento.

### O neurônio
"Neurônio" é o hardware IoT da Blips que vai instalado em cada equipamento financiado. Permite **telemetria + alienação** (a Finza pode bloquear/recuperar o equipamento remotamente se o cliente final ficar inadimplente).

**Situação atual da neuronização** (FinzaDay pp. 32-34):
- Hoje o time Blips treina técnicos da indústria para instalar neurônios nos equipamentos financiados.
- **Visão futura 2026**: neuronizar na própria indústria/China, homologando 100% dos equipamentos do parceiro. Vantagens: elimina esforço de instalação local, dependência do time de engenharia Blips, risco de danificar a placa. Habilita oferta de crédito para equipamentos já quitados e vendidos por outros meios.

---

## 3 · Fluxo do cliente — visão de ponta a ponta

| # | Etapa | Plataforma responsável | O que acontece |
|---|---|---|---|
| 1 | Originação | **Finza Start** | Representante do cliente Finza solicita crédito para um cliente final |
| 2 | Análise de crédito | **Falcon** | Motor aplica regras internas e libera/nega limite |
| 3 | Compliance + KYC | **Veritas** | Validação de documentos, biometria, antifraude |
| 4 | Aceite + CCB + Títulos | **Finza Start + Módulo Financeiro** | Assinatura + prova de vida; MF gera parcelas, boletos, recebíveis |
| 5 | Saúde do cliente | **Módulo Financeiro → Torre de Controle** | MF acompanha parcelas; inadimplência aciona a Torre (IAF) |
| 6 | Logística | **Finza Start + IoT** | Vínculo neurônio, anexa NF, despacha equipamento, cliente confirma recebimento |

A IAF atua a partir da **etapa 5**. As etapas 1-4 são vizinhanças — integramos, mas não governamos.

Detalhamento das plataformas: ver [PLATAFORMAS.md](PLATAFORMAS.md).

---

## 4 · Cedentes (importante para cobrança)

Os recebíveis Finza/Blips são antecipados para diferentes **cedentes** (instituições financeiras que compram os títulos):

- **FIDC** (Fundo de Investimento em Direitos Creditórios)
- **Blips**
- **Finza** (FIDC Finza próprio em implementação)
- **Ideal**
- **Suprimentos**

Cada cedente tem **regras próprias** de prazo, juros, contato e judicialização. Aparece constantemente nas demandas — é dimensão de filtro em qualquer régua de cobrança da Torre.

---

## 5 · Régua de comunicação

Documento operacional consolidado em `Apresentacoes/Régua de Comunicação_Atualizada.pptx`.

> **TODO:** o arquivo `.pptx` não pôde ser lido diretamente nesta iteração. A régua é a fonte autoritativa para definir quem fala com o cliente, em qual fase do atraso, com qual mensagem, em qual canal. Quando for materializada em texto (extração manual ou conversão), deve referenciar:
> - Fases: cobrança amigável (1-15 dias) → cobrança 4.0 (16-60 dias) → notificação extrajudicial (60+) → recuperação extrajudicial → judicial
> - Cada cedente tem variação
> - Canais oficiais: WhatsApp (via HyperFlow + API oficial Meta), e-mail registrado, SMS
> - Compliance de canal é estrito — bug em fluxo Esperanza pode virar passivo jurídico

---

## 6 · Organograma — TI & Produtos

### Topo
**Leonardo Caixeta** — CTO Finza (apresentação do deck atual é para ele).

### Sob DEV
- **João Vinicius (Supervisor)** — IA & Automação (Marcos, João Pedro, Leandro) + Dados (Salge, Alessandre, vagas Eng. Dados + Analista) ← **você**
- **Thiago (Supervisor)** — escopo ainda a confirmar
- **Marco (TechLead)** — MF Gestão de Cobranças (David, Valter, Matheus, Tiago) + Finza Start Portal de Negócios (Ronald, Wilianne, Murillo, Raul)
- **Girlan (TechLead)** — Motor de Crédito Falcon (Diogo, Lucas, Yago, Melqui) + Veritas KYC

### Sob Produtos
- **Herivelton** — Head Produtos
- **Bryan** — PO

### QA cross
- **Carlos** (Produtos), **Cássio** (MF / Finza Start)

### Apoio cross-squad para a IAF
- **Joao Lucas Freitas** — Tech Lead cross-squad (atende IAF, IA2, ISO). Apoio mais profundo para Torre, infra, bugs estruturais.

### Interlocução de negócio
- **Jéssica Margaritha** — líder Operações Finza (interlocutora direta da IAF para decisões de produto/régua/cenários de evaluation)
- **Bruno Garcia** — Diretor de Operações Finza
- **Eric Jun Urabayashi** — CEO Finza
- **Érica, Léo (Finza)** — citados como envolvidos no roadmap

### Curadoria Finza (autônoma após Sprint 5)
**Felipe, J, Breno** — recebem acesso à STIA e Torre 2.0 desde Sprint 0 para configurar prompts sem precisar de dev.

---

## 7 · Roadmap estratégico Finza (FinzaDay pp. 11)

| Ano | Fase | Foco |
|---|---|---|
| 2025 | **Estruturação** | Governança · Mitigação de risco · **Eficiência operacional** (Case Blips) |
| 2026 | **Novos Negócios** | Infratech (Novas Indústrias) · Seguro · Finza Cred · Tarifas · Dados · **Neuronização da Indústria** |
| 2027 | **Diversificação** | Operação SCFI · Setores alternativos ao varejo · Plataforma P2P · **Banco do Empreendedor** |
| 2028 | **Consolidação** | Ecossistema financeiro · ROE > 18% |

**Crescimento previsto** (FinzaDay pp. 13): originação saltando de R$ 80mi (2025) para R$ 507mi (2028) — +85,1%. Indústria entra forte a partir de 2026 (40mi → 200mi).

### Foco da missão 2026 (FinzaDay pp. 30)
1. **Expandir o Finza Start para novas indústrias** (em produção 15/03)
2. **Novas formas de arrecadar com eficiência e controle** — POC DESTRAVA.AI em validação
3. **Automação que elimina dependências de terceiros** — Motor de KYC proprietário (Veritas)
4. **Novos mecanismos de cobrança** — ampliação com negativação, protesto, notificações extrajudiciais ← **toca diretamente a IAF**

### Projetos futuros
- **FinzaCred** — equipamentos já quitados como garantia para empréstimos
- **FinzaProtege** (nome a definir) — Seguro Prestamista + Seguro do Equipamento

---

## 8 · O squad IA & Automação dentro disso

A IAF é o squad de **IA & Automação aplicada à área financeira** (cobrança, recuperação de crédito, formalização, relacionamento com cliente em situação financeira). É um dos três squads da grande área de IA & Automação da Blips:

- **ISO** — comercial / pré-venda (Supervisor Mateus Alberone)
- **IA2** — operação Blips, pós-venda, atendimento (Supervisor Saulo)
- **IAF** — Finza, cobrança, formalização, recuperação (Supervisor João Vinicius)

A IAF se diferencia por lidar com **cliente sob estresse financeiro** e processos com implicações jurídicas. **Compliance e precisão são tão importantes quanto velocidade.**

### Histórico recente
- Supervisor anterior: **Mateus Alberone**, repassou em **07/05/2026** o doc completo do squad (`Docs/repasse-joao-vinicius-iaf.html`)
- Roadmap atual: Mateus, aprovado pelo CTO em **28/abr/2026**, Epic Jira **IAF-130** com 37 issues
- Entrega total prevista: **10/jul/2026**
- A operação Finza cresceu **40% em carteira** entre out/25 e mar/26 — não dá pra escalar via headcount, daí o foco em IA

### Princípio orientador (vindo do roadmap herdado)
> Mudar a cultura "fazer pelo cliente" para "instruir o cliente a resolver". A IA não substitui atendimento humano — ela educa, orienta e executa o operacional repetitivo, liberando a equipe humana para casos que exigem julgamento.

---

## 9 · Vinculações úteis

- [PLATAFORMAS.md](PLATAFORMAS.md) — referência detalhada das 5 plataformas
- [BRIEFING.md](BRIEFING.md) — spec do deck para o CTO (11/05/2026)
- [repasse-joao-vinicius-iaf.html](repasse-joao-vinicius-iaf.html) — repasse Mateus → você, 07/05
- [../Apresentacoes/Boas Vinda FINZA - Tech - 2026.pdf](../Apresentacoes/Boas%20Vinda%20FINZA%20-%20Tech%20-%202026.pdf) — apresentação corporativa Finza (paleta de referência)
- [../Apresentacoes/Roadmap Agentes IA — Operações Finza.pdf](../Apresentacoes/Roadmap%20Agentes%20IA%20%E2%80%94%20Opera%C3%A7%C3%B5es%20Finza.pdf) — roadmap completo Mateus → CTO
- [../Apresentacoes/Régua de Comunicação_Atualizada.pptx](../Apresentacoes/R%C3%A9gua%20de%20Comunica%C3%A7%C3%A3o_Atualizada.pptx) — régua operacional (pendente extrair texto)
