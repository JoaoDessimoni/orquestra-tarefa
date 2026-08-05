# RCS — Resumo Executivo

> Uma página para diretoria. O que está no ar, o que ganhamos, do que dependemos e o que precisa de decisão.
> Data-base: 28 de julho de 2026 · Detalhe técnico: [rcs.md](./rcs.md)

---

## Em uma frase

RCS é a evolução do SMS: mensagem com imagem, título, texto formatado e botões, entregue no app de mensagens que já vem no celular Android, em nome de uma marca identificada. **Está em produção na Torre de Controle.**

---

## O que ganhamos

| | O que muda |
|---|---|
| **Alcance sem app** | Chega ao aparelho sem o cliente instalar nada — diferente do WhatsApp |
| **Mensagem com apresentação** | Imagem, título e botão de pagamento nativo, em vez de link solto num SMS |
| **Autonomia da operação** | O template é criado e publicado na própria Torre. Sem fila de aprovação externa, ao contrário do WhatsApp/Meta |
| **Intenção do cliente estruturada** | Botões de resposta rápida sinalizam o que o cliente quer (pagar, enviar comprovante, falar com atendente) em vez de texto livre a interpretar |

Do template ao disparo, a operação é autônoma. Time técnico entra só na porta de entrada: credenciais da integração, habilitação do canal numa organização nova e o fluxo do parceiro.

---

## Como se encaixa

**RCS não é um sistema novo — é um canal a mais dentro do motor que já roda.**

Segmentação da carteira, decisão título a título, bloqueio de cobrança, anti-duplicidade, janela de envio, feriados, limite por minuto, checagem de pagamento antes de enviar, tentativas, custo e status: tudo isso já existia e o RCS entrou usando. O que foi construído de fato foi a tela de template rico, o armazenamento de imagem e a tradução do conteúdo no momento do envio.

Consequência: **um único ponto de saída para todos os canais.** Menos superfície de erro, um lugar só para auditar.

A entrega foi incremental e rápida: canal no ar em **23 de junho**, carrossel completo em **22 de julho** — quatro semanas.

---

## Do que dependemos de terceiro

A Torre entrega o conteúdo pronto a um orquestrador externo (n8n/Hyperflow), que monta a mensagem e fala com a plataforma RCS e a operadora. **A Torre não fala com a operadora nem com o Google.**

| Camada | Quem responde |
|---|---|
| Template, imagem, variáveis, régua, segmentação, decisão de envio, status | **Nós** |
| Transporte e montagem final da mensagem | **Terceiro** (orquestrador) |
| Entrega ao aparelho e regras da plataforma | **Terceiro** (provedor + operadora) |
| Cadastro e verificação do agente — a marca no RCS | **Fora da Torre** |

Isso é dependência de terceiro em dois pontos do caminho e precisa entrar na conta de risco.

---

## Limitações que a diretoria precisa conhecer

- **"Enviado" não é "recebido".** Enviado significa que o orquestrador aceitou o disparo. A confirmação de entrega/leitura só aparece se o parceiro devolver o aviso.
- **Não há troca automática de canal.** Se o aparelho não suportar RCS, não há queda automática para SMS ou WhatsApp — a cobertura depende de a régua ter um passo alternativo.
- **Mensagem só com imagem não é rastreável.** Sem texto, não conseguimos detectar falha de entrega. A tela avisa, mas não bloqueia.
- **Template não tem versão nem histórico.** Editar sobrescreve, e a mudança não propaga sozinha para réguas já configuradas: é preciso reabrir o passo.
- **Imagens ficam em endereço público.** Quem tem o link vê a imagem — dado pessoal nunca deve ir na arte do card.
- **Dado pessoal do envio fica gravado sem mascaramento**, e não há prazo de retenção definido para esses registros.
- **Não conhecemos os limites da plataforma.** Quota diária, tamanho máximo real e regras de conteúdo do provedor não estão validados pelo sistema.

---

## O que ainda não sabemos

**Não existe métrica consolidada do canal.** Não há painel, indicador nem análise que compare RCS com WhatsApp e SMS em taxa de entrega, conversão ou custo real. A estimativa de custo usa o valor unitário que a organização cadastra — decisão comercial, não medição.

Ou seja: sabemos que o canal funciona e é operável. **Não sabemos ainda se ele paga.**

---

## Decisões pendentes

1. **Medição do canal.** Definir e instrumentar os indicadores de RCS (entrega, resposta, conversão, custo por real recuperado) para comparar com os canais atuais. Sem isso, a expansão do uso é aposta.
2. **Responsabilidade pelo agente RCS.** Definir quem provisiona e mantém a marca verificada junto ao provedor, e quem responde por incidente na ponta do parceiro.
3. **Quota e limites contratados.** Confirmar o volume contratado com o provedor e quem monitora.
4. **Política de dado pessoal.** Definir mascaramento no registro do envio e prazo de retenção dos dados e das imagens.

<!-- TODO: confirmar com gestor — provedor/agregador RBM por trás do Hyperflow, processo de verificação da marca, quota contratada, e comportamento do fluxo externo em cada categoria de botão -->

---

*Todo o conteúdo acima foi verificado contra o código em produção. Melhorias em branch de release não entram aqui — ver `rcs.md`.*
