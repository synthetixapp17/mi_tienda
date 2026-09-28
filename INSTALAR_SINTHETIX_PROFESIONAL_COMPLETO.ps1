# ================================================================
# SINTHETIX PRO - INSTALADOR PROFESIONAL COMPLETO
# Integra ProfesionalScreen + Cotizaciones en el menu lateral.
# NO modifica SQLite ni pro_features.dart.
# ================================================================

$ErrorActionPreference = "Stop"

$root = (Get-Location).Path
$main = Join-Path $root "lib\main.dart"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " SINTHETIX PRO - INSTALADOR PROFESIONAL" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $main)) {
    Write-Host "ERROR: No encuentro lib\main.dart." -ForegroundColor Red
    Write-Host "Abre PowerShell dentro de C:\Users\BRANAXEL\mi_tienda y vuelve a ejecutar." -ForegroundColor Yellow
    exit 1
}

# ------------------------------------------------
# 1. Copia de seguridad
# ------------------------------------------------
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $root "lib\main_BACKUP_PRO_$stamp.dart"
Copy-Item $main $backup -Force
Write-Host "[1/8] Backup creado:" -ForegroundColor Green
Write-Host "      $backup"

# ------------------------------------------------
# 2. Leer main.dart
# ------------------------------------------------
$utf8 = New-Object System.Text.UTF8Encoding($false)
$content = [System.IO.File]::ReadAllText($main, $utf8)

# Quitar restos del parche incorrecto anterior, si existen.
$content = [regex]::Replace(
    $content,
    "(?ms)^\s*final\s+cotizacionesItem\s*=\s*railItem\(\s*'Cotizaciones',\s*Icons\.request_quote_outlined,\s*23,\s*\);\s*",
    "",
    1
)
$content = [regex]::Replace(
    $content,
    "(?m)^\s*cotizacionesItem,\s*\r?\n",
    "",
    1
)

# ------------------------------------------------
# 3. Importar pro_features.dart
# ------------------------------------------------
if ($content -notmatch "(?m)^\s*import\s+'profesional/pro_features\.dart';") {
    $imports = [regex]::Matches($content, "(?m)^\s*import\s+[^;]+;\s*\r?\n")
    if ($imports.Count -eq 0) {
        throw "No pude localizar la zona de imports de main.dart."
    }

    $lastImport = $imports[$imports.Count - 1]
    $insertAt = $lastImport.Index + $lastImport.Length
    $content = $content.Insert($insertAt, "import 'profesional/pro_features.dart';`r`n")
}
Write-Host "[2/8] Import del modulo profesional: OK" -ForegroundColor Green

# ------------------------------------------------
# 4. Añadir ProfesionalScreen al IndexedStack
# ------------------------------------------------
if ($content -notmatch "\bProfesionalScreen\s*\(") {

    $pattern = "(?ms)(\s*EstadisticasScreen\(\s*onAbrirSidebar:\s*_abrirSidebar,\s*modoOscuro:\s*_modoOscuro\),)"

    if ($content -notmatch $pattern) {
        throw "No encontré EstadisticasScreen dentro del IndexedStack."
    }

    $replacement = '$1' + @"
`r`n                  ProfesionalScreen(
                    onAbrirSidebar: _abrirSidebar,
                    modoOscuro: _modoOscuro,
                  ),
"@

    $content = [regex]::Replace($content, $pattern, $replacement, 1)
}
Write-Host "[3/8] ProfesionalScreen en IndexedStack: OK" -ForegroundColor Green

# ------------------------------------------------
# 5. Añadir ruta "profesional" a _rutaActual()
# ------------------------------------------------
$rutaMethod = [regex]::Match(
    $content,
    "(?ms)String\s+_rutaActual\s*\(\s*\)\s*\{.*?\n\s*\}"
)

if (-not $rutaMethod.Success) {
    throw "No encontré el metodo _rutaActual()."
}

$rutaBlock = $rutaMethod.Value

if ($rutaBlock -notmatch "'profesional'") {
    if ($rutaBlock -notmatch "'estadisticas',") {
        throw "No encontré la ruta 'estadisticas' dentro de _rutaActual()."
    }
    $rutaBlock = $rutaBlock -replace "'estadisticas',", "'estadisticas',`r`n      'profesional',", 1
    $content = $content.Substring(0, $rutaMethod.Index) + $rutaBlock + $content.Substring($rutaMethod.Index + $rutaMethod.Length)
}
Write-Host "[4/8] Ruta profesional: OK" -ForegroundColor Green

# ------------------------------------------------
# 6. Añadir "profesional": 23 al mapa _navegar()
# ------------------------------------------------
$navMethod = [regex]::Match(
    $content,
    "(?ms)void\s+_navegar\s*\(\s*String\s+ruta\s*\)\s*\{.*?\n\s*\}"
)

