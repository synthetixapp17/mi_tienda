// SINTHETIX PRO - Centro Profesional V1
// Nuevas funciones: sesiones de caja, pagos mixtos, multimoneda,
// crÃ©dito/cuentas por cobrar, notas de crÃ©dito, cotizaciones PDF y auditorÃ­a.
//
// Este mÃ³dulo usa SharedPreferences para sus propios registros y NO modifica
// la base SQLite existente ni mueve la lÃ³gica de ventas/inventario actual.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class ProQuoteDraftBus {
  static final ValueNotifier<List<Map<String, dynamic>>> draft =
      ValueNotifier<List<Map<String, dynamic>>>(const []);
  static void fromCart(List<Map<String, dynamic>> cart) {
    draft.value = cart.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  static void clear() => draft.value = const [];
}

class ProColors {
  static const primary = Color(0xFF4A176B);
  static const secondary = Color(0xFF7C3AED);
  static const blue = Color(0xFF2563EB);
  static const success = Color(0xFF0ECB81);
  static const danger = Color(0xFFF6465D);
  static const warning = Color(0xFFF59E0B);
  static const bg = Color(0xFFF7F7FB);
  static const darkBg = Color(0xFF0D1016);
}

class ProStore {
  static const _quotes = 'sinthetix_pro_quotes_v1';
  static const _credits = 'sinthetix_pro_credits_v1';
  static const _creditPayments = 'sinthetix_pro_credit_payments_v1';
  static const _notes = 'sinthetix_pro_credit_notes_v1';
  static const _sessions = 'sinthetix_pro_cash_sessions_v1';
  static const _audits = 'sinthetix_pro_audits_v1';
  static const _rates = 'sinthetix_pro_rates_v1';
  static const _quoteSeq = 'sinthetix_pro_quote_seq_v1';
  static const _noteSeq = 'sinthetix_pro_note_seq_v1';

  Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final p = await _p;
    final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final value = jsonDecode(raw);
      if (value is! List) return [];
      return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> value) async {
    final p = await _p;
    await p.setString(key, jsonEncode(value));
  }

  Future<List<Map<String, dynamic>>> quotes() => _readList(_quotes);
  Future<List<Map<String, dynamic>>> credits() => _readList(_credits);
  Future<List<Map<String, dynamic>>> creditPayments() => _readList(_creditPayments);
  Future<List<Map<String, dynamic>>> notes() => _readList(_notes);
  Future<List<Map<String, dynamic>>> sessions() => _readList(_sessions);
  Future<List<Map<String, dynamic>>> audits() => _readList(_audits);

  Future<Map<String, double>> rates() async {
    final p = await _p;
    final raw = p.getString(_rates);
    if (raw == null) return {'USD': 1, 'VES': 60, 'COP': 4500, 'DOP': 60};
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw));
      return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {'USD': 1, 'VES': 60, 'COP': 4500, 'DOP': 60};
    }
  }

  Future<void> saveRates(Map<String, double> rates) async {
    final p = await _p;
    await p.setString(_rates, jsonEncode(rates));
    await addAudit('Tasas de cambio actualizadas', 'Monedas');
  }

  Future<String> _nextNumber(String key, String prefix) async {
    final p = await _p;
    final next = (p.getInt(key) ?? 0) + 1;
    await p.setInt(key, next);
    return '$prefix${next.toString().padLeft(6, '0')}';
  }

  Future<Map<String, dynamic>> addQuote({
    required String client,
    required String phone,
    required List<Map<String, dynamic>> items,
    required double total,
    required int validityDays,
    String notes = '',
  }) async {
    final list = await quotes();
    final quote = {
      'id': await _nextNumber(_quoteSeq, 'COT-'),
      'date': DateTime.now().toIso8601String(),
      'client': client,
      'phone': phone,
      'items': items,
      'total': total,
      'validityDays': validityDays,
      'status': 'Pendiente',
      'notes': notes,
    };
    list.insert(0, quote);
    await _writeList(_quotes, list);
    await addAudit('CotizaciÃ³n ${quote['id']} creada', 'Cotizaciones');
    return quote;
  }

  Future<void> updateQuoteStatus(String id, String status) async {
    final list = await quotes();
    for (final q in list) {
      if (q['id'] == id) q['status'] = status;
    }
    await _writeList(_quotes, list);
    await addAudit('CotizaciÃ³n $id â†’ $status', 'Cotizaciones');
  }

  Future<void> deleteQuote(String id) async {
    final list = await quotes();
    list.removeWhere((q) => q['id'] == id);
    await _writeList(_quotes, list);
    await addAudit('CotizaciÃ³n $id eliminada', 'Cotizaciones');
  }

  Future<Map<String, dynamic>> addCredit({
    required String client,
    required double amount,
    String phone = '',
    int days = 30,
    String note = '',
  }) async {
    final list = await credits();
    final now = DateTime.now();
    final credit = {
      'id': 'CR-${now.millisecondsSinceEpoch}',
      'date': now.toIso8601String(),
      'client': client,
      'phone': phone,
      'amount': amount,
      'paid': 0.0,
      'dueDate': now.add(Duration(days: days)).toIso8601String(),
      'status': 'Pendiente',
      'note': note,
    };
    list.insert(0, credit);
    await _writeList(_credits, list);
    await addAudit('CrÃ©dito creado para $client', 'CrÃ©dito');
    return credit;
  }

  Future<void> addCreditPayment({
    required String creditId,
    required double amount,
    required String method,
    required String currency,
    double rate = 1,
    String reference = '',
  }) async {
    final creditsList = await credits();
    Map<String, dynamic>? c;
    for (final row in creditsList) {
      if (row['id'] == creditId) {
        c = row;
        break;
      }
    }
    if (c == null) throw StateError('CrÃ©dito no encontrado');
    // Las tasas se expresan como: 1 USD = N unidades de la moneda.
    // Por eso, para volver a USD se divide el monto por la tasa.
    final totalBase = amount / (rate <= 0 ? 1 : rate);
    final originalPaid = (c['paid'] as num).toDouble();
    final originalAmount = (c['amount'] as num).toDouble();
    final newPaid = originalPaid + totalBase;
    if (newPaid > originalAmount + .01) {
      throw StateError('El abono supera el saldo pendiente.');
    }
    c['paid'] = newPaid;
    c['status'] = newPaid >= originalAmount - .01 ? 'Pagado' : 'Abierto';
    final payments = await creditPayments();
    payments.insert(0, {
      'id': 'AB-${DateTime.now().millisecondsSinceEpoch}',
      'creditId': creditId,
      'date': DateTime.now().toIso8601String(),
      'amount': amount,
      'currency': currency,
      'rate': rate,
      'baseAmount': totalBase,
      'method': method,
      'reference': reference,
    });
    await _writeList(_credits, creditsList);
    await _writeList(_creditPayments, payments);
    await addAudit('Abono registrado: ${_money(totalBase)}', 'CrÃ©dito');
  }

  Future<void> addNote({
    required String saleRef,
    required String client,
    required double amount,
    required String reason,
  }) async {
    final list = await notes();
    final id = await _nextNumber(_noteSeq, 'NC-');
    list.insert(0, {
      'id': id,
      'date': DateTime.now().toIso8601String(),
      'saleRef': saleRef,
      'client': client,
      'amount': amount,
      'reason': reason,
      'status': 'Emitida',
    });
    await _writeList(_notes, list);
    await addAudit('Nota de crÃ©dito $id emitida', 'Notas de crÃ©dito');
  }

  Future<void> openSession({
    required String cashier,
    required String register,
    required Map<String, double> opening,
  }) async {
    final list = await sessions();
    final open = list.where((e) => e['status'] == 'Abierta');
    if (open.isNotEmpty) throw StateError('Ya existe una sesiÃ³n de caja abierta.');
    list.insert(0, {
      'id': 'CA-${DateTime.now().millisecondsSinceEpoch}',
      'openedAt': DateTime.now().toIso8601String(),
      'closedAt': null,
      'cashier': cashier,
      'register': register,
      'opening': opening,
      'status': 'Abierta',
      'closing': null,
      'difference': null,
    });
    await _writeList(_sessions, list);
    await addAudit('Apertura de caja $register', 'Caja');
  }

  Future<void> closeSession(Map<String, double> counted) async {
    final list = await sessions();
    final index = list.indexWhere((e) => e['status'] == 'Abierta');
    if (index < 0) throw StateError('No hay una sesiÃ³n abierta.');
    final session = list[index];
    final opening = Map<String, dynamic>.from(session['opening'] as Map);
    final expected = <String, double>{};
    for (final e in opening.entries) expected[e.key] = (e.value as num).toDouble();
    session['closedAt'] = DateTime.now().toIso8601String();
    session['closing'] = counted;
    session['expected'] = expected;
    session['difference'] = {
      for (final k in {...expected.keys, ...counted.keys})
        k: (counted[k] ?? 0) - (expected[k] ?? 0),
    };
    session['status'] = 'Cerrada';
    await _writeList(_sessions, list);
    await addAudit('Cierre de caja ${session['register']}', 'Caja');
  }

  Future<void> addAudit(String action, String module) async {
    final list = await audits();
    list.insert(0, {
      'date': DateTime.now().toIso8601String(),
      'action': action,
      'module': module,
      'user': 'Administrador',
    });
    if (list.length > 300) list.removeRange(300, list.length);
    await _writeList(_audits, list);
  }
}

