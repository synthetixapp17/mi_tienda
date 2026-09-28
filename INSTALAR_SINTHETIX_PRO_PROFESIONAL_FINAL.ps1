# ================================================================
# SINTHETIX PRO - INSTALADOR MODULO PROFESIONAL
# ================================================================
# Hace backup, instala el modulo profesional, integra main.dart,
# formatea y verifica. Si la verificacion falla, restaura automaticamente.
# NO modifica SQLite, productos, ventas ni la base de datos.
# ================================================================

$ErrorActionPreference = "Stop"

$root = Get-Location
$main = Join-Path $root "lib\main.dart"
$proDir = Join-Path $root "lib\profesional"
$proFile = Join-Path $proDir "pro_features.dart"
$actFile = Join-Path $proDir "profesional_activator.dart"

if (!(Test-Path $main)) {
    Write-Host "ERROR: No encuentro lib\main.dart" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $proDir | Out-Null

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $root "BACKUP_INSTALADOR_PRO_$stamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

Copy-Item $main (Join-Path $backupDir "main.dart") -Force
if (Test-Path $proFile) { Copy-Item $proFile (Join-Path $backupDir "pro_features.dart") -Force }
if (Test-Path $actFile) { Copy-Item $actFile (Join-Path $backupDir "profesional_activator.dart") -Force }

Write-Host ""
Write-Host "BACKUP CREADO: $backupDir" -ForegroundColor Green

# ------------------------------------------------
# Modulo profesional autocontenido.
# ------------------------------------------------
$pro = @'
import 'package:flutter/material.dart';

class ProfesionalScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;

  const ProfesionalScreen({
    super.key,
    required this.onAbrirSidebar,
    required this.modoOscuro,
  });

  @override
  State<ProfesionalScreen> createState() => _ProfesionalScreenState();
}

class _ProfesionalScreenState extends State<ProfesionalScreen> {
  int _tab = 0;

  final List<String> _tabs = const [
    'Cotizaciones',
    'Crédito',
    'Notas de crédito',
    'Caja',
    'Pagos mixtos',
    'Monedas',
    'Auditoría',
  ];

  final List<Map<String, dynamic>> _cotizaciones = [];
  final List<Map<String, dynamic>> _creditos = [];
  final List<Map<String, dynamic>> _notas = [];
  final List<Map<String, dynamic>> _movimientos = [];
  final List<Map<String, dynamic>> _auditoria = [];

  final Map<String, double> _monedas = {
    'USD': 1.0,
    'VES': 1.0,
    'COP': 1.0,
    'DOP': 1.0,
  };

  Color get _bg => widget.modoOscuro
      ? const Color(0xFF11101A)
      : const Color(0xFFF5F6FA);

  Color get _cardColor => widget.modoOscuro
      ? const Color(0xFF1D1B29)
      : Colors.white;

  Color get _text => widget.modoOscuro
      ? Colors.white
      : const Color(0xFF202124);

  void _audit(String accion) {
    _auditoria.insert(0, {
      'fecha': DateTime.now(),
      'accion': accion,
    });
    if (mounted) setState(() {});
  }

