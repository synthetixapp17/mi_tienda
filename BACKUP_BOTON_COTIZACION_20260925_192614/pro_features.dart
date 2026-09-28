import 'package:flutter/material.dart';

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

class _ProfesionalScreenState extends State<ProfesionalScreen> {
  int _tab = 0;

  final List<String> _tabs = const [
    'Cotizaciones',
    'CrÃ©dito',
    'Notas de crÃ©dito',
    'Caja',
    'Pagos mixtos',
    'Monedas',
    'AuditorÃ­a',
  ];

  final List<Map<String, dynamic>> _cotizaciones = [];
  final List<Map<String, dynamic>> _creditos = [];
  final List<Map<String, dynamic>> _notas = [];
  final List<Map<String, dynamic>> _movimientos = [];
  final List<Map<String, dynamic>> _auditoria = [];

  final Map<String, double> _monedas = {
    'USD': 1.0,
    'VES': 1.0,
    'COP': 1.0,
    'DOP': 1.0,
  };

  Color get _bg =>
      widget.modoOscuro ? const Color(0xFF11101A) : const Color(0xFFF5F6FA);

  Color get _cardColor =>
      widget.modoOscuro ? const Color(0xFF1D1B29) : Colors.white;

  Color get _text => widget.modoOscuro ? Colors.white : const Color(0xFF202124);

  void _audit(String accion) {
    _auditoria.insert(0, {
      'fecha': DateTime.now(),
      'accion': accion,
    });
    if (mounted) setState(() {});
  }

