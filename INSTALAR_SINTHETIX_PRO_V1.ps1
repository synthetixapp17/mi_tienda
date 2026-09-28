#requires -Version 5.1
$ErrorActionPreference = "Stop"

# ============================================================
# SINTHETIX PRO - INSTALADOR PRO V1
# Cotizaciones + Pago múltiple + limpieza visual
#
# IMPORTANTE:
# - NO toca cámara / mobile_scanner.
# - NO toca SQLite ni archivos de base de datos.
# - NO reemplaza main.dart por otro proyecto.
# - Crea backup y revierte si detecta errores reales.
# ============================================================

$Root = (Get-Location).Path
$Main = Join-Path $Root "lib\main.dart"
$Pago = Join-Path $Root "lib\pagos\pago_mixto.dart"
$Pro  = Join-Path $Root "lib\profesional\pro_features.dart"

if (!(Test-Path $Main)) {
    throw "No encuentro lib\main.dart. Ejecuta este instalador desde C:\Users\BRANAXEL\mi_tienda"
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupDir = Join-Path $Root "BACKUP_PRO_V1_$stamp"
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

Copy-Item $Main (Join-Path $BackupDir "main.dart") -Force
if (Test-Path $Pago) { Copy-Item $Pago (Join-Path $BackupDir "pago_mixto.dart") -Force }
if (Test-Path $Pro)  { Copy-Item $Pro  (Join-Path $BackupDir "pro_features.dart") -Force }

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " SINTHETIX PRO - INSTALADOR PRO V1" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Backup: $BackupDir" -ForegroundColor Green
Write-Host ""
Write-Host "Protegidos: CAMARA / SQLITE / BASE DE DATOS" -ForegroundColor Green
Write-Host ""

function Restore-Backup {
    Write-Host ""
    Write-Host "RESTAURANDO BACKUP..." -ForegroundColor Yellow
    Copy-Item (Join-Path $BackupDir "main.dart") $Main -Force
    if (Test-Path (Join-Path $BackupDir "pago_mixto.dart")) {
        New-Item -ItemType Directory -Force (Split-Path $Pago) | Out-Null
        Copy-Item (Join-Path $BackupDir "pago_mixto.dart") $Pago -Force
    }
    if (Test-Path (Join-Path $BackupDir "pro_features.dart")) {
        New-Item -ItemType Directory -Force (Split-Path $Pro) | Out-Null
        Copy-Item (Join-Path $BackupDir "pro_features.dart") $Pro -Force
    }
}

try {
    # --------------------------------------------------------
    # 1. Leer main.dart
    # --------------------------------------------------------
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $mainText = [System.IO.File]::ReadAllText($Main, $utf8)

    # No continuar si el archivo parece estar roto o vacío.
    if ($mainText.Length -lt 100000) {
        throw "main.dart es demasiado pequeño para ser el proyecto actual. No se modificó nada."
    }

    # --------------------------------------------------------
    # 2. Verificar que el proyecto actual ya tiene el módulo PRO
    # --------------------------------------------------------
    if ($mainText -notmatch "ProfesionalScreen\s*\(") {
        throw "No encontré ProfesionalScreen en main.dart. No voy a insertar navegación a ciegas."
    }

    # --------------------------------------------------------
    # 3. Corrección segura de textos dañados por UTF-8
    # --------------------------------------------------------
    $fixes = [ordered]@{
        "Pago mÃºltiple" = "Pago múltiple"
        "pago mÃºltiple" = "pago múltiple"
        "Pago MÃ³vil"    = "Pago Móvil"
        "pago mÃ³vil"    = "pago móvil"
        "PÃºblico General" = "Público General"
        "pÃºblico general" = "Público General"
        "nÃºmero" = "número"
        "NÃºmero" = "Número"
        "telÃ©fono" = "teléfono"
        "TelÃ©fono" = "Teléfono"
        "mÃ©todo" = "método"
        "MÃ©todo" = "Método"
        "cotizaciÃ³n" = "cotización"
        "CotizaciÃ³n" = "Cotización"
        "cotizaciÃ³n" = "cotización"
        "distribuciÃ³n" = "distribución"
        "operaciÃ³n" = "operación"
        "Â¡" = "¡"
        "Â¿" = "¿"
    }

    foreach ($pair in $fixes.GetEnumerator()) {
        $mainText = $mainText.Replace($pair.Key, $pair.Value)
    }

    [System.IO.File]::WriteAllText($Main, $mainText, $utf8)
    Write-Host "[OK] Textos visibles revisados." -ForegroundColor Green

    # --------------------------------------------------------
    # 4. Mejorar Pago Mixto
    #
    # Mantiene exactamente las APIs:
    # PagoMixtoItem
    # PagoMixtoController
    # PagoMixtoPanel
    #
    # Esto evita romper llamadas existentes.
    # --------------------------------------------------------
    if (Test-Path $Pago) {
        $payment = @'
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
    _pagos.add(PagoMixtoItem(metodo: metodo, importe: importe));
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
  final importeController = TextEditingController();

  String metodo = 'Efectivo';

  static const metodos = <String>[
    'Efectivo',
    'Tarjeta',
    'Transferencia',
    'Pago móvil',
    'Zelle',
    'Otro',
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
        const SnackBar(
          content: Text('Introduce un importe válido.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    controller.agregar(metodo, valor);
    importeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendiente = controller.pendiente;
    final vuelto = controller.vuelto;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pago múltiple',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Combina diferentes métodos de pago',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: metodo,
                  decoration: const InputDecoration(
                    labelText: 'Método de pago',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
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
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: importeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Importe',
                    prefixText: '\$ ',
                    prefixIcon: Icon(Icons.attach_money_rounded),
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

          const SizedBox(height: 16),

          if (controller.pagos.isNotEmpty)
            ...List.generate(
              controller.pagos.length,
              (index) {
                final pago = controller.pagos[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _iconoMetodo(pago.metodo),
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pago.metodo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '\$${pago.importe.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      IconButton(
                        onPressed: () => controller.eliminar(index),
                        icon: const Icon(Icons.delete_outline_rounded),
                        tooltip: 'Eliminar',
                      ),
                    ],
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
              color: theme.colorScheme.error,
            ),

          if (vuelto > 0)
            _resumen(
              'Vuelto',
              vuelto,
              destacado: true,
              color: theme.colorScheme.primary,
            ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: controller.completado
                ? () => widget.onConfirmar?.call(
                      controller.toMapList(),
                    )
                : null,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 13),
              child: Text(
                'CONFIRMAR PAGO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: .3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconoMetodo(String metodo) {
    switch (metodo) {
      case 'Tarjeta':
        return Icons.credit_card_rounded;
      case 'Transferencia':
        return Icons.account_balance_rounded;
      case 'Pago móvil':
        return Icons.phone_android_rounded;
      case 'Zelle':
        return Icons.currency_exchange_rounded;
      case 'Efectivo':
        return Icons.payments_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  Widget _resumen(
    String titulo,
    double valor, {
    bool destacado = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
              fontSize: destacado ? 18 : 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
'@
        Set-Content -Path $Pago -Value $payment -Encoding UTF8
        Write-Host "[OK] Pago múltiple: estética PRO instalada." -ForegroundColor Green
    }
    else {
        Write-Host "[AVISO] No existe lib\pagos\pago_mixto.dart. No se creó a ciegas." -ForegroundColor Yellow
    }

    # --------------------------------------------------------
    # 5. Revisar textos rotos también en módulo profesional
    # --------------------------------------------------------
    if (Test-Path $Pro) {
        $proText = [System.IO.File]::ReadAllText($Pro, $utf8)
        foreach ($pair in $fixes.GetEnumerator()) {
            $proText = $proText.Replace($pair.Key, $pair.Value)
        }
        [System.IO.File]::WriteAllText($Pro, $proText, $utf8)
        Write-Host "[OK] Textos del módulo Profesional revisados." -ForegroundColor Green
    }

    # --------------------------------------------------------
    # 6. Formatear SOLO archivos tocados.
    # --------------------------------------------------------
    Write-Host ""
    Write-Host "Formateando..." -ForegroundColor Cyan

    & dart format $Main
    if ($LASTEXITCODE -ne 0) {
        throw "dart format falló en main.dart."
    }

    if (Test-Path $Pago) {
        & dart format $Pago
        if ($LASTEXITCODE -ne 0) {
            throw "dart format falló en pago_mixto.dart."
        }
    }

    if (Test-Path $Pro) {
        & dart format $Pro
        if ($LASTEXITCODE -ne 0) {
            throw "dart format falló en pro_features.dart."
        }
    }

    # --------------------------------------------------------
    # 7. Analizar el proyecto.
    # --------------------------------------------------------
    Write-Host ""
    Write-Host "Analizando..." -ForegroundColor Cyan

    $log = Join-Path $env:TEMP "sinthetix_pro_v1_$stamp.txt"
    cmd.exe /c "flutter analyze lib\main.dart lib\pagos\pago_mixto.dart > `"$log`" 2>&1"
    $exitCode = $LASTEXITCODE
    $analysis = Get-Content $log -Raw

    Write-Host $analysis

    # Solo errores reales provocan rollback.
    if ($analysis -match "(?m)^\s*error\s*-\s") {
        throw "Flutter detectó errores Dart reales. Se restaurará automáticamente."
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " INSTALADOR PRO V1 TERMINADO" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "MEJORADO:" -ForegroundColor Green
    Write-Host " - Pago múltiple / mixto"
    Write-Host " - Textos con caracteres dañados"
    Write-Host " - Estética de tarjetas y resumen de pago"
    Write-Host ""
    Write-Host "NO TOCADO:" -ForegroundColor Green
    Write-Host " - Cámara"
    Write-Host " - SQLite"
    Write-Host " - Base de datos"
    Write-Host " - Productos"
    Write-Host " - Ventas"
    Write-Host ""
    Write-Host "BACKUP: $BackupDir" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "IMPORTANTE: La cotización con selección real de productos + PDF"
    Write-Host "se deja para el siguiente bloque de instalación para conectarla"
    Write-Host "a las APIs exactas de tu base de datos sin romper el POS."
    Write-Host ""

}
catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Restore-Backup
    Write-Host "RESTORE COMPLETADO. El proyecto quedó como estaba antes." -ForegroundColor Green
    exit 1
}
