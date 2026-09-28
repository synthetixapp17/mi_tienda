$ErrorActionPreference = 'Stop'
$root = 'C:\Users\BRANAXEL\mi_tienda'
Set-Location $root

Write-Host "=== APLICANDO FIX FINAL ===" -ForegroundColor Cyan

$main = 'lib\main.dart'
$text = [System.IO.File]::ReadAllText($main)

# ============================================================
# FIX 1: db.insert('categorias', {...}) en pullFromSupabase
# ============================================================
$old1 = "            await db.insert('categorias', {`r`n              'id': localId,`r`n              'nombre': name,`r`n              'descripcion': cat['description']?.toString(),`r`n              'activo': (cat['active'] == true) ? 1 : 0,`r`n              'sync_estado': 'sincronizado',`r`n              'creado_en': cat['created_at']?.toString() ??`r`n                  DateTime.now().toIso8601String(),`r`n            });"

$new1 = "            await db.query(`r`n              'INSERT OR REPLACE INTO categorias (id, nombre, descripcion, activo, sync_estado, creado_en) VALUES (?, ?, ?, ?, ?, ?)',`r`n              [`r`n                localId,`r`n                name,`r`n                cat['description']?.toString(),`r`n                (cat['active'] == true) ? 1 : 0,`r`n                'sincronizado',`r`n                cat['created_at']?.toString() ??`r`n                    DateTime.now().toIso8601String(),`r`n              ],`r`n            );"

if ($text.Contains($old1)) {
    $text = $text.Replace($old1, $new1)
    Write-Host "FIX 1 aplicado (categorias)" -ForegroundColor Green
} else {
    Write-Host "FIX 1: no match exacto, probando variante..." -ForegroundColor Yellow
    $old1b = $old1.Replace("`r`n", "`n")
    $text = $text.Replace("`r`n", "`n")
    if ($text.Contains($old1b)) {
        $text = $text.Replace($old1b, $new1.Replace("`r`n", "`n"))
        Write-Host "FIX 1 aplicado (variante)" -ForegroundColor Green
    } else {
        Write-Host "FIX 1 FALLO" -ForegroundColor Red
    }
}

# ============================================================
# FIX 2: db.insert('productos', localData) en pullFromSupabase
# ============================================================
$old2 = "          await db.insert('productos', localData);"
$new2 = @"
          final cols = localData.keys.join(', ');
          final placeholders = localData.keys.map((_) => '?').join(', ');
          final values = localData.values.toList();
          await db.query(
            'INSERT OR REPLACE INTO productos (`$cols) VALUES (`$placeholders)',
            values,
          );
"@

if ($text.Contains($old2)) {
    $text = $text.Replace($old2, $new2)
    Write-Host "FIX 2 aplicado (productos)" -ForegroundColor Green
} else {
    Write-Host "FIX 2: no match" -ForegroundColor Red
}

# ============================================================
# GUARDAR
# ============================================================
[System.IO.File]::WriteAllText($main, $text, [System.Text.UTF8Encoding]::new($false))
Write-Host "Guardado" -ForegroundColor Green

# ============================================================
# FORMATEAR Y ANALIZAR
# ============================================================
Write-Host ""
Write-Host "=== Formateando ===" -ForegroundColor Cyan
dart format lib\main.dart

Write-Host ""
Write-Host "=== Analizando ===" -ForegroundColor Cyan
flutter analyze lib\main.dart 2>&1 | Select-String -Pattern 'error'

Write-Host ""
Write-Host "Si no hay errores arriba, todo bien" -ForegroundColor Green