$ErrorActionPreference="Stop"
$root=(Get-Location).Path
$main=Join-Path $root "lib\main.dart"
$pro=Join-Path $root "lib\profesional\pro_features.dart"
$panel=Join-Path $root "lib\profesional\cotizaciones_pro_panel.dart"
if(!(Test-Path $main)){throw "No encuentro lib\main.dart. Ejecuta desde C:\Users\BRANAXEL\mi_tienda"}
if(!(Test-Path $pro)){throw "No encuentro lib\profesional\pro_features.dart"}
$stamp=Get-Date -Format "yyyyMMdd_HHmmss"
$bak=Join-Path $root "BACKUP_COTIZACIONES_PRO_$stamp"
New-Item -ItemType Directory -Path $bak -Force|Out-Null
Copy-Item $main "$bak\main.dart"; Copy-Item $pro "$bak\pro_features.dart"
if(Test-Path $panel){Copy-Item $panel "$bak\cotizaciones_pro_panel.dart"}
$enc=New-Object System.Text.UTF8Encoding($false)
function R($p){[IO.File]::ReadAllText($p,$enc)}
function W($p,$s){[IO.File]::WriteAllText($p,$s,$enc)}
function Close([string]$s,[int]$o){
$d=0;$sq=$false;$dq=$false;$esc=$false;$lc=$false;$bc=$false
for($i=$o;$i-lt$s.Length;$i++){ $c=$s[$i];$n=if($i+1-lt$s.Length){$s[$i+1]}else{[char]0}
if($lc){if($c-eq"`n"){$lc=$false};continue};if($bc){if($c-eq"*" -and $n-eq"/"){$bc=$false;$i++};continue}
if(!$sq-and!$dq-and$c-eq"/"-and$n-eq"/"){$lc=$true;$i++;continue}
if(!$sq-and!$dq-and$c-eq"/"-and$n-eq"*"){$bc=$true;$i++;continue}
if($esc){$esc=$false;continue};if(($sq-or$dq)-and$c-eq"\"){$esc=$true;continue}
if($c-eq"'"-and!$dq){$sq=!$sq;continue};if($c-eq'"'-and!$sq){$dq=!$dq;continue}
if(!$sq-and!$dq){if($c-eq"{"){$d++}elseif($c-eq"}"){$d--;if($d-eq0){return$i}}}}
return -1}
function ReplaceMethod([string]$s,[string]$rx,[string]$new){
$m=[regex]::Match($s,$rx);if(!$m.Success){throw "No encontre el bloque esperado: $rx"}
$o=$s.IndexOf("{",$m.Index+$m.Length);if($o-lt0){throw "No encontre llave de apertura"}
$c=Close $s $o;if($c-lt0){throw "No encontre llave de cierre"}
$s.Substring(0,$m.Index)+$new+$s.Substring($c+1)}
try{
Write-Host "SINTHETIX PRO - COTIZACIONES PRO V1" -ForegroundColor Cyan
Write-Host "Backup: $bak" -ForegroundColor Green
$m=R $main;$p=R $pro

if($m-notmatch "import 'profesional/cotizaciones_pro_panel.dart';"){
$ms=[regex]::Matches($m,"(?m)^\s*import\s+[^;]+;\s*\r?\n")
if($ms.Count-eq0){throw "No localice imports"}
$x=$ms[$ms.Count-1];$m=$m.Insert($x.Index+$x.Length,"import 'profesional/cotizaciones_pro_panel.dart';`r`n")}

$rx="(?s)ProfesionalScreen\s*\(\s*onAbrirSidebar\s*:\s*_abrirSidebar\s*,\s*modoOscuro\s*:\s*_modoOscuro\s*(?:,\s*cargarProductos\s*:\s*[^,]+)?(?:,\s*cargarClientes\s*:\s*[^,]+)?\s*,?\s*\)"
if($m-notmatch $rx){throw "No encontre la instancia actual de ProfesionalScreen"}
$m=[regex]::Replace($m,$rx,"ProfesionalScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro, cargarProductos: () => DatabaseService().getProductos(), cargarClientes: () => DatabaseService().getClientes(),)",1)
if($m-notmatch "getProductos\s*\("){throw "main.dart no contiene getProductos()"}
if($m-notmatch "getClientes\s*\("){throw "main.dart no contiene getClientes()"}

if($p-notmatch "cotizaciones_pro_panel.dart"){
$p=$p.Replace("import 'package:flutter/material.dart';","import 'package:flutter/material.dart';`r`nimport 'cotizaciones_pro_panel.dart';")
}
if($p-notmatch "cargarProductos"){
$p=$p.Replace("  final bool modoOscuro;","  final bool modoOscuro;`r`n  final Future<List<Map<String, dynamic>>> Function() cargarProductos;`r`n  final Future<List<Map<String, dynamic>>> Function() cargarClientes;")
}
if($p-notmatch "required this.cargarProductos"){
$p=$p.Replace("    required this.modoOscuro,","    required this.modoOscuro,`r`n    required this.cargarProductos,`r`n    required this.cargarClientes,")
}
$p=ReplaceMethod $p '(?m)^\s*Widget\s+_quotes\s*\(\s*\)\s*\{' @'
  Widget _quotes() {
    return CotizacionesProPanel(
      modoOscuro: widget.modoOscuro,
      cargarProductos: widget.cargarProductos,
      cargarClientes: widget.cargarClientes,
      onAuditoria: _audit,
    );
  }
'@

$dart=@'
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class CotizacionesProPanel extends StatefulWidget {
  final bool modoOscuro;
  final Future<List<Map<String,dynamic>>> Function() cargarProductos;
  final Future<List<Map<String,dynamic>>> Function() cargarClientes;
  final void Function(String)? onAuditoria;
  const CotizacionesProPanel({super.key,required this.modoOscuro,required this.cargarProductos,required this.cargarClientes,this.onAuditoria});
  @override State<CotizacionesProPanel> createState()=>_CotizacionesProPanelState();
}
class _CotizacionesProPanelState extends State<CotizacionesProPanel>{
  final cliente=TextEditingController(),telefono=TextEditingController(),whatsapp=TextEditingController(),email=TextEditingController(),direccion=TextEditingController(),descuento=TextEditingController(text:'0');
  List<Map<String,dynamic>> productos=[],clientes=[]; final items=<_Item>[]; bool cargando=true,generando=false; late String numero;
  Color get bg=>widget.modoOscuro?const Color(0xff101119):const Color(0xfff4f6fa);
  Color get card=>widget.modoOscuro?const Color(0xff1b1d28):Colors.white;
  Color get ink=>widget.modoOscuro?Colors.white:const Color(0xff20232a);
  Color get muted=>widget.modoOscuro?const Color(0xff9ba2b2):const Color(0xff687181);
  Color get primary=>const Color(0xff5b2eff);
  @override void initState(){super.initState();numero=_numero();_load();}
  @override void dispose(){cliente.dispose();telefono.dispose();whatsapp.dispose();email.dispose();direccion.dispose();descuento.dispose();super.dispose();}
  String _numero()=> 'COT-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}';
  double n(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??0}'.replaceAll(',','.'))??0;
  Future<void> _load()async{try{final r=await Future.wait([widget.cargarProductos(),widget.cargarClientes()]);if(mounted)setState((){productos=List<Map<String,dynamic>>.from(r[0]);clientes=List<Map<String,dynamic>>.from(r[1]);cargando=false;});}catch(e){if(mounted){setState(()=>cargando=false);_snack('No se pudieron cargar los datos: $e',Colors.red);}}}
  double get subtotal=>items.fold(0,(s,i)=>s+i.subtotal);
  double get desc=>n(descuento.text).clamp(0,subtotal).toDouble();
  double get total=>(subtotal-desc).clamp(0,double.infinity);
  void _snack(String s,Color c)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s),backgroundColor:c));
  Future<void> _product()async{
    final q=TextEditingController();String term='';
    final p=await showDialog<Map<String,dynamic>>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setD){
      final list=productos.where((x)=>('${x['nombre']??''} ${x['codigo_barras']??''}').toLowerCase().contains(term.toLowerCase())).take(100).toList();
      return AlertDialog(title:const Text('Seleccionar producto'),content:SizedBox(width:600,height:480,child:Column(children:[
        TextField(controller:q,autofocus:true,onChanged:(v)=>setD(()=>term=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),labelText:'Buscar por nombre o código',border:OutlineInputBorder())),
        const SizedBox(height:10),Expanded(child:list.isEmpty?const Center(child:Text('No hay productos.')):ListView.builder(itemCount:list.length,itemBuilder:(_,i){final x=list[i];return ListTile(title:Text('${x['nombre']??'Producto'}'),subtitle:Text('Stock: ${x['stock']??0}  •  Código: ${x['codigo_barras']??'-'}'),trailing:Text('\$${n(x['precio']).toStringAsFixed(2)}'),onTap:()=>Navigator.pop(c,x));}))
      ])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancelar'))]);
    }));
    q.dispose();if(p==null)return;final i=items.indexWhere((x)=>x.id==p['id'].toString());if(i>=0){setState(()=>items[i].qty++);}else{setState(()=>items.add(_Item(p['id'].toString(),'${p['nombre']??'Producto'}','${p['codigo_barras']??''}',n(p['precio']))));}
  }
  Future<void> _client()async{
    if(clientes.isEmpty){_snack('No hay clientes registrados.',Colors.orange);return;}
    await showModalBottomSheet(context:context,builder:(c)=>SafeArea(child:ListView.builder(itemCount:clientes.length,itemBuilder:(_,i){final x=clientes[i],name='${x['nombre']??'Cliente'}';return ListTile(title:Text(name),subtitle:Text('${x['telefono']??x['phone']??''}  ${x['email']??''}'),onTap:(){cliente.text=name;telefono.text='${x['telefono']??x['phone']??''}';whatsapp.text='${x['whatsapp']??x['telefono']??x['phone']??''}';email.text='${x['email']??''}';direccion.text='${x['direccion']??x['address']??''}';Navigator.pop(c);setState((){});});})));
  }
  String _message()=>['COTIZACIÓN $numero','Cliente: ${cliente.text.trim().isEmpty?'Sin nombre':cliente.text.trim()}','',...items.map((i)=>'${i.name} x${i.qty} = \$${i.subtotal.toStringAsFixed(2)}'),'','Subtotal: \$${subtotal.toStringAsFixed(2)}','Descuento: \$${desc.toStringAsFixed(2)}','TOTAL: \$${total.toStringAsFixed(2)}'].join('\n');
  Future<void> _wa()async{var phone=(whatsapp.text.isEmpty?telefono.text:whatsapp.text).replaceAll(RegExp(r'[^0-9+]'),'');if(phone.startsWith('+'))phone=phone.substring(1);if(phone.isEmpty){_snack('Escribe el WhatsApp del cliente.',Colors.orange);return;}final u=Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(_message())}');if(await launchUrl(u,mode:LaunchMode.externalApplication)){widget.onAuditoria?.call('WhatsApp preparado para $numero');}}
  Future<Uint8List> _pdf()async{final d=pw.Document();d.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,build:(_)=>[
    pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text('SINTHETIX PRO',style:pw.TextStyle(fontSize:22,fontWeight:pw.FontWeight.bold)),pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.end,children:[pw.Text('COTIZACIÓN'),pw.Text(numero),pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()))])]),
    pw.SizedBox(height:18),pw.Text('CLIENTE',style:pw.TextStyle(fontWeight:pw.FontWeight.bold)),pw.Text('Nombre: ${cliente.text}'),pw.Text('Teléfono: ${telefono.text}'),pw.Text('WhatsApp: ${whatsapp.text}'),pw.Text('Email: ${email.text}'),pw.Text('Dirección: ${direccion.text}'),pw.SizedBox(height:18),
    pw.TableHelper.fromTextArray(headers:['Producto','Código','Cant.','Precio','Importe'],data:items.map((i)=>[i.name,i.code,'${i.qty}','\$${i.price.toStringAsFixed(2)}','\$${i.subtotal.toStringAsFixed(2)}']).toList()),
    pw.SizedBox(height:14),pw.Align(alignment:pw.Alignment.centerRight,child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.end,children:[pw.Text('Subtotal: \$${subtotal.toStringAsFixed(2)}'),pw.Text('Descuento: \$${desc.toStringAsFixed(2)}'),pw.Text('TOTAL: \$${total.toStringAsFixed(2)}',style:pw.TextStyle(fontSize:15,fontWeight:pw.FontWeight.bold))]))
  ]));return d.save();}
  Future<void> _share()async{if(items.isEmpty){_snack('Agrega al menos un producto.',Colors.orange);return;}setState(()=>generando=true);try{final b=await _pdf();await Printing.sharePdf(bytes:b,filename:'$numero.pdf');widget.onAuditoria?.call('PDF generado: $numero');}catch(e){_snack('Error generando PDF: $e',Colors.red);}finally{if(mounted)setState(()=>generando=false);}}
  Widget field(String l,TextEditingController c,{TextInputType? type})=>TextField(controller:c,onChanged:(_)=>setState((){}),keyboardType:type,decoration:InputDecoration(labelText:l,border:const OutlineInputBorder()));
  Widget section(String t,IconData icon,Widget child)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:card,borderRadius:BorderRadius.circular(18),border:Border.all(color:widget.modoOscuro?Colors.white12:const Color(0xffe2e5ec))),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[Icon(icon,color:primary),const SizedBox(width:8),Text(t,style:TextStyle(color:ink,fontSize:16,fontWeight:FontWeight.w900))]),const SizedBox(height:12),child]));
  Widget summary()=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:primary,borderRadius:BorderRadius.circular(16)),child:Column(children:[_row('Subtotal',subtotal),_row('Descuento',desc),const Divider(color:Colors.white38),_row('TOTAL',total,big:true)]));
  Widget _row(String l,double v,{bool big=false})=>Row(children:[Expanded(child:Text(l,style:TextStyle(color:Colors.white,fontSize:big?17:13,fontWeight:FontWeight.w800))),Text('\$${v.toStringAsFixed(2)}',style:TextStyle(color:Colors.white,fontSize:big?20:14,fontWeight:FontWeight.w900))]);
  Widget item(_Item x)=>Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:widget.modoOscuro?const Color(0xff151722):const Color(0xfff8f9fc),borderRadius:BorderRadius.circular(12)),child:Row(children:[
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(x.name,style:TextStyle(color:ink,fontWeight:FontWeight.w800)),Text(x.code.isEmpty?'Sin código':x.code,style:TextStyle(color:muted,fontSize:11))])),
    SizedBox(width:70,child:TextFormField(initialValue:'${x.qty}',keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Cant.',isDense:true),onChanged:(v){x.qty=(int.tryParse(v)??1).clamp(1,999);setState((){});})),
    const SizedBox(width:8),SizedBox(width:100,child:TextFormField(initialValue:x.price.toStringAsFixed(2),keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Precio',isDense:true),onChanged:(v){x.price=double.tryParse(v.replaceAll(',','.'))??x.price;setState((){});})),
    const SizedBox(width:10),SizedBox(width:100,child:Text('\$${x.subtotal.toStringAsFixed(2)}',textAlign:TextAlign.right,style:TextStyle(color:ink,fontWeight:FontWeight.w900))),IconButton(onPressed:()=>setState(()=>items.remove(x)),icon:const Icon(Icons.delete_outline,color:Colors.redAccent))
  ]));
  @override Widget build(BuildContext context){if(cargando)return Container(color:bg,child:Center(child:CircularProgressIndicator(color:primary)));final wide=MediaQuery.sizeOf(context).width>=950;final editor=Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    section('Cliente',Icons.person_outline,Column(children:[Row(children:[Expanded(child:field('Nombre',cliente)),const SizedBox(width:8),OutlinedButton.icon(onPressed:_client,icon:const Icon(Icons.people_outline),label:const Text('Buscar cliente'))]),const SizedBox(height:10),LayoutBuilder(builder:(_,c){final a=[field('Teléfono',telefono,type:TextInputType.phone),field('WhatsApp',whatsapp,type:TextInputType.phone),field('Email',email,type:TextInputType.emailAddress),field('Dirección',direccion)];return c.maxWidth>650?Column(children:[Row(children:[Expanded(child:a[0]),const SizedBox(width:8),Expanded(child:a[1])]),const SizedBox(height:8),Row(children:[Expanded(child:a[2]),const SizedBox(width:8),Expanded(child:a[3])])]):Column(children:[for(final z in a)...[z,const SizedBox(height:8)]]);})])),
    const SizedBox(height:12),section('Productos',Icons.inventory_2_outlined,Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Align(alignment:Alignment.centerRight,child:FilledButton.icon(onPressed:_product,icon:const Icon(Icons.add_shopping_cart),label:const Text('Agregar producto'))),const SizedBox(height:8),if(items.isEmpty)Text('Agrega productos reales del inventario.',style:TextStyle(color:muted)) else for(final x in items)item(x)]))
  ]);final side=Column(children:[section('Totales',Icons.calculate_outlined,Column(children:[TextField(controller:descuento,onChanged:(_)=>setState((){}),keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Descuento en \$',border:OutlineInputBorder())),const SizedBox(height:10),summary()])),const SizedBox(height:12),section('Enviar cotización',Icons.send_outlined,Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[FilledButton.icon(onPressed:generando?null:_share,icon:const Icon(Icons.picture_as_pdf_outlined),label:Text(generando?'Generando...':'GENERAR / COMPARTIR PDF')),const SizedBox(height:8),OutlinedButton.icon(onPressed:_wa,icon:const Icon(Icons.chat_outlined),label:const Text('ENVIAR POR WHATSAPP')),const SizedBox(height:8),Text('El PDF se comparte mediante la ventana de compartir del dispositivo.',style:TextStyle(color:muted,fontSize:11))]))]);return Container(color:bg,padding:const EdgeInsets.all(18),child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[Expanded(child:Text('Cotizaciones PRO',style:TextStyle(color:ink,fontSize:24,fontWeight:FontWeight.w900))),OutlinedButton.icon(onPressed:_load,icon:const Icon(Icons.refresh),label:const Text('Actualizar'))]),Text('$_numero • Productos reales del inventario',style:TextStyle(color:muted)),const SizedBox(height:16),if(wide)Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:editor),const SizedBox(width:14),SizedBox(width:330,child:side)])else ...[editor,const SizedBox(height:14),side]])));}
}
class _Item{final String id,name,code;int qty;double price;_Item(this.id,this.name,this.code,this.price,{this.qty=1});double get subtotal=>qty*price;}
'@
W $main $m;W $pro $p;W $panel $dart
& dart format $main $pro $panel
if($LASTEXITCODE-ne0){throw "dart format fallo"}
$a=cmd.exe /c "flutter analyze `"$main`" `"$pro`" `"$panel`" 2>&1"|Out-String
Write-Host $a
if($a-match "(?m)^\s*error\s*-"){throw "Se detectaron errores Dart reales. Restaurando."}
Write-Host "COTIZACIONES PRO INSTALADAS CORRECTAMENTE" -ForegroundColor Green
Write-Host "Backup: $bak" -ForegroundColor Cyan
Write-Host "Ejecuta: flutter run -d chrome"
}catch{
Write-Host "FALLO: $($_.Exception.Message)" -ForegroundColor Red
Copy-Item "$bak\main.dart" $main -Force;Copy-Item "$bak\pro_features.dart" $pro -Force
if(Test-Path "$bak\cotizaciones_pro_panel.dart"){Copy-Item "$bak\cotizaciones_pro_panel.dart" $panel -Force}elseif(Test-Path $panel){Remove-Item $panel -Force}
Write-Host "RESTAURACION COMPLETA" -ForegroundColor Green
exit 1
}