String _money(num value, [String currency = 'USD']) {
  final symbols = {'USD': '\$', 'VES': 'Bs.', 'COP': '\$', 'DOP': 'RD\$'};
  return '${symbols[currency] ?? currency} ${value.toStringAsFixed(2)}';
}

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

class _ProfesionalScreenState extends State<ProfesionalScreen> with SingleTickerProviderStateMixin {
  final store = ProStore();
  late final TabController _tabs;
  int _tab = 0;
  bool _loading = true;
  List<Map<String, dynamic>> quotes = [];
  List<Map<String, dynamic>> credits = [];
  List<Map<String, dynamic>> notes = [];
  List<Map<String, dynamic>> sessions = [];
  List<Map<String, dynamic>> audits = [];
  Map<String, double> rates = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() => _tab = _tabs.index);
    });
    ProQuoteDraftBus.draft.addListener(_consumeCartQuote);
    _load();
  }

  void _consumeCartQuote() {
    final draft = ProQuoteDraftBus.draft.value;
    if (!mounted || draft.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || ProQuoteDraftBus.draft.value.isEmpty) return;
      final items = ProQuoteDraftBus.draft.value;
      ProQuoteDraftBus.clear();
      await _newQuote(initialItems: items);
    });
  }

  @override
  void dispose() {
    ProQuoteDraftBus.draft.removeListener(_consumeCartQuote);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      store.quotes(), store.credits(), store.notes(), store.sessions(), store.audits(), store.rates(),
    ]);
    if (!mounted) return;
    setState(() {
      quotes = results[0] as List<Map<String, dynamic>>;
      credits = results[1] as List<Map<String, dynamic>>;
      notes = results[2] as List<Map<String, dynamic>>;
      sessions = results[3] as List<Map<String, dynamic>>;
      audits = results[4] as List<Map<String, dynamic>>;
      rates = results[5] as Map<String, double>;
      _loading = false;
    });
  }

  void _snack(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? ProColors.danger : ProColors.primary,
      content: Text(text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.modoOscuro;
    final bg = dark ? ProColors.darkBg : ProColors.bg;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: dark ? const Color(0xFF12151C) : Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'MenÃº',
          onPressed: widget.onAbrirSidebar,
          icon: const Icon(Icons.menu_rounded),
        ),
        title: const Text('Centro Profesional'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Cotizaciones'),
              Tab(icon: Icon(Icons.credit_score_rounded), text: 'CrÃ©dito'),
              Tab(icon: Icon(Icons.assignment_return_rounded), text: 'Notas de crÃ©dito'),
              Tab(icon: Icon(Icons.point_of_sale_rounded), text: 'Caja'),
              Tab(icon: Icon(Icons.payments_rounded), text: 'Pagos mixtos'),
              Tab(icon: Icon(Icons.currency_exchange_rounded), text: 'Monedas'),
              Tab(icon: Icon(Icons.history_rounded), text: 'AuditorÃ­a'),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _quotesTab(dark),
                _creditsTab(dark),
                _notesTab(dark),
                _cashTab(dark),
                _mixedPaymentsTab(dark),
                _currencyTab(dark),
                _auditTab(dark),
              ],
            ),
    );
  }

  Widget _shell(Widget child, bool dark) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900;
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: EdgeInsets.all(wide ? 26 : 14),
            child: child,
          ),
        ),
      );
    });
  }

  Widget _header(String title, String subtitle, IconData icon, bool dark, {Widget? action}) {
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [ProColors.primary, ProColors.secondary]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: dark ? Colors.white : const Color(0xFF171923))),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : Colors.black54)),
        ])),
        if (action != null) action,
      ],
    );
  }

  Widget _card(Widget child, bool dark) => Container(
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF171B23) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: dark ? Colors.white10 : const Color(0xFFE9E7F0)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .10 : .05), blurRadius: 18, offset: const Offset(0, 8))],
    ),
    child: child,
  );

  Widget _quotesTab(bool dark) {
    final total = quotes.fold<double>(0, (s, q) => s + ((q['total'] as num?)?.toDouble() ?? 0));
    return _shell(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Cotizaciones', 'Crea, guarda, genera PDF y comparte con el cliente.', Icons.receipt_long_rounded, dark,
          action: FilledButton.icon(onPressed: _newQuote, icon: const Icon(Icons.add_rounded), label: const Text('Nueva cotizaciÃ³n'))),
        const SizedBox(height: 18),
        Row(children: [
          _metric('Cotizaciones', '${quotes.length}', Icons.description_outlined, dark),
          const SizedBox(width: 10),
          _metric('Valor cotizado', _money(total), Icons.attach_money_rounded, dark),
          const SizedBox(width: 10),
          _metric('Pendientes', '${quotes.where((q) => q['status'] == 'Pendiente').length}', Icons.schedule_rounded, dark),
        ]),
        const SizedBox(height: 18),
        Expanded(child: quotes.isEmpty ? _empty('AÃºn no hay cotizaciones.', Icons.receipt_long_rounded, dark) : ListView.separated(
          itemCount: quotes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final q = quotes[i];
            final date = DateTime.tryParse('${q['date']}') ?? DateTime.now();
            return _card(ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              leading: CircleAvatar(backgroundColor: ProColors.primary.withValues(alpha: .10), child: const Icon(Icons.receipt_long_rounded, color: ProColors.primary)),
              title: Text('${q['id']} Â· ${q['client']}', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${DateFormat('dd/MM/yyyy HH:mm').format(date)} Â· ${q['items'] is List ? (q['items'] as List).length : 0} productos'),
              trailing: Wrap(spacing: 4, children: [
                Text(_money((q['total'] as num?)?.toDouble() ?? 0), style: const TextStyle(fontWeight: FontWeight.w900)),
                IconButton(tooltip: 'PDF', onPressed: () => _quotePdf(q), icon: const Icon(Icons.picture_as_pdf_rounded)),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'share') await _shareQuote(q);
                    if (v == 'sale') { await store.updateQuoteStatus('${q['id']}', 'Aceptada'); await _load(); _snack('CotizaciÃ³n marcada como aceptada.'); }
                    if (v == 'delete') { await store.deleteQuote('${q['id']}'); await _load(); }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'share', child: Text('Compartir PDF')),
                    PopupMenuItem(value: 'sale', child: Text('Marcar aceptada')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ]),
            ));
          },
        )),
      ],
    ));
  }

  Widget _metric(String title, String value, IconData icon, bool dark) => Expanded(child: _card(
    Padding(padding: const EdgeInsets.all(15), child: Row(children: [
      Icon(icon, color: ProColors.primary),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 10, color: dark ? Colors.white60 : Colors.black54)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      ])),
    ]),
  ));

  Widget _empty(String text, IconData icon, bool dark) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [Icon(icon, size: 48, color: dark ? Colors.white24 : Colors.black26), const SizedBox(height: 10), Text(text, style: TextStyle(color: dark ? Colors.white60 : Colors.black54))],
  ));

  Future<void> _newQuote({List<Map<String, dynamic>>? initialItems}) async {
    final client = TextEditingController();
    final phone = TextEditingController();
    final seed = initialItems == null
        ? 'Producto 1|1|100\nProducto 2|2|25'
        : initialItems.map((e) {
            final name = e['nombre'] ?? e['name'] ?? 'Producto';
            final qty = e['cantidad'] ?? e['qty'] ?? 1;
            final price = e['precio'] ?? e['price'] ?? 0;
            return '$name|$qty|$price';
          }).join('\n');
    final items = TextEditingController(text: seed);
    final days = TextEditingController(text: '7');
    final notes = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _FormDialog(
        title: 'Nueva cotizaciÃ³n',
        fields: [
          _F('Cliente', client),
          _F('TelÃ©fono / contacto', phone),
          _F('Productos (Nombre|Cantidad|Precio por lÃ­nea)', items, maxLines: 6),
          _F('Vigencia (dÃ­as)', days, keyboard: TextInputType.number),
          _F('Observaciones', notes, maxLines: 3),
        ],
        onSave: () {
          final parsed = <Map<String, dynamic>>[];
          double total = 0;
          for (final line in items.text.split('\n')) {
            final p = line.split('|');
            if (p.length < 3) continue;
            final qty = double.tryParse(p[1].trim()) ?? 0;
            final price = double.tryParse(p[2].trim()) ?? 0;
            if (qty <= 0 || price < 0) continue;
            final lineTotal = qty * price;
            parsed.add({'name': p[0].trim(), 'qty': qty, 'price': price, 'total': lineTotal});
            total += lineTotal;
          }
          if (client.text.trim().isEmpty || parsed.isEmpty) return null;
          return {'client': client.text.trim(), 'phone': phone.text.trim(), 'items': parsed, 'total': total, 'days': int.tryParse(days.text) ?? 7, 'notes': notes.text.trim()};
        },
      ),
    );
    if (result == null) return;
    await store.addQuote(client: result['client'], phone: result['phone'], items: List<Map<String, dynamic>>.from(result['items']), total: result['total'], validityDays: result['days'], notes: result['notes']);
    await _load();
    _snack('CotizaciÃ³n creada correctamente.');
  }

  Widget _creditsTab(bool dark) {
    final balance = credits.fold<double>(0, (s, c) => s + ((c['amount'] as num?)?.toDouble() ?? 0) - ((c['paid'] as num?)?.toDouble() ?? 0));
    return _shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _header('CrÃ©dito y cuentas por cobrar', 'Saldos, vencimientos y abonos por cliente.', Icons.credit_score_rounded, dark,
        action: FilledButton.icon(onPressed: _newCredit, icon: const Icon(Icons.add_rounded), label: const Text('Nuevo crÃ©dito'))),
      const SizedBox(height: 18),
      Row(children: [
        _metric('Cuentas', '${credits.length}', Icons.groups_rounded, dark),
        const SizedBox(width: 10),
        _metric('Saldo pendiente', _money(balance), Icons.account_balance_wallet_rounded, dark),
      ]),
      const SizedBox(height: 18),
      Expanded(child: credits.isEmpty ? _empty('No hay crÃ©ditos registrados.', Icons.credit_score_rounded, dark) : ListView.separated(
        itemCount: credits.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final c = credits[i];
          final amount = (c['amount'] as num?)?.toDouble() ?? 0;
          final paid = (c['paid'] as num?)?.toDouble() ?? 0;
          final pending = amount - paid;
          final due = DateTime.tryParse('${c['dueDate']}') ?? DateTime.now();
          return _card(ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            leading: CircleAvatar(backgroundColor: pending <= .01 ? ProColors.success.withValues(alpha: .12) : ProColors.warning.withValues(alpha: .12), child: Icon(pending <= .01 ? Icons.check_rounded : Icons.schedule_rounded, color: pending <= .01 ? ProColors.success : ProColors.warning)),
            title: Text('${c['client']}', style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('Vence ${DateFormat('dd/MM/yyyy').format(due)} Â· ${c['status']}'),
            trailing: Wrap(alignment: WrapAlignment.end, crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, children: [
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_money(pending), style: const TextStyle(fontWeight: FontWeight.w900)),
                Text('de ${_money(amount)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
              IconButton(tooltip: 'Registrar abono', onPressed: pending > .01 ? () => _payCredit(c) : null, icon: const Icon(Icons.payments_rounded)),
            ]),
          ));
        },
      )),
    ]));
  }

  Future<void> _newCredit() async {
    final client = TextEditingController();
    final amount = TextEditingController();
    final phone = TextEditingController();
    final days = TextEditingController(text: '30');
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FormDialog(title: 'Nuevo crÃ©dito', fields: [
        _F('Cliente', client), _F('TelÃ©fono', phone),
        _F('Monto', amount, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        _F('Plazo (dÃ­as)', days, keyboard: TextInputType.number),
      ], onSave: () {
        final a = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
        if (client.text.trim().isEmpty || a <= 0) return null;
        return {'client': client.text.trim(), 'phone': phone.text.trim(), 'amount': a, 'days': int.tryParse(days.text) ?? 30};
      }),
    );
    if (result == null) return;
    await store.addCredit(client: result['client'], amount: result['amount'], phone: result['phone'], days: result['days']);
    await _load(); _snack('CrÃ©dito creado.');
  }

  Future<void> _payCredit(Map<String, dynamic> credit) async {
    final amount = TextEditingController();
    final reference = TextEditingController();
    String method = 'Efectivo';
    String currency = 'USD';
    final result = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
      return AlertDialog(
        title: const Text('Registrar abono'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Saldo: ${_money(((credit['amount'] as num).toDouble()) - ((credit['paid'] as num).toDouble()))}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Monto recibido')),
          DropdownButtonFormField<String>(value: method, items: const ['Efectivo','Tarjeta','Transferencia','Zelle','Otro'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => set(() => method = v ?? method), decoration: const InputDecoration(labelText: 'MÃ©todo')),
          DropdownButtonFormField<String>(value: currency, items: const ['USD','VES','COP','DOP'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => set(() => currency = v ?? currency), decoration: const InputDecoration(labelText: 'Moneda')),
          TextField(controller: reference, decoration: const InputDecoration(labelText: 'Referencia')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')), FilledButton(onPressed: () async {
          final a = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
          final rate = rates[currency] ?? 1;
          if (a <= 0) return;
          try { await store.addCreditPayment(creditId: credit['id'], amount: a, method: method, currency: currency, rate: rate, reference: reference.text.trim()); if (ctx.mounted) Navigator.pop(ctx, true); } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'))); }
        }, child: const Text('Guardar'))],
      );
    }));
    if (result == true) { await _load(); _snack('Abono registrado.'); }
  }

  Widget _notesTab(bool dark) {
    return _shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _header('Notas de crÃ©dito', 'Documenta devoluciones y ajustes sin borrar la venta original.', Icons.assignment_return_rounded, dark,
        action: FilledButton.icon(onPressed: _newNote, icon: const Icon(Icons.add_rounded), label: const Text('Nueva nota'))),
      const SizedBox(height: 18),
      Expanded(child: notes.isEmpty ? _empty('No hay notas de crÃ©dito.', Icons.assignment_return_rounded, dark) : ListView.separated(
        itemCount: notes.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) { final n = notes[i]; return _card(ListTile(
          leading: CircleAvatar(backgroundColor: ProColors.danger.withValues(alpha: .10), child: const Icon(Icons.assignment_return_rounded, color: ProColors.danger)),
          title: Text('${n['id']} Â· ${n['client']}', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('Venta: ${n['saleRef']} Â· ${n['reason']}'),
          trailing: Text(_money((n['amount'] as num?)?.toDouble() ?? 0), style: const TextStyle(fontWeight: FontWeight.w900)),
        )); },
      )),
    ]));
  }

  Future<void> _newNote() async {
    final sale = TextEditingController();
    final client = TextEditingController();
    final amount = TextEditingController();
    final reason = TextEditingController();
    final result = await showDialog<Map<String, String>>(context: context, builder: (_) => _FormDialog(title: 'Nueva nota de crÃ©dito', fields: [
      _F('Venta relacionada', sale), _F('Cliente', client), _F('Monto', amount, keyboard: const TextInputType.numberWithOptions(decimal: true)), _F('Motivo', reason, maxLines: 3),
    ], onSave: () {
      final a = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
      if (sale.text.trim().isEmpty || client.text.trim().isEmpty || a <= 0 || reason.text.trim().isEmpty) return null;
      return {'sale': sale.text.trim(), 'client': client.text.trim(), 'amount': '$a', 'reason': reason.text.trim()};
    }));
    if (result == null) return;
    await store.addNote(saleRef: result['sale']!, client: result['client']!, amount: double.parse(result['amount']!), reason: result['reason']!);
    await _load(); _snack('Nota de crÃ©dito emitida.');
  }

  Widget _cashTab(bool dark) {
    final open = sessions.where((e) => e['status'] == 'Abierta').toList();
    return _shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _header('Sesiones de caja', 'Apertura, cierre y control del efectivo contado.', Icons.point_of_sale_rounded, dark,
        action: open.isEmpty ? FilledButton.icon(onPressed: _openCash, icon: const Icon(Icons.lock_open_rounded), label: const Text('Abrir caja')) : FilledButton.icon(onPressed: _closeCash, icon: const Icon(Icons.lock_rounded), label: const Text('Cerrar caja'))),
      const SizedBox(height: 18),
      if (open.isNotEmpty) _card(ListTile(
        leading: const CircleAvatar(backgroundColor: Color(0x220ECB81), child: Icon(Icons.lock_open_rounded, color: ProColors.success)),
        title: Text('Caja ${open.first['register']} Â· ${open.first['cashier']}', style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('Abierta ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse('${open.first['openedAt']}') ?? DateTime.now())}'),
        trailing: const Chip(label: Text('ABIERTA')),
      )),
      const SizedBox(height: 14),
      Expanded(child: sessions.isEmpty ? _empty('No hay sesiones registradas.', Icons.point_of_sale_rounded, dark) : ListView.separated(
        itemCount: sessions.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) { final s = sessions[i]; final diff = s['difference']; return _card(ListTile(
          leading: Icon(s['status'] == 'Abierta' ? Icons.lock_open_rounded : Icons.lock_rounded, color: s['status'] == 'Abierta' ? ProColors.success : Colors.grey),
          title: Text('${s['register']} Â· ${s['cashier']}', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${s['status']} Â· ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse('${s['openedAt']}') ?? DateTime.now())}'),
          trailing: Text(diff is Map ? diff.entries.map((e) => '${e.key}: ${(e.value as num).toStringAsFixed(2)}').join('\n') : 'â€”', textAlign: TextAlign.right, style: const TextStyle(fontSize: 10)),
        )); },
      )),
    ]));
  }

  Future<void> _openCash() async {
    final cashier = TextEditingController(text: 'Administrador');
    final register = TextEditingController(text: 'Caja 01');
    final usd = TextEditingController(text: '0');
    final ves = TextEditingController(text: '0');
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => _FormDialog(title: 'Apertura de caja', fields: [
      _F('Cajero', cashier), _F('Caja', register), _F('Fondo inicial USD', usd, keyboard: const TextInputType.numberWithOptions(decimal: true)), _F('Fondo inicial VES', ves, keyboard: const TextInputType.numberWithOptions(decimal: true)),
    ], onSave: () => {'cashier': cashier.text.trim().isEmpty ? 'Administrador' : cashier.text.trim(), 'register': register.text.trim().isEmpty ? 'Caja 01' : register.text.trim(), 'opening': {'USD': double.tryParse(usd.text.replaceAll(',', '.')) ?? 0, 'VES': double.tryParse(ves.text.replaceAll(',', '.')) ?? 0}}));
    if (result == null) return;
    try { await store.openSession(cashier: result['cashier'], register: result['register'], opening: Map<String, double>.from(result['opening'])); await _load(); _snack('Caja abierta.'); } catch (e) { _snack('$e', error: true); }
  }

  Future<void> _closeCash() async {
    final usd = TextEditingController();
    final ves = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (_) => _FormDialog(title: 'Cierre y arqueo', fields: [
      _F('Efectivo contado USD', usd, keyboard: const TextInputType.numberWithOptions(decimal: true)), _F('Efectivo contado VES', ves, keyboard: const TextInputType.numberWithOptions(decimal: true)),
    ], onSave: () => true));
    if (result != true) return;
    try { await store.closeSession({'USD': double.tryParse(usd.text.replaceAll(',', '.')) ?? 0, 'VES': double.tryParse(ves.text.replaceAll(',', '.')) ?? 0}); await _load(); _snack('Caja cerrada.'); } catch (e) { _snack('$e', error: true); }
  }

  Widget _mixedPaymentsTab(bool dark) {
    final total = TextEditingController(text: '100');
    final controllers = <String, TextEditingController>{
      'Efectivo': TextEditingController(text: '50'),
      'Tarjeta': TextEditingController(text: '30'),
      'Transferencia': TextEditingController(text: '20'),
      'Otro': TextEditingController(text: '0'),
    };
    final currencies = <String, String>{
      'Efectivo': 'USD',
      'Tarjeta': 'USD',
      'Transferencia': 'USD',
      'Otro': 'USD',
    };
    return _shell(StatefulBuilder(builder: (context, set) {
      double toUsd(String method) {
        final amount = double.tryParse(controllers[method]!.text.replaceAll(',', '.')) ?? 0;
        final rate = rates[currencies[method]] ?? 1;
        return rate <= 0 ? amount : amount / rate;
      }
      final target = double.tryParse(total.text.replaceAll(',', '.')) ?? 0;
      final paid = controllers.keys.fold<double>(0, (s, m) => s + toUsd(m));
      final pending = (target - paid).clamp(0, double.infinity);
      final over = (paid - target).clamp(0, double.infinity);

      Widget row(String label) {
        final cur = currencies[label]!;
        final amount = double.tryParse(controllers[label]!.text.replaceAll(',', '.')) ?? 0;
        final usd = toUsd(label);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(width: 112, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
            Expanded(child: TextField(
              controller: controllers[label],
              onChanged: (_) => set(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto'),
            )),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: cur,
              items: const ['USD','VES','COP','DOP']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => set(() => currencies[label] = v ?? cur),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 92, child: Text(
              '= ${_money(usd)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey),
            )),
          ]),
        );
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header('Pagos mixtos', 'Una misma venta puede combinar mÃ©todos y monedas.', Icons.payments_rounded, dark),
        const SizedBox(height: 18),
        _card(Padding(padding: const EdgeInsets.all(18), child: Column(children: [
          TextField(
            controller: total,
            onChanged: (_) => set(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Total de la venta en USD'),
          ),
          const SizedBox(height: 14),
          ...controllers.keys.map(row),
          const Divider(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total equivalente', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(_money(paid), style: const TextStyle(fontWeight: FontWeight.w900)),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Pendiente', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(_money(pending), style: TextStyle(fontWeight: FontWeight.w900, color: pending <= .01 ? ProColors.success : ProColors.warning)),
          ]),
          if (over > .01)
            Align(alignment: Alignment.centerLeft, child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Vuelto: ${_money(over)}', style: const TextStyle(color: ProColors.success, fontWeight: FontWeight.w800)),
            )),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: paid <= 0 ? null : () async {
              await store.addAudit(
                'DistribuciÃ³n: ${controllers.keys.map((m) => '$m ${controllers[m]!.text} ${currencies[m]}').join(' Â· ')}',
                'Pagos mixtos',
              );
              await _load();
              _snack(pending <= .01 ? 'DistribuciÃ³n completa registrada.' : 'DistribuciÃ³n guardada con saldo pendiente.');
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Registrar distribuciÃ³n'),
          ),
        ]))),
      ]);
    }));
  }


  Widget _currencyTab(bool dark) {
    final controllers = {for (final e in rates.entries) e.key: TextEditingController(text: e.value.toString())};
    return _shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _header('Monedas y tasas', 'Define la equivalencia respecto a USD y conserva el valor usado.', Icons.currency_exchange_rounded, dark),
      const SizedBox(height: 18),
      _card(Padding(padding: const EdgeInsets.all(18), child: Column(children: [
        ...controllers.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: e.value, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: '1 USD = ${e.key}')))),
        FilledButton.icon(onPressed: () async { rates = {for (final e in controllers.entries) e.key: double.tryParse(e.value.text.replaceAll(',', '.')) ?? 1}; await store.saveRates(rates); await _load(); _snack('Tasas guardadas.'); }, icon: const Icon(Icons.save_rounded), label: const Text('Guardar tasas')),
      ]))),
    ]));
  }

  Widget _auditTab(bool dark) {
    return _shell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _header('AuditorÃ­a', 'Registro de acciones del mÃ³dulo profesional.', Icons.history_rounded, dark),
      const SizedBox(height: 18),
      Expanded(child: audits.isEmpty ? _empty('No hay actividad registrada.', Icons.history_rounded, dark) : ListView.separated(
        itemCount: audits.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) { final a = audits[i]; return _card(ListTile(
          leading: const Icon(Icons.bolt_rounded, color: ProColors.primary),
          title: Text('${a['action']}', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${a['module']} Â· ${a['user']} Â· ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.tryParse('${a['date']}') ?? DateTime.now())}'),
        )); },
      )),
    ]));
  }

  Future<Uint8List> _quoteBytes(Map<String, dynamic> q) async {
    final doc = pw.Document();
    final items = (q['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#4A176B'), borderRadius: pw.BorderRadius.circular(14)),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('SINTHETIX PRO', style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 3),
              pw.Text('COTIZACIÃ“N COMERCIAL', style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
            ]),
            pw.Text('${q['id']}', style: pw.TextStyle(color: PdfColors.white, fontSize: 15, fontWeight: pw.FontWeight.bold)),
          ]),
        ),
        pw.SizedBox(height: 18),
        pw.Text('Cliente: ${q['client']}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        if ('${q['phone']}'.isNotEmpty) pw.Text('Contacto: ${q['phone']}'),
        pw.Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse('${q['date']}') ?? DateTime.now())}'),
        pw.Text('Vigencia: ${q['validityDays']} dÃ­as'),
        pw.SizedBox(height: 18),
        pw.TableHelper.fromTextArray(
          headers: const ['Producto', 'Cant.', 'Precio', 'Total'],
          data: items.map((e) => ['${e['name']}', '${e['qty']}', _money((e['price'] as num).toDouble()), _money((e['total'] as num).toDouble())]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#7C3AED')),
          cellPadding: const pw.EdgeInsets.all(7),
        ),
        pw.SizedBox(height: 18),
        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('TOTAL: ${_money((q['total'] as num).toDouble())}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
        if ('${q['notes']}'.isNotEmpty) ...[pw.SizedBox(height: 18), pw.Text('Observaciones', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('${q['notes']}')],
        pw.SizedBox(height: 30),
        pw.Divider(),
        pw.Text('Documento generado por SINTHETIX PRO.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      ],
    ));
    return doc.save();
  }

  Future<void> _quotePdf(Map<String, dynamic> q) async {
    final bytes = await _quoteBytes(q);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: '${q['id']}.pdf');
  }

  Future<void> _shareQuote(Map<String, dynamic> q) async {
    final bytes = await _quoteBytes(q);
    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'application/pdf',
            name: '${q['id']}.pdf',
          ),
        ],
        text: 'Cotización ${q['id']} de SINTHETIX PRO',
        subject: 'Cotización ${q['id']}',
        fileNameOverrides: ['${q['id']}.pdf'],
      );
    } catch (_) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${q['id']}.pdf',
      );
    }
  }
}

class _F {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final int maxLines;
  _F(this.label, this.controller, {this.keyboard, this.maxLines = 1});
}

class _FormDialog extends StatelessWidget {
  final String title;
  final List<_F> fields;
  final Map<String, dynamic>? Function() onSave;

  const _FormDialog({required this.title, required this.fields, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fields.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: f.controller,
                keyboardType: f.keyboard,
                maxLines: f.maxLines,
                decoration: InputDecoration(labelText: f.label, border: const OutlineInputBorder()),
              ),
            )).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final value = onSave();
            if (value != null) Navigator.pop(context, value);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}


