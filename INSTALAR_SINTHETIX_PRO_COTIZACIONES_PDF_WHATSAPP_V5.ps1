#requires -Version 5.1
$ErrorActionPreference = "Stop"

$root = (Get-Location).Path
$main = Join-Path $root "lib\main.dart"
$pro = Join-Path $root "lib\profesional\pro_features.dart"
$panel = Join-Path $root "lib\profesional\cotizaciones_pro_panel.dart"
$utf8 = New-Object System.Text.UTF8Encoding($false)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " SINTHETIX PRO - COTIZACIONES PROFESIONAL V5" -ForegroundColor Cyan
Write-Host " PRODUCTOS + CLIENTE + PDF + WHATSAPP + TEXTOS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $main)) { throw "No encuentro lib\main.dart." }
if (-not (Test-Path $pro)) { throw "No encuentro lib\profesional\pro_features.dart." }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $root "BACKUP_COTIZACION_V5_$stamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Copy-Item $main (Join-Path $backupDir "main.dart") -Force
Copy-Item $pro (Join-Path $backupDir "pro_features.dart") -Force
if (Test-Path $panel) { Copy-Item $panel (Join-Path $backupDir "cotizaciones_pro_panel.dart") -Force }

function U([int[]]$c) { return (-join ($c | ForEach-Object { [char]$_ })) }

