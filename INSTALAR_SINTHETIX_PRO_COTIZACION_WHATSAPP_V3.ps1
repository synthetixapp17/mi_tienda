#requires -Version 5.1
$ErrorActionPreference = "Stop"
$root = (Get-Location).Path
$main = Join-Path $root "lib\main.dart"
$pro = Join-Path $root "lib\profesional\pro_features.dart"
$panel = Join-Path $root "lib\profesional\cotizaciones_pro_panel.dart"
$utf8 = New-Object System.Text.UTF8Encoding($false)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " SINTHETIX PRO - COTIZACIONES + PDF + WHATSAPP V2" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

if (-not (Test-Path $main)) { throw "No encuentro lib\main.dart." }
if (-not (Test-Path $pro)) { throw "No encuentro lib\profesional\pro_features.dart." }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $root "BACKUP_COTIZACION_V2_$stamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Copy-Item $main (Join-Path $backupDir "main.dart") -Force
Copy-Item $pro (Join-Path $backupDir "pro_features.dart") -Force
if (Test-Path $panel) { Copy-Item $panel (Join-Path $backupDir "cotizaciones_pro_panel.dart") -Force }
Write-Host "Backup: $backupDir" -ForegroundColor Green

$mainText = [IO.File]::ReadAllText($main,$utf8)
$proText = [IO.File]::ReadAllText($pro,$utf8)

