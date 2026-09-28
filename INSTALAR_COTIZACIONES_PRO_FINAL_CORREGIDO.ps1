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
  const CotizacionesProPanel({super.key,required this.modoOscuro,required this.cargarProductos});
  @override State<CotizacionesProPanel> createState()=>_CotizacionesProPanelState();
}

class _Item {
  final Map<String,dynamic> producto;
  int cantidad;
  double precio;
  double descuento;
  _Item({required this.producto,required this.cantidad,required this.precio,this.descuento=0});
  double get bruto=>cantidad*precio;
  double get subtotal=>bruto-(bruto*descuento/100);
}

class _CotizacionesProPanelState extends State<CotizacionesProPanel>{
  final cliente=TextEditingController();
  final telefono=TextEditingController();
  final email=TextEditingController();
  final direccion=TextEditingController();
  final nota=TextEditingController();
  final buscar=TextEditingController();
  List<Map<String,dynamic>> productos=[];
  final items=< _Item>[];
  bool cargando=true;

  Color get bg=>widget.modoOscuro?const Color(0xFF11101A):const Color(0xFFF5F6FA);
  Color get card=>widget.modoOscuro?const Color(0xFF1D1B29):Colors.white;
  Color get text=>widget.modoOscuro?Colors.white:const Color(0xFF202124);
  Color get muted=>widget.modoOscuro?Colors.white70:const Color(0xFF687080);
  double num(dynamic v)=>v is num?v.toDouble():double.tryParse(v?.toString()??'')??0;
  double get total=>items.fold(0,(s,i)=>s+i.subtotal);
  String money(double v)=>'\$${v.toStringAsFixed(2)}';

  @override void initState(){super.initState();_load();}
  @override void dispose(){cliente.dispose();telefono.dispose();email.dispose();direccion.dispose();nota.dispose();buscar.dispose();super.dispose();}

  Future<void> _load()async{
    try{final x=await widget.cargarProductos();if(mounted)setState((){productos=x;cargando=false;});}
    catch(_){if(mounted)setState(()=>cargando=false);}
  }

  List<Map<String,dynamic>> get filtered{
    final q=buscar.text.trim().toLowerCase();
    if(q.isEmpty)return productos.take(80).toList();
    return productos.where((p){
      final s=[p['nombre'],p['codigo_barras'],p['categoria'],p['marca']].map((x)=>x?.toString().toLowerCase()??'').join(' ');
      return s.contains(q);
    }).take(80).toList();
  }

  void add(Map<String,dynamic> p){
    final stock=num(p['stock']).toInt();
    if(stock<=0)return;
    final i=items.indexWhere((x)=>x.producto['id']?.toString()==p['id']?.toString());
    setState((){if(i>=0){if(items[i].cantidad<stock)items[i].cantidad++;}else{items.add(_Item(producto:p,cantidad:1,precio:num(p['precio'])));}});
  }

