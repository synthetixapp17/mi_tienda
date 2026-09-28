$ErrorActionPreference = "Stop"

# ============================================================
# SINTHETIX PRO - INSTALADOR PROFESIONAL V4
# Corrige el instalador anterior:
# - No trata warnings/info como errores.
# - Elimina el parametro keyboard sin uso.
# - Hace backup antes de tocar nada.
# - Si falla una modificacion/verificacion, restaura main.dart
#   y los archivos profesionales desde el backup de esta ejecucion.
# ============================================================

$Root = (Get-Location).Path
$Main = Join-Path $Root "lib\main.dart"
$ProDir = Join-Path $Root "lib\profesional"
$Pro = Join-Path $ProDir "pro_features.dart"
$Activator = Join-Path $ProDir "profesional_activator.dart"

if (-not (Test-Path $Main)) {
    throw "No encuentro lib\main.dart. Ejecuta este instalador desde C:\Users\BRANAXEL\mi_tienda"
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupDir = Join-Path $Root "BACKUP_INSTALADOR_PRO_V4_$stamp"
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

Copy-Item $Main (Join-Path $BackupDir "main.dart") -Force
if (Test-Path $Pro) { Copy-Item $Pro (Join-Path $BackupDir "pro_features.dart") -Force }
if (Test-Path $Activator) { Copy-Item $Activator (Join-Path $BackupDir "profesional_activator.dart") -Force }

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " SINTHETIX PRO - INSTALADOR PROFESIONAL V4" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "BACKUP: $BackupDir" -ForegroundColor Green
Write-Host ""

try {
    New-Item -ItemType Directory -Path $ProDir -Force | Out-Null

    # --------------------------------------------------------
    # MODULO PROFESIONAL
    # En memoria/local de pantalla. No toca SQLite.
    # --------------------------------------------------------
    $proCode = @'
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

class _ProfesionalScreenState extends State<ProfesionalScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final List<Map<String, String>> _cotizacionesData = [];
  final List<Map<String, String>> _creditosData = [];
  final List<Map<String, String>> _notasData = [];
  final List<Map<String, String>> _auditoriaData = [];

  double _cajaSaldo = 0;
  String _moneda = 'USD';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF11121A) : const Color(0xFFF5F6FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onAbrirSidebar,
        ),
        title: const Text('Módulo Profesional'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.request_quote_outlined), text: 'Cotizaciones'),
            Tab(icon: Icon(Icons.credit_card_outlined), text: 'Crédito'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Notas de crédito'),
            Tab(icon: Icon(Icons.point_of_sale_outlined), text: 'Caja'),
            Tab(icon: Icon(Icons.payments_outlined), text: 'Pagos mixtos'),
            Tab(icon: Icon(Icons.currency_exchange), text: 'Monedas'),
            Tab(icon: Icon(Icons.history), text: 'Auditoría'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildCotizaciones(),
          _buildCredito(),
          _buildNotasCredito(),
          _buildCaja(),
          _buildPagosMixtos(),
          _buildMonedas(),
          _buildAuditoria(),
        ],
      ),
    );
  }

  Widget _panel({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildCotizaciones() {
    return _panel(
      title: 'Cotizaciones',
      icon: Icons.request_quote_outlined,
      action: FilledButton.icon(
        onPressed: _nuevaCotizacion,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      child: _cotizacionesData.isEmpty
          ? _empty('No hay cotizaciones creadas.')
          : ListView.builder(
              itemCount: _cotizacionesData.length,
              itemBuilder: (_, i) {
                final item = _cotizacionesData[i];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.request_quote_outlined),
                  ),
                  title: Text(item['cliente'] ?? 'Cliente'),
                  subtitle: Text(item['detalle'] ?? ''),
                  trailing: Text(item['total'] ?? '0.00'),
                );
              },
            ),
    );
  }

  Future<void> _nuevaCotizacion() async {
    final cliente = TextEditingController();
    final detalle = TextEditingController();
    final total = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _FormDialog(
        title: 'Nueva cotización',
        fields: [
          _F('Cliente', cliente),
          _F('Detalle', detalle),
          _F('Total', total, keyboard: TextInputType.number),
        ],
        onSave: () => {
          'cliente': cliente.text.trim().isEmpty ? 'Cliente' : cliente.text.trim(),
          'detalle': detalle.text.trim(),
          'total': total.text.trim().isEmpty ? '0.00' : total.text.trim(),
        },
      ),
    );

    cliente.dispose();
    detalle.dispose();
    total.dispose();

    if (!mounted || result == null) return;
    setState(() => _cotizacionesData.add(result));
    _registrar('Nueva cotización');
  }

  Widget _buildCredito() {
    return _panel(
      title: 'Crédito',
      icon: Icons.credit_card_outlined,
      action: FilledButton.icon(
        onPressed: _nuevoCredito,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      child: _creditosData.isEmpty
          ? _empty('No hay créditos registrados.')
          : ListView.builder(
              itemCount: _creditosData.length,
              itemBuilder: (_, i) {
                final item = _creditosData[i];
                return ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(item['cliente'] ?? 'Cliente'),
                  subtitle: Text('Vencimiento: ${item['vencimiento'] ?? ''}'),
                  trailing: Text(item['monto'] ?? '0.00'),
                );
              },
            ),
    );
  }

  Future<void> _nuevoCredito() async {
    final cliente = TextEditingController();
    final monto = TextEditingController();
    final vencimiento = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _FormDialog(
        title: 'Nuevo crédito',
        fields: [
          _F('Cliente', cliente),
          _F('Monto', monto, keyboard: TextInputType.number),
          _F('Vencimiento', vencimiento),
        ],
        onSave: () => {
          'cliente': cliente.text.trim().isEmpty ? 'Cliente' : cliente.text.trim(),
          'monto': monto.text.trim().isEmpty ? '0.00' : monto.text.trim(),
          'vencimiento': vencimiento.text.trim(),
        },
      ),
    );

    cliente.dispose();
    monto.dispose();
    vencimiento.dispose();

    if (!mounted || result == null) return;
    setState(() => _creditosData.add(result));
    _registrar('Nuevo crédito');
  }

  Widget _buildNotasCredito() {
    return _panel(
      title: 'Notas de crédito',
      icon: Icons.receipt_long_outlined,
      action: FilledButton.icon(
        onPressed: _nuevaNota,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      child: _notasData.isEmpty
          ? _empty('No hay notas de crédito.')
          : ListView.builder(
              itemCount: _notasData.length,
              itemBuilder: (_, i) {
                final item = _notasData[i];
                return ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text(item['motivo'] ?? 'Nota'),
                  trailing: Text(item['monto'] ?? '0.00'),
                );
              },
            ),
    );
  }

  Future<void> _nuevaNota() async {
    final motivo = TextEditingController();
    final monto = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _FormDialog(
        title: 'Nueva nota de crédito',
        fields: [
          _F('Motivo', motivo),
          _F('Monto', monto, keyboard: TextInputType.number),
        ],
        onSave: () => {
          'motivo': motivo.text.trim().isEmpty ? 'Sin motivo' : motivo.text.trim(),
          'monto': monto.text.trim().isEmpty ? '0.00' : monto.text.trim(),
        },
      ),
    );

    motivo.dispose();
    monto.dispose();

    if (!mounted || result == null) return;
    setState(() => _notasData.add(result));
    _registrar('Nueva nota de crédito');
  }

  Widget _buildCaja() {
    return _panel(
      title: 'Caja',
      icon: Icons.point_of_sale_outlined,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            '${_cajaSaldo.toStringAsFixed(2)} $_moneda',
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _abrirCaja,
                icon: const Icon(Icons.lock_open),
                label: const Text('Abrir caja'),
              ),
              OutlinedButton.icon(
                onPressed: _cerrarCaja,
                icon: const Icon(Icons.lock),
                label: const Text('Cerrar caja'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _abrirCaja() {
    setState(() => _cajaSaldo = 0);
    _registrar('Caja abierta');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caja abierta')),
    );
  }

  void _cerrarCaja() {
    _registrar('Caja cerrada');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caja cerrada')),
    );
  }

  Widget _buildPagosMixtos() {
    return _panel(
      title: 'Pagos mixtos',
      icon: Icons.payments_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribuye un pago entre varios métodos.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _pagoMixto,
            icon: const Icon(Icons.add_card),
            label: const Text('Registrar pago mixto'),
          ),
        ],
      ),
    );
  }

  Future<void> _pagoMixto() async {
    final monto = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pago mixto'),
        content: TextField(
          controller: monto,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monto total',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, monto.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    monto.dispose();

    if (!mounted || result == null) return;
    _registrar('Pago mixto: $result');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pago mixto registrado')),
    );
  }

  Widget _buildMonedas() {
    return _panel(
      title: 'Monedas',
      icon: Icons.currency_exchange,
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Dólar estadounidense'),
            subtitle: const Text('USD'),
            trailing: Radio<String>(
              value: 'USD',
              groupValue: _moneda,
              onChanged: (v) {
                if (v != null) setState(() => _moneda = v);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.euro),
            title: const Text('Euro'),
            subtitle: const Text('EUR'),
            trailing: Radio<String>(
              value: 'EUR',
              groupValue: _moneda,
              onChanged: (v) {
                if (v != null) setState(() => _moneda = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditoria() {
    return _panel(
      title: 'Auditoría',
      icon: Icons.history,
      child: _auditoriaData.isEmpty
          ? _empty('No hay movimientos registrados.')
          : ListView.builder(
              itemCount: _auditoriaData.length,
              itemBuilder: (_, i) {
                final item = _auditoriaData[i];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(item['accion'] ?? ''),
                  subtitle: Text(item['fecha'] ?? ''),
                );
              },
            ),
    );
  }

  void _registrar(String accion) {
    setState(() {
      _auditoriaData.insert(0, {
        'accion': accion,
        'fecha': DateTime.now().toString(),
      });
    });
  }
}

class _F {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;

  _F(this.label, this.controller, {this.keyboard});
}

class _FormDialog extends StatelessWidget {
  final String title;
  final List<_F> fields;
  final Map<String, String> Function() onSave;

  const _FormDialog({
    required this.title,
    required this.fields,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fields
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: f.controller,
                      keyboardType: f.keyboard,
                      decoration: InputDecoration(
                        labelText: f.label,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, onSave());
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
'@

    # La advertencia del instalador anterior venía de este parametro.
    # Aquí se usa realmente, así que no queda warning de parametro no usado.
    if ($proCode -match "final List<Map<String, String>> _cotizaciones = \[\];" -or
        $proCode -match "double _caja = 0;" -or
        $proCode -match "Widget _cotizaciones\(\)" -or
        $proCode -match "Widget _caja\(\)") {
        throw "La plantilla profesional contiene nombres duplicados; instalacion cancelada."
    }

    Set-Content -Path $Pro -Value $proCode -Encoding UTF8

    $activatorCode = @'
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
    Set-Content -Path $Activator -Value $activatorCode -Encoding UTF8

    # --------------------------------------------------------
    # MAIN.DART
    # --------------------------------------------------------
    $mainText = Get-Content $Main -Raw

    if ($mainText -notmatch "profesional/pro_features\.dart") {
        $mainText = $mainText -replace "(?m)^import ", "import 'profesional/pro_features.dart';`r`nimport ", 1
    }

    if ($mainText -notmatch "ProfesionalScreen\(") {
        $needle = "EstadisticasScreen(`r`n                      onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),"
        $insert = @"
EstadisticasScreen(
                      onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  ProfesionalScreen(
                    onAbrirSidebar: _abrirSidebar,
                    modoOscuro: _modoOscuro,
                  ),
"@
        if ($mainText.Contains($needle)) {
            $mainText = $mainText.Replace($needle, $insert.TrimEnd())
        } else {
            # Fallback: inserta después del primer bloque de EstadisticasScreen.
            $pattern = "(EstadisticasScreen\([\s\S]*?modoOscuro: _modoOscuro\),)"
            $match = [regex]::Match($mainText, $pattern)
            if (-not $match.Success) {
                throw "No pude localizar EstadisticasScreen en main.dart. No se modifico la integracion."
            }
            $replacement = $match.Groups[1].Value + @"
                  ProfesionalScreen(
                    onAbrirSidebar: _abrirSidebar,
                    modoOscuro: _modoOscuro,
                  ),
"@
            $mainText = $mainText.Remove($match.Index, $match.Length).Insert($match.Index, $replacement)
        }
    }

    if ($mainText -notmatch "'profesional'") {
        $mainText = $mainText -replace "('estadisticas',)", "'estadisticas',`r`n      'profesional',", 1
    }

    if ($mainText -notmatch "'profesional'\s*:\s*23") {
        $mainText = $mainText -replace "('estadisticas'\s*:\s*22,)", "'estadisticas': 22,`r`n      'profesional': 23,", 1
    }

    Set-Content -Path $Main -Value $mainText -Encoding UTF8

    Write-Host ""
    Write-Host "Archivos instalados. Formateando..." -ForegroundColor Yellow

    & dart format $Pro $Activator $Main
    if ($LASTEXITCODE -ne 0) {
        throw "dart format fallo."
    }

    # --------------------------------------------------------
    # VERIFICACION REAL
    # Flutter analyze devuelve warnings/info como salida no fatal.
    # El criterio aqui es buscar errores Dart reales.
    # --------------------------------------------------------
    Write-Host ""
    Write-Host "Verificando modulo profesional..." -ForegroundColor Yellow

    # IMPORTANTE:
    # flutter analyze puede devolver codigo de salida distinto de 0
    # solamente por warnings/info. Por eso NO usamos $LASTEXITCODE
    # como criterio de fallo. Capturamos toda la salida y buscamos
    # un error Dart real.
    $proAnalyze = cmd.exe /c "flutter analyze `"$Pro`" 2>&1"
    $proText = ($proAnalyze | Out-String)
    Write-Host $proText

    if ($proText -match "(?m)^\s*error\s*-\s") {
        throw "El modulo profesional tiene errores Dart reales."
    }

    Write-Host "Modulo profesional: OK (sin errores Dart)" -ForegroundColor Green

    Write-Host ""
    Write-Host "Verificando main.dart..." -ForegroundColor Yellow

    $mainAnalyze = cmd.exe /c "flutter analyze `"$Main`" 2>&1"
    $mainText = ($mainAnalyze | Out-String)
    Write-Host $mainText

    if ($mainText -match "(?m)^\s*error\s*-\s") {
        throw "main.dart tiene errores Dart reales."
    }

    Write-Host "main.dart: OK (sin errores Dart)" -ForegroundColor Green

    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host " INSTALACION TERMINADA CORRECTAMENTE" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Backup guardado en:"
    Write-Host $BackupDir -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Ahora puedes ejecutar:"
    Write-Host "flutter run -d chrome" -ForegroundColor White
    Write-Host ""

}
catch {
    Write-Host ""
    Write-Host "FALLO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "RESTAURANDO archivos del backup..." -ForegroundColor Yellow

    if (Test-Path (Join-Path $BackupDir "main.dart")) {
        Copy-Item (Join-Path $BackupDir "main.dart") $Main -Force
    }
    if (Test-Path (Join-Path $BackupDir "pro_features.dart")) {
        Copy-Item (Join-Path $BackupDir "pro_features.dart") $Pro -Force
    }
    if (Test-Path (Join-Path $BackupDir "profesional_activator.dart")) {
        Copy-Item (Join-Path $BackupDir "profesional_activator.dart") $Activator -Force
    }

    Write-Host "RESTAURACION TERMINADA." -ForegroundColor Green
    Write-Host "Backup utilizado: $BackupDir" -ForegroundColor Cyan
    exit 1
}
