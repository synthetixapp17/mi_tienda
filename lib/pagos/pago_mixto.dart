import 'package:flutter/material.dart';

class PagoMixtoItem {
  final String metodo;
  final double importe;

  const PagoMixtoItem({
    required this.metodo,
    required this.importe,
  });

  Map<String, dynamic> toMap() => {
        'metodo': metodo,
        'importe': importe,
      };
}

class PagoMixtoController extends ChangeNotifier {
  final double total;

  final List<PagoMixtoItem> _pagos = [];

  PagoMixtoController(this.total);

  List<PagoMixtoItem> get pagos => List.unmodifiable(_pagos);

  double get totalPagado =>
      _pagos.fold<double>(0, (sum, item) => sum + item.importe);

  double get pendiente =>
      (total - totalPagado).clamp(0, double.infinity).toDouble();

  double get vuelto =>
      (totalPagado - total).clamp(0, double.infinity).toDouble();

  bool get completado => pendiente <= 0.009;

  void agregar(String metodo, double importe) {
    if (importe <= 0) return;

    _pagos.add(PagoMixtoItem(
      metodo: metodo,
      importe: importe,
    ));

    notifyListeners();
  }

  void eliminar(int index) {
    if (index < 0 || index >= _pagos.length) return;

    _pagos.removeAt(index);
    notifyListeners();
  }

  void limpiar() {
    _pagos.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toMapList() =>
      _pagos.map((p) => p.toMap()).toList();
}

class PagoMixtoPanel extends StatefulWidget {
  final double total;
  final ValueChanged<List<Map<String, dynamic>>>? onConfirmar;

  const PagoMixtoPanel({
    super.key,
    required this.total,
    this.onConfirmar,
  });

  @override
  State<PagoMixtoPanel> createState() => _PagoMixtoPanelState();
}

class _PagoMixtoPanelState extends State<PagoMixtoPanel> {
  late final PagoMixtoController controller;
  final TextEditingController importeController = TextEditingController();
  String metodo = 'Efectivo';

  static const metodos = [
    'Efectivo',
    'Tarjeta',
    'Transferencia',
    'Pago móvil',
  ];

  @override
  void initState() {
    super.initState();
    controller = PagoMixtoController(widget.total);
    controller.addListener(_actualizar);
  }

  void _actualizar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_actualizar);
    controller.dispose();
    importeController.dispose();
    super.dispose();
  }

  void _agregarPago() {
    final valor = double.tryParse(
      importeController.text.trim().replaceAll(',', '.'),
    );

    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce un importe válido.')),
      );
      return;
    }

    controller.agregar(metodo, valor);
    importeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final pendiente = controller.pendiente;
    final vuelto = controller.vuelto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pago múltiple',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: metodo,
                decoration: const InputDecoration(
                  labelText: 'Método',
                  border: OutlineInputBorder(),
                ),
                items: metodos
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(m),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => metodo = v);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: importeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Importe',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _agregarPago(),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _agregarPago,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Agregar pago',
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (controller.pagos.isNotEmpty)
          ...List.generate(
            controller.pagos.length,
            (index) {
              final pago = controller.pagos[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 7),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.payments_outlined),
                  ),
                  title: Text(
                    pago.metodo,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${pago.importe.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      IconButton(
                        onPressed: () => controller.eliminar(index),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        _resumen('Total', widget.total),
        _resumen('Total pagado', controller.totalPagado),
        if (pendiente > 0)
          _resumen(
            'Saldo pendiente',
            pendiente,
            destacado: true,
          ),
        if (vuelto > 0)
          _resumen(
            'Vuelto',
            vuelto,
            destacado: true,
          ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: controller.completado
              ? () => widget.onConfirmar?.call(controller.toMapList())
              : null,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text(
            'CONFIRMAR PAGO',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _resumen(
    String titulo,
    double valor, {
    bool destacado = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontWeight: destacado ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '\$${valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: destacado ? 17 : 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
