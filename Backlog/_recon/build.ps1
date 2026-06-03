$ErrorActionPreference = 'Stop'
$base   = Join-Path $env:USERPROFILE 'Documents\Finza\Repasse'
$tr     = Join-Path $env:USERPROFILE '.claude\projects\C--Users-Jo-o-Vinicius-Documents-Finza-Repasse\f57e42ea-25c9-46c5-9bbe-fae3c433f804\tool-results'
$recon  = Join-Path $base 'Backlog\_recon'
$frentesDir = Join-Path $base 'Backlog\frentes'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Strip([string]$s){
  if(-not $s){return ""}
  $s=$s.Normalize([Text.NormalizationForm]::FormD)
  $sb=New-Object Text.StringBuilder
  foreach($c in $s.ToCharArray()){ if([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark){[void]$sb.Append($c)} }
  return $sb.ToString()
}
function Slug([string]$t){
  $s = [regex]::Replace($t,'\[[^\]]*\]',' ')
  $s = (Strip $s).ToLowerInvariant()
  $s = [regex]::Replace($s,'[^a-z0-9]+','-')
  $s = $s.Trim('-')
  if($s.Length -gt 60){ $s=$s.Substring(0,60).Trim('-') }
  if(-not $s){ $s='item' }
  return $s
}
function MapQuimera([string]$s){
  switch($s){
    'backlog'{'a-refinar'} 'fila_exec'{'refinado'} 'em_andamento'{'em-curso'}
    'em_validacao'{'validacao'} 'bloqueado'{'bloqueado'} 'finalizado'{'entregue'}
    'cancelado'{'cancelado'} default{'a-refinar'}
  }
}
function MapJira([string]$name){
  $n=(Strip $name).ToUpperInvariant()
  if($n -match 'CONCLU'){'entregue'} elseif($n -match 'CANCEL'){'cancelado'}
  elseif($n -match 'VALIDA'){'validacao'} elseif($n -match 'BLOQUE'){'bloqueado'}
  elseif($n -match 'ANDAMENTO|DESENVOLV'){'em-curso'} elseif($n -match 'PRIORIZ'){'refinado'}
  else{'a-refinar'}
}
function MapPrio([string]$p){
  if(-not $p){return 'media'}
  $n=$p.ToLowerInvariant()
  if($n -match 'high|alt|highest'){'alta'} elseif($n -match 'low|baix'){'baixa'} else{'media'}
}
function Frente([string]$text){
  $t=(Strip $text).ToLowerInvariant()
  if($t -match 'esperanza|renegocia|hsm|protocolo ativo'){return 'esperanza'}
  if($t -match 'distrato|retirada|negativ|juridic'){return 'livia'}
  if($t -match 'formaliza|clara|comprovante|biometria|veritas|francisco|maryam'){return 'clara'}
  if($t -match 'valentina|saque'){return 'valentina'}
  if($t -match 'torre|dashboard|multi-org|multi org|supabase|backend|regua|régua|disparo| etl |rhino|negocia'){return 'torre'}
  if($t -match 'bitrix|hyper|hyperflow|gatilho|n8n|sankhya|shankya|automac|email|campanha'){return 'bitrix-automacoes'}
  if($t -match 'narrativa| nps |roadmap|spec|processo|kanban|repasse|documenta'){return 'estrategica'}
  return 'sustentacao'
}
# UUID Quimera -> nome (time ia_automacao_finza, via list_users)
$USERS = @{
  'b90f482e-5852-4e8c-87c5-578d9b82b93b'='Joao Lucas Pontes Freitas'
  'f403707d-27d8-4c49-8632-28d53c3eafe3'='João Pedro da Silva Neto'
  '34a15ef4-cfb6-4c4a-86e8-e069b068677f'='João Vinicius Dessimoni'
  '857575b1-6803-4d5b-b817-b521cc45c5eb'='Leandro Marques Gontijo'
  '409661f3-603f-4ab1-ae15-146076ddca0a'='Marcos Rodrigues'
}
function UserName($uuid){ if($uuid -and $USERS.ContainsKey([string]$uuid)){ $USERS[[string]$uuid] } else { '—' } }
function FmtDate($d){ if($d){ try{ ([datetime]$d).ToString('yyyy-MM-dd') }catch{ [string]$d } } else { $null } }
function IsClosed([string]$st){ $st -eq 'entregue' -or $st -eq 'cancelado' }
function EstDeadline([string]$status,$sp){
  $ref=[datetime]'2026-06-02'
  if($status -eq 'validacao'){ return $ref.AddDays(7).ToString('yyyy-MM-dd') }
  if($status -eq 'em-curso'){
    $h = if($sp){ [math]::Max(10,[math]::Min(45,([int]$sp)*3)) } else { 21 }
    return $ref.AddDays($h).ToString('yyyy-MM-dd')
  }
  return $null
}
# unifica variantes de nome (Quimera vs Jira displayName) num responsavel canonico
function Canon([string]$name){
  if(-not $name -or $name -eq '—'){ return '—' }
  $n=(Strip $name).ToLowerInvariant()
  if($n -match 'freitas|joao lucas'){ return 'João Lucas Freitas' }
  if($n -match 'dessimoni'){ return 'João Vinícius Dessimoni' }
  if($n -match 'joao pedro'){ return 'João Pedro' }
  if($n -match 'leandro'){ return 'Leandro Marques' }
  if($n -match 'marcos rodrigues|marcos .*oliveira'){ return 'Marcos Rodrigues' }
  if($n -match 'mateus'){ return 'Mateus Mesquita' }
  if($n -match 'vinicius cunha'){ return 'Vinícius Cunha' }
  return $name
}

# ---------- carregar fontes ----------
# Jira nodes (todas as paginas)
$JN = @{}
Get-ChildItem $tr -Filter 'mcp-claude_ai_Atlassian-searchJiraIssuesUsingJql-*.txt' | ForEach-Object {
  try { $jj = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { return }
  if(-not $jj.issues.nodes){ return }
  foreach($n in $jj.issues.nodes){
    if($n.key -notlike 'IAF-*'){ continue }
    if($JN.ContainsKey($n.key)){ continue }
    $JN[$n.key] = [pscustomobject]@{
      key=$n.key; summary=$n.fields.summary; desc=$n.fields.description
      statusName=$n.fields.status.name; type=$n.fields.issuetype.name
      parent=$(if($n.fields.parent){$n.fields.parent.key}else{$null})
      prio=$(if($n.fields.priority){$n.fields.priority.name}else{$null})
      created=$(if($n.fields.created){([datetime]$n.fields.created).ToString('yyyy-MM-dd')}else{$null})
      assignee=$(if($n.fields.assignee){$n.fields.assignee.displayName}else{$null})
      resolved=$(if($n.fields.resolutiondate){([datetime]$n.fields.resolutiondate).ToString('yyyy-MM-dd')}else{$null})
    }
  }
}
# Quimera list (status/category/assignee/datas por num)
$qf = Get-ChildItem $tr -Filter 'mcp-quimera-list_tickets-*.txt' | Sort-Object LastWriteTime -Desc | Select-Object -First 1
$QL = @{}
(Get-Content $qf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json).tickets | ForEach-Object { $QL[[int]$_.ticket_number]=$_ }
# qjMatches
$ds = Get-Content (Join-Path $recon 'dataset.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$qj = $ds.qjMatches
$matchedJira = $qj.jira | Select-Object -Unique
# quimera-only data
. (Join-Path $recon 'quimera_only_data.ps1')

# ---------- montar demands ----------
$demands = @()
# 1) quimera+jira  (verdade = Quimera para status/responsavel/conclusao; criada = Jira original)
foreach($m in $qj){
  $n = $JN[$m.jira]; if(-not $n){ continue }
  $qnum = [int]([regex]::Replace([string]$m.quimera,'\D',''))
  $qt = $QL[$qnum]
  $qstatus = if($qt){ $qt.status } else { 'backlog' }
  $st = (MapQuimera $qstatus)
  $sp = if($qt){ $qt.story_points } else { $null }
  $resp = UserName $(if($qt){ $qt.assigned_to } else { $null })
  $concl = if((IsClosed $st) -and $qt){ FmtDate $qt.resolved_at } else { $null }
  $demands += [pscustomobject]@{
    id=("QMR{0}" -f $qnum); jira=$m.jira; quimera=$qnum; fonte='quimera+jira'
    title=$n.summary; desc=$n.desc; status=$st; prio=(MapPrio $n.prio)
    categoria=$(if($qt){$qt.category}else{$null}); deliverable=$(if($qt){$qt.deliverable_type}else{$null})
    sp=$sp; criada=$n.created; concluida=$concl; responsavel=$resp
    deadline=(EstDeadline $st $sp); prazo_estimado=$false
    type=$n.type; parent=$n.parent; tags=@(); dependencias=@(); bloqueia=@()
  }
}
# 2) jira-only
foreach($k in $JN.Keys){
  if($matchedJira -contains $k){ continue }
  $n=$JN[$k]
  $st=(MapJira $n.statusName)
  $concl = if(IsClosed $st){ $n.resolved } else { $null }
  $demands += [pscustomobject]@{
    id=$k; jira=$k; quimera=$null; fonte='jira'
    title=$n.summary; desc=$n.desc; status=$st; prio=(MapPrio $n.prio)
    categoria=$null; deliverable=$null; sp=$null; criada=$n.created; concluida=$concl
    responsavel=$(if($n.assignee){$n.assignee}else{'—'})
    deadline=(EstDeadline $st $null); prazo_estimado=$false
    type=$n.type; parent=$n.parent; tags=@(); dependencias=@(); bloqueia=@()
  }
}
# 3) quimera-only
foreach($q in $QuimeraOnly){
  $fonte = if($q.jira){'quimera+jira'}else{'quimera'}
  $st=(MapQuimera $q.status)
  $qt=$QL[[int]$q.num]
  $resp = UserName $(if($qt){ $qt.assigned_to } else { $null })
  $concl = if(IsClosed $st){ FmtDate $q.resolved } else { $null }
  $demands += [pscustomobject]@{
    id=("QMR{0}" -f $q.num); jira=$q.jira; quimera=[int]$q.num; fonte=$fonte
    title=$q.title; desc=$q.desc; status=$st; prio='media'
    categoria=$q.category; deliverable=$q.deliverable; sp=$q.sp; criada=$q.created; concluida=$concl
    responsavel=$resp; deadline=(EstDeadline $st $q.sp); prazo_estimado=$false
    type='ticket'; parent=$null; tags=$q.tags; dependencias=@(); bloqueia=@()
  }
}
# marcar prazo_estimado para em-curso/validacao (deadline derivado)
foreach($d in $demands){ if($d.deadline -and ($d.status -eq 'em-curso' -or $d.status -eq 'validacao')){ $d.prazo_estimado=$true } }
foreach($d in $demands){ $d.responsavel = (Canon $d.responsavel) }

# ---------- frente + vinculo subtarefa->pai ----------
$byId = @{}; foreach($d in $demands){ $d | Add-Member -NotePropertyName frente -NotePropertyValue (Frente "$($d.title) $($d.categoria)") -Force; $byId[$d.id]=$d }
$jiraToId = @{}; foreach($d in $demands){ if($d.jira){ $jiraToId[$d.jira]=$d.id } }
$linked=0
foreach($d in $demands){
  if($d.type -eq 'Subtarefa' -and $d.parent -and $jiraToId.ContainsKey($d.parent)){
    $parId=$jiraToId[$d.parent]; if($parId -eq $d.id){continue}
    $d.bloqueia=@($parId)
    $p=$byId[$parId]; $p.dependencias=@($p.dependencias + $d.id | Select-Object -Unique)
    $d.frente=$p.frente  # filho herda frente do pai (cluster coeso)
    $linked++
  }
}

# ---------- escrever .md ----------
New-Item -ItemType Directory -Force (Join-Path $frentesDir 'sustentacao') | Out-Null
$proj=@()
foreach($d in $demands){
  $dir = Join-Path $frentesDir $d.frente
  New-Item -ItemType Directory -Force $dir | Out-Null
  $slug = Slug $d.title
  $path = Join-Path $dir ("{0}_{1}.md" -f $d.id, $slug)
  $tagList = @("fonte-$($d.fonte -replace '\+','-')")
  if($d.categoria){ $tagList += ("cat-" + ((Strip $d.categoria).ToLowerInvariant() -replace '[^a-z0-9]+','-')) }
  if($d.tags){ $tagList += ($d.tags | ForEach-Object { (Strip $_).ToLowerInvariant() -replace '[^a-z0-9]+','-' }) }
  $tagList = $tagList | Where-Object { $_ } | Select-Object -Unique
  $depStr = if($d.dependencias.Count){ '[' + ($d.dependencias -join ', ') + ']' } else { '[]' }
  $blkStr = if($d.bloqueia.Count){ '[' + ($d.bloqueia -join ', ') + ']' } else { '[]' }
  $qStr = if($d.quimera){ "$($d.quimera)" } else { 'null' }
  $jStr = if($d.jira){ $d.jira } else { 'null' }
  $catStr = if($d.criada){ $d.criada } else { 'null' }
  $conclStr = if($d.concluida){ $d.concluida } else { 'null' }
  $prazoStr = if($d.deadline){ $d.deadline } else { 'null' }
  $respStr = if($d.responsavel){ $d.responsavel } else { '—' }
  $spStr = if($d.sp){ "$($d.sp)" } else { 'null' }
  $delStr = if($d.deliverable){ $d.deliverable } else { 'null' }
  $catg = if($d.categoria){ $d.categoria } else { 'null' }

  $fm = @()
  $fm += '---'
  $fm += "id: $($d.id)"
  $fm += "title: $($d.title -replace '\r?\n',' ')"
  $fm += "frente: $($d.frente)"
  $fm += "status: $($d.status)"
  $fm += "prioridade: $($d.prio)"
  $fm += "fonte: $($d.fonte)"
  $fm += "quimera: $qStr"
  $fm += "jira: $jStr"
  $fm += "categoria: $catg"
  $fm += "deliverable_type: $delStr"
  $fm += "story_points: $spStr"
  $fm += "tipo_origem: $($d.type)"
  $fm += "responsavel: $respStr"
  $fm += "criada: $catStr"
  $fm += "concluida: $conclStr"
  $fm += "prazo: $prazoStr"
  $fm += "prazo_estimado: $([bool]$d.prazo_estimado)"
  $fm += "rice: null"
  $fm += "esforco: null"
  $fm += "valor_negocio: null"
  $fm += "owner: João Vinícius"
  $fm += "dependencias: $depStr"
  $fm += "bloqueia: $blkStr"
  $fm += "tags: [" + ($tagList -join ', ') + "]"
  $fm += '---'
  $fm += ''
  $fm += "# $($d.id) — $($d.title)"
  $fm += ''
  $fm += "## Descrição (espelho — fonte: $($d.fonte))"
  $fm += ''
  $origem = @(); if($d.quimera){$origem+="Quimera #$($d.quimera)"}; if($d.jira){$origem+="Jira $($d.jira)"}
  $fm += "> Origem: " + ($origem -join ' · ') + " · categoria: $catg"
  $fm += ''
  $body = if($d.desc -is [string]){ $d.desc } elseif($d.desc){ [string]($d.desc | ConvertTo-Json -Depth 30 -Compress) } else { '' }
  $body = if($body.Trim()){ $body.TrimEnd() } else { '(sem descrição na fonte)' }
  $fm += $body
  $fm += ''
  $fm += "## Rastreabilidade"
  $fm += ''
  $fm += "- **Responsável:** $respStr"
  if($d.quimera){ $fm += "- **Quimera:** #$($d.quimera) (status fonte mapeado → ``$($d.status)``)" }
  if($d.jira){ $fm += "- **Jira:** $($d.jira) (projeto IAF)" }
  $fm += "- **Categoria fonte:** $catg"
  if($d.criada){ $fm += "- **Criada:** $($d.criada)" }
  if($d.concluida){ $fm += "- **Concluída:** $($d.concluida)" }
  if($d.deadline){ $fm += "- **Prazo$(if($d.prazo_estimado){' (estimado)'}):** $($d.deadline)" }
  if($d.bloqueia.Count){ $fm += "- **Subtarefa de** (bloqueia): $($d.bloqueia -join ', ') — convertida de subtarefa Jira $($d.parent)" }
  if($d.dependencias.Count){ $fm += "- **Subtarefas vinculadas** (depende de): $($d.dependencias -join ', ')" }
  $fm += ''
  $fm += "## Histórico"
  $fm += ''
  $fm += "- 2026-06-02 — Item importado por espelhamento Quimera/Jira (reconciliação de backlog). fonte=$($d.fonte)."

  [IO.File]::WriteAllText($path, ($fm -join "`r`n"), $utf8)

  $proj += [pscustomobject]@{
    id=$d.id; frente=$d.frente; title=$d.title; status=$d.status; prioridade=$d.prio
    esforco=$null; valor_negocio=$null; rice=$null
    dependencias=@($d.dependencias); bloqueia=@($d.bloqueia)
    deadline=$(if($d.deadline){$d.deadline}else{$null}); prazo_estimado=[bool]$d.prazo_estimado
    responsavel=$(if($d.responsavel){$d.responsavel}else{'—'})
    criada=$(if($d.criada){$d.criada}else{$null}); concluida=$(if($d.concluida){$d.concluida}else{$null})
    fonte=$d.fonte; categoria=$catg; jira=$jStr; quimera=$(if($d.quimera){$d.quimera}else{$null})
    tipo_origem=$d.type; descricao=$body; tags=@($tagList)
  }
}

# imported_items.json
($proj | ConvertTo-Json -Depth 6) | Out-File (Join-Path $recon 'imported_items.json') -Encoding utf8

# matriz.md
$mz = @('# Matriz de reconciliação — Jira · Quimera · Backlog','', "Gerado 2026-06-02. Total importados: $($demands.Count).",'', '| ID | Título | Jira | Quimera | fonte | frente | status | responsável | criada | concluída | prazo |','|---|---|---|---|---|---|---|---|---|---|---|')
foreach($d in ($demands | Sort-Object fonte, id)){
  $t = $d.title -replace '\|','/' ; if($t.Length -gt 50){$t=$t.Substring(0,50)}
  $pz = if($d.deadline){ $d.deadline + $(if($d.prazo_estimado){' (est)'}) } else {'—'}
  $mz += "| $($d.id) | $t | $(if($d.jira){$d.jira}else{'—'}) | $(if($d.quimera){'#'+$d.quimera}else{'—'}) | $($d.fonte) | $($d.frente) | $($d.status) | $($d.responsavel) | $(if($d.criada){$d.criada}else{'—'}) | $(if($d.concluida){$d.concluida}else{'—'}) | $pz |"
}
$mz -join "`r`n" | Out-File (Join-Path $recon 'matriz.md') -Encoding utf8

# resumo
Write-Output ("Demands geradas: {0}" -f $demands.Count)
Write-Output ("  responsavel preenchido: {0}" -f ($demands|?{$_.responsavel -and $_.responsavel -ne '—'}).Count)
Write-Output ("  com concluida: {0}" -f ($demands|?{$_.concluida}).Count)
Write-Output ("  com prazo estimado (em-curso/validacao): {0}" -f ($demands|?{$_.prazo_estimado}).Count)
Write-Output ("  subtarefas vinculadas: {0}" -f $linked)
Write-Output "`n--- responsavel ---"
$demands | Group-Object responsavel | Sort-Object Count -Desc | ForEach-Object { "  {0,-30} {1}" -f $_.Name,$_.Count }
Write-Output "`n[ok] build concluido."