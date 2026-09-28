$ErrorActionPreference="Stop"
$root=(Get-Location).Path
$main=Join-Path $root "lib\main.dart"
$pro=Join-Path $root "lib\profesional\pro_features.dart"
$pub=Join-Path $root "pubspec.yaml"
$panel=Join-Path $root "lib\profesional\cotizaciones_pro_panel.dart"

if(!(Test-Path $main) -or !(Test-Path $pro) -or !(Test-Path $pub)){throw "Ejecuta este instalador dentro de C:\Users\BRANAXEL\mi_tienda"}

$stamp=Get-Date -Format "yyyyMMdd_HHmmss"
$bak=Join-Path $root "backup_cotizaciones_pro_$stamp"
New-Item -ItemType Directory -Path $bak -Force|Out-Null
Copy-Item $main "$bak\main.dart"
Copy-Item $pro "$bak\pro_features.dart"
Copy-Item $pub "$bak\pubspec.yaml"
if(Test-Path $panel){Copy-Item $panel "$bak\cotizaciones_pro_panel.dart"}

try{
$enc=New-Object System.Text.UTF8Encoding($false)
$m=[IO.File]::ReadAllText($main,$enc)
$ptext=[IO.File]::ReadAllText($pro,$enc)
$pubtext=[IO.File]::ReadAllText($pub,$enc)

if($pubtext -notmatch '(?m)^\s*pdf:'){throw "Falta pdf en pubspec.yaml"}
if($pubtext -notmatch '(?m)^\s*printing:'){throw "Falta printing en pubspec.yaml"}
if($pubtext -notmatch '(?m)^\s*share_plus:'){throw "Falta share_plus en pubspec.yaml"}
if($pubtext -notmatch '(?m)^\s*url_launcher:'){throw "Falta url_launcher en pubspec.yaml"}

$panelCode=@'
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

typedef CargarProductosCotizacion = Future<List<Map<String,dynamic>>> Function();

class CotizacionesProPanel extends StatefulWidget {
  final bool modoOscuro;
  final CargarProductosCotizacion cargarProductos;

  const CotizacionesProPanel({
    super.key,
    required this.modoOscuro,
    required this.cargarProductos,
  });

  @override
  State<CotizacionesProPanel> createState() => _CotizacionesProPanelState();
}

class _Item {
  final Map<String,dynamic> producto;
  int cantidad;
  double precio;
  double descuento;

  _Item({
    required this.producto,
    required this.cantidad,
    required this.precio,
    this.descuento = 0,
  });

  double get bruto => cantidad * precio;
  double get subtotal => bruto - (bruto * descuento / 100);
}

class _CotizacionesProPanelState extends State<CotizacionesProPanel> {
  final cliente = TextEditingController();
  final telefono = TextEditingController();
  final email = TextEditingController();
  final direccion = TextEditingController();
  final nota = TextEditingController();
  final buscar = TextEditingController();

  List<Map<String,dynamic>> productos = [];
  final List<_Item> items = [];
  bool cargando = true;

  Color get bg => widget.modoOscuro ? const Color(0xFF11101A) : const Color(0xFFF5F6FA);
  Color get card => widget.modoOscuro ? const Color(0xFF1D1B29) : Colors.white;
  Color get text => widget.modoOscuro ? Colors.white : const Color(0xFF202124);
  Color get muted => widget.modoOscuro ? Colors.white70 : const Color(0xFF687080);

  double toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  String money(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    cliente.dispose();
    telefono.dispose();
    email.dispose();
    direccion.dispose();
    nota.dispose();
    buscar.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await widget.cargarProductos();
      if (!mounted) return;
      setState(() {
        productos = result;
        cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => cargando = false);
    }
  }

  List<Map<String,dynamic>> get filtered {
    final q = buscar.text.trim().toLowerCase();
    if (q.isEmpty) return productos.take(80).toList();

    return productos.where((product) {
      final searchable = [
        product['nombre'],
        product['codigo_barras'],
        product['categoria'],
        product['marca'],
      ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');
      return searchable.contains(q);
    }).take(80).toList();
  }

  void add(Map<String,dynamic> product) {
    final stock = toDouble(product['stock']).toInt();
    if (stock <= 0) return;

    final index = items.indexWhere(
      (item) => item.producto['id']?.toString() == product['id']?.toString(),
    );

    setState(() {
      if (index >= 0) {
        if (items[index].cantidad < stock) {
          items[index].cantidad++;
        }
      } else {
        items.add(_Item(
          producto: product,
          cantidad: 1,
          precio: toDouble(product['precio']),
        ));
      }
    });
  }

  Future<void> edit(int index) async {
    final item = items[index];
    final quantityController = TextEditingController(text: '${item.cantidad}');
    final priceController = TextEditingController(text: item.precio.toStringAsFixed(2));
    final discountController = TextEditingController(text: item.descuento.toStringAsFixed(2));

    final result = await showDialog<List<double>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item.producto['nombre']?.toString() ?? 'Producto'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio unitario',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Descuento %',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, [
              (int.tryParse(quantityController.text) ?? 1).clamp(1, 9999).toDouble(),
              (double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0)
                  .clamp(0, 999999999)
                  .toDouble(),
              (double.tryParse(discountController.text.replaceAll(',', '.')) ?? 0)
                  .clamp(0, 100)
                  .toDouble(),
            ]),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );

    quantityController.dispose();
    priceController.dispose();
    discountController.dispose();

    if (result != null && mounted) {
      setState(() {
        item.cantidad = result[0].toInt();
        item.precio = result[1];
        item.descuento = result[2];
      });
    }
  }

  pw.Widget pdfCell(String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<Uint8List> buildPdf() async {
    final document = pw.Document();
    final now = DateTime.now();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SINTHETIX PRO',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text('COTIZACION'),
                ],
              ),
              pw.Text(
                '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CLIENTE',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  cliente.text.trim().isEmpty ? 'Cliente' : cliente.text.trim(),
                ),
                if (telefono.text.trim().isNotEmpty)
                  pw.Text('Telefono: ${telefono.text.trim()}'),
                if (email.text.trim().isNotEmpty)
                  pw.Text('Email: ${email.text.trim()}'),
                if (direccion.text.trim().isNotEmpty)
                  pw.Text('Direccion: ${direccion.text.trim()}'),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              pw.TableRow(
                children: [
                  pdfCell('Producto', bold: true),
                  pdfCell('Cant.', bold: true),
                  pdfCell('Precio', bold: true),
                  pdfCell('Subtotal', bold: true),
                ],
              ),
              for (final item in items)
                pw.TableRow(
                  children: [
                    pdfCell(item.producto['nombre']?.toString() ?? 'Producto'),
                    pdfCell('${item.cantidad}'),
                    pdfCell(money(item.precio)),
                    pdfCell(money(item.subtotal)),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'TOTAL: ${money(total)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          if (nota.text.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 12),
              child: pw.Text('Nota: ${nota.text.trim()}'),
            ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Cotizacion sujeta a confirmacion.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return document.save();
  }

  Future<void> sharePdf() async {
    if (items.isEmpty) {
      msg('Agrega al menos un producto.');
      return;
    }

    final bytes = await buildPdf();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'cotizacion_sinthetix_pro.pdf',
    );
  }

  Future<void> shareFile() async {
    if (items.isEmpty) {
      msg('Agrega al menos un producto.');
      return;
    }

    final bytes = await buildPdf();
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: 'cotizacion_sinthetix_pro.pdf',
          mimeType: 'application/pdf',
        ),
      ],
      text: 'Cotizacion SINTHETIX PRO',
    );
  }

  Future<void> whatsapp() async {
    if (items.isEmpty) {
      msg('Agrega al menos un producto.');
      return;
    }

    final phone = telefono.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) {
      msg('Escribe el telefono/WhatsApp del cliente.');
      return;
    }

    final name = cliente.text.trim().isEmpty ? 'Cliente' : cliente.text.trim();
    final message = 'SINTHETIX PRO - COTIZACION\n'
        'Cliente: $name\n'
        'Total: ${money(total)}\n'
        'Productos: ${items.length}';

    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      msg('No se pudo abrir WhatsApp.');
    }
  }

  void msg(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration dec(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: card,
    );
  }

  Widget productsPanel() {
    return Card(
      color: card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Productos del inventario',
                    style: TextStyle(
                      color: text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
              ],
            ),
            TextField(
              controller: buscar,
              onChanged: (_) => setState(() {}),
              decoration: dec(
                'Buscar nombre, codigo, marca o categoria',
                icon: Icons.search,
              ),
            ),
            const SizedBox(height: 10),
            if (cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              Text(
                'No hay productos para mostrar.',
                style: TextStyle(color: muted),
              )
            else
              SizedBox(
                height: 360,
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final product = filtered[index];
                    final stock = toDouble(product['stock']).toInt();

                    return ListTile(
                      title: Text(
                        product['nombre']?.toString() ?? 'Producto',
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${product['categoria'] ?? 'Sin categoria'} · Stock: $stock · ${money(toDouble(product['precio']))}',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                      trailing: FilledButton.icon(
                        onPressed: stock > 0 ? () => add(product) : null,
                        icon: const Icon(Icons.add, size: 17),
                        label: const Text('Agregar'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget itemsPanel() {
    return Card(
      color: card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Detalle de cotizacion',
                    style: TextStyle(
                      color: text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${items.length} productos',
                  style: TextStyle(color: muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text(
                'Agrega productos del inventario.',
                style: TextStyle(color: muted),
              )
            else
              for (int index = 0; index < items.length; index++)
                _itemTile(index),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL',
                  style: TextStyle(
                    color: text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  money(total),
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemTile(int index) {
    final item = items[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: muted.withValues(alpha: .18)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.producto['nombre']?.toString() ?? 'Producto',
                  style: TextStyle(color: text, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${item.cantidad} x ${money(item.precio)} · Desc. ${item.descuento.toStringAsFixed(1)}%',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            money(item.subtotal),
            style: TextStyle(color: text, fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: () => edit(index),
            icon: const Icon(Icons.edit_outlined, size: 19),
          ),
          IconButton(
            onPressed: () => setState(() => items.removeAt(index)),
            icon: const Icon(Icons.delete_outline, size: 19),
          ),
        ],
      ),
    );
  }

  Widget clientPanel() {
    return Card(
      color: card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datos del cliente',
              style: TextStyle(
                color: text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: cliente, decoration: dec('Nombre')),
            const SizedBox(height: 10),
            TextField(
              controller: telefono,
              keyboardType: TextInputType.phone,
              decoration: dec('Telefono / WhatsApp', icon: Icons.phone_outlined),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: dec('Email', icon: Icons.email_outlined),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: direccion,
              decoration: dec('Direccion', icon: Icons.location_on_outlined),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nota,
              maxLines: 2,
              decoration: dec('Nota / condiciones'),
            ),
          ],
        ),
      ),
    );
  }

  Widget actions() {
    return Card(
      color: card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: sharePdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF / Imprimir'),
            ),
            OutlinedButton.icon(
              onPressed: shareFile,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartir PDF'),
            ),
            OutlinedButton.icon(
              onPressed: whatsapp,
              icon: const Icon(Icons.chat_outlined),
              label: const Text('WhatsApp'),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  items.clear();
                  cliente.clear();
                  telefono.clear();
                  email.clear();
                  direccion.clear();
                  nota.clear();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Nueva cotizacion'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cotizaciones profesionales',
              style: TextStyle(
                color: text,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Selecciona productos reales del inventario y genera un documento para compartir.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final left = Column(
                  children: [
                    productsPanel(),
                    const SizedBox(height: 14),
                    itemsPanel(),
                  ],
                );

                final right = Column(
                  children: [
                    clientPanel(),
                    const SizedBox(height: 14),
                    actions(),
                  ],
                );

                if (constraints.maxWidth >= 1050) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: left),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: right),
                    ],
                  );
                }

                return Column(
                  children: [
                    left,
                    const SizedBox(height: 14),
                    right,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
'@


[IO.File]::WriteAllText($panel,$panelCode,$enc)

if($ptext -notmatch "cotizaciones_pro_panel.dart"){$ptext="import 'cotizaciones_pro_panel.dart';`n"+$ptext}

if($ptext -notmatch "CargarProductosCotizacion"){
  $ptext=$ptext.Replace(
    "final bool modoOscuro;",
    "final bool modoOscuro;`r`n  final CargarProductosCotizacion? cargarProductos;"
  )
  $ptext=$ptext.Replace(
    "required this.modoOscuro,",
    "required this.modoOscuro,`r`n    this.cargarProductos,"
  )
}

$q='(?ms)  Widget _quotes\(\) \{.*?\r?\n  \}\r?\n\r?\n  Widget _credits\(\)'
if($ptext -notmatch $q){throw "No encontre _quotes() con la estructura esperada."}
$replacement=@"
  Widget _quotes() {
    final loader = widget.cargarProductos;
    if (loader == null) {
      return _panel(title:'Cotizaciones',subtitle:'Inventario no conectado.',icon:Icons.request_quote_rounded,child:_empty('Falta el cargador de productos.'));
    }
    return CotizacionesProPanel(modoOscuro:widget.modoOscuro,cargarProductos:loader);
  }

  Widget _credits()
"@
$ptext=[regex]::Replace($ptext,$q,$replacement,1)

$call='(?s)ProfesionalScreen\(\s*onAbrirSidebar\s*:\s*_abrirSidebar\s*,\s*modoOscuro\s*:\s*_modoOscuro\s*,'
if($m -notmatch $call){throw "No encontre la llamada actual a ProfesionalScreen en main.dart."}
$m=[regex]::Replace($m,$call,'ProfesionalScreen(onAbrirSidebar:_abrirSidebar,modoOscuro:_modoOscuro,cargarProductos:()=>DatabaseService().getProductos(),',1)

[IO.File]::WriteAllText($pro,$ptext,$enc)
[IO.File]::WriteAllText($main,$m,$enc)

dart format $main $pro $panel
if($LASTEXITCODE -ne 0){throw "dart format fallo."}

$out=& flutter analyze lib/main.dart lib/profesional/pro_features.dart lib/profesional/cotizaciones_pro_panel.dart 2>&1
$out|ForEach-Object{Write-Host $_}
$errs=@($out|Where-Object{$_ -match '\berror\s*-\s'})
if($errs.Count -gt 0){throw "flutter analyze encontro $($errs.Count) error(es)."}

Write-Host "`nINSTALACION COMPLETADA." -ForegroundColor Green
Write-Host "Backup: $bak"
Write-Host "Prueba: flutter run -d chrome" -ForegroundColor Cyan
}
catch{
Write-Host "`nFALLO. RESTAURANDO..." -ForegroundColor Red
Copy-Item "$bak\main.dart" $main -Force
Copy-Item "$bak\pro_features.dart" $pro -Force
Copy-Item "$bak\pubspec.yaml" $pub -Force
if(Test-Path "$bak\cotizaciones_pro_panel.dart"){Copy-Item "$bak\cotizaciones_pro_panel.dart" $panel -Force}elseif(Test-Path $panel){Remove-Item $panel -Force}
Write-Host "RESTAURACION COMPLETA." -ForegroundColor Yellow
Write-Host $_.Exception.Message -ForegroundColor Red
exit 1
}
