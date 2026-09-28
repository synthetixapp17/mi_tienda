$ErrorActionPreference = 'Stop'
$root = 'C:\Users\BRANAXEL\mi_tienda'
Set-Location $root

$main = Join-Path $root 'lib\main.dart'
$pro  = Join-Path $root 'lib\profesional\pro_features.dart'

Write-Host ''
Write-Host '============================================='`nWrite-Host ' SINTHETIX PRO - BOTON COTIZACION V1' -ForegroundColor Cyan
Write-Host '============================================='n
if (-not (Test-Path -LiteralPath $main)) { throw 'No existe lib\main.dart' }
if (-not (Test-Path -LiteralPath $pro))  { throw 'No existe lib\profesional\pro_features.dart' }

$mainText = [System.IO.File]::ReadAllText($main)
$proText  = [System.IO.File]::ReadAllText($pro)

if ($mainText -notmatch 'ProfesionalScreen\(') { throw 'No encuentro ProfesionalScreen en main.dart' }
if ($proText -notmatch 'Widget _quotes\(\)') { throw 'No encuentro _quotes() en pro_features.dart' }
if ($proText -notmatch 'class ProfesionalScreen') { throw 'No encuentro ProfesionalScreen en pro_features.dart' }

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path $root ("BACKUP_BOTON_COTIZACION_$stamp")
New-Item -ItemType Directory -Path $backup | Out-Null
Copy-Item -LiteralPath $main -Destination (Join-Path $backup 'main.dart') -Force
Copy-Item -LiteralPath $pro  -Destination (Join-Path $backup 'pro_features.dart') -Force

Write-Host "Backup creado: $backup" -ForegroundColor DarkGray

$newQuotes = @'
  Widget _quotes() {
    return _panel(
      title: 'Cotizaciones',
      subtitle: 'Crea una cotización profesional para tu cliente.',
      icon: Icons.request_quote_rounded,
      action: FilledButton.icon(
        onPressed: _abrirNuevaCotizacion,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva cotización'),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4B1FA8), Color(0xFF2457D6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            return Flex(
              direction: compact ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: compact ? 0 : 1,
                  child: Column(
                    crossAxisAlignment: compact
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.description_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nueva cotización',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Prepara una cotización para tu cliente y continúa con el siguiente paso.',
                        textAlign: compact ? TextAlign.center : TextAlign.left,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact) const SizedBox(width: 24),
                if (compact) const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4B1FA8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                  ),
                  onPressed: _abrirNuevaCotizacion,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'CREAR COTIZACIÓN',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _abrirNuevaCotizacion() async {
    final cliente = TextEditingController();
    final descripcion = TextEditingController();
    final total = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.request_quote_rounded),
            SizedBox(width: 10),
            Text('Nueva cotización'),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: cliente,
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descripcion,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: total,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Total',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, {
              'cliente': cliente.text.trim(),
              'descripcion': descripcion.text.trim(),
              'total': total.text.trim(),
            }),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Guardar'),
          ),
        ],
      ),
    );

    cliente.dispose();
    descripcion.dispose();
    total.dispose();

    if (result == null) return;

    _cotizaciones.insert(0, {
      'cliente': result['cliente'] ?? '',
      'descripcion': result['descripcion'] ?? '',
      'total': result['total'] ?? '',
      'fecha': DateTime.now(),
    });
    _audit('Nueva cotización');
    if (mounted) setState(() {});
  }
'@

$pattern = '(?s)  Widget _quotes\(\) \{.*?\n  \}\r?\n\r?\n  Widget _credits\(\)'
$replacement = $newQuotes + "`r`n  Widget _credits()"
$newPro = [regex]::Replace($proText, $pattern, $replacement, 1)

if ($newPro -eq $proText) { throw 'No pude reemplazar _quotes() de forma segura.' }

[System.IO.File]::WriteAllText($pro, $newPro, [System.Text.UTF8Encoding]::new($false))

Write-Host 'Cambio instalado. Formateando...' -ForegroundColor Green
& dart format lib\profesional\pro_features.dart
if ($LASTEXITCODE -ne 0) { throw 'dart format fallo.' }

Write-Host 'Analizando archivo modificado...' -ForegroundColor Cyan
& flutter analyze lib\profesional\pro_features.dart
if ($LASTEXITCODE -ne 0) {
  Write-Host 'ANALYZE FALLO. Restaurando backup...' -ForegroundColor Red
  Copy-Item -LiteralPath (Join-Path $backup 'pro_features.dart') -Destination $pro -Force
  Copy-Item -LiteralPath (Join-Path $backup 'main.dart') -Destination $main -Force
  Write-Host 'RESTAURACION COMPLETA.' -ForegroundColor Yellow
  exit 1
}

Write-Host ''
Write-Host '============================================='`nWrite-Host ' INSTALACION CORRECTA' -ForegroundColor Green
Write-Host '============================================='`nWrite-Host 'Boton NUEVA COTIZACION instalado.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor DarkGray
Write-Host ''
Write-Host 'Ahora prueba:' -ForegroundColor Cyan
Write-Host 'flutter run -d chrome'
