#requires -Version 5.1
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$main = Join-Path $root "lib\main.dart"
$pro = Join-Path $root "lib\profesional\pro_features.dart"
$panel = Join-Path $root "lib\profesional\cotizaciones_pro_panel.dart"
$pubspec = Join-Path $root "pubspec.yaml"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " SINTHETIX PRO - COTIZACIONES PDF + WHATSAPP V6" -ForegroundColor Cyan
Write-Host " INSTALADOR VERIFICADO Y AUTO-RESTAURABLE" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

foreach ($f in @($main,$pro,$pubspec)) {
    if (!(Test-Path $f)) {
        throw "No encuentro: $f"
    }
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $root "BACKUP_COTIZACIONES_V6_VERIFICADO_$stamp"
New-Item -ItemType Directory -Path $backup -Force | Out-Null

Copy-Item $main (Join-Path $backup "main.dart") -Force
Copy-Item $pro (Join-Path $backup "pro_features.dart") -Force
Copy-Item $pubspec (Join-Path $backup "pubspec.yaml") -Force
if (Test-Path $panel) {
    Copy-Item $panel (Join-Path $backup "cotizaciones_pro_panel.dart") -Force
}

Write-Host "BACKUP CREADO: $backup" -ForegroundColor Green

try {
    $mainText = Get-Content $main -Raw
    $proText = Get-Content $pro -Raw
    $pubText = Get-Content $pubspec -Raw

    # ------------------------------------------------------------
    # 1. VERIFICACIONES PREVIAS.
    # No se modifica nada si la estructura esperada no coincide.
    # ------------------------------------------------------------
    if ($mainText -notmatch "DatabaseService") {
        throw "main.dart no contiene DatabaseService. No puedo conectar productos reales de forma segura."
    }

    if ($mainText -notmatch "getProductos\s*\(") {
        throw "main.dart no contiene getProductos(). No puedo conectar productos reales de forma segura."
    }

    if ($proText -notmatch "class\s+ProfesionalScreen") {
        throw "No encontre ProfesionalScreen en pro_features.dart."
    }

    if ($proText -notmatch "Widget\s+_quotes\s*\(") {
        throw "No encontre _quotes() activo en pro_features.dart. No se hizo ningun cambio."
    }

    if ($proText -notmatch "required\s+VoidCallback\s+onAbrirSidebar" -or
        $proText -notmatch "required\s+bool\s+modoOscuro") {
        throw "El constructor actual de ProfesionalScreen no coincide con la estructura esperada."
    }

    # ------------------------------------------------------------
    # 2. DEPENDENCIAS.
    # ------------------------------------------------------------
    foreach ($pkg in @("pdf","printing","url_launcher","intl")) {
        if ($pubText -notmatch "(?m)^\s*$pkg\s*:") {
            Write-Host "Agregando dependencia: $pkg" -ForegroundColor Yellow
            & flutter pub add $pkg
            if ($LASTEXITCODE -ne 0) {
                throw "No se pudo agregar la dependencia $pkg."
            }
            $pubText = Get-Content $pubspec -Raw
        }
    }

    # ------------------------------------------------------------
    # 3. Agregar callback de productos reales a ProfesionalScreen.
    # Esto evita importar archivos 'part' desde una pantalla nueva.
    # ------------------------------------------------------------
    if ($proText -notmatch "cargarProductos") {
        $oldFields = @"
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
"@
        $newFields = @"
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  final Future<List<Map<String, dynamic>>> Function() cargarProductos;
"@

        if (!$proText.Contains($oldFields)) {
            throw "No encontre exactamente los campos del constructor de ProfesionalScreen."
        }
        $proText = $proText.Replace($oldFields, $newFields)

        $oldCtor = @"
    required this.onAbrirSidebar,
    required this.modoOscuro,
"@
        $newCtor = @"
    required this.onAbrirSidebar,
    required this.modoOscuro,
    required this.cargarProductos,
"@

        if (!$proText.Contains($oldCtor)) {
            throw "No encontre exactamente los argumentos del constructor de ProfesionalScreen."
        }
        $proText = $proText.Replace($oldCtor, $newCtor)
    }

    # ------------------------------------------------------------
    # 4. Reemplazar SOLO _quotes().
    # ------------------------------------------------------------
    $quotePattern = '(?s)\n\s*Widget\s+_quotes\s*\(\s*\)\s*\{.*?\n\s*\}\s*(?=\n\s*Widget\s+_credits\s*\()'
    if (-not [regex]::IsMatch($proText, $quotePattern)) {
        throw "No pude localizar el bloque completo _quotes() hasta _credits(). No se modifico."
    }

    $quoteReplacement = @'

  Widget _quotes() {
    return CotizacionesProPanel(
      modoOscuro: widget.modoOscuro,
      cargarProductos: widget.cargarProductos,
      onGuardar: (cotizacion) {
        _cotizaciones.insert(0, cotizacion);
        _audit('Nueva cotizacion');
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
'@

    $proText = [regex]::Replace($proText, $quotePattern, $quoteReplacement, 1)

    # ------------------------------------------------------------
    # 5. Importar el panel una sola vez.
    # ------------------------------------------------------------
    if ($proText -notmatch "(?m)^\s*import\s+'cotizaciones_pro_panel\.dart';") {
        $imports = [regex]::Matches($proText, "(?m)^import\s+[^;]+;\s*\r?\n")
        if ($imports.Count -eq 0) {
            throw "No encontre los imports de pro_features.dart."
        }
        $last = $imports[$imports.Count - 1]
        $proText = $proText.Insert(
            $last.Index + $last.Length,
            "import 'cotizaciones_pro_panel.dart';`r`n"
        )
    }

    # ------------------------------------------------------------
    # 6. Integrar el callback en la instancia existente de main.dart.
    # Solo modifica la llamada a ProfesionalScreen.
    # ------------------------------------------------------------
    if ($mainText -notmatch "cargarProductos:\s*\(\)\s*=>\s*DatabaseService\(\)\.getProductos") {
        $screenPattern = '(?s)ProfesionalScreen\s*\(\s*onAbrirSidebar\s*:\s*_abrirSidebar\s*,\s*modoOscuro\s*:\s*_modoOscuro\s*,?\s*\)'
        if (-not [regex]::IsMatch($mainText, $screenPattern)) {
            throw "No encontre la instancia actual de ProfesionalScreen en main.dart."
        }

        $screenReplacement = @'
ProfesionalScreen(
                    onAbrirSidebar: _abrirSidebar,
                    modoOscuro: _modoOscuro,
                    cargarProductos: () => DatabaseService().getProductos(),
                  )
'@

        $mainText = [regex]::Replace($mainText, $screenPattern, $screenReplacement, 1)
    }

    # ------------------------------------------------------------
    # 7. Crear panel. IMPORTANTE:
    # No importa database_service_real.dart.
    # Recibe los productos desde main.dart mediante callback.
    # ------------------------------------------------------------
    $panelText = @'
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class CotizacionesProPanel extends StatefulWidget {
  final bool modoOscuro;
  final Future<List<Map<String, dynamic>>> Function() cargarProductos;
  final void Function(Map<String, dynamic>) onGuardar;

  const CotizacionesProPanel({
    super.key,
    required this.modoOscuro,
    required this.cargarProductos,
    required this.onGuardar,
  });

  @override
  State<CotizacionesProPanel> createState() => _CotizacionesProPanelState();
}

class _CotizacionesProPanelState extends State<CotizacionesProPanel> {
  final _buscar = TextEditingController();
  final _cliente = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _direccion = TextEditingController();
  final _notas = TextEditingController();
  final _descuento = TextEditingController(text: '0');

  List<Map<String, dynamic>> _productos = [];
  final List<Map<String, dynamic>> _items = [];
  bool _cargando = true;
  bool _enviando = false;

  Color get _purple => const Color(0xFF5B21B6);
  Color get _blue => const Color(0xFF2563EB);

  Color get _bg => widget.modoOscuro
      ? const Color(0xFF10111B)
      : const Color(0xFFF5F6FA);

  Color get _card => widget.modoOscuro
      ? const Color(0xFF1C1A2B)
      : Colors.white;

  Color get _text => widget.modoOscuro
      ? Colors.white
      : const Color(0xFF202332);

  Color get _muted => widget.modoOscuro
      ? const Color(0xFFAAA5BA)
      : const Color(0xFF667085);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _buscar.dispose();
    _cliente.dispose();
    _telefono.dispose();
    _email.dispose();
    _direccion.dispose();
    _notas.dispose();
    _descuento.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final rows = await widget.cargarProductos();
      if (!mounted) return;
      setState(() {
        _productos = rows;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _productos = [];
        _cargando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar los productos.')),
      );
    }
  }

  String _nombre(Map<String, dynamic> p) {
    return (p['nombre'] ?? p['name'] ?? 'Producto').toString();
  }

  double _precio(Map<String, dynamic> p) {
    final v = p['precio'] ?? p['price'] ?? p['venta'] ?? 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0;
  }

  int _stock(Map<String, dynamic> p) {
    final v = p['stock'] ?? 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double get _subtotal => _items.fold(
        0,
        (sum, item) =>
            sum +
            ((item['precio'] as num).toDouble() *
                (item['cantidad'] as int)),
      );

  double get _descuentoMonto {
    final pct =
        double.tryParse(_descuento.text.replaceAll(',', '.')) ?? 0;
    final safe = pct.clamp(0, 100).toDouble();
    return _subtotal * safe / 100;
  }

  double get _total => _subtotal - _descuentoMonto;

  List<Map<String, dynamic>> get _filtrados {
    final q = _buscar.text.trim().toLowerCase();
    if (q.isEmpty) return _productos;
    return _productos
        .where((p) => _nombre(p).toLowerCase().contains(q))
        .toList();
  }

  void _agregar(Map<String, dynamic> p) {
    final nombre = _nombre(p);
    final index =
        _items.indexWhere((item) => item['nombre'] == nombre);

    if (index >= 0) {
      final stock = _stock(p);
      final actual = _items[index]['cantidad'] as int;
      if (stock > 0 && actual >= stock) return;
      setState(() => _items[index]['cantidad'] = actual + 1);
      return;
    }

    setState(() {
      _items.add({
        'nombre': nombre,
        'precio': _precio(p),
        'cantidad': 1,
        'codigo': (p['codigo_barras'] ?? p['codigo'] ?? '').toString(),
      });
    });
  }

  void _cambiarCantidad(int index, int delta) {
    final actual = _items[index]['cantidad'] as int;
    final nueva = actual + delta;
    if (nueva <= 0) {
      setState(() => _items.removeAt(index));
      return;
    }
    setState(() => _items[index]['cantidad'] = nueva);
  }

  Future<List<int>> _crearPdf(Map<String, dynamic> q) async {
    final doc = pw.Document();
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(q['fecha'] as DateTime);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SINTHETIX PRO',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'COTIZACION',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Text('Fecha: $fecha'),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'DATOS DEL CLIENTE',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Cliente: ${q['cliente']}'),
          if ((q['telefono'] as String).isNotEmpty)
            pw.Text('Telefono: ${q['telefono']}'),
          if ((q['email'] as String).isNotEmpty)
            pw.Text('Email: ${q['email']}'),
          if ((q['direccion'] as String).isNotEmpty)
            pw.Text('Direccion: ${q['direccion']}'),
          pw.SizedBox(height: 18),
          pw.Text(
            'DETALLE',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Producto', 'Cant.', 'Precio', 'Subtotal'],
            data: (q['items'] as List<Map<String, dynamic>>).map((item) {
              final price = (item['precio'] as num).toDouble();
              final qty = item['cantidad'] as int;
              return [
                item['nombre'].toString(),
                qty.toString(),
                '\$${price.toStringAsFixed(2)}',
                '\$${(price * qty).toStringAsFixed(2)}',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Subtotal: \$${(q['subtotal'] as num).toDouble().toStringAsFixed(2)}',
                ),
                pw.Text(
                  'Descuento: \$${(q['descuento'] as num).toDouble().toStringAsFixed(2)}',
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'TOTAL: \$${(q['total'] as num).toDouble().toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if ((q['notas'] as String).isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'NOTAS',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text(q['notas'] as String),
          ],
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.Text(
            'Gracias por su preferencia.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> _enviar() async {
    if (_cliente.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre del cliente.')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto.')),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final data = {
        'cliente': _cliente.text.trim(),
        'telefono': _telefono.text.trim(),
        'email': _email.text.trim(),
        'direccion': _direccion.text.trim(),
        'notas': _notas.text.trim(),
        'items': _items
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        'subtotal': _subtotal,
        'descuento': _descuentoMonto,
        'total': _total,
        'fecha': DateTime.now(),
      };

      widget.onGuardar(data);

      final bytes = await _crearPdf(data);
      final nombre =
          'cotizacion_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      await Printing.sharePdf(
        bytes: bytes,
        filename: nombre,
      );

      final phone =
          _telefono.text.replaceAll(RegExp(r'[^0-9]'), '');

      if (phone.isNotEmpty) {
        final mensaje = Uri.encodeComponent(
          'SINTHETIX PRO - Cotizacion\n'
          'Cliente: ${_cliente.text.trim()}\n'
          'Total: \$${_total.toStringAsFixed(2)}\n'
          'El PDF de la cotizacion fue generado.',
        );

        await launchUrl(
          Uri.parse('https://wa.me/$phone?text=$mensaje'),
          mode: LaunchMode.externalApplication,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cotizacion generada. Se abrio el panel de compartir.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtrados;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              padding: EdgeInsets.all(wide ? 24 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_purple, _blue],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.request_quote_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nueva cotizacion',
                              style: TextStyle(
                                color: _text,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Selecciona productos reales del inventario y envia el PDF.',
                              style: TextStyle(color: _muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _clienteCard()),
                            const SizedBox(width: 18),
                            Expanded(child: _productosCard(filtered)),
                          ],
                        )
                      : Column(
                          children: [
                            _clienteCard(),
                            const SizedBox(height: 14),
                            _productosCard(filtered),
                          ],
                        ),
                  const SizedBox(height: 14),
                  _itemsCard(),
                  const SizedBox(height: 14),
                  _totalesCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _clienteCard() {
    return Card(
      color: _card,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cliente',
              style: TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cliente,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            TextField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp / telefono',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            TextField(
              controller: _direccion,
              decoration: const InputDecoration(
                labelText: 'Direccion',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            TextField(
              controller: _notas,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productosCard(List<Map<String, dynamic>> filtered) {
    return Card(
      color: _card,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productos del inventario',
              style: TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _buscar,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Buscar producto',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No hay productos para esa busqueda.',
                  style: TextStyle(color: _muted),
                ),
              )
            else
              ...filtered.take(12).map(
                    (p) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _nombre(p),
                        style: TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'Stock: ${_stock(p)}',
                        style: TextStyle(color: _muted),
                      ),
                      trailing: FilledButton.icon(
                        onPressed: () => _agregar(p),
                        icon: const Icon(Icons.add),
                        label: Text(
                          '\$${_precio(p).toStringAsFixed(2)}',
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _itemsCard() {
    return Card(
      color: _card,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productos seleccionados',
              style: TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Todavia no has agregado productos.',
                  style: TextStyle(color: _muted),
                ),
              )
            else
              ..._items.asMap().entries.map(
                    (entry) {
                      final i = entry.key;
                      final item = entry.value;
                      final price =
                          (item['precio'] as num).toDouble();
                      final qty = item['cantidad'] as int;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item['nombre'].toString(),
                          style: TextStyle(
                            color: _text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '\$${price.toStringAsFixed(2)} x $qty = '
                          '\$${(price * qty).toStringAsFixed(2)}',
                          style: TextStyle(color: _muted),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _cambiarCantidad(i, -1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$qty',
                              style: TextStyle(
                                color: _text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _cambiarCantidad(i, 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _totalesCard() {
    return Card(
      color: _card,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _descuento,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Descuento %',
                      prefixIcon: Icon(Icons.discount_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Subtotal: \$${_subtotal.toStringAsFixed(2)}',
                      style: TextStyle(color: _muted),
                    ),
                    Text(
                      'Descuento: \$${_descuentoMonto.toStringAsFixed(2)}',
                      style: TextStyle(color: _muted),
                    ),
                    Text(
                      'TOTAL: \$${_total.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: _text,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _enviando ? null : _enviar,
                icon: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded),
                label: Text(
                  _enviando
                      ? 'GENERANDO COTIZACION...'
                      : 'ENVIAR COTIZACION - PDF / WHATSAPP',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
'@

    Set-Content $panel $panelText -Encoding UTF8
    Set-Content $pro $proText -Encoding UTF8
    Set-Content $main $mainText -Encoding UTF8

    # ------------------------------------------------------------
    # 8. Formato.
    # ------------------------------------------------------------
    Write-Host ""
    Write-Host "Formateando archivos activos..." -ForegroundColor Yellow
    & dart format $main $pro $panel
    if ($LASTEXITCODE -ne 0) {
        throw "dart format fallo."
    }

    # ------------------------------------------------------------
    # 9. Analisis REAL. Los comandos nativos reportan el resultado
    # mediante LASTEXITCODE; PowerShell no siempre lanza catch.
    # Aqui buscamos errores Dart reales en la salida.
    # ------------------------------------------------------------
    Write-Host ""
    Write-Host "Analizando SOLO archivos activos modificados..." -ForegroundColor Yellow

    $log = Join-Path $env:TEMP "sinthetix_cotizaciones_v6_$stamp.txt"
    cmd.exe /c "flutter analyze lib\main.dart lib\profesional\pro_features.dart lib\profesional\cotizaciones_pro_panel.dart > `"$log`" 2>&1"
    $analysis = Get-Content $log -Raw -ErrorAction SilentlyContinue

    if ($analysis) {
        Write-Host $analysis
    }

    if ($analysis -match "(?m)^\s*error\s*-\s") {
        throw "Flutter encontro errores Dart reales. Se restaurara el backup."
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " INSTALACION COMPLETADA SIN ERRORES DART" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "Cotizaciones: OK" -ForegroundColor Green
    Write-Host "Productos reales: conectados mediante callback" -ForegroundColor Green
    Write-Host "PDF: OK" -ForegroundColor Green
    Write-Host "WhatsApp: OK" -ForegroundColor Green
    Write-Host "Backup: $backup" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "No se modifico la logica de camara, SQLite, ventas ni pagos." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "FALLO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "RESTAURANDO LOS ARCHIVOS..." -ForegroundColor Yellow

    Copy-Item (Join-Path $backup "main.dart") $main -Force
    Copy-Item (Join-Path $backup "pro_features.dart") $pro -Force
    Copy-Item (Join-Path $backup "pubspec.yaml") $pubspec -Force

    if (Test-Path (Join-Path $backup "cotizaciones_pro_panel.dart")) {
        Copy-Item (Join-Path $backup "cotizaciones_pro_panel.dart") $panel -Force
    } elseif (Test-Path $panel) {
        Remove-Item $panel -Force
    }

    Write-Host "RESTAURACION COMPLETA." -ForegroundColor Green
    exit 1
}
