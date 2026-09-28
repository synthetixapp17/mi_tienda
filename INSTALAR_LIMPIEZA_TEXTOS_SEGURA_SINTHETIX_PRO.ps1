$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
$lib = Join-Path $root 'lib'
if (-not (Test-Path $lib)) { throw 'No existe la carpeta lib.' }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $root ("backup_textos_$stamp")
New-Item -ItemType Directory -Path $backupDir | Out-Null

$files = Get-ChildItem $lib -Recurse -Filter *.dart | Where-Object {
    $_.Name -notmatch '(?i)_backup|_roto|\.tmp|\.bak' -and $_.FullName -notmatch '(?i)[\\/]backup[\\/]'
}

$markers = @(
    [char]0x00C3, [char]0x00C2, [char]0x00E2, [char]0x00F0,
    [char]0xFFFD, [char]0x0192, [char]0x201A, [char]0x2018, [char]0x2019
)

function BadCount([string]$s) {
    $n = 0
    foreach ($m in $markers) { $n += ([regex]::Matches($s, [regex]::Escape([string]$m))).Count }
    return $n
}

$latin1 = [Text.Encoding]::GetEncoding(28591)
$utf8 = New-Object Text.UTF8Encoding($false, $true)
$changed = @()

foreach ($f in $files) {
    $raw = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
    $current = $raw
    $beforeScore = BadCount $current
    if ($beforeScore -eq 0) { continue }

    for ($i = 0; $i -lt 4; $i++) {
        try {
            $bytes = $latin1.GetBytes($current)
            $candidate = $utf8.GetString($bytes)
        } catch { break }
        if ($candidate -eq $current) { break }
        $oldScore = BadCount $current
        $newScore = BadCount $candidate
        if ($newScore -lt $oldScore) { $current = $candidate } else { break }
    }

    if ($current -ne $raw) {
        $dest = Join-Path $backupDir ($f.FullName.Substring($lib.Length).TrimStart('\/'))
        New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
        [IO.File]::Copy($f.FullName, $dest, $true)
        [IO.File]::WriteAllText($f.FullName, $current, $utf8)
        $changed += $f.FullName
    }
}

$remaining = @()
foreach ($f in $files) {
    $s = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
    $score = BadCount $s
    if ($score -gt 0) { $remaining += "$($f.FullName): $score posibles marcadores" }
}

Write-Host ''
Write-Host '=== LIMPIEZA SEGURA DE TEXTOS ===' -ForegroundColor Cyan
Write-Host "Archivos activos revisados: $($files.Count)"
Write-Host "Archivos modificados: $($changed.Count)"
if ($changed.Count -gt 0) { $changed | ForEach-Object { Write-Host "  CAMBIO: $_" } }
Write-Host "Backup creado: $backupDir"
if ($remaining.Count -eq 0) {
    Write-Host 'OK: no quedan marcadores comunes de mojibake en archivos activos.' -ForegroundColor Green
} else {
    Write-Host 'ATENCION: quedan posibles textos danados. NO se hicieron cambios forzados:' -ForegroundColor Yellow
    $remaining | ForEach-Object { Write-Host "  $_" }
}
Write-Host 'No se tocaron archivos BACKUP ni ROTO.' -ForegroundColor DarkGray
Write-Host 'No se modificaron logica, camara, SQLite, productos, ventas ni pagos.' -ForegroundColor DarkGray
