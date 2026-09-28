# ================================================================
# SINTHETIX PRO - INSTALADOR PROFESIONAL V5
# Repara la integracion en main.dart.
# NO reemplaza pro_features.dart.
# NO modifica SQLite ni Supabase.
# ================================================================

$ErrorActionPreference = "Stop"
$root = (Get-Location).Path
$main = Join-Path $root "lib\main.dart"

if (-not (Test-Path $main)) {
    throw "No encuentro lib\main.dart. Ejecuta desde C:\Users\BRANAXEL\mi_tienda"
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $root "lib\main_BACKUP_PRO_V5_$stamp.dart"
Copy-Item $main $backup -Force

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " SINTHETIX PRO - REPARADOR PROFESIONAL V5" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "BACKUP: $backup" -ForegroundColor Green
Write-Host ""

try {
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $content = [System.IO.File]::ReadAllText($main, $utf8)

    # 1. Eliminar el resto conocido del parche de Cotizaciones que provocaba
    #    llamadas mal formadas dentro de railItem().
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

    # 2. Import profesional.
    if ($content -notmatch "(?m)^\s*import\s+'profesional/pro_features\.dart';") {
        $imports = [regex]::Matches($content, "(?m)^\s*import\s+[^;]+;\s*\r?\n")
        if ($imports.Count -eq 0) { throw "No pude localizar los imports de main.dart." }
        $lastImport = $imports[$imports.Count - 1]
        $insertAt = $lastImport.Index + $lastImport.Length
        $content = $content.Insert($insertAt, "import 'profesional/pro_features.dart';`r`n")
    }

    # 3. ProfesionalScreen en IndexedStack, solo si no existe.
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

    # 4. Ruta profesional.
    $rutaMethod = [regex]::Match(
        $content,
        "(?ms)String\s+_rutaActual\s*\(\s*\)\s*\{.*?\n\s*\}"
    )
    if (-not $rutaMethod.Success) { throw "No encontré _rutaActual()." }

    $rutaBlock = $rutaMethod.Value
    if ($rutaBlock -notmatch "'profesional'") {
        if ($rutaBlock -notmatch "'estadisticas',") {
            throw "No encontré 'estadisticas' dentro de _rutaActual()."
        }
        $rutaBlock = [regex]::Replace(
            $rutaBlock,
            "'estadisticas',",
            "'estadisticas',`r`n      'profesional',",
            1
        )
        $content = $content.Substring(0, $rutaMethod.Index) +
                   $rutaBlock +
                   $content.Substring($rutaMethod.Index + $rutaMethod.Length)
    }

    # 5. Mapa _navegar().
    $navMethod = [regex]::Match(
        $content,
        "(?ms)void\s+_navegar\s*\(\s*String\s+ruta\s*\)\s*\{.*?\n\s*\}"
    )
    if (-not $navMethod.Success) { throw "No encontré _navegar()." }

    $navBlock = $navMethod.Value
    if ($navBlock -notmatch "'profesional'\s*:\s*23") {
        if ($navBlock -notmatch "'estadisticas'\s*:\s*22\s*,") {
            throw "No encontré 'estadisticas': 22 dentro de _navegar()."
        }
        $navBlock = [regex]::Replace(
            $navBlock,
            "'estadisticas'\s*:\s*22\s*,",
            "'estadisticas': 22,`r`n      'profesional': 23,",
            1
        )
        $content = $content.Substring(0, $navMethod.Index) +
                   $navBlock +
                   $content.Substring($navMethod.Index + $navMethod.Length)
    }

    # 6. Cotizaciones en el menú: localizar la lista REAL de railItem,
    #    nunca insertar dentro de la función railItem().
    if ($content -notmatch "'Cotizaciones'") {
        $sideStart = $content.IndexOf("Widget _buildSideRail")
        if ($sideStart -lt 0) { $sideStart = $content.IndexOf("_buildSideRail(") }
        if ($sideStart -lt 0) { throw "No encontré _buildSideRail()." }

        $railDecl = $content.IndexOf("Widget railItem", $sideStart)
        if ($railDecl -lt 0) { throw "No encontré la función railItem()." }

        $open = $content.IndexOf("{", $railDecl)
        if ($open -lt 0) { throw "No pude localizar el inicio de railItem()." }

        $depth = 0
        $close = -1
        for ($i = $open; $i -lt $content.Length; $i++) {
            if ($content[$i] -eq "{") { $depth++ }
            elseif ($content[$i] -eq "}") {
                $depth--
                if ($depth -eq 0) { $close = $i; break }
            }
        }
        if ($close -lt 0) { throw "No pude localizar el final de railItem()." }

        $firstReal = $content.IndexOf("railItem(", $close + 1)
        if ($firstReal -lt 0) { throw "No encontré elementos del menú lateral." }

        $childrenBefore = $content.LastIndexOf("children: [", $firstReal)
        if ($childrenBefore -lt $close) {
            throw "No pude identificar con seguridad la lista del menú lateral."
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

    # 7. Verificación textual antes de escribir.
    foreach ($required in @(
        "import 'profesional/pro_features.dart';",
        "ProfesionalScreen(",
        "'profesional'",
        "'profesional': 23",
        "'Cotizaciones'",
        "Icons.request_quote_outlined"
    )) {
        if ($content.IndexOf($required, [System.StringComparison]::Ordinal) -lt 0) {
            throw "Verificación interna falló: falta [$required]."
        }
    }

    [System.IO.File]::WriteAllText($main, $content, $utf8)

    Write-Host "Formateando main.dart..." -ForegroundColor Yellow
    & dart format $main
    if ($LASTEXITCODE -ne 0) { throw "dart format falló." }

    # 8. Analizar SOLO errores reales.
    Write-Host ""
    Write-Host "Verificando main.dart..." -ForegroundColor Yellow
    $analysis = cmd.exe /c "flutter analyze `"$main`" 2>&1"
    $analysisText = $analysis | Out-String
    Write-Host $analysisText

    if ($analysisText -match "(?m)^\s*error\s*-\s") {
        throw "main.dart todavía tiene errores Dart reales."
    }

    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    Write-Host " MAIN.DART REPARADO CORRECTAMENTE" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "Los warnings/info no detienen la instalacion."
    Write-Host ""
    Write-Host "Backup: $backup" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Ahora puedes ejecutar:"
    Write-Host "flutter run -d chrome" -ForegroundColor White
}
catch {
    Write-Host ""
    Write-Host "FALLO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Restaurando main.dart..." -ForegroundColor Yellow
    Copy-Item $backup $main -Force
    Write-Host "RESTAURACION TERMINADA." -ForegroundColor Green
    Write-Host "Backup: $backup" -ForegroundColor Cyan
    exit 1
}
