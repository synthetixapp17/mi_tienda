$ErrorActionPreference='Stop'
$root=(Get-Location).Path
$target=Join-Path $root 'lib\profesional\pro_features.dart'
if(!(Test-Path $target)){throw "No existe $target"}
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$backup=Join-Path $root "backup_cotizacion_$stamp"
New-Item -ItemType Directory -Path $backup -Force | Out-Null
Copy-Item $target (Join-Path $backup 'pro_features.dart') -Force
$text=[IO.File]::ReadAllText($target,[Text.Encoding]::UTF8)
# Add imports only when absent.
$imports=""
if($text -notmatch 'package:pdf/pdf.dart'){$imports += "import 'package:pdf/pdf.dart';`r`n"}
if($text -notmatch 'package:pdf/widgets.dart'){$imports += "import 'package:pdf/widgets.dart' as pw;`r`n"}
if($text -notmatch 'package:share_plus/share_plus.dart'){$imports += "import 'package:share_plus/share_plus.dart';`r`n"}
if($text -notmatch 'package:cross_file/cross_file.dart'){$imports += "import 'package:cross_file/cross_file.dart';`r`n"}
if($imports){$text=$imports+$text}
$method=@'
  Future<void> _generarYCompartirCotizacionPdf() async {
    final items = <Map<String, dynamic>>[];
    try {
      final dynamic source = _cotizacionItems;
      if (source is Iterable) {
        for (final item in source) {
          if (item is Map) items.add(Map<String, dynamic>.from(item));
        }
      }
    } catch (_) {}
    if (items.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega al menos un producto a la cotizacion.')));
      return;
    }
    final pdf = pw.Document();
    double total = 0;
    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (context) => [
      pw.Text('SINTHETIX PRO', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6), pw.Text('COTIZACION'), pw.SizedBox(height: 14),
      pw.TableHelper.fromTextArray(
        headers: const ['Producto', 'Cant.', 'Precio', 'Subtotal'],
        data: items.map((item) {
          final nombre = '${item['nombre'] ?? item['producto'] ?? 'Producto'}';
          final cantidad = double.tryParse('${item['cantidad'] ?? item['qty'] ?? 1}') ?? 1;
          final precio = double.tryParse('${item['precio'] ?? item['price'] ?? 0}') ?? 0;
          final subtotal = cantidad * precio; total += subtotal;
          return [nombre, cantidad.toStringAsFixed(cantidad % 1 == 0 ? 0 : 2), precio.toStringAsFixed(2), subtotal.toStringAsFixed(2)];
        }).toList(),
      ),
      pw.SizedBox(height: 18),
      pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('TOTAL: \\$${total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
    ]));
    final bytes = await pdf.save();
    final name = 'cotizacion_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await Share.shareXFiles([XFile.fromData(bytes, name: name, mimeType: 'application/pdf')], text: 'Cotizacion SINTHETIX PRO');
  }
'@
if($text -notmatch '_generarYCompartirCotizacionPdf\(\) async'){
  $needle='  Widget _buildCotizaciones()'
  $idx=$text.IndexOf($needle)
  if($idx -lt 0){throw 'No encontre _buildCotizaciones en pro_features.dart; no se hizo ningun cambio.'}
  $text=$text.Insert($idx,$method+"`r`n")
}
[IO.File]::WriteAllText($target,$text,(New-Object Text.UTF8Encoding($false)))
Write-Host '=== INSTALADOR PREPARADO: PDF + COMPARTIR WHATSAPP ===' -ForegroundColor Green
Write-Host "Backup: $backup"
Write-Host 'Funcion agregada en pro_features.dart.'
Write-Host 'IMPORTANTE: no se conecto automaticamente a un boton existente porque primero hay que verificar el nombre real del boton en tu archivo.'
Write-Host 'No se tocaron camara, SQLite, productos, ventas, pagos ni archivos BACKUP/ROTO.'
Write-Host ''
Write-Host 'Siguiente comando: flutter pub add share_plus cross_file'
Write-Host 'Luego: flutter analyze lib/profesional/pro_features.dart'
