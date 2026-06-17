# sync_quimera.ps1 — reconcilia os .md de Backlog/frentes com o estado ao vivo do Quimera.
# Fonte: dump de list_tickets (team=ia_automacao_finza) salvo na sessão.
# Faz: (A) atualiza itens concluídos/cancelados; (B) cria itens para tickets novos. Idempotente.
$ErrorActionPreference = 'Stop'
$base   = 'C:\Users\iamju\Documents\Pessoal\workspace\Trabalho\BLIPS\orquestra-tarefa'
$frentes = Join-Path $base 'Backlog\frentes'
$dump   = $args[0]
$today  = '2026-06-15'
$utf8   = New-Object System.Text.UTF8Encoding($false)

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
function Slug($t){
  $x = $t.ToLower()
  $x = $x -replace '[áàâãä]','a' -replace '[éèêë]','e' -replace '[íìîï]','i' -replace '[óòôõö]','o' -replace '[úùûü]','u' -replace 'ç','c' -replace 'ñ','n'
  $x = $x -replace '[^a-z0-9]+','-' -replace '^-+','' -replace '-+$',''
  if($x.Length -gt 60){ $x = $x.Substring(0,60) -replace '-+$','' }
  return $x
}

# ---- carregar Quimera ----
$bytes = [System.IO.File]::ReadAllBytes($dump)
$tickets = ([System.Text.Encoding]::UTF8.GetString($bytes) | ConvertFrom-Json).tickets
$q = @{}; foreach($x in $tickets){ $q[[int]$x.ticket_number] = $x }

# ---- mapear .md existentes (autoritativo: filename QMR#### + origem.quimera) ----
$md = Get-ChildItem $frentes -Filter '*.md' -Recurse | Where-Object { $_.Name -ne 'README.md' }
$mapped = @{}   # qmr -> @{path; status}
foreach($f in $md){
  $c = Get-Content $f.FullName -Raw -Encoding UTF8
  $st = if($c -match '(?m)^status:\s*(\S+)'){ $Matches[1] } else { '-' }
  $nums = @()
  if($f.Name -match '^QMR(\d+)_'){ $nums += [int]$Matches[1] }
  if($c -match '(?ms)origem:.*?quimera:\s*\[([^\]]*)\]'){ $nums += [regex]::Matches($Matches[1],'\d{3,5}') | ForEach-Object { [int]$_.Value } }
  foreach($n in ($nums | Sort-Object -Unique)){ if(-not $mapped.ContainsKey($n)){ $mapped[$n] = @{ path=$f.FullName; status=$st } } }
}

# ================= (A) UPDATES =================
$updated = @()
foreach($n in ($mapped.Keys | Sort-Object)){
  if(-not $q.ContainsKey($n)){ continue }
  $x = $q[$n]; $qs = $x.status; $bs = $mapped[$n].status
  $qDone = ($qs -eq 'finalizado' -or $qs -eq 'cancelado')
  $bDone = ($bs -eq 'entregue' -or $bs -eq 'cancelado' -or $bs -eq 'arquivado')
  if(-not ($qDone -and -not $bDone)){ continue }
  $newSt = $smap[$qs]
  $conc  = if($qs -eq 'finalizado'){ DOnly $x.resolved_at } else { $null }
  $resp  = Nm $x.assigned_to
  $p = $mapped[$n].path
  $c = Get-Content $p -Raw -Encoding UTF8
  $c = [regex]::Replace($c, '(?m)^status:\s*.*$', "status: $newSt", 1)
  $cv = if($conc){ $conc } else { 'null' }
  if($c -match '(?m)^concluida:'){ $c = [regex]::Replace($c, '(?m)^concluida:\s*.*$', "concluida: $cv", 1) }
  else { $c = [regex]::Replace($c, '(?m)^(criada:.*)$', "`$1`r`nconcluida: $cv", 1) }
  if($c -match '(?m)^responsavel:'){ $c = [regex]::Replace($c, '(?m)^responsavel:\s*.*$', "responsavel: $resp", 1) }
  $hist = "- $today — Status sincronizado do Quimera #${n}: $newSt." + $(if($conc){ " Concluída $conc." } else { "" }) + " Responsável: $resp."
  $c = $c.TrimEnd() + "`r`n$hist`r`n"
  [IO.File]::WriteAllText($p, $c, $utf8)
  $updated += "QMR$n  $bs -> $newSt  $(if($conc){$conc}else{'—'})  $resp  | $(Split-Path $p -Leaf)"
}

# ================= (B) CREATES =================
$created = @()
$missing = $q.Keys | Where-Object { -not $mapped.ContainsKey($_) } | Sort-Object
foreach($n in $missing){
  $x = $q[$n]
  if($n -eq 2649){ continue }                              # ticket de teste (DiretoriaFinza)
  if($x.team -and $x.team -ne 'ia_automacao_finza'){ continue }
  $fr = Frente $x.title $x.category
  $newSt = $smap[$x.status]; if(-not $newSt){ $newSt = 'a-refinar' }
  $prio = $pmap[$x.priority]; if(-not $prio){ $prio = 'media' }
  $conc = if($x.status -eq 'finalizado'){ DOnly $x.resolved_at } else { $null }
  $resp = Nm $x.assigned_to
  $cri  = DOnly $x.created_at
  $cat  = if($x.category){ $x.category } else { 'TI' }
  $catTag = ($cat.ToLower() -replace '[áàâã]','a' -replace 'ç','c' -replace '[^a-z0-9]','')
  $slug = Slug $x.title
  $dir  = Join-Path $frentes $fr
  $path = Join-Path $dir ("QMR{0}_{1}.md" -f $n,$slug)
  if(Test-Path $path){ continue }
  $cv = if($conc){ $conc } else { 'null' }
  $sp = if($x.story_points){ $x.story_points } else { 'null' }
  $fm = @"
---
id: QMR$n
title: $($x.title)
frente: $fr
status: $newSt
prioridade: $prio
fonte: quimera
quimera: $n
jira: null
categoria: $cat
deliverable_type: $(if($x.deliverable_type){$x.deliverable_type}else{'null'})
story_points: $sp
tipo_origem: Tarefa
responsavel: $resp
criada: $cri
concluida: $cv
prazo: null
prazo_estimado: False
rice: null
esforco: null
valor_negocio: null
owner: João Vinícius
dependencias: []
bloqueia: []
tags: [fonte-quimera, cat-$catTag]
---

# QMR$n — $($x.title)

## Descrição (espelho — fonte: quimera)

> Origem: Quimera #$n · categoria: $cat · status fonte: $($x.status) → ``$newSt``

Demanda importada do Quimera em $today (sincronização do estado ao vivo). Descrição completa no ticket Quimera #$n.

## Rastreabilidade

- **Responsável:** $resp
- **Quimera:** #$n (status fonte mapeado → ``$newSt``)
- **Categoria fonte:** $cat
- **Criada:** $cri$(if($conc){ "`r`n- **Concluída:** $conc" })

## Histórico

- $today — Item criado por sincronização do Quimera (estado ao vivo). fonte=quimera, status=$newSt.
"@
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [IO.File]::WriteAllText($path, $fm, $utf8)
  $created += "QMR$n  [$newSt]  -> $fr  | QMR${n}_$slug.md  ($resp)"
}

Write-Output ("===== UPDATES ({0}) =====" -f $updated.Count)
$updated | ForEach-Object { Write-Output $_ }
Write-Output ("`n===== CREATES ({0}) =====" -f $created.Count)
$created | ForEach-Object { Write-Output $_ }
