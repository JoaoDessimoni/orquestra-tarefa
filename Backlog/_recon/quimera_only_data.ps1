# Dados dos tickets quimera-only (descrição verbatim via get_ticket). Dot-sourced por build.ps1.
# QMR2649 "teste - Cancelar Finza" intencionalmente omitido (lixo de teste).
$QuimeraOnly = @(
  # QMR3421 removido daqui: ja consta em qjMatches (matched IAF-184) como quimera+jira.
  [pscustomobject]@{ num=3457; title='Envio de Email Hyper'; status='fila_exec'; category='Cobrança'; deliverable='Liberação de acessos'; sp=3; created='2026-05-21'; resolved=$null; tags=@('cobrança','hyperflow'); jira=$null; desc=@'
Foi solicitado pela Jéssica que fosse posto os envios de emails dentro do hyper de forma que ela consiga acompanhar e responder os retornos dos emails. Atualmente é feito via n8n pois anteriormente tentaram colocar o envio dentro do hyper mas foi frustrante a experiencia com o hyper e houveram alguns bloqueios nos emails. Segue descrição do card no bitrix:

"Por gentileza, vincular as contas de e-mail boletos@blips.com.br ; boletos@ideal.com.br e boletos@finza.com.br na plataforma Hyperflow e os colaboradores citados abaixo para visualizar os protocolos gerados.

A ideia é tratarmos os retornos que recebemos via e-mail, diretamente pela plataforma Omnichannel, oferecendo atendimento personalizado por mais esse canal.

Importante:  Os e-mails de retorno de erro, com o título "Delivery Status Notification (Delay)" e remetente "mailer-daemon@googlemail.com" devem ser finalizados automaticamente, pois não teremos nenhuma ação para realizar. "
'@ }
  [pscustomobject]@{ num=3467; title='Importar dados títulos futuros por contrato'; status='finalizado'; category='TI'; deliverable='Query'; sp=2; created='2026-05-21'; resolved='2026-05-28'; tags=@(); jira=$null; desc=@'
Trazer dados de quantas parcelas ainda existem para o fim do contrato, vencidas e a cencer para o cliente poder saber sobre as percelas futuras.
'@ }
  [pscustomobject]@{ num=3529; title='Analise de incidente'; status='cancelado'; category='Cobrança'; deliverable='Outros'; sp=$null; created='2026-05-25'; resolved=$null; tags=@('incidente'); jira=$null; desc=@'
problema x n sei onde
'@ }
  [pscustomobject]@{ num=3531; title='INCIDENTE - NEGATIVAÇÃO TORRE'; status='finalizado'; category='Cobrança'; deliverable='Aplicação/Sistema'; sp=3; created='2026-05-25'; resolved='2026-05-29'; tags=@('incidente'); jira=$null; desc=@'
J falou que as negativações da torre não estão funcionando.
'@ }
  [pscustomobject]@{ num=3555; title='Investigação de hsm enviado no meio de protocolo ativo'; status='finalizado'; category='IA'; deliverable='Informação'; sp=1; created='2026-05-26'; resolved='2026-05-26'; tags=@('incidente'); jira=$null; desc=@'
No meio de um atendimento de instalação, um HSM foi enviado

Segue o protocolo: 2205269322920
'@ }
  [pscustomobject]@{ num=3567; title='Documentação Esperanza'; status='em_validacao'; category='TI'; deliverable='Informação'; sp=2; created='2026-05-27'; resolved=$null; tags=@(); jira=$null; desc=@'
Documentação pedida pelo Dessimoni da Esperanza.

Da onde veio, onde estamos e para onde vamos
Principais fluxos (trabalho)
Pessoas Chaves
Principais problemas/incidentes
Pendencias
'@ }
  [pscustomobject]@{ num=3623; title='Novo numero cobrança Blips'; status='finalizado'; category='Cobrança'; deliverable='Agente de IA'; sp=1; created='2026-05-29'; resolved='2026-06-01'; tags=@(); jira=$null; desc=@'
Conforme alinhado, preciso que o novo numero da blips de cobrança (em anexo) seja posto na estrutura da torre e hyper com a esperanza, lembrando que é um teste por enquanto, então o time de cobrança deve ser capaz de configurar esse canal na torre como bem entender. A IA que vai recepcionar nesse numero será a Esperanza
'@ }
  [pscustomobject]@{ num=3624; title='Fluxo Distrato'; status='em_andamento'; category='Recuperação'; deliverable='Informação'; sp=3; created='2026-05-29'; resolved=$null; tags=@(); jira=$null; desc=@'
Preciso que seja desenhado no miro todo o fluxo de distrato que temos conhecimento do nosso lado hoje. Eu quero um fluxo bem detalhado que me monstre:

- origem dos dados
- operadores envolvidos no processo
- ferramentas
- canais
- cenários de distrato
'@ }
  [pscustomobject]@{ num=3625; title='Análise Torre'; status='em_andamento'; category='TI'; deliverable='Informação'; sp=8; created='2026-05-29'; resolved=$null; tags=@(); jira=$null; desc=@'
Eu preciso que seja feita uma análise minuciosa de todos os relatórios e dashs que temos na torre e seja elaborado um diagnóstico e uma apresentação para o negócio para eles nos ajudarem a entender oque é necessário e inútil ou errado. Eu quero ter uma visão de:

- origens dos dados
- formulas e calculos
- consistência dos dados
- todos os relatorios e dash existentes
- consultas utilizadas
- endpoints que trazem as informações
- tabelas de onde os dados estão sendo retirados
- apresentação para o negócio pois nem mesmo eles sabem oque tem na torre e veracidade dos dados exibidos.
'@ }
  [pscustomobject]@{ num=3659; title='Curadoria Valentina'; status='fila_exec'; category='Cobrança'; deliverable='Informação'; sp=1; created='2026-06-01'; resolved=$null; tags=@('valentina'); jira=$null; desc=@'
Boa tarde Senhores(as),

João Neto. Segue formalização da demanda no qual o objetivo é ter a capacidade de fazer curadoria da Valentina assim como é possível atualmente pela Esperanza.

Grato J
'@ }
  [pscustomobject]@{ num=3664; title='Documentação de Repasse'; status='em_andamento'; category='TI'; deliverable='Informação'; sp=8; created='2026-06-01'; resolved=$null; tags=@(); jira=$null; desc=@'
Como o João Lucas esta de saída eu quero que ele documente tudo que pode até sua saída para ser utilizado de contexto posteriormente, todas as documentações devem ser anexadas no Confluence. Eu quero documentação das seguintes frentes:

Automações / Aplicações:

1 - Da onde veio, onde estamos e para onde vamos.
2 - Principais fluxos (trabalho - Urls, n8n, Hyperflow,  relacionamentos entre fluxos).
3 - Pessoas Chaves de cada frente
4 - Principais problemas/incidentes de cada frente
5 - Pendencias de cada frente
6 - Agentes relacionados a cada automação
7 - Git

Agentes:

1 - Da onde veio, onde estamos e para onde vamos.
2 - Principais fluxos (trabalho - Urls, n8n, Hyperflow, relacionamentos entre fluxos).
3 - Pessoas Chaves de cada frente
4 - Principais problemas/incidentes de cada frente
5 - Pendencias de cada frente

  - Esperanza
  - Torre de Controle
  - Valentina
  - Livia
  - Automações chave e Bitrix
  - Clara
  - Prudente
  - Francisco

Suporte(Grupos - Google e Whats):

 - Como é a atuação em cada grupo, como atua, objetivo do grupo, o que é cada alerta, como e onde resolve . (Supervisão IA - Socorro, Alertas de erros gerais, Ia & Automação, etc. )

Documentar acessos:

 - Plataformas, ferramentas, bancos, hyperflow, n8n, Bq, etc...
 - Quais Aplicações utilizam cada um deles.
'@ }
  [pscustomobject]@{ num=3690; title='Fallback ação pontual torre'; status='em_andamento'; category='Cobrança'; deliverable='Aplicação/Sistema'; sp=3; created='2026-06-02'; resolved=$null; tags=@(); jira=$null; desc=@'
Liberar todas as campanhas pontuais do fallback que impede enviar a campanha aos fins de semana, as campanhas devem poder ser disparadas quando o usuario quiser.
'@ }
  [pscustomobject]@{ num=3691; title='Recriar Supabase PROD'; status='em_andamento'; category='Cobrança'; deliverable='Aplicação/Sistema'; sp=3; created='2026-06-02'; resolved=$null; tags=@(); jira=$null; desc=@'
Devido a grande mudança de migrations da demanda mult-org da torre, é necessário uma réplica exata de produção no supabase para garantirmos que todas as migrations irão executar
'@ }
  [pscustomobject]@{ num=3692; title='Card duplicado no Bitrix'; status='finalizado'; category='TI'; deliverable='Automação'; sp=1; created='2026-06-02'; resolved='2026-06-02'; tags=@(); jira=$null; desc=@'
No Bitrix estava ocorrendo duplicidade de Cards funil de formalização.
'@ }
)
