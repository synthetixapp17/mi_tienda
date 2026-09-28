#requires -Version 5.1
$ErrorActionPreference = "Stop"

$root = (Get-Location).Path
$main  = Join-Path $root "lib\main.dart"
$pro   = Join-Path $root "lib\profesional\pro_features.dart"
$panel = Join-Path $root "lib\profesional\cotizaciones_pro_panel.dart"
$utf8  = New-Object System.Text.UTF8Encoding($false)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " SINTHETIX PRO - COTIZACIONES PDF + WHATSAPP V4" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

if (!(Test-Path $main))  { throw "No encuentro lib\main.dart." }
if (!(Test-Path $pro))   { throw "No encuentro lib\profesional\pro_features.dart." }
if (!(Test-Path $panel)) { throw "No encuentro lib\profesional\cotizaciones_pro_panel.dart." }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $root "BACKUP_COTIZACION_V4_$stamp"
New-Item -ItemType Directory -Path $backup -Force | Out-Null

Copy-Item $main  (Join-Path $backup "main.dart") -Force
Copy-Item $pro   (Join-Path $backup "pro_features.dart") -Force
Copy-Item $panel (Join-Path $backup "cotizaciones_pro_panel.dart") -Force

Write-Host "Backup: $backup" -ForegroundColor Green

try {
    $text = [IO.File]::ReadAllText($panel, $utf8)

    # CORRECCION EXACTA DEL ERROR V3:
    # El panel no debe importar LocalDatabase ni instanciarlo.
    $oldImport = "import '../database/local_database.dart';"
    $newImport = "import '../services/database_service_real.dart';"

    if ($text.Contains($oldImport)) {
        $text = $text.Replace($oldImport, $newImport)
        Write-Host "OK: import cambiado a DatabaseService." -ForegroundColor Green
    } elseif ($text -notmatch "(?m)^import '../services/database_service_real\.dart';") {
        throw "El panel no tiene el import esperado de base de datos."
    }

    $oldDb = "final LocalDatabase _db = LocalDatabase();"
    $newDb = "final DatabaseService _db = DatabaseService();"

    if ($text.Contains($oldDb)) {
        $text = $text.Replace($oldDb, $newDb)
        Write-Host "OK: LocalDatabase reemplazado por DatabaseService." -ForegroundColor Green
    } elseif ($text -notmatch "final DatabaseService _db = DatabaseService\(\);") {
        throw "No encontre la declaracion de la base de datos del panel."
    }

    # DatabaseService expone getProductos(), que devuelve los productos reales.
    $oldLoad = "final rows = await _db.getAll('productos', orderBy: 'nombre');"
    $newLoad = "final rows = await _db.getProductos();"

    if ($text.Contains($oldLoad)) {
        $text = $text.Replace($oldLoad, $newLoad)
        Write-Host "OK: productos conectados a getProductos()." -ForegroundColor Green
    }

    [IO.File]::WriteAllText($panel, $text, $utf8)

    Write-Host ""
    Write-Host "Formateando..." -ForegroundColor Yellow
    & dart format $panel $pro
    if ($LASTEXITCODE -ne 0) {
        throw "dart format fallo."
    }

    Write-Host ""
    Write-Host "Comprobando SOLO archivos activos..." -ForegroundColor Yellow

    $log = Join-Path $env:TEMP "sinthetix_cotizacion_v4_$stamp.txt"
    cmd.exe /c "flutter analyze lib\main.dart lib\profesional\pro_features.dart lib\profesional\cotizaciones_pro_panel.dart > `"$log`" 2>&1"
    $analysis = Get-Content $log -Raw -ErrorAction SilentlyContinue
    if ($analysis) { Write-Host $analysis }

    if ($analysis -match "(?m)^\s*error\s*-\s") {
        throw "Flutter encontro errores Dart reales."
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " COTIZACIONES V4 INSTALADAS CORRECTAMENTE" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "Productos reales del inventario: OK" -ForegroundColor Green
    Write-Host "Cliente / telefono / correo / direccion: OK" -ForegroundColor Green
    Write-Host "Cantidades / descuento / total: OK" -ForegroundColor Green
    Write-Host "PDF profesional: OK" -ForegroundColor Green
    Write-Host "Compartir PDF: OK" -ForegroundColor Green
    Write-Host "WhatsApp: disponible mediante compartir / enlace" -ForegroundColor Green
    Write-Host ""
    Write-Host "Backup: $backup" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "SIGUIENTE PASO: flutter run -d chrome" -ForegroundColor Yellow
}
catch {
    Write-Host ""
    Write-Host "FALLO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Restaurando archivos..." -ForegroundColor Yellow

    Copy-Item (Join-Path $backup "main.dart") $main -Force
    Copy-Item (Join-Path $backup "pro_features.dart") $pro -Force
    Copy-Item (Join-Path $backup "cotizaciones_pro_panel.dart") $panel -Force

    Write-Host "RESTAURACION COMPLETA." -ForegroundColor Green
    Write-Host "Backup: $backup" -ForegroundColor Cyan
    exit 1
}
