---
title: Alinhamento Jéssica — formalização (Clara, biometria, reembolso, raia Bitrix)
data: 2026-05-18
participantes: [Jéssica (Gerente Cobrança), João Vinícius]
duracao: 1h
tipo: alinhamento
tags: [jessica, clara, formalizacao, biometria, reembolso, bitrix, raia, operacao]
pendencias-geradas: [P25, P26, P27, P28]
---

## Pauta

Detalhar o escopo da agente Clara (formalização) — fluxos específicos de comprovantes, biometria e tratativa de reprovados — e desenhar a nova raia no Bitrix para dar visibilidade aos operadores sobre reembolsos pendentes.

## Discussão

Segunda reunião do dia com Jéssica, dedicada exclusivamente à formalização. A primeira reunião (11h) cobriu o roadmap geral e marcou esta para aprofundar Clara.

### 1. Comprovantes de endereço — Clara como solicitante

Hoje a solicitação de comprovantes é processo manual humano. Clara assume a parte de "solicitação + recebimento", mantendo o operador humano para validação:

- Clara solicita conforme a regra vigente (3 endereços: empresa, residencial, entrega; comprovantes de últimos 30 dias).
- Cliente envia.
- Clara recebe e **transfere para validação humana**.
- Humano valida e inclui na Plataforma Blips.

Princípio compartilhado: **IA é facilitadora, humano é decisor.** Clara não aprova nem rejeita comprovante — só agiliza a coleta e organiza para o humano.

### 2. Tratativa de reprovados em formalização

Fluxo atual: cliente paga entrada → entra em formalização → análise jurídica/compliance pode reprovar → cliente fica sem retorno claro + sem visibilidade do reembolso.

Fluxo proposto com Clara:
- Em caso de retorno negativo na "Análise de Formalização", Clara comunica o cliente sobre a negativa (de forma humana, não burocrática).
- Clara solicita os dados de reembolso (banco, agência, conta, PIX — titular CNPJ).
- Operador humano **executa o reembolso** (Clara não tem permissão para movimentar dinheiro).
- Clara acompanha e dá visibilidade ao cliente sobre o status.

### 3. Biometria — gatilho e acompanhamento

- Identificar o gatilho atual responsável pelo envio do link de biometria ao cliente.
- Clara executa acompanhamento se cliente não concluir biometria em 2 horas:
  - Chamada de atenção (relembrando que a biometria está pendente).
  - Orientações sobre boas práticas (formato da foto, iluminação, documento aceito).
  - Suporte para conclusão.

Não há decisão automatizada — Clara apenas reduz fricção e aumenta taxa de conversão.

### 4. Nova raia no Bitrix — visibilidade de reembolso

Problema atual: os operadores trabalham no Bitrix mas não há raia/coluna específica para "reembolso pendente de execução". Reembolsos ficam misturados em outras filas ou na cabeça do operador.

Proposta:
- Criar nova raia no Bitrix com critério de entrada: cliente reprovado em compliance + entrada paga.
- Operador humano executa o reembolso a partir dessa raia.
- Saída da raia: reembolso confirmado em conta + cliente notificado.

Operadores usam Bitrix como hub diário — adicionar a raia ali é onde a informação tem que estar para ser usada.

## Decisões

1. **Clara opera em 3 fluxos:** comprovantes, tratativa de reprovados, biometria. Cada um vira pendência separada.
2. **Princípio "IA facilitadora, humano decisor"** vale para todos os 3 fluxos — sem exceção.
3. **Raia Bitrix de reembolso** vira pendência de processo, não de código — alguém precisa configurar no Bitrix. Owner provisório: supervisor IAF, mas pode delegar.
4. **Regras operacionais** (endereço, construção civil, reembolso) ficam consolidadas na análise mestre do Roadmap como seção de referência — não viram pendências.

## Pendências geradas

- **P25** — Implementar solicitação/recebimento de comprovantes de endereço (Clara) — alta — 2026-06-15
- **P26** — Implementar tratativa de reprovados em formalização (negativa + dados reembolso) — alta — 2026-06-15
- **P27** — Implementar envio e acompanhamento de biometria pela Clara — alta — 2026-06-30
- **P28** — Criar nova raia Bitrix para visibilidade de reembolsos aos operadores — alta — 2026-06-05

## Próximos passos

- Definir owner da raia Bitrix (TI Finza ou operações da cobrança) — primeiro passo é decidir quem configura.
- Mapear o gatilho atual de envio de biometria antes de codar o acompanhamento (sem entender o gatilho, qualquer implementação fica especulativa).
- Validar com compliance que a comunicação automática de reprovação não tem fricção jurídica.

## Notas / observações

- Jéssica enfatizou que o ponto não-negociável é a **separação de responsabilidade**: IA pode coletar, organizar, comunicar e acompanhar — não pode aprovar, rejeitar ou movimentar dinheiro.
- O Bitrix Cobrança 4.0 (sistema usado pelos operadores) é também tema de automação no Roadmap geral (RM21/P34) — mas o desenho da raia de reembolso é independente da automação de histórico contínuo. São dois projetos paralelos no mesmo sistema.
- Conexão com a Reunião Diretoria 15/05: a melhoria de Valentina (originador automático) e Clara (formalização end-to-end) compõem a "jornada do cliente" que a diretoria mencionou como falta de visibilidade — fechar Clara é o primeiro grande marco visível dessa jornada.
