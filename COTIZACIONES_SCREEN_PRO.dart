import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CotizacionesScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  final Future<List<Map<String, dynamic>>> Function() cargarProductos;

  const CotizacionesScreen({
    super.key,
    required this.onAbrirSidebar,
    required this.cargarProductos,
    this.modoOscuro = false,
  });

  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> {
  static const _purple = Color(0xFF4A176B);
  static const _blue = Color(0xFF3861FB);
  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);
  static const _orange = Color(0xFFF59E0B);

  final _search = TextEditingController();
  final _client = TextEditingController();
  final _phone = TextEditingController();
  final _validity = TextEditingController(text: '15 días');

  final List<_Quote> _quotes = [];
  List<Map<String, dynamic>> _products = [];
  List<_QuoteItem> _draftItems = [];
  bool _loading = true;
  int _counter = 1;
  String _filter = 'Todas';

  Color get _bg => widget.modoOscuro ? const Color(0xFF0B1020) : const Color(0xFFF6F7FB);
  Color get _card => widget.modoOscuro ? const Color(0xFF121A2A) : Colors.white;
  Color get _text => widget.modoOscuro ? Colors.white : const Color(0xFF202332);
  Color get _muted => widget.modoOscuro ? const Color(0xFFAAB3C5) : const Color(0xFF6B7280);
  Color get _border => widget.modoOscuro ? Colors.white12 : const Color(0xFFE4E7EF);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _search.dispose();
    _client.dispose();
    _phone.dispose();
    _validity.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      _products = await widget.cargarProductos();
    } catch (_) {
      _products = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  double get _draftTotal => _draftItems.fold(0, (s, i) => s + i.total);

  List<_Quote> get _visibleQuotes {
    final q = _search.text.trim().toLowerCase();
    return _quotes.where((item) {
      final filterOk = _filter == 'Todas' || item.status == _filter;
      final text = '${item.number} ${item.client}'.toLowerCase();
      return filterOk && (q.isEmpty || text.contains(q));
    }).toList();
  }

  Future<void> _newQuote() async {
    _client.clear();
    _phone.clear();
    _validity.text = '15 días';
    _draftItems = [];
    await _loadProducts();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 760),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(28),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _iconBox(Icons.request_quote_rounded),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Nueva cotización', style: TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w900)),
                        Text('Crea una propuesta profesional para tu cliente', style: TextStyle(color: _muted, fontSize: 11)),
                      ])),
                      IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: _muted)),
                    ]),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(child: _field(_client, 'Cliente', Icons.person_outline_rounded, onChanged: (_) => setModalState(() {}))),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_phone, 'WhatsApp / teléfono', Icons.phone_outlined)),
                    ]),
                    const SizedBox(height: 10),
                    _field(_validity, 'Validez de la cotización', Icons.event_available_outlined),
                    const SizedBox(height: 18),
                    Text('Productos', style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    if (_loading)
                      const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                    else if (_products.isEmpty)
                      _emptyProducts()
                    else
                      DropdownButtonFormField<int>(
                        decoration: _decoration('Seleccionar producto', Icons.add_shopping_cart_outlined),
                        items: List.generate(_products.length, (index) {
                          final p = _products[index];
                          return DropdownMenuItem(value: index, child: Text('${p['nombre'] ?? 'Producto'} — ${_money((p['precio'] as num?)?.toDouble() ?? 0)}'));
                        }),
                        onChanged: (index) {
                          if (index == null) return;
                          final p = _products[index];
                          final item = _QuoteItem(
                            name: (p['nombre'] ?? 'Producto').toString(),
                            qty: 1,
                            unit: (p['precio'] as num?)?.toDouble() ?? 0,
                          );
                          setModalState(() => _draftItems = [..._draftItems, item]);
                        },
                      ),
                    const SizedBox(height: 10),
                    ..._draftItems.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(color: widget.modoOscuro ? Colors.white.withValues(alpha: .035) : const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
                        child: Row(children: [
                          Expanded(child: Text(item.name, style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 12))),
                          IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18), onPressed: () => setModalState(() { if (item.qty > 1) item.qty--; })),
                          Text('${item.qty}', style: TextStyle(color: _text, fontWeight: FontWeight.w900)),
                          IconButton(icon: const Icon(Icons.add_circle_outline, size: 18), onPressed: () => setModalState(() => item.qty++)),
                          SizedBox(width: 76, child: Text(_money(item.total), textAlign: TextAlign.right, style: TextStyle(color: _text, fontWeight: FontWeight.w900))),
                          IconButton(icon: Icon(Icons.delete_outline_rounded, size: 18, color: _red), onPressed: () => setModalState(() => _draftItems.removeAt(i))),
                        ]),
                      );
                    }),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [_purple, _blue]), borderRadius: BorderRadius.circular(18)),
                      child: Row(children: [
                        const Icon(Icons.receipt_long_rounded, color: Colors.white),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('TOTAL DE LA COTIZACIÓN', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800))),
                        Text(_money(_draftTotal), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(width: double.infinity, child: FilledButton.icon(
                      onPressed: _draftItems.isEmpty || _client.text.trim().isEmpty ? null : () {
                        final quote = _Quote(number: 'C-${_counter.toString().padLeft(6, '0')}', client: _client.text.trim(), phone: _phone.text.trim(), date: DateTime.now(), total: _draftTotal, status: 'Pendiente', validity: _validity.text.trim(), items: List.of(_draftItems));
                        setState(() { _quotes.insert(0, quote); _counter++; });
                        Navigator.pop(context);
                        _showQuoteActions(quote);
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Crear cotización', style: TextStyle(fontWeight: FontWeight.w900)),
                      style: FilledButton.styleFrom(backgroundColor: _blue, minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    )),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyProducts() => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14)), child: Text('No hay productos disponibles para agregar.', style: TextStyle(color: _muted, fontSize: 12)));

  Widget _field(TextEditingController c, String label, IconData icon, {ValueChanged<String>? onChanged}) => TextField(controller: c, onChanged: onChanged, style: TextStyle(color: _text), decoration: _decoration(label, icon));

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(labelText: label, labelStyle: TextStyle(color: _muted, fontSize: 11), prefixIcon: Icon(icon, color: _purple, size: 19), filled: true, fillColor: widget.modoOscuro ? Colors.white.withValues(alpha: .035) : const Color(0xFFF8F8FC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: _border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: _border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: _blue, width: 1.5)));

  Widget _iconBox(IconData icon) => Container(width: 46, height: 46, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_purple, _blue]), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.white));

  Future<Uint8List> _buildPdf(_Quote quote) async {
    final doc = pw.Document();
    final date = DateFormat('dd/MM/yyyy HH:mm').format(quote.date);
    final purple = PdfColor.fromHex('#4A176B');
    final blue = PdfColor.fromHex('#3861FB');
    final light = PdfColor.fromHex('#F4F6FB');
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => [
        pw.Container(padding: const pw.EdgeInsets.all(18), decoration: pw.BoxDecoration(color: purple, borderRadius: pw.BorderRadius.circular(14)), child: pw.Row(children: [
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('SINTHETIX PRO', style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold)), pw.SizedBox(height: 3), pw.Text('PUNTO DE VENTA · COTIZACIÓN', style: const pw.TextStyle(color: PdfColors.white, fontSize: 9))]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [pw.Text(quote.number, style: pw.TextStyle(color: PdfColors.white, fontSize: 15, fontWeight: pw.FontWeight.bold)), pw.Text(date, style: const pw.TextStyle(color: PdfColors.white, fontSize: 8))]),
        ])),
        pw.SizedBox(height: 18),
        pw.Container(padding: const pw.EdgeInsets.all(14), decoration: pw.BoxDecoration(color: light, borderRadius: pw.BorderRadius.circular(10)), child: pw.Row(children: [pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('CLIENTE', style: pw.TextStyle(color: purple, fontSize: 8, fontWeight: pw.FontWeight.bold)), pw.SizedBox(height: 4), pw.Text(quote.client, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)), if (quote.phone.isNotEmpty) pw.Text('Tel: ${quote.phone}', style: const pw.TextStyle(fontSize: 9))]), pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [pw.Text('VÁLIDA POR', style: pw.TextStyle(color: blue, fontSize: 8, fontWeight: pw.FontWeight.bold)), pw.Text(quote.validity, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))])])),
        pw.SizedBox(height: 18),
        pw.Table.fromTextArray(headerDecoration: pw.BoxDecoration(color: purple), headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), cellStyle: const pw.TextStyle(fontSize: 9), cellPadding: const pw.EdgeInsets.all(7), headers: ['#', 'Producto', 'Cant.', 'P. Unit.', 'P. Total'], data: [for (var i = 0; i < quote.items.length; i++) [ '${i + 1}', quote.items[i].name, '${quote.items[i].qty}', _money(quote.items[i].unit), _money(quote.items[i].total) ]]),
        pw.SizedBox(height: 16),
        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Container(width: 220, padding: const pw.EdgeInsets.all(14), decoration: pw.BoxDecoration(color: light, borderRadius: pw.BorderRadius.circular(10)), child: pw.Column(children: [pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Subtotal'), pw.Text(_money(quote.total))]), pw.Divider(), pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: purple)), pw.Text(_money(quote.total), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: blue))])]))),
        pw.SizedBox(height: 28),
        pw.Divider(),
        pw.Text('Esta cotización es una propuesta comercial y no constituye una factura fiscal.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 5),
        pw.Text('SINTHETIX PRO · Tecnología que impulsa tu negocio', style: pw.TextStyle(fontSize: 8, color: purple, fontWeight: pw.FontWeight.bold)),
      ],
    ));
    return doc.save();
  }

  Future<void> _sharePdf(_Quote quote) async {
    final bytes = await _buildPdf(quote);
    await Share.shareXFiles([XFile.fromData(bytes, mimeType: 'application/pdf', name: '${quote.number}.pdf')], text: 'Cotización ${quote.number} · ${quote.client} · ${_money(quote.total)}');
  }

  Future<void> _printPdf(_Quote quote) async {
    final bytes = await _buildPdf(quote);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: '${quote.number}.pdf');
  }

  Future<void> _whatsapp(_Quote quote) async {
    if (quote.phone.isEmpty) {
      _snack('La cotización no tiene número de WhatsApp.');
      return;
    }
    var phone = quote.phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) phone = '58${phone.substring(1)}';
    final products = quote.items.map((i) => '• ${i.name} x${i.qty} ${_money(i.total)}').join('\n');
    final message = 'SINTHETIX PRO - COTIZACIÓN\n\nCotización: ${quote.number}\nCliente: ${quote.client}\nFecha: ${DateFormat('dd/MM/yyyy HH:mm').format(quote.date)}\nVálida por: ${quote.validity}\n\nProductos:\n$products\n\nTOTAL: ${_money(quote.total)}\n\nGracias por confiar en SINTHETIX PRO.';
    await launchUrl(Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}'), mode: LaunchMode.externalApplication);
  }

  void _showQuoteActions(_Quote quote) {
    showModalBottomSheet<void>(context: context, backgroundColor: Colors.transparent, builder: (_) => Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(26)), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(quote.number, style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w900)),
      Text('${quote.client} · ${_money(quote.total)}', style: TextStyle(color: _muted, fontSize: 11)),
      const SizedBox(height: 14),
      _action('PDF profesional', Icons.picture_as_pdf_rounded, _purple, () async { Navigator.pop(context); await _printPdf(quote); }),
      _action('Enviar por WhatsApp', Icons.chat_rounded, const Color(0xFF25D366), () async { Navigator.pop(context); await _whatsapp(quote); }),
      _action('Compartir PDF', Icons.share_rounded, _blue, () async { Navigator.pop(context); await _sharePdf(quote); }),
    ])));
  }

  Widget _action(String title, IconData icon, Color color, VoidCallback onTap) => ListTile(leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)), title: Text(title, style: TextStyle(color: _text, fontWeight: FontWeight.w800)), trailing: Icon(Icons.chevron_right_rounded, color: _muted), onTap: onTap);

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final list = _visibleQuotes;
    return Scaffold(backgroundColor: _bg, body: SafeArea(child: LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 900;
      return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: Padding(padding: const EdgeInsets.fromLTRB(18, 14, 18, 18), child: Column(children: [
        Row(children: [IconButton(onPressed: widget.onAbrirSidebar, icon: Icon(Icons.menu_rounded, color: _text)), const SizedBox(width: 6), _iconBox(Icons.request_quote_rounded), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Cotizaciones', style: TextStyle(color: _text, fontSize: 21, fontWeight: FontWeight.w900)), Text('Crea, genera PDF y envía tus cotizaciones', style: TextStyle(color: _muted, fontSize: 11))])), FilledButton.icon(onPressed: _newQuote, icon: const Icon(Icons.add_rounded), label: const Text('Nueva cotización', style: TextStyle(fontWeight: FontWeight.w900)), style: FilledButton.styleFrom(backgroundColor: _blue, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))]),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)), child: Row(children: [Expanded(child: TextField(controller: _search, onChanged: (_) => setState(() {}), style: TextStyle(color: _text), decoration: _decoration('Buscar por cliente o número...', Icons.search_rounded))), const SizedBox(width: 10), if (wide) ...['Todas', 'Pendiente', 'Aceptada', 'Rechazada'].map((f) => Padding(padding: const EdgeInsets.only(left: 6), child: ChoiceChip(label: Text(f), selected: _filter == f, onSelected: (_) => setState(() => _filter = f), selectedColor: _purple.withValues(alpha: .14), labelStyle: TextStyle(color: _filter == f ? _purple : _muted, fontWeight: FontWeight.w800, fontSize: 10))))]),
        ),
        const SizedBox(height: 12),
        Expanded(child: list.isEmpty ? Center(child: Text('Aún no hay cotizaciones. Pulsa “Nueva cotización”.', style: TextStyle(color: _muted, fontWeight: FontWeight.w700))) : ListView.separated(itemCount: list.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) { final q = list[i]; return _quoteRow(q); })),
      ]))));
    })));
  }

  Widget _quoteRow(_Quote q) {
    final color = q.status == 'Aceptada' ? _green : q.status == 'Rechazada' ? _red : _orange;
    return Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)), child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_purple, _blue]), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.description_outlined, color: Colors.white)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(q.number, style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 12)), const SizedBox(height: 3), Text(q.client, style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 12)), Text(DateFormat('dd/MM/yyyy · HH:mm').format(q.date), style: TextStyle(color: _muted, fontSize: 10))])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(20)), child: Text(q.status, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900))),
      const SizedBox(width: 14),
      Text(_money(q.total), style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w900)),
      IconButton(onPressed: () => _showQuoteActions(q), icon: Icon(Icons.more_vert_rounded, color: _muted)),
    ]));
  }
}

class _Quote {
  final String number;
  final String client;
  final String phone;
  final DateTime date;
  final double total;
  final String status;
  final String validity;
  final List<_QuoteItem> items;
  _Quote({required this.number, required this.client, required this.phone, required this.date, required this.total, required this.status, required this.validity, required this.items});
}

class _QuoteItem {
  final String name;
  int qty;
  final double unit;
  _QuoteItem({required this.name, required this.qty, required this.unit});
  double get total => qty * unit;
}