  Future<void> edit(int n)async{
    final i=items[n];
    final c=TextEditingController(text:'${i.cantidad}');
    final p=TextEditingController(text:i.precio.toStringAsFixed(2));
    final d=TextEditingController(text:i.descuento.toStringAsFixed(2));
    final r=await showDialog<List<double>>(context:context,builder:(ctx)=>AlertDialog(
      title:Text(i.producto['nombre']?.toString()??'Producto'),
      content:SizedBox(width:420,child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:c,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Cantidad',border:OutlineInputBorder())),
        const SizedBox(height:10),
        TextField(controller:p,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Precio unitario',prefixText:'\$ ',border:OutlineInputBorder())),
        const SizedBox(height:10),
        TextField(controller:d,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Descuento %',border:OutlineInputBorder())),
      ])),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,[
          (int.tryParse(c.text)??1).clamp(1,9999).toDouble(),
          (double.tryParse(p.text.replaceAll(',','.'))??0).clamp(0,999999999).toDouble(),
          (double.tryParse(d.text.replaceAll(',','.'))??0).clamp(0,100).toDouble()
        ]),child:const Text('Aplicar'))
      ]));
    c.dispose();p.dispose();d.dispose();
    if(r!=null&&mounted)setState((){i.cantidad=r[0].toInt();i.precio=r[1];i.descuento=r[2];});
  }

  pw.Widget cell(String s,{bool bold=false})=>pw.Padding(padding:const pw.EdgeInsets.all(6),child:pw.Text(s,style:pw.TextStyle(fontSize:9,fontWeight:bold?pw.FontWeight.bold:pw.FontWeight.normal)));

  Future<Uint8List> pdf()async{
    final doc=pw.Document();final now=DateTime.now();
    doc.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,margin:const pw.EdgeInsets.all(32),build:(_)=>[
      pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[
        pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
          pw.Text('SINTHETIX PRO',style:pw.TextStyle(fontSize:22,fontWeight:pw.FontWeight.bold)),
          pw.SizedBox(height:3),pw.Text('COTIZACION')
        ]),
        pw.Text('${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}')
      ]),
      pw.SizedBox(height:18),
      pw.Container(padding:const pw.EdgeInsets.all(10),decoration:pw.BoxDecoration(border:pw.Border.all(color:PdfColors.grey400)),child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
        pw.Text('CLIENTE',style:pw.TextStyle(fontWeight:pw.FontWeight.bold)),
        pw.Text(cliente.text.trim().isEmpty?'Cliente':cliente.text.trim()),
        if(telefono.text.trim().isNotEmpty)pw.Text('Telefono: ${telefono.text.trim()}'),
        if(email.text.trim().isNotEmpty)pw.Text('Email: ${email.text.trim()}'),
        if(direccion.text.trim().isNotEmpty)pw.Text('Direccion: ${direccion.text.trim()}')
      ])),
      pw.SizedBox(height:18),
      pw.Table(border:pw.TableBorder.all(color:PdfColors.grey400),children:[
        pw.TableRow(children:[cell('Producto',bold:true),cell('Cant.',bold:true),cell('Precio',bold:true),cell('Subtotal',bold:true)]),
        ...items.map((i)=>pw.TableRow(children:[cell(i.producto['nombre']?.toString()??'Producto'),cell('${i.cantidad}'),cell(money(i.precio)),cell(money(i.subtotal))]))
      ]),
      pw.SizedBox(height:16),
      pw.Align(alignment:pw.Alignment.centerRight,child:pw.Text('TOTAL: ${money(total)}',style:pw.TextStyle(fontSize:16,fontWeight:pw.FontWeight.bold))),
      if(nota.text.trim().isNotEmpty)pw.Padding(padding:const pw.EdgeInsets.only(top:12),child:pw.Text('Nota: ${nota.text.trim()}')),
      pw.SizedBox(height:24),pw.Text('Cotizacion sujeta a confirmacion.',style:const pw.TextStyle(fontSize:9,color:PdfColors.grey600))
    ]));
    return doc.save();
  }

  Future<void> sharePdf()async{
    if(items.isEmpty){msg('Agrega al menos un producto.');return;}
    final b=await pdf();
    await Printing.sharePdf(bytes:b,filename:'cotizacion_sinthetix_pro.pdf');
  }

  Future<void> shareFile()async{
    if(items.isEmpty){msg('Agrega al menos un producto.');return;}
    final b=await pdf();
    await Share.shareXFiles([XFile.fromData(b,name:'cotizacion_sinthetix_pro.pdf',mimeType:'application/pdf')],text:'Cotizacion SINTHETIX PRO');
  }

  Future<void> whatsapp()async{
    if(items.isEmpty){msg('Agrega al menos un producto.');return;}
    final phone=telefono.text.replaceAll(RegExp(r'[^0-9]'),'');
    if(phone.isEmpty){msg('Escribe el telefono/WhatsApp del cliente.');return;}
    final name=cliente.text.trim().isEmpty?'Cliente':cliente.text.trim();
    final uri=Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent('SINTHETIX PRO - COTIZACION\nCliente: $name\nTotal: ${money(total)}\nProductos: ${items.length}') }');
    if(!await launchUrl(uri,mode:LaunchMode.externalApplication))msg('No se pudo abrir WhatsApp.');
  }

  void msg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}

  InputDecoration dec(String s,{IconData? icon})=>InputDecoration(labelText:s,prefixIcon:icon==null?null:Icon(icon),border:const OutlineInputBorder(),filled:true,fillColor:card);

  Widget productsPanel()=>Card(color:card,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Icon(Icons.inventory_2_outlined,color:Colors.deepPurple),const SizedBox(width:8),Expanded(child:Text('Productos del inventario',style:TextStyle(color:text,fontSize:17,fontWeight:FontWeight.w800))),IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),
    TextField(controller:buscar,onChanged:(_)=>setState((){}),decoration:dec('Buscar nombre, codigo, marca o categoria',icon:Icons.search)),
    const SizedBox(height:10),
    if(cargando)const Center(child:Padding(padding:EdgeInsets.all(25),child:CircularProgressIndicator()))
    else if(filtered.isEmpty)Text('No hay productos para mostrar.',style:TextStyle(color:muted))
    else SizedBox(height:360,child:ListView.separated(itemCount:filtered.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(_,n){
      final p=filtered[n];final stock=num(p['stock']).toInt();
      return ListTile(title:Text(p['nombre']?.toString()??'Producto',style:TextStyle(color:text,fontWeight:FontWeight.w700)),subtitle:Text('${p['categoria']??'Sin categoria'} · Stock: $stock · ${money(num(p['precio']))}',style:TextStyle(color:muted,fontSize:12)),trailing:FilledButton.icon(onPressed:stock>0?()=>add(p):null,icon:const Icon(Icons.add,size:17),label:const Text('Agregar')));
    }))
  ])));

  Widget itemsPanel()=>Card(color:card,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Icon(Icons.receipt_long,color:Colors.deepPurple),const SizedBox(width:8),Expanded(child:Text('Detalle de cotizacion',style:TextStyle(color:text,fontSize:17,fontWeight:FontWeight.w800))),Text('${items.length} productos',style:TextStyle(color:muted))]),
    const SizedBox(height:10),
    if(items.isEmpty)Text('Agrega productos del inventario.',style:TextStyle(color:muted))
    else ...List.generate(items.length,(n){final i=items[n];return Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(10),decoration:BoxDecoration(border:Border.all(color:muted.withValues(alpha:.18)),borderRadius:BorderRadius.circular(12)),child:Row(children:[
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(i.producto['nombre']?.toString()??'Producto',style:TextStyle(color:text,fontWeight:FontWeight.w700)),Text('${i.cantidad} x ${money(i.precio)} · Desc. ${i.descuento.toStringAsFixed(1)}%',style:TextStyle(color:muted,fontSize:12))])),
      Text(money(i.subtotal),style:TextStyle(color:text,fontWeight:FontWeight.w800)),
      IconButton(onPressed:()=>edit(n),icon:const Icon(Icons.edit_outlined,size:19)),
      IconButton(onPressed:()=>setState(()=>items.removeAt(n)),icon:const Icon(Icons.delete_outline,size:19))
    ]));}),
    const Divider(height:24),
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('TOTAL',style:TextStyle(color:text,fontSize:18,fontWeight:FontWeight.w900)),Text(money(total),style:const TextStyle(color:Colors.deepPurple,fontSize:22,fontWeight:FontWeight.w900))])
  ])));

  Widget clientPanel()=>Card(color:card,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('Datos del cliente',style:TextStyle(color:text,fontSize:17,fontWeight:FontWeight.w800)),
    const SizedBox(height:12),
    TextField(controller:cliente,decoration:dec('Nombre')),
    const SizedBox(height:10),TextField(controller:telefono,keyboardType:TextInputType.phone,decoration:dec('Telefono / WhatsApp',icon:Icons.phone_outlined)),
    const SizedBox(height:10),TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:dec('Email',icon:Icons.email_outlined)),
    const SizedBox(height:10),TextField(controller:direccion,decoration:dec('Direccion',icon:Icons.location_on_outlined)),
    const SizedBox(height:10),TextField(controller:nota,maxLines:2,decoration:dec('Nota / condiciones'))
  ])));

  Widget actions()=>Card(color:card,child:Padding(padding:const EdgeInsets.all(16),child:Wrap(spacing:10,runSpacing:10,children:[
    FilledButton.icon(onPressed:sharePdf,icon:const Icon(Icons.picture_as_pdf_outlined),label:const Text('PDF / Imprimir')),
    OutlinedButton.icon(onPressed:shareFile,icon:const Icon(Icons.share_outlined),label:const Text('Compartir PDF')),
    OutlinedButton.icon(onPressed:whatsapp,icon:const Icon(Icons.chat_outlined),label:const Text('WhatsApp')),
    TextButton.icon(onPressed:(){setState((){items.clear();cliente.clear();telefono.clear();email.clear();direccion.clear();nota.clear();});},icon:const Icon(Icons.refresh),label:const Text('Nueva cotizacion'))
  ])));

  @override Widget build(BuildContext context)=>Container(color:bg,child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(20,12,20,30),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('Cotizaciones profesionales',style:TextStyle(color:text,fontSize:24,fontWeight:FontWeight.w900)),
    const SizedBox(height:4),Text('Selecciona productos reales del inventario y genera un documento para compartir.',style:TextStyle(color:muted)),
    const SizedBox(height:18),
    LayoutBuilder(builder:(context,c){
      final left=Column(children:[productsPanel(),const SizedBox(height:14),itemsPanel()]);
      final right=Column(children:[clientPanel(),const SizedBox(height:14),actions()]);
      if(c.maxWidth>=1050)return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(flex:6,child:left),const SizedBox(width:16),Expanded(flex:4,child:right)]);
      return Column(children:[left,const SizedBox(height:14),right]);
    })
  ]));
}
'@

[IO.File]::WriteAllText($panel,$panelCode,$enc)

if($ptext -notmatch "cotizaciones_pro_panel.dart"){$ptext="import 'cotizaciones_pro_panel.dart';`n"+$ptext}

if($ptext -notmatch "CargarProductosCotizacion"){
  $ptext=[regex]::Replace($ptext,'(final bool modoOscuro;)', '$1`n  final CargarProductosCotizacion? cargarProductos;',1)
  $ptext=[regex]::Replace($ptext,'(required this\.modoOscuro,)', '$1`n    this.cargarProductos,',1)
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

$call='(?ms)ProfesionalScreen\(\s*onAbrirSidebar:\s*_abrirSidebar,\s*modoOscuro:\s*_modoOscuro,\s*\),'
if($m -notmatch $call){throw "No encontre la llamada actual a ProfesionalScreen en main.dart."}
$m=[regex]::Replace($m,$call,"ProfesionalScreen(onAbrirSidebar:_abrirSidebar,modoOscuro:_modoOscuro,cargarProductos:()=>DatabaseService().getProductos(),),",1)

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