  Future<void> _nuevoSimple({
    required String titulo,
    required List<_Field> fields,
    required void Function(Map<String, String>) guardar,
  }) async {
    final controllers = {
      for (final f in fields) f.label: TextEditingController(),
    };

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final f in fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: controllers[f.label],
                      keyboardType: f.keyboard,
                      maxLines: f.maxLines,
                      decoration: InputDecoration(
                        labelText: f.label,
                        border: const OutlineInputBorder(),
                      ),
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
          FilledButton(
            onPressed: () {
              Navigator.pop(
                ctx,
                {
                  for (final f in fields)
                    f.label: controllers[f.label]!.text.trim(),
                },
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    for (final c in controllers.values) {
      c.dispose();
    }

    if (result != null) {
      guardar(result);
      if (mounted) setState(() {});
    }
  }

  Widget _shell(Widget child) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Menú',
                  onPressed: widget.onAbrirSidebar,
                  icon: const Icon(Icons.menu_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Módulo Profesional',
                    style: TextStyle(
                      color: _text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 58,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tabs.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: _tab == i,
                  label: Text(_tabs[i]),
                  onSelected: (_) => setState(() => _tab = i),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              child: _body(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_tab) {
      case 0:
        return _quotes();
      case 1:
        return _credits();
      case 2:
        return _creditNotes();
      case 3:
        return _cash();
      case 4:
        return _mixedPayments();
      case 5:
        return _currencies();
      default:
        return _auditView();
    }
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    return Card(
      color: _cardColor,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: _text,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: _text.withValues(alpha: .65),
                        ),
                      ),
                    ],
                  ),
                ),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: _text.withValues(alpha: .65)),
        ),
      ),
    );
  }

  Widget _quotes() {
    return _panel(
      title: 'Cotizaciones',
      subtitle: 'Crea y administra cotizaciones para clientes.',
      icon: Icons.request_quote_rounded,
      action: FilledButton.icon(
        onPressed: () => _nuevoSimple(
          titulo: 'Nueva cotización',
          fields: const [
            _Field('Cliente'),
            _Field('Descripción', maxLines: 3),
            _Field('Total'),
          ],
          guardar: (v) {
            _cotizaciones.insert(0, {
              'cliente': v['Cliente'] ?? '',
              'descripcion': v['Descripción'] ?? '',
              'total': v['Total'] ?? '',
              'fecha': DateTime.now(),
            });
            _audit('Nueva cotización');
          },
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      child: _cotizaciones.isEmpty
          ? _empty('Todavía no hay cotizaciones.')
          : Column(
              children: [
                for (final q in _cotizaciones)
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(
                      q['cliente'].toString().isEmpty
                          ? 'Cliente'
                          : q['cliente'].toString(),
                      style: TextStyle(color: _text),
                    ),
                    subtitle: Text(
                      '${q['descripcion']}  •  ${q['total']}',
                      style: TextStyle(color: _text.withValues(alpha: .65)),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _credits() {
    return _panel(
      title: 'Crédito',
      subtitle: 'Registro básico de ventas y saldos a crédito.',
      icon: Icons.credit_score_rounded,
      action: FilledButton.icon(
        onPressed: () => _nuevoSimple(
          titulo: 'Nuevo crédito',
          fields: const [
            _Field('Cliente'),
            _Field('Monto'),
            _Field('Referencia'),
          ],
          guardar: (v) {
            _creditos.insert(0, {
              'cliente': v['Cliente'] ?? '',
              'monto': v['Monto'] ?? '',
              'referencia': v['Referencia'] ?? '',
              'fecha': DateTime.now(),
            });
            _audit('Nuevo crédito');
          },
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      child: _creditos.isEmpty
          ? _empty('Todavía no hay créditos registrados.')
          : Column(
              children: [
                for (final c in _creditos)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(c['cliente'].toString(),
                        style: TextStyle(color: _text)),
                    subtitle: Text(
                      'Monto: ${c['monto']}  •  ${c['referencia']}',
                      style: TextStyle(color: _text.withValues(alpha: .65)),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _creditNotes() {
    return _panel(
      title: 'Notas de crédito',
      subtitle: 'Registra devoluciones, ajustes y notas de crédito.',
      icon: Icons.receipt_long_rounded,
      action: FilledButton.icon(
        onPressed: () => _nuevoSimple(
          titulo: 'Nueva nota de crédito',
          fields: const [
            _Field('Cliente'),
            _Field('Motivo', maxLines: 3),
            _Field('Monto'),
          ],
          guardar: (v) {
            _notas.insert(0, {
              'cliente': v['Cliente'] ?? '',
              'motivo': v['Motivo'] ?? '',
              'monto': v['Monto'] ?? '',
              'fecha': DateTime.now(),
            });
            _audit('Nueva nota de crédito');
          },
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      child: _notas.isEmpty
          ? _empty('Todavía no hay notas de crédito.')
          : Column(
              children: [
                for (final n in _notas)
                  ListTile(
                    leading: const Icon(Icons.undo_rounded),
                    title: Text(n['cliente'].toString(),
                        style: TextStyle(color: _text)),
                    subtitle: Text(
                      '${n['motivo']}  •  ${n['monto']}',
                      style: TextStyle(color: _text.withValues(alpha: .65)),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _cash() {
    return _panel(
      title: 'Caja',
      subtitle: 'Apertura, movimientos y cierre de caja.',
      icon: Icons.point_of_sale_rounded,
      action: FilledButton.icon(
        onPressed: () => _nuevoSimple(
          titulo: 'Movimiento de caja',
          fields: const [
            _Field('Tipo'),
            _Field('Monto'),
            _Field('Descripción'),
          ],
          guardar: (v) {
            _movimientos.insert(0, {
              'tipo': v['Tipo'] ?? '',
              'monto': v['Monto'] ?? '',
              'descripcion': v['Descripción'] ?? '',
              'fecha': DateTime.now(),
            });
            _audit('Movimiento de caja');
          },
        ),
        icon: const Icon(Icons.add),
        label: const Text('Movimiento'),
      ),
      child: _movimientos.isEmpty
          ? _empty('No hay movimientos de caja.')
          : Column(
              children: [
                for (final m in _movimientos)
                  ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: Text(m['tipo'].toString(),
                        style: TextStyle(color: _text)),
                    subtitle: Text(
                      '${m['monto']}  •  ${m['descripcion']}',
                      style: TextStyle(color: _text.withValues(alpha: .65)),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _mixedPayments() {
    return _panel(
      title: 'Pagos mixtos',
      subtitle: 'Registra una venta distribuida entre varios métodos.',
      icon: Icons.account_balance_wallet_rounded,
      action: FilledButton.icon(
        onPressed: () => _nuevoSimple(
          titulo: 'Pago mixto',
          fields: const [
            _Field('Efectivo'),
            _Field('Tarjeta'),
            _Field('Transferencia'),
            _Field('Referencia'),
          ],
          guardar: (v) {
            _movimientos.insert(0, {
              'tipo': 'Pago mixto',
              'monto':
                  'Efectivo ${v['Efectivo']} / Tarjeta ${v['Tarjeta']} / Transferencia ${v['Transferencia']}',
              'descripcion': v['Referencia'] ?? '',
              'fecha': DateTime.now(),
            });
            _audit('Pago mixto registrado');
          },
        ),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      child: _empty(
        'Usa "Registrar" para distribuir el pago entre varios métodos.',
      ),
    );
  }

  Widget _currencies() {
    return _panel(
      title: 'Monedas',
      subtitle: 'Tasas configurables para USD, VES, COP y DOP.',
      icon: Icons.currency_exchange_rounded,
      action: FilledButton.icon(
        onPressed: () => _nuevoSimple(
          titulo: 'Actualizar tasa',
          fields: const [
            _Field('Moneda'),
            _Field('Tasa'),
          ],
          guardar: (v) {
            final moneda = (v['Moneda'] ?? '').toUpperCase();
            final tasa = double.tryParse(v['Tasa'] ?? '');
            if (_monedas.containsKey(moneda) && tasa != null) {
              _monedas[moneda] = tasa;
              _audit('Tasa actualizada: $moneda');
              setState(() {});
            }
          },
        ),
        icon: const Icon(Icons.edit),
        label: const Text('Actualizar'),
      ),
      child: Column(
        children: [
          for (final e in _monedas.entries)
            ListTile(
              leading: const Icon(Icons.attach_money_rounded),
              title: Text(e.key, style: TextStyle(color: _text)),
              trailing: Text(
                e.value.toString(),
                style: TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _auditView() {
    return _panel(
      title: 'Auditoría',
      subtitle: 'Registro de acciones realizadas dentro del módulo.',
      icon: Icons.history_rounded,
      child: _auditoria.isEmpty
          ? _empty('No hay eventos registrados.')
          : Column(
              children: [
                for (final a in _auditoria)
                  ListTile(
                    leading: const Icon(Icons.event_note_outlined),
                    title: Text(
                      a['accion'].toString(),
                      style: TextStyle(color: _text),
                    ),
                    subtitle: Text(
                      a['fecha'].toString(),
                      style: TextStyle(color: _text.withValues(alpha: .65)),
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) => _shell(_body());
}

class _Field {
  final String label;
  final TextInputType? keyboard;
  final int maxLines;

  const _Field(
    this.label, {
    this.keyboard,
    this.maxLines = 1,
  });
}
'@

Set-Content -Path $proFile -Value $pro -Encoding UTF8

$activator = @'
import 'package:flutter/material.dart';
import 'pro_features.dart';

class ProfesionalActivator {
  const ProfesionalActivator._();

  static Future<void> abrir(
    BuildContext context, {
    required VoidCallback onAbrirSidebar,
    required bool modoOscuro,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfesionalScreen(
          onAbrirSidebar: onAbrirSidebar,
          modoOscuro: modoOscuro,
        ),
      ),
    );
  }
}
'@

Set-Content -Path $actFile -Value $activator -Encoding UTF8

# ------------------------------------------------
# Integracion de main.dart
# ------------------------------------------------
$mainText = Get-Content $main -Raw

if ($mainText -notmatch "profesional/pro_features\.dart") {
    $mainText = "import 'profesional/pro_features.dart';`r`n" + $mainText
}

if ($mainText -notmatch "ProfesionalScreen\(") {
    $needle = "EstadisticasScreen("
    $pos = $mainText.IndexOf($needle)
    if ($pos -lt 0) {
        throw "No encuentro EstadisticasScreen para insertar el modulo Profesional."
    }

    $lineEnd = $mainText.IndexOf("),", $pos)
    if ($lineEnd -lt 0) {
        throw "No pude localizar el cierre de EstadisticasScreen."
    }

    $insertAt = $lineEnd + 2
    $block = @"
                  ProfesionalScreen(
                    onAbrirSidebar: _abrirSidebar,
                    modoOscuro: _modoOscuro,
                  ),
"@
    $mainText = $mainText.Insert($insertAt, $block)
}

if ($mainText -notmatch "'profesional'") {
    $mainText = $mainText -replace "('estadisticas',)", "`$1`r`n      'profesional',"
}

if ($mainText -notmatch "'profesional'\s*:\s*23") {
    $mainText = $mainText -replace "('estadisticas'\s*:\s*22,)", "`$1`r`n      'profesional': 23,"
}

Set-Content -Path $main -Value $mainText -Encoding UTF8

Write-Host ""
Write-Host "Archivos instalados." -ForegroundColor Green
Write-Host "Formateando..." -ForegroundColor Cyan

& dart format $proFile $actFile $main
if ($LASTEXITCODE -ne 0) {
    throw "Dart format fallo."
}

Write-Host ""
Write-Host "Verificando modulo profesional..." -ForegroundColor Cyan
& flutter analyze $proFile
if ($LASTEXITCODE -ne 0) {
    throw "El modulo profesional no paso flutter analyze."
}

Write-Host ""
Write-Host "Verificando proyecto completo..." -ForegroundColor Cyan
& flutter analyze lib/main.dart
if ($LASTEXITCODE -ne 0) {
    throw "main.dart no paso flutter analyze."
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "SINTHETIX PRO - INSTALACION TERMINADA" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "Backup: $backupDir"
Write-Host ""
Write-Host "Ahora puedes ejecutar:" -ForegroundColor Yellow
Write-Host "flutter run -d chrome" -ForegroundColor White
Write-Host ""