  Future<void> _nuevoSimple({
    required String titulo,
    required List<_Field> fields,
    required void Function(Map<String, String>) guardar,
  }) async {
    final controllers = {
      for (final f in fields) f.label: TextEditingController(),
    };

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final f in fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: controllers[f.label],
                      keyboardType: f.keyboard,
                      maxLines: f.maxLines,
                      decoration: InputDecoration(
                        labelText: f.label,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                ctx,
                {
                  for (final f in fields)
                    f.label: controllers[f.label]!.text.trim(),
                },
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    for (final c in controllers.values) {
      c.dispose();
    }

    if (result != null) {
      guardar(result);
      if (mounted) setState(() {});
    }
  }

  Widget _shell(Widget child) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'MenÃº',
                  onPressed: widget.onAbrirSidebar,
                  icon: const Icon(Icons.menu_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MÃ³dulo Profesional',
                    style: TextStyle(
                      color: _text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 58,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tabs.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: _tab == i,
                  label: Text(_tabs[i]),
                  onSelected: (_) => setState(() => _tab = i),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              child: _body(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_tab) {
      case 0:
        return _quotes();
      case 1:
        return _credits();
      case 2:
        return _creditNotes();
      case 3:
        return _cash();
      case 4:
        return _mixedPayments();
      case 5:
        return _currencies();
      default:
        return _auditView();
    }
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    return Card(
      color: _cardColor,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: _text,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: _text.withValues(alpha: .65),
                        ),
                      ),
                    ],
                  ),
                ),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: _text.withValues(alpha: .65)),
        ),
      ),
    );
  }

  Widget _quotes() {
    return _panel(
      title: 'Cotizaciones',
      subtitle: 'Crea una cotizaciÃ³n profesional para tu cliente.',
      icon: Icons.request_quote_rounded,
      action: FilledButton.icon(
        onPressed: _abrirNuevaCotizacion,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva cotizaciÃ³n'),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4B1FA8), Color(0xFF2457D6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            return Flex(
              direction: compact ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: compact ? 0 : 1,
                  child: Column(
                    crossAxisAlignment: compact
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.description_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nueva cotizaciÃ³n',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Prepara una cotizaciÃ³n para tu cliente y continÃºa con el siguiente paso.',
                        textAlign: compact ? TextAlign.center : TextAlign.left,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact) const SizedBox(width: 24),
                if (compact) const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4B1FA8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                  ),
                  onPressed: _abrirNuevaCotizacion,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'CREAR COTIZACIÃ“N',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _abrirNuevaCotizacion() async {
    final cliente = TextEditingController();
    final descripcion = TextEditingController();
    final total = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.request_quote_rounded),
            SizedBox(width: 10),
            Text('Nueva cotizaciÃ³n'),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: cliente,
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descripcion,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'DescripciÃ³n',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: total,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Total',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, {
              'cliente': cliente.text.trim(),
              'descripcion': descripcion.text.trim(),
              'total': total.text.trim(),
            }),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Guardar'),
          ),
        ],
      ),
    );

    cliente.dispose();
    descripcion.dispose();
    total.dispose();

    if (result == null) return;

    _cotizaciones.insert(0, {
      'cliente': result['cliente'] ?? '',
      'descripcion': result['descripcion'] ?? '',
      'total': result['total'] ?? '',
      'fecha': DateTime.now(),
    });
    _audit('Nueva cotizaciÃ³n');
    if (mounted) setState(() {});
  }
  Widget _credits() {
    return _panel(
      title: 'CrÃ©dito',
      subtitle: 'Registro bÃ¡sico de ventas y saldos a crÃ©dito.',
      icon: Icons.credit_score_rounded,
      action: FilledButton.icon(
        onPressed: () => _nuevoSimple(
          titulo: 'Nuevo crÃ©dito',
          fields: const [
            _Field('Cliente'),
            _Field('Monto'),
            _Field('Referencia'),
          ],
          guardar: (v) {
            _creditos.insert(0, {
              'cliente': v['Cliente'] ?? '',
              'monto': v['Monto'] ?? '',
              'referencia': v['Referencia'] ?? '',
              'fecha': DateTime.now(),
            });
            _audit('Nuevo crÃ©dito');
          },
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      child: _creditos.isEmpty
          ? _empty('TodavÃ­a no hay crÃ©ditos registrados.')
          : Column(
              children: [
                for (final c in _creditos)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(c['cliente'].toString(),
                        style: TextStyle(color: _text)),
                    subtitle: Text(
                      'Monto: ${c['monto']}  â€¢  ${c['referencia']}',
                      style: TextStyle(color: _text.withValues(alpha: .65)),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _creditNotes() {
    return _panel(
      title: 'Notas de crÃ©dito',
      subtitle: 'Registra devoluciones, ajustes y notas de crÃ©dito.',
      icon: Icons.receipt_long_rounded,
      action: FilledButton.icon(
        onPressed: () => _nuevoSimple(
          titulo: 'Nueva nota de crÃ©dito',
          fields: const [
            _Field('Cliente'),
            _Field('Motivo', maxLines: 3),
            _Field('Monto'),
          ],
          guardar: (v) {
            _notas.insert(0, {
              'cliente': v['Cliente'] ?? '',
              'motivo': v['Motivo'] ?? '',
              'monto': v['Monto'] ?? '',
              'fecha': DateTime.now(),
            });
            _audit('Nueva nota de crÃ©dito');
          },
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      child: _notas.isEmpty
          ? _empty('TodavÃ­a no hay notas de crÃ©dito.')
          : Column(
              children: [
                for (final n in _notas)
                  ListTile(
                    leading: const Icon(Icons.undo_rounded),
                    title: Text(n['cliente'].toString(),
                        style: TextStyle(color: _text)),
                    subtitle: Text(
                      '${n['motivo']}  â€¢  ${n['monto']}',
                      style: TextStyle(color: _text.withValues(alpha: .65)),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _cash() {
    return _panel(
      title: 'Caja',
      subtitle: 'Apertura, movimientos y cierre de caja.',
      icon: Icons.point_of_sale_rounded,
      action: FilledButton.icon(
        onPressed: () => _nuevoSimple(
          titulo: 'Movimiento de caja',
          fields: const [
            _Field('Tipo'),
            _Field('Monto'),
            _Field('DescripciÃ³n'),
          ],
          guardar: (v) {
            _movimientos.insert(0, {
              'tipo': v['Tipo'] ?? '',
              'monto': v['Monto'] ?? '',
              'descripcion': v['DescripciÃ³n'] ?? '',
              'fecha': DateTime.now(),
            });
            _audit('Movimiento de caja');
          },
        ),
        icon: const Icon(Icons.add),
        label: const Text('Movimiento'),
      ),
      child: _movimientos.isEmpty
          ? _empty('No hay movimientos de caja.')
          : Column(
              children: [
                for (final m in _movimientos)
                  ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: Text(m['tipo'].toString(),
                        style: TextStyle(color: _text)),
                    subtitle: Text(
                      '${m['monto']}  â€¢  ${m['descripcion']}',
                      style: TextStyle(color: _text.withValues(alpha: .65)),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _mixedPayments() {
    return _panel(
      title: 'Pagos mixtos',
      subtitle: 'Registra una venta distribuida entre varios mÃ©todos.',
      icon: Icons.account_balance_wallet_rounded,
      action: FilledButton.icon(
        onPressed: () => _nuevoSimple(
          titulo: 'Pago mixto',
          fields: const [
            _Field('Efectivo'),
            _Field('Tarjeta'),
            _Field('Transferencia'),
            _Field('Referencia'),
          ],
          guardar: (v) {
            _movimientos.insert(0, {
              'tipo': 'Pago mixto',
              'monto':
                  'Efectivo ${v['Efectivo']} / Tarjeta ${v['Tarjeta']} / Transferencia ${v['Transferencia']}',
              'descripcion': v['Referencia'] ?? '',
              'fecha': DateTime.now(),
            });
            _audit('Pago mixto registrado');
          },
        ),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      child: _empty(
        'Usa "Registrar" para distribuir el pago entre varios mÃ©todos.',
      ),
    );
  }

  Widget _currencies() {
    return _panel(
      title: 'Monedas',
      subtitle: 'Tasas configurables para USD, VES, COP y DOP.',
      icon: Icons.currency_exchange_rounded,
      action: FilledButton.icon(
        onPressed: () => _nuevoSimple(
          titulo: 'Actualizar tasa',
          fields: const [
            _Field('Moneda'),
            _Field('Tasa'),
          ],
          guardar: (v) {
            final moneda = (v['Moneda'] ?? '').toUpperCase();
            final tasa = double.tryParse(v['Tasa'] ?? '');
            if (_monedas.containsKey(moneda) && tasa != null) {
              _monedas[moneda] = tasa;
              _audit('Tasa actualizada: $moneda');
              setState(() {});
            }
          },
        ),
        icon: const Icon(Icons.edit),
        label: const Text('Actualizar'),
      ),
      child: Column(
        children: [
          for (final e in _monedas.entries)
            ListTile(
              leading: const Icon(Icons.attach_money_rounded),
              title: Text(e.key, style: TextStyle(color: _text)),
              trailing: Text(
                e.value.toString(),
                style: TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _auditView() {
    return _panel(
      title: 'AuditorÃ­a',
      subtitle: 'Registro de acciones realizadas dentro del mÃ³dulo.',
      icon: Icons.history_rounded,
      child: _auditoria.isEmpty
          ? _empty('No hay eventos registrados.')
          : Column(
              children: [
                for (final a in _auditoria)
                  ListTile(
                    leading: const Icon(Icons.event_note_outlined),
                    title: Text(
                      a['accion'].toString(),
                      style: TextStyle(color: _text),
                    ),
                    subtitle: Text(
                      a['fecha'].toString(),
                      style: TextStyle(color: _text.withValues(alpha: .65)),
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) => _shell(_body());
}

class _Field {
  final String label;
  final TextInputType? keyboard;
  final int maxLines;

  const _Field(
    this.label, {
    this.keyboard,
    this.maxLines = 1,
  });
}
