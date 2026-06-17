# regen_apply.ps1 — regenera backlog.html + mapa-mental.html + BACKLOG.md
# aplicando o delta do Quimera (32 updates + 27 creates) sobre o JSON atual,
# preservando integralmente os itens existentes. Fonte do delta = dump list_tickets.
$ErrorActionPreference = 'Stop'
$base  = 'C:\Users\iamju\Documents\Pessoal\workspace\Trabalho\BLIPS\orquestra-tarefa'
$bhtml = Join-Path $base 'backlog.html'
$mhtml = Join-Path $base 'mapa-mental.html'
$dump  = $args[0]
$today = '2026-06-15'
$utf8  = New-Object System.Text.UTF8Encoding($false)

$names = @{
 '34a15ef4-cfb6-4c4a-86e8-e069b068677f'='João Vinícius Dessimoni'
 'b90f482e-5852-4e8c-87c5-578d9b82b93b'='Joao Lucas Pontes Freitas'
 'f403707d-27d8-4c49-8632-28d53c3eafe3'='João Pedro da Silva Neto'
 '857575b1-6803-4d5b-b817-b521cc45c5eb'='Leandro Marques Gontijo'
 '409661f3-603f-4ab1-ae15-146076ddca0a'='Marcos Rodrigues'
}
$smap = @{ 'finalizado'='entregue';'cancelado'='cancelado';'em_andamento'='em-curso';'em_validacao'='validacao';'fila_exec'='refinado';'backlog'='a-refinar' }
$pmap = @{ 'high'='alta';'medium'='media';'low'='baixa' }
function Nm($u){ if($u -and $names.ContainsKey($u)){$names[$u]}else{'João Vinícius'} }
function DOnly($s){ if($s){ ($s -split 'T')[0] } else { $null } }
function Frente($title,$cat){
  $s = ("$title $cat").ToLower()
  if($s -match 'distrato|retirada'){ return 'livia' }
  if($s -match 'formaliza|comprovante|biometr|assinatura'){ return 'clara' }
  if($s -match 'esperanza|renegoci|prompt|fallback|adimplente|cobrando|agente de transfer'){ return 'esperanza' }
  if($s -match 'valentina'){ return 'valentina' }
  if($s -match 'torre|dashboard|relat[oó]ri|etl|kpi|org-slug|rcs|swagger|mv_titles|negativ|carteira|t[ií]tulo|blocklist'){ return 'torre' }
  if($s -match 'bitrix|hyper|n8n|gatilho|template|campanha'){ return 'bitrix-automacoes' }
  return 'sustentacao'
}

function Get-Block($html,$id){
  $rx = New-Object Text.RegularExpressions.Regex("<script[^>]*id=""$id""[^>]*>(.*?)</script>", [Text.RegularExpressions.RegexOptions]::Singleline)
  $m = $rx.Match($html); if(-not $m.Success){ throw "bloco $id nao encontrado" }; return $m.Groups[1].Value.Trim()
}
function Set-Block($html,$id,$json){
  $rx = New-Object Text.RegularExpressions.Regex("(<script[^>]*id=""$id""[^>]*>)(.*?)(</script>)", [Text.RegularExpressions.RegexOptions]::Singleline)
  $eval = [Text.RegularExpressions.MatchEvaluator]{ param($m) $m.Groups[1].Value + "`r`n" + $json + "`r`n" + $m.Groups[3].Value }
  return $rx.Replace($html, $eval, 1)
}
function To-Json($obj){ ($obj | ConvertTo-Json -Depth 40) -replace '</','<\/' }

# ---- Quimera dump ----
$tickets = ([System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($dump)) | ConvertFrom-Json).tickets
$q = @{}; foreach($x in $tickets){ $q[[int]$x.ticket_number] = $x }

# ---- carregar backlog-data ----
$bh = Get-Content $bhtml -Raw -Encoding UTF8
$bdata = Get-Block $bh 'backlog-data' | ConvertFrom-Json
$items = [System.Collections.ArrayList]@($bdata.items)

# índice por quimera number
$byQmr = @{}
foreach($it in $items){ if($it.quimera){ $byQmr[[int]$it.quimera] = $it } }

# ---- (A) PATCH dos concluídos/cancelados ----
$patched = 0
foreach($n in ($byQmr.Keys | Sort-Object)){
  if(-not $q.ContainsKey($n)){ continue }
  $qs = $q[$n].status
  if($qs -ne 'finalizado' -and $qs -ne 'cancelado'){ continue }
  $it = $byQmr[$n]
  if($it.status -eq 'entregue' -or $it.status -eq 'cancelado' -or $it.status -eq 'arquivado'){ continue }
  $it.status = $smap[$qs]
  $it.concluida = if($qs -eq 'finalizado'){ DOnly $q[$n].resolved_at } else { $null }
  $resp = Nm $q[$n].assigned_to
  $it.responsavel = $resp; $it.implementador = $resp
  $patched++
}