try {
    # 1) Dependencias. Solo se agregan si faltan.
    $pubspec = Join-Path $root "pubspec.yaml"
    $pub = [IO.File]::ReadAllText($pubspec,$utf8)
    foreach ($pkg in @('pdf','printing','url_launcher','intl')) {
        if ($pub -notmatch "(?m)^\s*$pkg\s*:") {
            Write-Host "Agregando dependencia: $pkg" -ForegroundColor Yellow
            & flutter pub add $pkg
            if ($LASTEXITCODE -ne 0) { throw "No se pudo agregar $pkg." }
            $pub = [IO.File]::ReadAllText($pubspec,$utf8)
        }
    }

    # 2) Importar el panel una sola vez.
    if ($proText -notmatch "(?m)^\s*import\s+'cotizaciones_pro_panel\.dart';") {
        $imports = [regex]::Matches($proText, "(?m)^\s*import\s+[^;]+;\s*\r?\n")
        if ($imports.Count -eq 0) { throw "No pude localizar los imports de pro_features.dart." }
        $last = $imports[$imports.Count-1]
        $proText = $proText.Insert($last.Index + $last.Length, "import 'cotizaciones_pro_panel.dart';`r`n")
    }

    # 3) Reemplazar SOLO la primera pestaa del TabBarView real.
    #    No dependemos de nombres como _buildCotizaciones.
    $replaced = $false
    $patterns = @(
        '(?m)^(\s*)_cotizaciones\(\)\s*,',
        '(?m)^(\s*)_buildCotizaciones\(\)\s*,',
        '(?m)^(\s*)CotizacionesScreen\([^\r\n]*\)\s*,'
    )
    foreach ($pat in $patterns) {
        if (-not $replaced -and $proText -match $pat) {
            $proText = [regex]::Replace($proText,$pat,'${1}CotizacionesProPanel(modoOscuro: widget.modoOscuro),',1)
            $replaced = $true
        }
    }

    if (-not $replaced) {
        $tab = $proText.IndexOf('TabBarView(')
        if ($tab -ge 0) {
            $children = $proText.IndexOf('children:', $tab)
            if ($children -ge 0) {
                $bracket = $proText.IndexOf('[', $children)
                if ($bracket -ge 0 -and ($bracket-$children) -lt 200) {
                    $start = $bracket + 1
                    $rest = $proText.Substring($start)
                    $m = [regex]::Match($rest,'(?s)^\s*([A-Za-z_][A-Za-z0-9_]*\s*\([^\r\n]*\))\s*,')
                    if ($m.Success) {
                        $abs = $start + $m.Index
                        $proText = $proText.Remove($abs,$m.Length).Insert($abs,'CotizacionesProPanel(modoOscuro: widget.modoOscuro),')
                        $replaced = $true
                    }
                }
            }
        }
    }

    if (-not $replaced) {
        $m = [regex]::Match($proText,'(?s)children\s*:\s*\[\s*([A-Za-z_][A-Za-z0-9_]*\s*\([^\r\n]*\))\s*,')
        if ($m.Success) {
            $replacement = 'children: [' + [Environment]::NewLine + '          CotizacionesProPanel(modoOscuro: widget.modoOscuro),'
            $proText = $proText.Remove($m.Index,$m.Length).Insert($m.Index,$replacement)
            $replaced = $true
        }
    }

    if (-not $replaced) { throw "No encontre el TabBarView de Cotizaciones en pro_features.dart. No se hizo ningun cambio." }

    # 4) Crear el panel. SOLO LEE productos desde LocalDatabase.
    #    No crea tablas, no actualiza stock y no toca ventas.
    $panelText = @'
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/local_database.dart';

class CotizacionesProPanel extends StatefulWidget {
  final bool modoOscuro;
  const CotizacionesProPanel({super.key, required this.modoOscuro});

  @override
  State<CotizacionesProPanel> createState() => _CotizacionesProPanelState();
}

class _CotizacionesProPanelState extends State<CotizacionesProPanel> {
  final LocalDatabase _db = LocalDatabase();
  final _buscar = TextEditingController();
  final _cliente = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();
  final _direccion = TextEditingController();
  final _notas = TextEditingController();
  List<Map<String,dynamic>> _productos = [];
  List<Map<String,dynamic>> _filtrados = [];
  final List<Map<String,dynamic>> _items = [];
  bool _cargando = true;
  bool _enviando = false;
  double _descuento = 0;

  Color get _violeta => const Color(0xFF5B21B6);
  Color get _azul => const Color(0xFF2563EB);
  Color get _fondo => widget.modoOscuro ? const Color(0xFF10111B) : const Color(0xFFF5F6FA);
  Color get _tarjeta => widget.modoOscuro ? const Color(0xFF1B1930) : Colors.white;
  Color get _texto => widget.modoOscuro ? Colors.white : const Color(0xFF202332);
  Color get _suave => widget.modoOscuro ? const Color(0xFFAAA4BA) : const Color(0xFF667085);

  @override
  void initState() { super.initState(); _cargarProductos(); }
  @override
  void dispose() { _buscar.dispose(); _cliente.dispose(); _telefono.dispose(); _correo.dispose(); _direccion.dispose(); _notas.dispose(); super.dispose(); }

  Future<void> _cargarProductos() async {
    try {
      final rows = await _db.getAll('productos', orderBy: 'nombre');
      if (!mounted) return;
      setState(() { _productos = rows; _filtrados = rows; _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _aviso('No se pudieron cargar los productos.');
    }
  }

  double _precio(Map<String,dynamic> p) => (p['precio'] as num? ?? p['price'] as num? ?? 0).toDouble();
  void _buscarProductos(String value) {
    final q = value.trim().toLowerCase();
    setState(() => _filtrados = q.isEmpty ? _productos : _productos.where((p) {
      final n=(p['nombre']??'').toString().toLowerCase();
      final c=(p['codigo_barras']??'').toString().toLowerCase();
      final m=(p['marca']??'').toString().toLowerCase();
      return n.contains(q)||c.contains(q)||m.contains(q);
    }).toList());
  }

  void _agregar(Map<String,dynamic> p) {
    final id=(p['id']??p['codigo_barras']??p['nombre']).toString();
    final i=_items.indexWhere((x)=>x['_id']==id);
    setState(() {
      if(i>=0) { _items[i]['cantidad']=(_items[i]['cantidad'] as int)+1; }
      else { _items.add({'_id':id,'nombre':(p['nombre']??'Producto').toString(),'codigo':(p['codigo_barras']??'').toString(),'precio':_precio(p),'cantidad':1}); }
    });
  }
  void _cantidad(int i,int delta){ setState(()=>(((_items[i]['cantidad'] as int)+delta)<=0)?_items.removeAt(i):_items[i]['cantidad']=(_items[i]['cantidad'] as int)+delta); }
  double _linea(Map<String,dynamic> x)=>(x['precio'] as double)*(x['cantidad'] as int);
  double get _subtotal=>_items.fold(0,(s,x)=>s+_linea(x));
  double get _descuentoMonto=>_subtotal*(_descuento/100);
  double get _total=>_subtotal-_descuentoMonto;
  String _numero()=> 'COT-${DateTime.now().millisecondsSinceEpoch}';
  void _aviso(String t){if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(t),behavior:SnackBarBehavior.floating,backgroundColor:_violeta));}

  InputDecoration _input(String label,IconData icon)=>InputDecoration(labelText:label,prefixIcon:Icon(icon,color:_violeta),filled:true,fillColor:widget.modoOscuro?const Color(0xFF24203B):const Color(0xFFF7F5FF),border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none));

  Future<Uint8List> _crearPdf(String numero) async {
    final doc=pw.Document();
    final fecha=DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final violeta=PdfColor.fromHex('#5B21B6');
    final azul=PdfColor.fromHex('#2563EB');
    final claro=PdfColor.fromHex('#F4F3FF');
    doc.addPage(pw.MultiPage(margin:const pw.EdgeInsets.all(32),build:(_)=>[
      pw.Container(padding:const pw.EdgeInsets.all(20),decoration:pw.BoxDecoration(color:violeta,borderRadius:pw.BorderRadius.circular(14)),child:pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[
        pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.Text('SINTHETIX PRO',style:pw.TextStyle(color:PdfColors.white,fontSize:22,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:4),pw.Text('COTIZACION COMERCIAL',style:const pw.TextStyle(color:PdfColors.white,fontSize:10))]),
        pw.Text(numero,style:pw.TextStyle(color:PdfColors.white,fontWeight:pw.FontWeight.bold))])),
      pw.SizedBox(height:16),
      pw.Container(padding:const pw.EdgeInsets.all(14),color:claro,child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.Text('CLIENTE',style:pw.TextStyle(color:violeta,fontSize:9,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:4),pw.Text(_cliente.text.trim().isEmpty?'Cliente general':_cliente.text.trim(),style:pw.TextStyle(fontSize:12,fontWeight:pw.FontWeight.bold)),if(_telefono.text.trim().isNotEmpty)pw.Text('WhatsApp: ${_telefono.text.trim()}'),if(_correo.text.trim().isNotEmpty)pw.Text(_correo.text.trim()),if(_direccion.text.trim().isNotEmpty)pw.Text(_direccion.text.trim()),pw.Text('Fecha: $fecha')])),
      pw.SizedBox(height:18),
      pw.Table(border:pw.TableBorder(horizontalInside:pw.BorderSide(color:PdfColors.grey300,width:.5)),children:[
        pw.TableRow(decoration:pw.BoxDecoration(color:claro),children:[_celda('PRODUCTO',true,violeta),_celda('CANT.',true,violeta),_celda('PRECIO',true,violeta),_celda('TOTAL',true,violeta)]),
        ..._items.map((x)=>pw.TableRow(children:[_celda(x['nombre'].toString(),false,null),_celda('${x['cantidad']}',false,null),_celda('\$${(x['precio'] as double).toStringAsFixed(2)}',false,null),_celda('\$${_linea(x).toStringAsFixed(2)}',false,null)]))]),
      pw.SizedBox(height:18),
      pw.Align(alignment:pw.Alignment.centerRight,child:pw.Container(width:230,padding:const pw.EdgeInsets.all(14),color:claro,child:pw.Column(children:[_filaPdf('Subtotal',_subtotal),_filaPdf('Descuento',_descuentoMonto),pw.Divider(),_filaPdf('TOTAL',_total,grande:true)]))),
      if(_notas.text.trim().isNotEmpty)pw.Padding(padding:const pw.EdgeInsets.only(top:18),child:pw.Text('Notas: ${_notas.text.trim()}')),
      pw.SizedBox(height:28),pw.Divider(),pw.Center(child:pw.Text('Gracias por preferir SINTHETIX PRO',style:pw.TextStyle(color:azul,fontWeight:pw.FontWeight.bold)))
    ]));
    return doc.save();
  }
  pw.Widget _celda(String s,bool bold,PdfColor? color)=>pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Text(s,style:pw.TextStyle(fontSize:9,fontWeight:bold?pw.FontWeight.bold:pw.FontWeight.normal,color:color)));
  pw.Widget _filaPdf(String s,double v,{bool grande=false})=>pw.Padding(padding:const pw.EdgeInsets.symmetric(vertical:3),child:pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text(s,style:pw.TextStyle(fontSize:grande?12:9,fontWeight:grande?pw.FontWeight.bold:pw.FontWeight.normal)),pw.Text('\$${v.toStringAsFixed(2)}',style:pw.TextStyle(fontSize:grande?15:9,fontWeight:grande?pw.FontWeight.bold:pw.FontWeight.normal))]));

  Future<void> _enviarCotizacion() async {
    if(_items.isEmpty){_aviso('Agrega productos antes de enviar la cotizacion.');return;}
    setState(()=>_enviando=true);
    try {
      final numero=_numero();
      final bytes=await _crearPdf(numero);
      await Printing.sharePdf(bytes:bytes,filename:'$numero.pdf',subject:'Cotizacion $numero - SINTHETIX PRO');
      _aviso('PDF listo para compartir. En Android selecciona WhatsApp.');
    } catch(e) { _aviso('No se pudo preparar el PDF.'); }
    finally { if(mounted)setState(()=>_enviando=false); }
  }

  Future<void> _abrirWhatsApp() async {
    final telefono=_telefono.text.replaceAll(RegExp(r'[^0-9]'),'');
    final msg=Uri.encodeComponent('SINTHETIX PRO - COTIZACION\nNumero: ${_numero()}\nCliente: ${_cliente.text.trim().isEmpty?'Cliente':_cliente.text.trim()}\nTotal: \$${_total.toStringAsFixed(2)}\nEl PDF se envia desde el boton Enviar cotizacion.');
    final uri=telefono.isEmpty?Uri.parse('https://wa.me/?text=$msg'):Uri.parse('https://wa.me/$telefono?text=$msg');
    await launchUrl(uri,webOnlyWindowName:'_blank');
  }

  @override Widget build(BuildContext context){
    if(_cargando)return const Center(child:CircularProgressIndicator());
    return Container(color:_fondo,child:LayoutBuilder(builder:(context,c)=>SingleChildScrollView(padding:const EdgeInsets.all(16),child:c.maxWidth>=900?Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(flex:6,child:_editor()),const SizedBox(width:16),Expanded(flex:4,child:_resumen())]):Column(children:[_editor(),const SizedBox(height:16),_resumen()]))));
  }

  Widget _editor()=>_card(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('Nueva cotizacion',style:TextStyle(color:_texto,fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:14),
    Wrap(spacing:12,runSpacing:12,children:[SizedBox(width:280,child:TextField(controller:_cliente,decoration:_input('Nombre del cliente',Icons.person_outline))),SizedBox(width:230,child:TextField(controller:_telefono,keyboardType:TextInputType.phone,decoration:_input('Telefono / WhatsApp',Icons.phone_outlined))),SizedBox(width:250,child:TextField(controller:_correo,keyboardType:TextInputType.emailAddress,decoration:_input('Correo',Icons.email_outlined))),SizedBox(width:280,child:TextField(controller:_direccion,decoration:_input('Direccion',Icons.location_on_outlined)))]),
    const SizedBox(height:14),TextField(controller:_buscar,onChanged:_buscarProductos,decoration:_input('Buscar y seleccionar productos',Icons.search_rounded)),const SizedBox(height:10),
    Container(constraints:const BoxConstraints(maxHeight:300),child:ListView.separated(shrinkWrap:true,itemCount:_filtrados.length,separatorBuilder:(_,__)=>const SizedBox(height:5),itemBuilder:(_,i){final p=_filtrados[i];return ListTile(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),tileColor:widget.modoOscuro?const Color(0xFF24203B):const Color(0xFFF8F7FC),title:Text(p['nombre']?.toString()??'Producto',style:TextStyle(color:_texto,fontWeight:FontWeight.w800)),subtitle:Text(p['codigo_barras']?.toString()??'',style:TextStyle(color:_suave)),trailing:Row(mainAxisSize:MainAxisSize.min,children:[Text('\$${_precio(p).toStringAsFixed(2)}',style:TextStyle(color:_azul,fontWeight:FontWeight.w900)),const SizedBox(width:8),Icon(Icons.add_circle_rounded,color:_violeta)]),onTap:()=>_agregar(p));})),
    const SizedBox(height:12),TextField(controller:_notas,maxLines:3,decoration:_input('Notas y condiciones',Icons.notes_outlined)),const SizedBox(height:10),
    Row(children:[Expanded(child:Text('Descuento general (%)',style:TextStyle(color:_suave))),SizedBox(width:110,child:TextField(keyboardType:const TextInputType.numberWithOptions(decimal:true),onChanged:(v)=>setState(()=>_descuento=double.tryParse(v.replaceAll(',','.'))??0),decoration:const InputDecoration(suffixText:'%',isDense:true)))])
  ]));

  Widget _resumen()=>_card(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Expanded(child:Text('Productos seleccionados',style:TextStyle(color:_texto,fontSize:18,fontWeight:FontWeight.w900))),Text('${_items.length}',style:TextStyle(color:_violeta,fontWeight:FontWeight.w900))]),const SizedBox(height:12),
    if(_items.isEmpty)Text('Selecciona productos del inventario.',style:TextStyle(color:_suave)),
    ...List.generate(_items.length,(i){final x=_items[i];return Container(margin:const EdgeInsets.only(bottom:7),padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:widget.modoOscuro?const Color(0xFF24203B):const Color(0xFFF8F7FC),borderRadius:BorderRadius.circular(12)),child:Row(children:[Expanded(child:Text(x['nombre'].toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(color:_texto,fontWeight:FontWeight.w800))),IconButton(onPressed:()=>_cantidad(i,-1),icon:const Icon(Icons.remove_circle_outline)),Text('${x['cantidad']}',style:TextStyle(color:_texto,fontWeight:FontWeight.w900)),IconButton(onPressed:()=>_cantidad(i,1),icon:const Icon(Icons.add_circle_outline)),SizedBox(width:80,child:Text('\$${_linea(x).toStringAsFixed(2)}',textAlign:TextAlign.right,style:TextStyle(color:_azul,fontWeight:FontWeight.w900)))]));}),
    const Divider(height:24),_fila('Subtotal',_subtotal),_fila('Descuento',_descuentoMonto),const SizedBox(height:4),Row(children:[Expanded(child:Text('TOTAL',style:TextStyle(color:_suave,fontWeight:FontWeight.w900))),Text('\$${_total.toStringAsFixed(2)}',style:TextStyle(color:_violeta,fontSize:27,fontWeight:FontWeight.w900))]),const SizedBox(height:16),
    SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:_enviando?null:_enviarCotizacion,icon:_enviando?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.send_rounded),label:const Text('ENVIAR COTIZACION - PDF / WHATSAPP'),style:FilledButton.styleFrom(backgroundColor:_violeta,foregroundColor:Colors.white,padding:const EdgeInsets.symmetric(vertical:16)))),
    const SizedBox(height:8),SizedBox(width:double.infinity,child:TextButton.icon(onPressed:_abrirWhatsApp,icon:const Icon(Icons.chat_rounded),label:const Text('Abrir WhatsApp con el mensaje')))
  ]));
  Widget _fila(String s,double v)=>Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Row(children:[Expanded(child:Text(s,style:TextStyle(color:_suave))),Text('\$${v.toStringAsFixed(2)}',style:TextStyle(color:_texto,fontWeight:FontWeight.w700))]));
  Widget _card({required Widget child})=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:_tarjeta,borderRadius:BorderRadius.circular(22),border:Border.all(color:widget.modoOscuro?Colors.white.withValues(alpha:.07):const Color(0xFFE7E4EF)),boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.04),blurRadius:22,offset:const Offset(0,8))]),child:child);
}
'@
    [IO.File]::WriteAllText($panel,$panelText,$utf8)

    [IO.File]::WriteAllText($pro,$proText,$utf8)

    Write-Host "Formateando archivos nuevos/modificados..." -ForegroundColor Yellow
    & dart format $pro $panel
    if ($LASTEXITCODE -ne 0) { throw "dart format fallo." }

    Write-Host "Verificando solo los archivos activos modificados..." -ForegroundColor Yellow
    $log = Join-Path $env:TEMP "sinthetix_cotizacion_v2_$stamp.txt"
    cmd.exe /c "flutter analyze lib\main.dart lib\profesional\pro_features.dart lib\profesional\cotizaciones_pro_panel.dart > `"$log`" 2>&1"
    $analysis = Get-Content $log -Raw -ErrorAction SilentlyContinue
    if ($analysis) { Write-Host $analysis }
    if ($analysis -match '(?m)^\s*error\s*-\s') { throw "Se detectaron errores Dart reales en los archivos activos." }

    Write-Host ""; Write-Host "============================================================" -ForegroundColor Green
    Write-Host " COTIZACIONES INSTALADAS CORRECTAMENTE" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "Productos reales + cliente + descuento + PDF + compartir." -ForegroundColor Green
    Write-Host "El boton ENVIAR COTIZACION prepara el PDF para compartir." -ForegroundColor Green
    Write-Host "En Android: selecciona WhatsApp en la ventana de compartir." -ForegroundColor Green
    Write-Host "Backup: $backupDir" -ForegroundColor Cyan
    Write-Host "Ejecuta: flutter run -d chrome" -ForegroundColor Yellow
}
catch {
    Write-Host ""; Write-Host "FALLO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "RESTaurando archivos originales..." -ForegroundColor Yellow
    Copy-Item (Join-Path $backupDir 'main.dart') $main -Force
    Copy-Item (Join-Path $backupDir 'pro_features.dart') $pro -Force
    if (Test-Path (Join-Path $backupDir 'cotizaciones_pro_panel.dart')) { Copy-Item (Join-Path $backupDir 'cotizaciones_pro_panel.dart') $panel -Force }
    elseif (Test-Path $panel) { Remove-Item $panel -Force }
    Write-Host "RESTAURACION COMPLETA." -ForegroundColor Green
    Write-Host "Backup: $backupDir" -ForegroundColor Cyan
    exit 1
}
