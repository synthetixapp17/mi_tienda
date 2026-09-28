# ============================================================
# INSTALADOR SYNC - SINTHETIX PRO
# Agrega:
#   1. pullFromSupabase() en SupabaseSyncService
#   2. syncFromCloud() en DatabaseService
#   3. Llamada al sync al arrancar la app
#   4. Boton "Sincronizar" en el menu lateral
# ============================================================

$ErrorActionPreference = 'Stop'
$root = 'C:\Users\BRANAXEL\mi_tienda'
Set-Location $root

Write-Host ''
Write-Host '============================================='
Write-Host ' INSTALADOR SYNC - SINTHETIX PRO'
Write-Host '============================================='
Write-Host ''

$main = Join-Path $root 'lib\main.dart'
if (-not (Test-Path -LiteralPath $main)) { throw 'No existe lib\main.dart' }

# ------------------------------------------------------------
# Backup
# ------------------------------------------------------------
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path $root "BACKUP_SYNC_$stamp"
New-Item -ItemType Directory -Path $backup | Out-Null
Copy-Item -LiteralPath $main -Destination (Join-Path $backup 'main.dart') -Force
Write-Host "Backup creado: $backup"
Write-Host ''

$text = [System.IO.File]::ReadAllText($main)

# ------------------------------------------------------------
# 1. Agregar pullFromSupabase() al final de SupabaseSyncService
# ------------------------------------------------------------
if ($text -match 'static Future<int> pullFromSupabase\(\)') {
    Write-Host '1. pullFromSupabase ya existe, saltando...' -ForegroundColor Yellow
} else {
    $pullMethod = @'


  static Future<int> pullFromSupabase() async {
    final c = client;
    if (c == null) {
      debugPrint('PULL: Supabase no disponible');
      return 0;
    }
    try {
      if (c.auth.currentSession == null) {
        try {
          await c.auth.signInAnonymously();
        } catch (_) {}
      }
      if (c.auth.currentSession == null) {
        debugPrint('PULL: sin sesion autenticada');
        return 0;
      }

      final db = DatabaseService();
      int totalBajados = 0;

      // 1) CATEGORIAS
      try {
        final cats = await c.from('store_categories').select('id, name, description, active, created_at');
        for (final cat in (cats as List)) {
          final name = cat['name']?.toString().trim() ?? '';
          if (name.isEmpty) continue;
          final localId = cat['id']?.toString() ?? '';
          if (localId.isEmpty) continue;
          final existing = await db.query(
            'SELECT id FROM categorias WHERE nombre = ? LIMIT 1',
            [name],
          );
          if (existing.isEmpty) {
            await db.insert('categorias', {
              'id': localId,
              'nombre': name,
              'descripcion': cat['description']?.toString(),
              'activo': (cat['active'] == true) ? 1 : 0,
              'sync_estado': 'sincronizado',
              'creado_en': cat['created_at']?.toString() ??
                  DateTime.now().toIso8601String(),
            });
            totalBajados++;
          }
        }
        debugPrint('PULL: categorias OK');
      } catch (e) {
        debugPrint('PULL categorias error: $e');
      }

      // 2) PRODUCTOS
      final prods = await c.from('store_products').select('*').order('updated_at', ascending: false);
      for (final p in (prods as List)) {
        final localId = p['local_id']?.toString().trim() ?? '';
        if (localId.isEmpty) continue;

        String categoriaNombre = 'General';
        final catId = p['category_id']?.toString();
        if (catId != null && catId.isNotEmpty) {
          try {
            final catResult = await c.from('store_categories').select('name').eq('id', catId).maybeSingle();
            if (catResult != null && catResult['name'] != null) {
              categoriaNombre = catResult['name'].toString();
            }
          } catch (_) {}
        }

        final localData = <String, dynamic>{
          'id': localId,
          'nombre': p['name']?.toString() ?? '',
          'codigo_barras': p['barcode']?.toString(),
          'precio': (p['price'] as num?)?.toDouble() ?? 0.0,
          'stock': (p['stock'] as num?)?.toInt() ?? 0,
          'categoria': categoriaNombre,
          'descripcion': p['description']?.toString(),
          'imagen_url': p['image_url']?.toString(),
          'marca': p['brand']?.toString(),
          'talla': p['size']?.toString(),
          'color': p['color']?.toString(),
          'activo': (p['active'] == true) ? 1 : 0,
          'destacado': (p['featured'] == true) ? 1 : 0,
          'sync_estado': 'sincronizado',
          'sync_error': null,
          'creado_en': p['created_at']?.toString() ?? DateTime.now().toIso8601String(),
          'actualizado_en': p['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
        };

        final existe = await db.query(
          'SELECT id FROM productos WHERE id = ? LIMIT 1',
          [localId],
        );
        if (existe.isEmpty) {
          await db.insert('productos', localData);
        } else {
          await db.update('productos', localData, 'id = ?', [localId]);
        }
        totalBajados++;
      }

      debugPrint('PULL: total $totalBajados registros bajados');
      return totalBajados;
    } catch (e) {
      debugPrint('PULL ERROR: $e');
      return 0;
    }
  }

'@
    # Insertar antes del cierre de SupabaseSyncService
    $anchor = 'class MiApp extends StatefulWidget'
    $idx = $text.IndexOf($anchor)
    if ($idx -lt 0) { throw 'No encontre class MiApp' }
    $before = $text.Substring(0, $idx)
    $lastClose = $before.LastIndexOf('}')
    $text = $before.Substring(0, $lastClose) + $pullMethod + $before.Substring($lastClose) + $text.Substring($idx)
    Write-Host '1. pullFromSupabase agregado' -ForegroundColor Green
}

# ------------------------------------------------------------
# 2. Agregar syncFromCloud() en DatabaseService
# ------------------------------------------------------------
if ($text -match 'Future<void> syncFromCloud\(\)') {
    Write-Host '2. syncFromCloud ya existe, saltando...' -ForegroundColor Yellow
} else {
    $syncMethod = @'

  Future<void> syncFromCloud() async {
    try {
      debugPrint('SYNC FROM CLOUD: iniciando...');
      final n = await SupabaseSyncService.pullFromSupabase();
      if (n > 0) {
        productosVersion.value++;
        debugPrint('SYNC FROM CLOUD: $n registros bajados');
      } else {
        debugPrint('SYNC FROM CLOUD: sin cambios');
      }
    } catch (e) {
      debugPrint('SYNC FROM CLOUD error: $e');
    }
  }

'@
    $anchor2 = 'class BarcodeService'
    $idx2 = $text.IndexOf($anchor2)
    if ($idx2 -lt 0) { throw 'No encontre class BarcodeService' }
    $before2 = $text.Substring(0, $idx2)
    $lastClose2 = $before2.LastIndexOf('}')
    $text = $before2.Substring(0, $lastClose2) + $syncMethod + $before2.Substring($lastClose2) + $text.Substring($idx2)
    Write-Host '2. syncFromCloud agregado' -ForegroundColor Green
}

# ------------------------------------------------------------
# 3. Llamar syncFromCloud() al arrancar (_MiAppState.initState)
# ------------------------------------------------------------
if ($text -match 'syncFromCloud\(\)\);\s*\r?\n\s*_stockTimer') {
    Write-Host '3. initState ya tiene syncFromCloud, saltando...' -ForegroundColor Yellow
} else {
    $oldInit = @'
  void initState() {
    super.initState();
    _actualizarStockBajo();
    _stockTimer = Timer.periodic(
'@
    $newInit = @'
  void initState() {
    super.initState();
    _actualizarStockBajo();
    Future.microtask(() => DatabaseService().syncFromCloud());
    _stockTimer = Timer.periodic(
'@
    if ($text.Contains($oldInit)) {
        $text = $text.Replace($oldInit, $newInit)
        Write-Host '3. initState modificado' -ForegroundColor Green
    } else {
        Write-Host '3. ADVERTENCIA: no encontre initState esperado' -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------
# 4. Agregar boton "Sincronizar" en el menu lateral
# ------------------------------------------------------------
if ($text -match "railItemEspecial") {
    Write-Host '4. Boton sync ya existe, saltando...' -ForegroundColor Yellow
} else {
    # 4a. Agregar el railItemEspecial despues de Widget railItem(...)
    $railItemAnchor = "    Widget railItem(String label, IconData icon, int index, {int badge = 0}) {"
    $idxRail = $text.IndexOf($railItemAnchor)
    if ($idxRail -lt 0) { throw 'No encontre Widget railItem' }

    # Buscar el cierre del metodo railItem (buscando el "}" correspondiente)
    # Es mas facil: buscar el siguiente "Widget _" o "// " despues de railItem
    $afterRail = $text.Substring($idxRail)
    $nextMethodMatch = [regex]::Match($afterRail, "\r?\n    Widget [a-zA-Z_]+\(|[\r\n]+    // =")
    if (-not $nextMethodMatch.Success) { throw 'No encontre fin de railItem' }
    $insertAt = $idxRail + $nextMethodMatch.Index

    $railItemEspecial = @'


    Widget railItemEspecial(
        String label, IconData icon, Future<void> Function() onTap) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              await onTap();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: expanded ? 14 : 0, vertical: 12),
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: active),
                  if (expanded) ...[
                    const SizedBox(width: 14),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: active,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

'@
    $text = $text.Substring(0, $insertAt) + $railItemEspecial + $text.Substring($insertAt)
    Write-Host '4a. railItemEspecial agregado' -ForegroundColor Green

    # 4b. Agregar el boton debajo de Estadisticas
    $statsAnchor = "                    railItem('Estadísticas', Icons.insights_rounded, 22),"
    if ($text.Contains($statsAnchor)) {
        $syncBtn = @"
                    railItem('Estadísticas', Icons.insights_rounded, 22),
                    railItemEspecial(
                      'Sincronizar',
                      Icons.sync_rounded,
                      () async {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sincronizando con la nube...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        await DatabaseService().syncFromCloud();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sincronizado correctamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
"@
        $text = $text.Replace($statsAnchor, $syncBtn)
        Write-Host '4b. Boton Sincronizar agregado al menu' -ForegroundColor Green
    } else {
        Write-Host '4b. ADVERTENCIA: no encontre railItem Estadisticas' -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------
# Guardar
# ------------------------------------------------------------
[System.IO.File]::WriteAllText($main, $text, [System.Text.UTF8Encoding]::new($false))
Write-Host ''
Write-Host 'Archivo guardado' -ForegroundColor Green

# ------------------------------------------------------------
# Formatear y verificar
# ------------------------------------------------------------
Write-Host ''
Write-Host 'Formateando...' -ForegroundColor Cyan
& dart format lib\main.dart

Write-Host ''
Write-Host 'Analizando...' -ForegroundColor Cyan
& flutter analyze lib\main.dart 2>&1 | Select-String -Pattern 'error'

Write-Host ''
Write-Host '============================================='
Write-Host ' INSTALACION COMPLETA' -ForegroundColor Green
Write-Host '============================================='
Write-Host ''
Write-Host 'Si no hubo errores arriba, todo quedo bien.'
Write-Host "Backup: $backup" -ForegroundColor DarkGray
Write-Host ''
Write-Host 'Ahora corre:'
Write-Host '  flutter run -d chrome' -ForegroundColor Cyan
Write-Host ''