if (-not $navMethod.Success) {
    throw "No encontré el metodo _navegar()."
}

$navBlock = $navMethod.Value

if ($navBlock -notmatch "'profesional'\s*:\s*23") {
    if ($navBlock -notmatch "'estadisticas'\s*:\s*22\s*,") {
        throw "No encontré 'estadisticas': 22 dentro de _navegar()."
    }
    $navBlock = $navBlock -replace "'estadisticas'\s*:\s*22\s*,", "'estadisticas': 22,`r`n      'profesional': 23,", 1
    $content = $content.Substring(0, $navMethod.Index) + $navBlock + $content.Substring($navMethod.Index + $navMethod.Length)
}
Write-Host "[5/8] Navegación profesional: OK" -ForegroundColor Green

# ------------------------------------------------
# 7. Añadir Cotizaciones al menú lateral
#    Busca la función local railItem y coloca el
#    nuevo item en la lista real de items, no dentro
#    de la función railItem.
# ------------------------------------------------
if ($content -notmatch "onNavigate\('profesional'\)") {

    $sideStart = $content.IndexOf("Widget _buildSideRail")
    if ($sideStart -lt 0) {
        # Algunos archivos pueden declarar el método con otro formato.
        $sideStart = $content.IndexOf("_buildSideRail(")
    }

    if ($sideStart -lt 0) {
        throw "No encontré _buildSideRail()."
    }

    $railDecl = $content.IndexOf("Widget railItem", $sideStart)
    if ($railDecl -lt 0) {
        throw "No encontré la función railItem dentro de _buildSideRail()."
    }

    # Encontrar la llave de apertura de railItem.
    $open = $content.IndexOf("{", $railDecl)
    if ($open -lt 0) {
        throw "No pude localizar el inicio de railItem()."
    }

    $depth = 0
    $close = -1
    for ($i = $open; $i -lt $content.Length; $i++) {
        $ch = $content[$i]
        if ($ch -eq "{") {
            $depth++
        } elseif ($ch -eq "}") {
            $depth--
            if ($depth -eq 0) {
                $close = $i
                break
            }
        }
    }

    if ($close -lt 0) {
        throw "No pude localizar el final de railItem()."
    }

    # Primer railItem() después de la función local = primer
    # elemento real de la lista lateral.
    $firstReal = $content.IndexOf("railItem(", $close + 1)
    if ($firstReal -lt 0) {
        throw "No encontré los elementos railItem del menú lateral."
    }

    # Verificación: debe existir children: [ antes del primer item.
    $childrenBefore = $content.LastIndexOf("children: [", $firstReal)
    if ($childrenBefore -lt 0 -or $childrenBefore -lt $close) {
        throw "No pude identificar con seguridad la lista principal del menú lateral."
    }

    $newItem = @"
    railItem(
      'Cotizaciones',
      Icons.request_quote_outlined,
      23,
    ),
"@

    $content = $content.Insert($firstReal, $newItem)
}
Write-Host "[6/8] Cotizaciones en menú lateral: OK" -ForegroundColor Green

# ------------------------------------------------
# 8. Verificaciones y guardar
# ------------------------------------------------
$required = @(
    "import 'profesional/pro_features.dart';",
    "ProfesionalScreen(",
    "'profesional': 23",
    "railItem(",
    "'Cotizaciones'",
    "Icons.request_quote_outlined"
)

foreach ($item in $required) {
    if ($content.IndexOf($item, [System.StringComparison]::Ordinal) -lt 0) {
        throw "Fallo de verificación: no encontré [$item]."
    }
}

[System.IO.File]::WriteAllText($main, $content, $utf8)

Write-Host "[7/8] main.dart guardado: OK" -ForegroundColor Green

# ------------------------------------------------
# Formato
# ------------------------------------------------
Write-Host ""
Write-Host "Ejecutando dart format..." -ForegroundColor Cyan
& dart format $main
if ($LASTEXITCODE -ne 0) {
    throw "dart format devolvió un error."
}

Write-Host "[8/8] dart format: OK" -ForegroundColor Green

# ------------------------------------------------
# Comprobación final
# ------------------------------------------------
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host " INSTALACION TERMINADA" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Backup:" -ForegroundColor Yellow
Write-Host "  $backup"
Write-Host ""
Write-Host "AHORA ejecuta:" -ForegroundColor Cyan
Write-Host "  flutter analyze .\lib\main.dart" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANTE: este instalador NO modifica SQLite ni pro_features.dart." -ForegroundColor Yellow
Write-Host ""
