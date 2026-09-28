#requires -Version 5.1
$ErrorActionPreference = "Stop"
$root = (Get-Location).Path
$lib = Join-Path $root "lib"
if (-not (Test-Path $lib)) { throw "No encuentro la carpeta lib. Ejecuta desde C:\Users\BRANAXEL\mi_tienda" }
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $root ("BACKUP_TEXTOS_" + $stamp)
New-Item -ItemType Directory -Path $backup -Force | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)
$cp1252 = [System.Text.Encoding]::GetEncoding(1252)
$files = Get-ChildItem $lib -Recurse -File -Filter *.dart
$changed = 0
$replacements = 0
function Get-BadCount([string]$s) {
    $n = 0
    foreach ($m in @([char]0x00C3,[char]0x00C2,[char]0x00E2,[char]0x00F0,[char]0x0192,[char]0x00C5,[char]0x2122,[char]0x0178,[char]0x2018,[char]0x2019,[char]0x00A4,[char]0x0099)) {
        $n += ([regex]::Matches($s,[regex]::Escape([string]$m))).Count
    }
    return $n
}
function Try-RepairLine([string]$line) {
    $current = $line
    for ($pass=1; $pass -le 3; $pass++) {
        $before = Get-BadCount $current
        if ($before -eq 0) { break }
        try { $candidate = $utf8.GetString($cp1252.GetBytes($current)) } catch { break }
        $after = Get-BadCount $candidate
        if ($after -lt $before) { $script:replacements++; $current=$candidate } else { break }
    }
    return $current
}
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " SINTHETIX PRO - PARCHE DE TEXTOS / UTF-8" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
foreach ($file in $files) {
    $text = [IO.File]::ReadAllText($file.FullName,$utf8)
    $lines = $text -split "`r?`n",-1
    $out = New-Object System.Collections.Generic.List[string]
    $fileChanged = $false
    foreach ($line in $lines) {
        $newLine = Try-RepairLine $line
        if ($newLine -cne $line) { $fileChanged=$true }
        [void]$out.Add($newLine)
    }
    if ($fileChanged) {
        $relative=$file.FullName.Substring($lib.Length).TrimStart('')
        $dest=Join-Path $backup $relative
        New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
        Copy-Item $file.FullName $dest -Force
        [IO.File]::WriteAllText($file.FullName,($out -join [Environment]::NewLine),$utf8)
        $changed++
        Write-Host ("CORREGIDO: "+$relative) -ForegroundColor Green
    }
}
Write-Host ""
Write-Host ("Archivos corregidos: "+$changed) -ForegroundColor Green
Write-Host ("Reparaciones realizadas: "+$replacements) -ForegroundColor Green
Write-Host ("Backup: "+$backup) -ForegroundColor Cyan
Write-Host ""
Write-Host "Verificando Dart..." -ForegroundColor Yellow
$analysis=cmd.exe /c "flutter analyze 2>&1"
$analysisText=$analysis | Out-String
Write-Host $analysisText
if ($analysisText -match "(?m)^\s*error\s+-\s+") {
    Write-Host "SE DETECTARON ERRORES DART. RESTAURANDO..." -ForegroundColor Red
    Get-ChildItem $backup -Recurse -File -Filter *.dart | ForEach-Object {
        $relative=$_.FullName.Substring($backup.Length).TrimStart('')
        Copy-Item $_.FullName (Join-Path $lib $relative) -Force
    }
    Write-Host "RESTAURACION COMPLETA." -ForegroundColor Yellow
    exit 1
}
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " PARCHE TERMINADO - TEXTOS CORREGIDOS SIN TOCAR LOGICA" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