try {
    Write-Host "[1/6] Backup creado." -ForegroundColor Green

    # Dependencias necesarias para PDF, compartir, WhatsApp y fechas.
    $pubspec = Join-Path $root "pubspec.yaml"
    $pub = [IO.File]::ReadAllText($pubspec,$utf8)
    foreach ($pkg in @("pdf","printing","url_launcher","intl")) {
        if ($pub -notmatch "(?m)^\s*$pkg\s*:") {
            Write-Host "Agregando $pkg..." -ForegroundColor Yellow
            & flutter pub add $pkg
            if ($LASTEXITCODE -ne 0) { throw "No se pudo agregar $pkg." }
            $pub = [IO.File]::ReadAllText($pubspec,$utf8)
        }
    }

    $proText = [IO.File]::ReadAllText($pro,$utf8)

    # Reparacion puntual de mojibake. NO se hace conversion masiva.
    $fixes = @(
        @((U @(0x00C3,0x0192,0x00C2,0x00A1)),(U @(0x00E1))),
        @((U @(0x00C3,0x0192,0x00C2,0x00A9)),(U @(0x00E9))),
        @((U @(0x00C3,0x0192,0x00C2,0x00AD)),(U @(0x00ED))),
        @((U @(0x00C3,0x0192,0x00C2,0x00B3)),(U @(0x00F3))),
        @((U @(0x00C3,0x0192,0x00C2,0x00BA)),(U @(0x00FA))),
        @((U @(0x00C3,0x0192,0x00C2,0x00B1)),(U @(0x00F1))),
        @((U @(0x00C3,0x0192,0x00C2,0x201C)),(U @(0x00D3))),
        @((U @(0x00C3,0x0192,0x00C2,0x00DA)),(U @(0x00DA))),
        @((U @(0x00C3,0x0192,0x00E2,0x20AC,0x02DC)),(U @(0x00D1))),
        @((U @(0x00C3,0x00A1)),(U @(0x00E1))),
        @((U @(0x00C3,0x00A9)),(U @(0x00E9))),
        @((U @(0x00C3,0x00AD)),(U @(0x00ED))),
        @((U @(0x00C3,0x00B3)),(U @(0x00F3))),
        @((U @(0x00C3,0x00BA)),(U @(0x00FA))),
        @((U @(0x00C3,0x00B1)),(U @(0x00F1))),
        @((U @(0x00C2,0x00A1)),(U @(0x00A1))),
        @((U @(0x00C2,0x00BF)),(U @(0x00BF))),
        @((U @(0x00C3,0x0192,0x00C2,0x00B3)),(U @(0x00F3))),
        @((U @(0x00C3,0x0192,0x00C2,0x00A9)),(U @(0x00E9))),
        @((U @(0x00C3,0x0192,0x00C2,0x00BA)),(U @(0x00FA))),
        @((U @(0x00C3,0x0192,0x00C2,0x00B1)),(U @(0x00F1))),
        @((U @(0x00C3,0x0192,0x00C2,0x00AD)),(U @(0x00ED))),
        @((U @(0x00C3,0x0192,0x00C2,0x00A1)),(U @(0x00E1))),
        @((U @(0x00C3,0x0192,0x00C2,0x00A9)),(U @(0x00E9))),
        @((U @(0x00C3,0x0192,0x00C2,0x00BF)),(U @(0x00BF))),
        @((U @(0x00C3,0x00A7)),(U @(0x00E7))),
        @((U @(0x00C3,0x0192,0x00E2,0x20AC,0x00A2,0x00AC,0x00C2,0x00A2)),(U @(0x0020,0x2022,0x0020))),
        @((U @(0x00C3,0x00A2,0x00E2,0x201A,0x00AC,0x00C2,0x00A2)),(U @(0x0020,0x2022,0x0020))),
        @((U @(0x00C3,0x00A2,0x00E2,0x201A,0x00AC,0x00C2,0x00A2)),(U @(0x0020,0x2022,0x0020)))
    )
    foreach ($p in $fixes) { $proText = $proText.Replace($p[0],$p[1]) }

    # El panel de Cotizaciones actual es el bloque _quotes().
    # Lo conservamos como punto de entrada y sustituimos solo su contenido.
    $quoteMethod = @'
  Widget _quotes() {
    return CotizacionesProPanel(modoOscuro: widget.modoOscuro);
  }

'@

    $pattern = '(?s)\n  Widget _quotes\(\) \{.*?\n  \}\n\n  Widget _credits'
    if (-not [regex]::IsMatch($proText,$pattern)) {
        throw "No encontre exactamente el bloque _quotes() de pro_features.dart. No se hizo ningun cambio."
    }
    $proText = [regex]::Replace($proText,$pattern,("`r`n" + $quoteMethod + "  Widget _credits"),1)

    # Importar el nuevo panel.
    if ($proText -notmatch "(?m)^\s*import\s+'cotizaciones_pro_panel\.dart';") {
        $imports = [regex]::Matches($proText,"(?m)^\s*import\s+[^;]+;\s*\r?\n")
        if ($imports.Count -eq 0) { throw "No encontre los imports de pro_features.dart." }
        $last = $imports[$imports.Count-1]
        $proText = $proText.Insert($last.Index + $last.Length,"import 'cotizaciones_pro_panel.dart';`r`n")
    }

    # Panel profesional. SOLO lee productos con DatabaseService.getProductos().
    $panelText = @'
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/database_service_real.dart';

class CotizacionesProPanel extends StatefulWidget {
  final bool modoOscuro;

  const CotizacionesProPanel({
    super.key,
    required this.modoOscuro,
  });

  @override
  State<CotizacionesProPanel> createState() => _CotizacionesProPanelState();
}

class _CotizacionesProPanelState extends State<CotizacionesProPanel> {
  final DatabaseService _db = DatabaseService();

  final _buscar = TextEditingController();
  final _cliente = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();
  final _direccion = TextEditingController();
  final _notas = TextEditingController();

  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _filtrados = [];
  final List<Map<String, dynamic>> _items = [];

  bool _cargando = true;
  bool _enviando = false;
  double _descuento = 0;

  Color get _violeta => const Color(0xFF5B21B6);
  Color get _azul => const Color(0xFF2563EB);
  Color get _fondo => widget.modoOscuro
      ? const Color(0xFF10111B)
      : const Color(0xFFF5F6FA);
  Color get _tarjeta => widget.modoOscuro
      ? const Color(0xFF1B1930)
      : Colors.white;
  Color get _texto => widget.modoOscuro
      ? Colors.white
      : const Color(0xFF202332);
  Color get _suave => widget.modoOscuro
      ? const Color(0xFFAAA4BA)
      : const Color(0xFF667085);

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  @override
  void dispose() {
    _buscar.dispose();
    _cliente.dispose();
    _telefono.dispose();
    _correo.dispose();
    _direccion.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    try {
      final rows = await _db.getProductos();
      if (!mounted) return;
      setState(() {
        _productos = rows;
        _filtrados = rows;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _aviso('No se pudieron cargar los productos.');
    }
  }

  double _precio(Map<String, dynamic> p) {
    return (p['precio'] as num? ?? p['price'] as num? ?? 0).toDouble();
  }

  void _buscarProductos(String value) {
    final q = value.trim().toLowerCase();
    setState(() {
      _filtrados = q.isEmpty
          ? _productos
          : _productos.where((p) {
              final nombre =
                  (p['nombre'] ?? '').toString().toLowerCase();
              final codigo =
                  (p['codigo_barras'] ?? '').toString().toLowerCase();
              final marca =
                  (p['marca'] ?? '').toString().toLowerCase();
              return nombre.contains(q) ||
                  codigo.contains(q) ||
                  marca.contains(q);
            }).toList();
    });
  }

  void _agregar(Map<String, dynamic> p) {
    final id =
        (p['id'] ?? p['codigo_barras'] ?? p['nombre']).toString();
    final i = _items.indexWhere((x) => x['_id'] == id);

    setState(() {
      if (i >= 0) {
        _items[i]['cantidad'] = (_items[i]['cantidad'] as int) + 1;
      } else {
        _items.add({
          '_id': id,
          'nombre': (p['nombre'] ?? 'Producto').toString(),
          'codigo': (p['codigo_barras'] ?? '').toString(),
          'precio': _precio(p),
          'cantidad': 1,
        });
      }
    });
  }

  void _cantidad(int i, int delta) {
    setState(() {
      final nueva = (_items[i]['cantidad'] as int) + delta;
      if (nueva <= 0) {
        _items.removeAt(i);
      } else {
        _items[i]['cantidad'] = nueva;
      }
    });
  }

  double _linea(Map<String, dynamic> x) =>
      (x['precio'] as double) * (x['cantidad'] as int);

  double get _subtotal => _items.fold(0, (s, x) => s + _linea(x));
  double get _descuentoMonto => _subtotal * (_descuento / 100);
  double get _total => _subtotal - _descuentoMonto;

  String _numero() =>
      'COT-${DateTime.now().millisecondsSinceEpoch}';

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _violeta,
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _violeta),
      filled: true,
      fillColor: widget.modoOscuro
          ? const Color(0xFF24203B)
          : const Color(0xFFF7F5FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<Uint8List> _crearPdf(String numero) async {
    final doc = pw.Document();
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final violeta = PdfColor.fromHex('#5B21B6');
    final azul = PdfColor.fromHex('#2563EB');
    final claro = PdfColor.fromHex('#F4F3FF');

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: violeta,
              borderRadius: pw.BorderRadius.circular(14),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SINTHETIX PRO',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'COTIZACION COMERCIAL',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  numero,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            color: claro,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CLIENTE',
                  style: pw.TextStyle(
                    color: violeta,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _cliente.text.trim().isEmpty
                      ? 'Cliente general'
                      : _cliente.text.trim(),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (_telefono.text.trim().isNotEmpty)
                  pw.Text('WhatsApp: ${_telefono.text.trim()}'),
                if (_correo.text.trim().isNotEmpty)
                  pw.Text(_correo.text.trim()),
                if (_direccion.text.trim().isNotEmpty)
                  pw.Text(_direccion.text.trim()),
                pw.Text('Fecha: $fecha'),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Table(
            border: pw.TableBorder(
              horizontalInside:
                  pw.BorderSide(color: PdfColors.grey300, width: .5),
            ),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: claro),
                children: [
                  _celda('PRODUCTO', true, violeta),
                  _celda('CANT.', true, violeta),
                  _celda('PRECIO', true, violeta),
                  _celda('TOTAL', true, violeta),
                ],
              ),
              ..._items.map(
                (x) => pw.TableRow(
                  children: [
                    _celda(x['nombre'].toString(), false, null),
                    _celda('${x['cantidad']}', false, null),
                    _celda(
                      '\$${(x['precio'] as double).toStringAsFixed(2)}',
                      false,
                      null,
                    ),
                    _celda(
                      '\$${_linea(x).toStringAsFixed(2)}',
                      false,
                      null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 230,
              padding: const pw.EdgeInsets.all(14),
              color: claro,
              child: pw.Column(
                children: [
                  _filaPdf('Subtotal', _subtotal),
                  _filaPdf('Descuento', _descuentoMonto),
                  pw.Divider(),
                  _filaPdf('TOTAL', _total, grande: true),
                ],
              ),
            ),
          ),
          if (_notas.text.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 18),
              child: pw.Text('Notas: ${_notas.text.trim()}'),
            ),
          pw.SizedBox(height: 28),
          pw.Divider(),
          pw.Center(
            child: pw.Text(
              'Gracias por preferir SINTHETIX PRO',
              style: pw.TextStyle(
                color: azul,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _celda(String texto, bool bold, PdfColor? color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(7),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight:
              bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  pw.Widget _filaPdf(
    String texto,
    double valor, {
    bool grande = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            texto,
            style: pw.TextStyle(
              fontSize: grande ? 12 : 9,
              fontWeight:
                  grande ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            '\$${valor.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: grande ? 15 : 9,
              fontWeight:
                  grande ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarCotizacion() async {
    if (_items.isEmpty) {
      _aviso('Agrega productos antes de enviar la cotizacion.');
      return;
    }

    setState(() => _enviando = true);

    try {
      final numero = _numero();
      final bytes = await _crearPdf(numero);

      await Printing.sharePdf(
        bytes: bytes,
        filename: '$numero.pdf',
        subject: 'Cotizacion $numero - SINTHETIX PRO',
      );

      _aviso(
        'PDF listo para compartir. En Android selecciona WhatsApp.',
      );
    } catch (_) {
      _aviso('No se pudo preparar el PDF.');
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  Future<void> _abrirWhatsApp() async {
    final telefono =
        _telefono.text.replaceAll(RegExp(r'[^0-9]'), '');

    final mensaje = Uri.encodeComponent(
      'SINTHETIX PRO - COTIZACION\n'
      'Numero: ${_numero()}\n'
      'Cliente: ${_cliente.text.trim().isEmpty ? 'Cliente' : _cliente.text.trim()}\n'
      'Total: \$${_total.toStringAsFixed(2)}\n'
      'El PDF se envia desde el boton Enviar cotizacion.',
    );

    final uri = telefono.isEmpty
        ? Uri.parse('https://wa.me/?text=$mensaje')
        : Uri.parse('https://wa.me/$telefono?text=$mensaje');

    await launchUrl(uri, webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: _fondo,
      child: LayoutBuilder(
        builder: (context, c) {
          final contenido = c.maxWidth >= 900
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _editor()),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: _resumen()),
                  ],
                )
              : Column(
                  children: [
                    _editor(),
                    const SizedBox(height: 16),
                    _resumen(),
                  ],
                );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: contenido,
          );
        },
      ),
    );
  }

  Widget _editor() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nueva cotizacion',
            style: TextStyle(
              color: _texto,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _cliente,
                  decoration: _input(
                    'Nombre del cliente',
                    Icons.person_outline,
                  ),
                ),
              ),
              SizedBox(
                width: 230,
                child: TextField(
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  decoration: _input(
                    'Telefono / WhatsApp',
                    Icons.phone_outlined,
                  ),
                ),
              ),
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _correo,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _input(
                    'Correo',
                    Icons.email_outlined,
                  ),
                ),
              ),
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _direccion,
                  decoration: _input(
                    'Direccion',
                    Icons.location_on_outlined,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _buscar,
            onChanged: _buscarProductos,
            decoration: _input(
              'Buscar y seleccionar productos',
              Icons.search_rounded,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _filtrados.length,
              separatorBuilder: (_, __) => const SizedBox(height: 5),
              itemBuilder: (_, i) {
                final p = _filtrados[i];

                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: widget.modoOscuro
                      ? const Color(0xFF24203B)
                      : const Color(0xFFF8F7FC),
                  title: Text(
                    p['nombre']?.toString() ?? 'Producto',
                    style: TextStyle(
                      color: _texto,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    p['codigo_barras']?.toString() ?? '',
                    style: TextStyle(color: _suave),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${_precio(p).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: _azul,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.add_circle_rounded,
                        color: _violeta,
                      ),
                    ],
                  ),
                  onTap: () => _agregar(p),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notas,
            maxLines: 3,
            decoration: _input(
              'Notas y condiciones',
              Icons.notes_outlined,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Descuento general (%)',
                  style: TextStyle(color: _suave),
                ),
              ),
              SizedBox(
                width: 110,
                child: TextField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => setState(
                    () => _descuento =
                        double.tryParse(v.replaceAll(',', '.')) ?? 0,
                  ),
                  decoration: const InputDecoration(
                    suffixText: '%',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resumen() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Productos seleccionados',
                  style: TextStyle(
                    color: _texto,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${_items.length}',
                style: TextStyle(
                  color: _violeta,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            Text(
              'Selecciona productos del inventario.',
              style: TextStyle(color: _suave),
            ),
          ...List.generate(
            _items.length,
            (i) {
              final x = _items[i];

              return Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: widget.modoOscuro
                      ? const Color(0xFF24203B)
                      : const Color(0xFFF8F7FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        x['nombre'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _texto,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _cantidad(i, -1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${x['cantidad']}',
                      style: TextStyle(
                        color: _texto,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _cantidad(i, 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '\$${_linea(x).toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: _azul,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 24),
          _fila('Subtotal', _subtotal),
          _fila('Descuento', _descuentoMonto),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'TOTAL',
                  style: TextStyle(
                    color: _suave,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style: TextStyle(
                  color: _violeta,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _enviando ? null : _enviarCotizacion,
              icon: _enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text(
                'ENVIAR COTIZACION - PDF / WHATSAPP',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _violeta,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _abrirWhatsApp,
              icon: const Icon(Icons.chat_rounded),
              label: const Text(
                'Abrir WhatsApp con el mensaje',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(String texto, double valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: _suave),
            ),
          ),
          Text(
            '\$${valor.toStringAsFixed(2)}',
            style: TextStyle(
              color: _texto,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _tarjeta,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.modoOscuro
              ? Colors.white.withValues(alpha: .07)
              : const Color(0xFFE7E4EF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
'@

    [IO.File]::WriteAllText($panel,$panelText,$utf8)
    [IO.File]::WriteAllText($pro,$proText,$utf8)

    Write-Host "[2/6] Cotizaciones conectadas al panel profesional." -ForegroundColor Green
    Write-Host "[3/6] Productos reales + cliente + descuento + PDF + WhatsApp." -ForegroundColor Green

    Write-Host "[4/6] Formateando..." -ForegroundColor Yellow
    & dart format $pro $panel
    if ($LASTEXITCODE -ne 0) { throw "dart format fallo." }

    Write-Host "[5/6] Verificando SOLO archivos activos..." -ForegroundColor Yellow
    $log = Join-Path $env:TEMP "sinthetix_cotizacion_v5_$stamp.txt"
    cmd.exe /c "flutter analyze lib\main.dart lib\profesional\pro_features.dart lib\profesional\cotizaciones_pro_panel.dart > `"$log`" 2>&1"
    $analysis = Get-Content $log -Raw -ErrorAction SilentlyContinue
    if ($analysis) { Write-Host $analysis }

    if ($analysis -match '(?m)^\s*error\s*-\s') {
        throw "Se detectaron errores Dart reales."
    }

    Write-Host "[6/6] INSTALACION TERMINADA SIN ERRORES DART." -ForegroundColor Green
    Write-Host ""
    Write-Host "Cotizaciones profesionales instaladas." -ForegroundColor Green
    Write-Host "Productos reales del inventario." -ForegroundColor Green
    Write-Host "Cliente + telefono + correo + direccion." -ForegroundColor Green
    Write-Host "Cantidades + descuento + totales." -ForegroundColor Green
    Write-Host "PDF profesional + compartir + WhatsApp." -ForegroundColor Green
    Write-Host ""
    Write-Host "Backup: $backupDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "NO se modificaron main.dart, camara, SQLite, ventas ni pagos." -ForegroundColor Cyan
}
catch {
    Write-Host ""
    Write-Host "FALLO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "RESTAURANDO..." -ForegroundColor Yellow

    Copy-Item (Join-Path $backupDir "main.dart") $main -Force
    Copy-Item (Join-Path $backupDir "pro_features.dart") $pro -Force

    if (Test-Path (Join-Path $backupDir "cotizaciones_pro_panel.dart")) {
        Copy-Item (Join-Path $backupDir "cotizaciones_pro_panel.dart") $panel -Force
    } elseif (Test-Path $panel) {
        Remove-Item $panel -Force
    }

    Write-Host "RESTAURACION COMPLETA." -ForegroundColor Green
    Write-Host "Backup: $backupDir" -ForegroundColor Cyan
    exit 1
}