# ---- (B) CREATE dos novos ----
$mappedNums = @{}; foreach($it in $items){ if($it.quimera){ $mappedNums[[int]$it.quimera]=$true } }
$created = 0
foreach($n in ($q.Keys | Sort-Object)){
  if($mappedNums.ContainsKey($n)){ continue }
  if($n -eq 2649){ continue }
  $x = $q[$n]
  if($x.team -and $x.team -ne 'ia_automacao_finza'){ continue }
  $fr = Frente $x.title $x.category
  $st = $smap[$x.status]; if(-not $st){ $st='a-refinar' }
  $prio = $pmap[$x.priority]; if(-not $prio){ $prio='media' }
  $conc = if($x.status -eq 'finalizado'){ DOnly $x.resolved_at } else { $null }
  $resp = Nm $x.assigned_to
  $cat = if($x.category){ $x.category } else { 'TI' }
  $catTag = ($cat.ToLower() -replace '[áàâã]','a' -replace 'ç','c' -replace '[^a-z0-9]','')
  $obj = [pscustomobject]@{
    id="QMR$n"; frente=$fr; title=$x.title; status=$st; prioridade=$prio
    sponsor=$null; owner='João Vinícius'; implementador=$resp; deadline_alvo=$null
    criada=(DOnly $x.created_at); refinada=$null; concluida=$conc; prazo_estimado=$false
    responsavel=$resp; valor_negocio=$null; esforco=$null; rice=$null
    origem=[pscustomobject]@{ pendencias=@(); reunioes=@(); solicitacoes=@() }; roadmap_vinculado=$null
    dependencias=@(); bloqueia=@(); tags=@('fonte-quimera',"cat-$catTag")
    historia=''; contexto=("Demanda importada do Quimera #$n em $today (sincronização do estado ao vivo). Categoria: $cat.")
    criterios_aceite=@(); subtarefas=@(); premissas=@(); riscos=@(); observacoes_po=''
    historico=@([pscustomobject]@{ data=$today; texto="Criado por sincronização do Quimera (estado ao vivo). fonte=quimera, status=$st." })
    notas=''; fonte='quimera'; categoria=$cat; jira=$null; quimera=$n
  }
  [void]$items.Add($obj); $created++
}

$bdata.items = @($items)
$bdata | Add-Member generated_at $today -Force
$bdata | Add-Member refinement_pass ("Sync Quimera ($today): $patched itens marcados concluídos/cancelados (data+responsável do Quimera) e $created novas demandas importadas do estado ao vivo (team ia_automacao_finza). Base anterior: 02/06/2026.") -Force
$bh = Set-Block $bh 'backlog-data' (To-Json $bdata)
[IO.File]::WriteAllText($bhtml, $bh, $utf8)
Write-Output ("backlog.html: {0} itens (patch {1}, novos {2})" -f $bdata.items.Count, $patched, $created)

# ---- map-data (lean) ----
$mh = Get-Content $mhtml -Raw -Encoding UTF8
$mdata = Get-Block $mh 'map-data' | ConvertFrom-Json
$lean = foreach($it in $items){
  [pscustomobject]@{
    id=$it.id; frente=$it.frente; title=$it.title; status=$it.status; prioridade=$it.prioridade
    esforco=$it.esforco; valor_negocio=$it.valor_negocio; rice=$it.rice
    dependencias=@($it.dependencias); bloqueia=@($it.bloqueia); deadline=$it.deadline_alvo
    subtarefas=@(); fonte=$it.fonte; categoria=$it.categoria; tags=@($it.tags)
    criada=$it.criada; responsavel=$it.responsavel; concluida=$it.concluida; prazo_estimado=[bool]$it.prazo_estimado
  }
}
$mdata.items = @($lean)
$mdata | Add-Member generated_at $today -Force
$mh = Set-Block $mh 'map-data' (To-Json $mdata)
$mh = [regex]::Replace($mh, '<strong>\d+\s+itens</strong>\s*·\s*\d+\s+frentes\s*·\s*\d+\s+subtarefas', ("<strong>{0} itens</strong> · {1} frentes · 0 subtarefas" -f $mdata.items.Count, $mdata.frentes.Count))
[IO.File]::WriteAllText($mhtml, $mh, $utf8)
Write-Output ("mapa-mental.html: {0} itens" -f $mdata.items.Count)

# ---- BACKLOG.md ----
$all = $bdata.items
$lines = @('# BACKLOG — IAF (espelho Quimera + Jira)','', "Gerado $today. Total: **$($all.Count) itens** em $($bdata.frentes.Count) frentes. Sincronizado com o estado ao vivo do Quimera (team ia_automacao_finza).",'')
$lines += '## Por status'; $lines += ''; $lines += '| status | itens |'; $lines += '|---|---|'
$all | Group-Object status | Sort-Object Count -Descending | ForEach-Object { $lines += "| $($_.Name) | $($_.Count) |" }
$lines += ''; $lines += '## Por responsável'; $lines += ''; $lines += '| responsável | itens |'; $lines += '|---|---|'
$all | Group-Object responsavel | Sort-Object Count -Descending | ForEach-Object { $lines += "| $($_.Name) | $($_.Count) |" }
$lines += ''; $lines += '## Por fonte'; $lines += ''; $lines += '| fonte | itens |'; $lines += '|---|---|'
$all | Group-Object fonte | Sort-Object Count -Descending | ForEach-Object { $lines += "| $($_.Name) | $($_.Count) |" }
$lines += ''; $lines += '## Por frente'; $lines += ''; $lines += '| frente | itens |'; $lines += '|---|---|'
$all | Group-Object frente | Sort-Object Count -Descending | ForEach-Object { $lines += "| $($_.Name) | $($_.Count) |" }
$lines += ''; $lines += '> Fonte da verdade: arquivos .md em `Backlog/frentes/`. Matriz completa em `Backlog/_recon/matriz.md`.'
[IO.File]::WriteAllText((Join-Path $base 'Backlog\BACKLOG.md'), ($lines -join "`r`n"), $utf8)
Write-Output 'BACKLOG.md regenerado.'
