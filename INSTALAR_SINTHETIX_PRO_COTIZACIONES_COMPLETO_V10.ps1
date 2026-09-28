#requires -Version 5.1
$ErrorActionPreference = "Stop"

$root = (Get-Location).Path
$main = Join-Path $root "lib\main.dart"
$pro = Join-Path $root "lib\profesional\pro_features.dart"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " SINTHETIX PRO - INSTALADOR COTIZACIONES PROFESIONAL V10" -ForegroundColor Cyan
Write-Host " COTIZACIONES + PRODUCTOS + CLIENTE + PDF + COMPARTIR" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $main)) { throw "No encuentro lib\main.dart. Ejecuta desde C:\Users\BRANAXEL\mi_tienda." }
if (-not (Test-Path $pro)) { throw "No encuentro lib\profesional\pro_features.dart." }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $root "BACKUP_COTIZACIONES_V10_$stamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Copy-Item $main (Join-Path $backupDir "main.dart") -Force
Copy-Item $pro (Join-Path $backupDir "pro_features.dart") -Force

Write-Host "[1/7] Backup creado: $backupDir" -ForegroundColor Green

$utf8 = New-Object System.Text.UTF8Encoding($false)
$mainText = [IO.File]::ReadAllText($main,$utf8)
$proText  = [IO.File]::ReadAllText($pro,$utf8)

try {
    # ------------------------------------------------------------
    # 2. Reparacion segura de textos mojibake conocidos.
    # NO hacemos conversion masiva de bytes.
    # ------------------------------------------------------------
    # ASCII-only installer source. Unicode is built by codepoint.
    function U([int[]]$c) { return (-join ($c | ForEach-Object { [char]$_ })) }

    $pairs = @(
        @((U @(0x00C3,0x0192,0x00C2,0x00A1)), (U @(0x00E1))),
        @((U @(0x00C3,0x0192,0x00C2,0x00A9)), (U @(0x00E9))),
        @((U @(0x00C3,0x0192,0x00C2,0x00AD)), (U @(0x00ED))),
        @((U @(0x00C3,0x0192,0x00C2,0x00B3)), (U @(0x00F3))),
        @((U @(0x00C3,0x0192,0x00C2,0x00BA)), (U @(0x00FA))),
        @((U @(0x00C3,0x0192,0x00C2,0x00B1)), (U @(0x00F1))),
        @((U @(0x00C3,0x0192,0x00C2,0x2030)), (U @(0x00C9))),
        @((U @(0x00C3,0x0192,0x00C2,0x201C)), (U @(0x00D3))),
        @((U @(0x00C3,0x0192,0x00C2,0x00DA)), (U @(0x00DA))),
        @((U @(0x00C3,0x0192,0x00E2,0x20AC,0x02DC)), (U @(0x00D1))),
        @((U @(0x00C3,0x00A1)), (U @(0x00E1))),
        @((U @(0x00C3,0x00A9)), (U @(0x00E9))),
        @((U @(0x00C3,0x00AD)), (U @(0x00ED))),
        @((U @(0x00C3,0x00B3)), (U @(0x00F3))),
        @((U @(0x00C3,0x00BA)), (U @(0x00FA))),
        @((U @(0x00C3,0x00B1)), (U @(0x00F1))),
        @((U @(0x00C3,0x2030)), (U @(0x00C9))),
        @((U @(0x00C3,0x201C)), (U @(0x00D3))),
        @((U @(0x00C3,0x00DA)), (U @(0x00DA))),
        @((U @(0x00C3,0x2018)), (U @(0x00D1))),
        @((U @(0x00C2,0x00A1)), (U @(0x00A1))),
        @((U @(0x00C2,0x00BF)), (U @(0x00BF)))
    )
    foreach ($pair in $pairs) {
        $mainText = $mainText.Replace($pair[0], $pair[1])
        $proText  = $proText.Replace($pair[0], $pair[1])
    }
    $mainText = $mainText.Replace((U @(0x44,0x49,0x53,0x45,0x00C3,0x0192,0x00E2,0x20AC,0x02DC,0x4F)), (U @(0x44,0x49,0x53,0x45,0x00D1,0x4F)))
    $mainText = $mainText.Replace((U @(0x4D,0x45,0x4E,0x00C3,0x0192,0x00C5,0x00A1)), (U @(0x4D,0x45,0x4E,0x00DA)))
    $mainText = $mainText.Replace((U @(0x00C3,0x0192,0x00C5,0x00A1,0x6E,0x69,0x63,0x61)), (U @(0x00DA,0x6E,0x69,0x63,0x61)))
    Write-Host "[2/7] Text cleanup completed." -ForegroundColor Green

    Write-Host "[2/7] Textos danados corregidos sin conversion masiva." -ForegroundColor Green

    # ------------------------------------------------------------
    # 3. Importar pantalla de cotizaciones.
    # ------------------------------------------------------------
    $importLine = "import 'cotizaciones_pro_panel.dart';"
    if ($proText -notmatch "(?m)^\s*import\s+'cotizaciones_pro_panel\.dart';") {
        $imports = [regex]::Matches($proText, "(?m)^\s*import\s+[^;]+;\s*\r?\n")
        if ($imports.Count -eq 0) { throw "No pude localizar los imports de pro_features.dart." }
        $last = $imports[$imports.Count-1]
        $proText = $proText.Insert($last.Index + $last.Length, $importLine + "`r`n")
    }

    # ------------------------------------------------------------
    # 4. Integrar la cotizacion en la PRIMERA pestaña real.
    #    No suponemos que el metodo se llame _cotizaciones().
    #    Detectamos el TabBarView real y reemplazamos SOLO su
    #    primer hijo. Esto conserva las demas pestañas.
    # ------------------------------------------------------------
    $replaced = $false

    # Caso conocido: _cotizaciones(), _buildCotizaciones(), etc.
    $tabPatterns = @(
        '(?m)^(\s*)_cotizaciones\(\)\s*,',
        '(?m)^(\s*)_buildCotizaciones\(\)\s*,',
        '(?m)^(\s*)CotizacionesScreen\([^\r\n]*\)\s*,'
    )

    foreach ($pat in $tabPatterns) {
        if (-not $replaced -and $proText -match $pat) {
            $proText = [regex]::Replace(
                $proText,
                $pat,
                '${1}CotizacionesProPanel(modoOscuro: widget.modoOscuro),',
                1
            )
            $replaced = $true
        }
    }

    # Caso general: localizar TabBarView -> children: [ y reemplazar
    # el primer hijo que sea una llamada de widget/metodo.
    if (-not $replaced) {
        $tabIndex = $proText.IndexOf('TabBarView(')
        if ($tabIndex -ge 0) {
            $childrenIndex = $proText.IndexOf('children:', $tabIndex)
            if ($childrenIndex -ge 0) {
                $openBracket = $proText.IndexOf('[', $childrenIndex)
                if ($openBracket -ge 0 -and ($openBracket - $childrenIndex) -lt 200) {
                    $after = $openBracket + 1
                    $rest = $proText.Substring($after)
                    $m = [regex]::Match($rest, '(?s)^\s*([A-Za-z_][A-Za-z0-9_]*\s*\([^\r\n]*\))\s*,')
                    if ($m.Success) {
                        $replacement = 'CotizacionesProPanel(modoOscuro: widget.modoOscuro),'
                        $absolute = $after + $m.Index
                        $proText = $proText.Remove($absolute, $m.Length).Insert($absolute, $replacement)
                        $replaced = $true
                    }
                }
            }
        }
    }

    # Segundo fallback: algunas versiones usan un array asignado a una
    # variable antes de TabBarView. Buscamos la primera llamada despues
    # de "children: [" aunque tenga espacios/saltos de linea.
    if (-not $replaced) {
        $m = [regex]::Match($proText, '(?s)children\s*:\s*\[\s*([A-Za-z_][A-Za-z0-9_]*\s*\([^\r\n]*\))\s*,')
        if ($m.Success) {
            $replacement = 'children: [' + [Environment]::NewLine + '          CotizacionesProPanel(modoOscuro: widget.modoOscuro),'
            $proText = $proText.Remove($m.Index, $m.Length).Insert($m.Index, $replacement)
            $replaced = $true
        }
    }

    if (-not $replaced) {
        throw "No pude localizar el TabBarView real de pro_features.dart. No se modifico la navegacion."
    }

    # ------------------------------------------------------------
    # 5. Crear panel nuevo. Usa DatabaseService SOLO para LEER
    #    productos; no crea ni modifica tablas.
    # ------------------------------------------------------------
    $panelPath = Join-Path $root "lib\profesional\cotizaciones_pro_panel.dart"

    $panel = @'
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/database_service.dart';

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
  final TextEditingController _search = TextEditingController();
  final TextEditingController _cliente = TextEditingController();
  final TextEditingController _telefono = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _direccion = TextEditingController();
  final TextEditingController _notas = TextEditingController();

  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _filtrados = [];
  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _busy = false;
  double _descuentoGlobal = 0;

  Color get _purple => const Color(0xFF5B21B6);
  Color get _blue => const Color(0xFF2563EB);

  Color get _background => widget.modoOscuro
      ? const Color(0xFF10111B)
      : const Color(0xFFF5F6FA);

  Color get _card => widget.modoOscuro
      ? const Color(0xFF1B1930)
      : Colors.white;

  Color get _text => widget.modoOscuro
      ? Colors.white
      : const Color(0xFF202332);

  Color get _muted => widget.modoOscuro
      ? const Color(0xFFAAA4BA)
      : const Color(0xFF667085);

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  @override
  void dispose() {
    _search.dispose();
    _cliente.dispose();
    _telefono.dispose();
    _email.dispose();
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
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('No se pudieron cargar los productos: $e');
    }
  }

  void _filtrar(String value) {
    final q = value.trim().toLowerCase();
    setState(() {
      _filtrados = q.isEmpty
          ? _productos
          : _productos.where((p) {
              final nombre = (p['nombre'] ?? '').toString().toLowerCase();
              final codigo =
                  (p['codigo_barras'] ?? '').toString().toLowerCase();
              final marca = (p['marca'] ?? '').toString().toLowerCase();
              return nombre.contains(q) ||
                  codigo.contains(q) ||
                  marca.contains(q);
            }).toList();
    });
  }

  double _precio(Map<String, dynamic> p) =>
      (p['precio'] as num? ?? p['price'] as num? ?? 0).toDouble();

  void _agregar(Map<String, dynamic> p) {
    final id = (p['id'] ?? p['codigo_barras'] ?? p['nombre']).toString();
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
          'descuento': 0.0,
        });
      }
    });
  }

  void _cantidad(int i, int delta) {
    setState(() {
      final n = (_items[i]['cantidad'] as int) + delta;
      if (n <= 0) {
        _items.removeAt(i);
      } else {
        _items[i]['cantidad'] = n;
      }
    });
  }

  double _linea(Map<String, dynamic> item) {
    final base =
        (item['precio'] as double) * (item['cantidad'] as int);
    final pct = (item['descuento'] as double?) ?? 0;
    return base - (base * pct / 100);
  }

  double get _subtotal => _items.fold(
        0,
        (sum, item) =>
            sum + (item['precio'] as double) * (item['cantidad'] as int),
      );

  double get _descuentoItems => _items.fold(
        0,
        (sum, item) {
          final base =
              (item['precio'] as double) * (item['cantidad'] as int);
          final pct = (item['descuento'] as double?) ?? 0;
          return sum + (base * pct / 100);
        },
      );

  double get _descuentoGlobalMonto =>
      (_subtotal - _descuentoItems) * (_descuentoGlobal / 100);

  double get _total =>
      _subtotal - _descuentoItems - _descuentoGlobalMonto;

  String _numero() {
    final now = DateTime.now();
    return 'COT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _purple,
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _purple),
        filled: true,
        fillColor: widget.modoOscuro
            ? const Color(0xFF24203B)
            : const Color(0xFFF7F5FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  Future<Uint8List> _pdf(String numero) async {
    final doc = pw.Document();
    final date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final purple = PdfColor.fromHex('#5B21B6');
    final blue = PdfColor.fromHex('#2563EB');
    final light = PdfColor.fromHex('#F4F3FF');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(colors: [purple, blue]),
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
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  color: light,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CLIENTE',
                          style: pw.TextStyle(
                              color: purple,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _cliente.text.trim().isEmpty
                            ? 'Cliente general'
                            : _cliente.text.trim(),
                        style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold),
                      ),
                      if (_telefono.text.trim().isNotEmpty)
                        pw.Text(_telefono.text.trim()),
                      if (_email.text.trim().isNotEmpty)
                        pw.Text(_email.text.trim()),
                      if (_direccion.text.trim().isNotEmpty)
                        pw.Text(_direccion.text.trim()),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  color: PdfColor.fromHex('#EEF4FF'),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FECHA',
                          style: pw.TextStyle(
                              color: blue,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(date,
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('Validez: 7 dias'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder(
              horizontalInside:
                  pw.BorderSide(color: PdfColors.grey300, width: .5),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: light),
                children: [
                  _cell('PRODUCTO', true, purple),
                  _cell('CANT.', true, purple),
                  _cell('PRECIO', true, purple),
                  _cell('TOTAL', true, purple),
                ],
              ),
              ..._items.map((item) {
                final qty = item['cantidad'] as int;
                final price = item['precio'] as double;
                return pw.TableRow(children: [
                  _cell(item['nombre'].toString(), false, null,
                      sub: item['codigo'].toString()),
                  _cell('$qty', false, null),
                  _cell('\$${price.toStringAsFixed(2)}', false, null),
                  _cell('\$${_linea(item).toStringAsFixed(2)}', false, null),
                ]);
              }),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 240,
              padding: const pw.EdgeInsets.all(14),
              color: light,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _totalRow('SUBTOTAL', _subtotal),
                  if (_descuentoItems > 0)
                    _totalRow('DESCUENTO PRODUCTOS', _descuentoItems),
                  if (_descuentoGlobalMonto > 0)
                    _totalRow('DESCUENTO GENERAL', _descuentoGlobalMonto),
                  pw.Divider(),
                  _totalRow('TOTAL', _total, big: true),
                ],
              ),
            ),
          ),
          if (_notas.text.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text('NOTAS',
                style: pw.TextStyle(
                    color: purple,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(_notas.text.trim()),
          ],
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.Center(
            child: pw.Text('Gracias por preferir SINTHETIX PRO'),
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _cell(String text, bool bold, PdfColor? color, {String? sub}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(7),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(text,
                style: pw.TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            if (sub != null && sub.isNotEmpty)
              pw.Text(sub,
                  style: const pw.TextStyle(
                      color: PdfColors.grey600, fontSize: 7)),
          ],
        ),
      );

  pw.Widget _totalRow(String label, double value, {bool big = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    fontSize: big ? 12 : 9,
                    fontWeight: big
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal)),
            pw.Text('\$${value.toStringAsFixed(2)}',
                style: pw.TextStyle(
                    fontSize: big ? 15 : 9,
                    fontWeight: big
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal)),
          ],
        ),
      );

  Future<void> _compartir() async {
    if (_items.isEmpty) {
      _snack('Agrega productos antes de compartir.');
      return;
    }
    setState(() => _busy = true);
    try {
      final numero = _numero();
      final bytes = await _pdf(numero);
      await Printing.sharePdf(
        bytes: bytes,
        filename: '$numero.pdf',
        subject: 'Cotizacion $numero - SINTHETIX PRO',
      );
      _snack('PDF preparado para compartir.');
    } catch (e) {
      _snack('No se pudo compartir el PDF: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generar() async {
    if (_items.isEmpty) {
      _snack('Agrega productos antes de generar el PDF.');
      return;
    }
    setState(() => _busy = true);
    try {
      final numero = _numero();
      final bytes = await _pdf(numero);
      await Printing.layoutPdf(
        name: '$numero.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      _snack('No se pudo generar el PDF: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _whatsapp() async {
    if (_items.isEmpty) {
      _snack('Agrega productos antes de enviar.');
      return;
    }
    final phone = _telefono.text.replaceAll(RegExp(r'[^0-9]'), '');
    final numero = _numero();
    final msg = Uri.encodeComponent(
      'SINTHETIX PRO - COTIZACION\n'
      'Numero: $numero\n'
      'Cliente: ${_cliente.text.trim().isEmpty ? 'Cliente' : _cliente.text.trim()}\n'
      'Total: \$${_total.toStringAsFixed(2)}\n'
      'El PDF de la cotizacion se puede adjuntar desde Compartir.',
    );
    final url = phone.isEmpty
        ? Uri.parse('https://wa.me/?text=$msg')
        : Uri.parse('https://wa.me/$phone?text=$msg');
    await launchUrl(url, webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: wide
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
                ),
        );
      },
    );
  }

  Widget _editor() {
    return _cardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nueva cotizacion',
              style: TextStyle(
                  color: _text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _cliente,
                  decoration: _dec('Nombre del cliente', Icons.person_outline),
                ),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  decoration: _dec('Telefono / WhatsApp', Icons.phone_outlined),
                ),
              ),
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dec('Correo', Icons.email_outlined),
                ),
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _direccion,
                  decoration: _dec('Direccion', Icons.location_on_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            onChanged: _filtrar,
            decoration: _dec(
              'Buscar y seleccionar productos',
              Icons.search_rounded,
            ),
          ),
          const SizedBox(height: 10),
          if (_filtrados.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text('No hay productos encontrados.',
                  style: TextStyle(color: _muted)),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _filtrados.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final p = _filtrados[i];
                  final price = _precio(p);
                  return Material(
                    color: widget.modoOscuro
                        ? const Color(0xFF24203B)
                        : const Color(0xFFF8F7FC),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => _agregar(p),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_purple, _blue],
                                ),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.inventory_2_outlined,
                                  color: Colors.white, size: 19),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p['nombre']?.toString() ?? 'Producto',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: _text,
                                          fontWeight: FontWeight.w800)),
                                  Text(
                                    p['codigo_barras']?.toString() ?? '',
                                    style: TextStyle(
                                        color: _muted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text('\$${price.toStringAsFixed(2)}',
                                style: TextStyle(
                                    color: _blue,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(width: 8),
                            Icon(Icons.add_circle_rounded, color: _purple),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _notas,
            maxLines: 3,
            decoration: _dec('Notas y condiciones', Icons.notes_outlined),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Descuento general (%)',
                  style: TextStyle(color: _muted),
                ),
              ),
              SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: '0',
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  onChanged: (v) {
                    setState(() {
                      _descuentoGlobal =
                          double.tryParse(v.replaceAll(',', '.')) ?? 0;
                    });
                  },
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
    return _cardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Productos de la cotizacion',
                  style: TextStyle(
                      color: _text,
                      fontSize: 18,
                      fontWeight: FontWeight.w900),
                ),
              ),
              Text('${_items.length}',
                  style: TextStyle(
                      color: _purple, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            Text(
              'Selecciona productos del catalogo.',
              style: TextStyle(color: _muted),
            )
          else
            ...List.generate(_items.length, (i) {
              final item = _items[i];
              final qty = item['cantidad'] as int;
              final price = item['precio'] as double;
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: widget.modoOscuro
                        ? const Color(0xFF24203B)
                        : const Color(0xFFF8F7FC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['nombre'].toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: _text, fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _cantidad(i, -1),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$qty',
                          style: TextStyle(
                              color: _text, fontWeight: FontWeight.w900)),
                      IconButton(
                        onPressed: () => _cantidad(i, 1),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      SizedBox(
                        width: 82,
                        child: Text(
                          '\$${_linea(item).toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: _blue, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const Divider(height: 26),
          _summaryRow('Subtotal', _subtotal),
          _summaryRow('Descuentos', _descuentoItems + _descuentoGlobalMonto),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text('TOTAL',
                    style: TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
              ),
              Text('\$${_total.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: _purple,
                      fontSize: 27,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _generar,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Generar PDF'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _compartir,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Enviar cotizacion'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _busy ? null : _whatsapp,
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Abrir WhatsApp con el mensaje'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(color: _muted))),
            Text('\$${value.toStringAsFixed(2)}',
                style: TextStyle(
                    color: _text, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _cardBox({required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
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
'@

    [IO.File]::WriteAllText($panelPath,$panel,$utf8)
    Write-Host "[3/7] Pantalla profesional de cotizaciones creada." -ForegroundColor Green
    Write-Host "       $panelPath"

    # ------------------------------------------------------------
    # 6. Asegurar dependencias necesarias.
    # ------------------------------------------------------------
    Write-Host "[4/7] Revisando dependencias..." -ForegroundColor Yellow
    $pubspec = Join-Path $root "pubspec.yaml"
    $pub = [IO.File]::ReadAllText($pubspec,$utf8)

    if ($pub -notmatch "(?m)^\s*url_launcher\s*:") {
        & flutter pub add url_launcher
        if ($LASTEXITCODE -ne 0) { throw "No se pudo agregar url_launcher." }
    }
    if ($pub -notmatch "(?m)^\s*pdf\s*:") {
        & flutter pub add pdf
        if ($LASTEXITCODE -ne 0) { throw "No se pudo agregar pdf." }
    }
    if ($pub -notmatch "(?m)^\s*printing\s*:") {
        & flutter pub add printing
        if ($LASTEXITCODE -ne 0) { throw "No se pudo agregar printing." }
    }

    # ------------------------------------------------------------
    # 7. Intentar dejar Cotizaciones / Profesional visible en movil.
    # No toca la camara.
    # ------------------------------------------------------------
    if ($mainText -notmatch "Cotizaciones / Profesional") {
        $mobilePat = "(?m)^(\s*)(railItem\('Estad[ii]sticas'.*?\),\s*)$"
        if ($mainText -match $mobilePat) {
            $mainText = [regex]::Replace(
                $mainText,
                $mobilePat,
                '${1}${2}`r`n${1}railItem(''Cotizaciones / Profesional'', Icons.request_quote_rounded, 23),',
                1
            )
        }
    }

    # Si ya existe la etiqueta, no duplicarla. Para el movil intentamos
    # agregarla al bloque de _buildMobileNav solo cuando exista un railItem
    # en ese bloque. Si no coincide, dejamos la navegacion intacta.
    $mobileStart = $mainText.IndexOf("_buildMobileNav")
    if ($mobileStart -ge 0 -and $mainText.IndexOf("Cotizaciones / Profesional",$mobileStart) -lt 0) {
        $morePos = $mainText.IndexOf("'Mas'",$mobileStart)
        if ($morePos -lt 0) { $morePos = $mainText.IndexOf("'Mas'",$mobileStart) }
        if ($morePos -ge 0) {
            # No insertamos dentro de funciones desconocidas: solo anadimos
            # una marca segura antes del primer bloque de cierre cercano si
            # encontramos exactamente "Mas".
            Write-Host "[5/7] Navegacion movil detectada; no se altera automaticamente para evitar romperla." -ForegroundColor Yellow
        } else {
            Write-Host "[5/7] No se encontro boton Mas dentro de _buildMobileNav; navegacion movil preservada." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[5/7] Navegacion movil preservada; el modulo profesional ya es accesible por su ruta." -ForegroundColor Green
    }

    # Escribir archivos.
    [IO.File]::WriteAllText($main,$mainText,$utf8)
    [IO.File]::WriteAllText($pro,$proText,$utf8)

    Write-Host "[6/7] Archivos integrados. Formateando..." -ForegroundColor Yellow
    & dart format (Join-Path $root "lib\main.dart"), (Join-Path $root "lib\profesional\pro_features.dart"), $panelPath
    if ($LASTEXITCODE -ne 0) { throw "dart format fallo." }

    Write-Host "[7/7] Ejecutando flutter analyze..." -ForegroundColor Yellow
    $log = Join-Path $env:TEMP "sinthetix_v6_analyze_$stamp.txt"
    cmd.exe /c "flutter analyze . > `"$log`" 2>&1"
    $analysis = Get-Content $log -Raw -ErrorAction SilentlyContinue
    if ($analysis) { Write-Host $analysis }

    if ($analysis -match "(?m)^\s*error\s*-\s") {
        throw "Flutter encontro errores Dart reales. Se restaurara el backup."
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " INSTALACION TERMINADA SIN ERRORES DART" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "Cotizaciones ahora usa productos reales del inventario."
    Write-Host "Incluye cliente, telefono, correo, direccion, descuentos, PDF y compartir."
    Write-Host ""
    Write-Host "Backup: $backupDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Ejecuta: flutter run -d chrome" -ForegroundColor Yellow
}
catch {
    Write-Host ""
    Write-Host "FALLO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Restaurando archivos..." -ForegroundColor Yellow
    Copy-Item (Join-Path $backupDir "main.dart") $main -Force
    Copy-Item (Join-Path $backupDir "pro_features.dart") $pro -Force
    $panelPath = Join-Path $root "lib\profesional\cotizaciones_pro_panel.dart"
    if (Test-Path $panelPath) { Remove-Item $panelPath -Force }
    Write-Host "RESTAURACION TERMINADA." -ForegroundColor Green
    Write-Host "Backup: $backupDir" -ForegroundColor Cyan
    exit 1
}
