import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';

Map<String, double> tasasCambio = {'USD': 1.0, 'COP': 4500.0, 'VES': 60.0};
Map<String, String> simbolosMoneda = {'USD': '\$', 'COP': '\$', 'VES': 'Bs.'};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rbgtbwzyvrgaslaajxev.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJiZ3Rid3p5dnJnYXNsYWFqeGV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5NjMzMDksImV4cCI6MjEwMDUzOTMwOX0.uc85JmtU1SfO7vBTwuSMJEqqIlHK9mAR2jtyH9c8EnA',
  );

  final prefs = await SharedPreferences.getInstance();
  tasasCambio['COP'] = prefs.getDouble('tasa_cop') ?? 4500.0;
  tasasCambio['VES'] = prefs.getDouble('tasa_ves') ?? 60.0;
  runApp(const MiApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ============================================
// SERVICIO DE SONIDO - BEEP ARREGLADO DIRECTO Y SIMPLE
// ============================================
class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  Future<void> playBeep() async {
    if (_isPlaying) return;
    _isPlaying = true;

    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/beep.mp3'));
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      debugPrint('Error reproduciendo beep: $e');
      // Respaldo: usar sonido del sistema
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.mediumImpact();
    } finally {
      _isPlaying = false;
    }
  }

  void dispose() {
    _player.dispose();
  }
}

class AppColors {
  static Color background(bool isDark) =>
      isDark ? const Color(0xFF0C0D12) : const Color(0xFFF8F9FA);
  static Color card(bool isDark) =>
      isDark ? const Color(0xFF1F222B) : Colors.white;
  static Color appBar(bool isDark) =>
      isDark ? const Color(0xFF1F222B) : Colors.white;
  static Color text(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF1A1A2E);
  static Color subtext(bool isDark) =>
      isDark ? const Color(0xFFB0B0B0) : const Color(0xFF6B7280);
  static Color drawerBg(bool isDark) =>
      isDark ? const Color(0xFF0C0D12) : Colors.white;
  static Color iconBg(bool isDark) =>
      isDark ? const Color(0xFF1F222B) : const Color(0xFFF0F0F0);
  static Color iconBgHeader(bool isDark) =>
      isDark ? const Color(0xFF1F222B) : const Color(0xFFF0F0F0);
  static Color headerIcon(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF1A1A2E);
  static Color bannerBg(bool isDark) =>
      isDark ? const Color(0xFF1F222B) : Colors.white;
  static Color footerBg(bool isDark) =>
      isDark ? const Color(0xFF0C0D12) : const Color(0xFFF8F9FA);
  static Color shadow(bool isDark) =>
      isDark ? Colors.black : const Color(0xFF7C3AED).withValues(alpha: 0.08);
  static Color divider(bool isDark) =>
      isDark ? Colors.white10 : const Color(0xFFE5E7EB);
  static Color announcementBg(bool isDark) =>
      isDark ? const Color(0xFF161820) : const Color(0xFF7C3AED);

  static const Color primary = Color(0xFF7C3AED);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color whatsapp = Color(0xFF25D366);
  static const Color blue = Color(0xFF7C3AED);
  static const Color cartBg = Color(0xFFF8F9FA);
  static const Color cartCard = Colors.white;
  static const Color logoFuchsia = Color(0xFF7C3AED);
  static const Color logoCyan = Color(0xFF06B6D4);
  static const Color logoRed = Color(0xFFEF4444);

  static const Color textLight = Color(0xFF1A1A2E);
  static const Color subtextLight = Color(0xFF6B7280);
  static const Color dividerLight = Color(0xFFE5E7EB);
  static const Color backgroundLight = Color(0xFFF8F9FA);
}

Map<String, dynamic> convertToMapStringDynamic(dynamic data) {
  if (data == null) return {};
  if (data is Map<String, dynamic>) return data;
  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

Future<String> getDeviceId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? deviceId = prefs.getString('device_id');
  if (deviceId == null) {
    deviceId = DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecondsSinceEpoch % 1000).toString();
    await prefs.setString('device_id', deviceId);
  }
  return deviceId;
}

Future<void> launchURL(String url) async {}

Future<String> comprimirImagen(Uint8List bytes) async {
  return base64Encode(bytes);
}

class ImagenProducto extends StatelessWidget {
  final String? imagenUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final IconData icono;

  const ImagenProducto({
    super.key,
    required this.imagenUrl,
    this.width = 60,
    this.height = 60,
    this.fit = BoxFit.cover,
    this.icono = Icons.shopping_bag_outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (imagenUrl == null || imagenUrl!.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Icon(icono, color: AppColors.subtextLight, size: width * 0.4),
      );
    }

    if (imagenUrl!.startsWith('data:image')) {
      try {
        final base64Data = imagenUrl!.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child:
                Icon(icono, color: AppColors.subtextLight, size: width * 0.4),
          ),
        );
      } catch (e) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(icono, color: AppColors.subtextLight, size: width * 0.4),
        );
      }
    }

    if (imagenUrl!.startsWith('http')) {
      return Image.network(
        imagenUrl!,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(icono, color: AppColors.subtextLight, size: width * 0.4),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(icono, color: AppColors.subtextLight, size: width * 0.4),
    );
  }
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._();
  factory DatabaseService() => _instance;
  DatabaseService._();

  Future<List<Map<String, dynamic>>> getProductos() async {
    try {
      final response = await Supabase.instance.client
          .from('productos')
          .select()
          .order('nombre');
      final productos = List<Map<String, dynamic>>.from(response as List);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('productos_local', jsonEncode(productos));

      return productos;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('productos_local');
      if (data != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(data));
      }
      return [];
    }
  }

  Future<Map<String, dynamic>?> crearProducto(Map<String, dynamic> prod) async {
    try {
      final response = await Supabase.instance.client
          .from('productos')
          .insert(prod)
          .select()
          .single();
      return response as Map<String, dynamic>;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final productos = await getProductos();
      prod['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      prod['creado_en'] = DateTime.now().toIso8601String();
      productos.add(prod);
      await prefs.setString('productos_local', jsonEncode(productos));
      return prod;
    }
  }

  Future<Map<String, dynamic>?> actualizarProducto(
      String id, Map<String, dynamic> prod) async {
    try {
      final response = await Supabase.instance.client
          .from('productos')
          .update(prod)
          .eq('id', id)
          .select()
          .single();
      return response as Map<String, dynamic>;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final productos = await getProductos();
      final index = productos.indexWhere((p) => p['id'].toString() == id);
      if (index >= 0) {
        productos[index] = {...productos[index], ...prod};
        await prefs.setString('productos_local', jsonEncode(productos));
      }
      return prod;
    }
  }

  Future<void> eliminarProducto(String id) async {
    try {
      await Supabase.instance.client.from('productos').delete().eq('id', id);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final productos = await getProductos();
      productos.removeWhere((p) => p['id'].toString() == id);
      await prefs.setString('productos_local', jsonEncode(productos));
    }
  }

  Future<Map<String, dynamic>?> buscarPorCodigo(String codigo) async {
    try {
      final response = await Supabase.instance.client
          .from('productos')
          .select()
          .eq('codigo_barras', codigo)
          .single();
      return response as Map<String, dynamic>;
    } catch (e) {
      final productos = await getProductos();
      for (var p in productos) {
        if (p['codigo_barras'] == codigo) return p;
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> crearVenta(Map<String, dynamic> venta) async {
    try {
      final response = await Supabase.instance.client
          .from('ventas')
          .insert(venta)
          .select()
          .single();
      return response as Map<String, dynamic>;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final ventasData = prefs.getString('ventas_local');
      List<Map<String, dynamic>> ventas = [];
      if (ventasData != null) {
        ventas = List<Map<String, dynamic>>.from(jsonDecode(ventasData));
      }
      venta['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      venta['fecha'] = DateTime.now().toIso8601String();
      ventas.add(venta);
      await prefs.setString('ventas_local', jsonEncode(ventas));
      return venta;
    }
  }

  Future<void> crearDetalleVenta(Map<String, dynamic> detalle) async {
    try {
      await Supabase.instance.client.from('detalle_venta').insert(detalle);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final detallesData = prefs.getString('detalle_venta_local');
      List<Map<String, dynamic>> detalles = [];
      if (detallesData != null) {
        detalles = List<Map<String, dynamic>>.from(jsonDecode(detallesData));
      }
      detalles.add(detalle);
      await prefs.setString('detalle_venta_local', jsonEncode(detalles));
    }
  }

  Future<List<Map<String, dynamic>>> getVentasHoy() async {
    try {
      final hoy = DateTime.now();
      final inicio = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();
      final response = await Supabase.instance.client
          .from('ventas')
          .select()
          .gte('fecha', inicio)
          .order('fecha', ascending: false);
      final ventas = List<Map<String, dynamic>>.from(response as List);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ventas_local', jsonEncode(ventas));

      return ventas;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final ventasData = prefs.getString('ventas_local');
      if (ventasData != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(ventasData));
      }
      return [];
    }
  }

  Future<double> getTotalVentasHoy() async {
    final ventas = await getVentasHoy();
    double total = 0;
    for (var v in ventas) {
      total += (v['total'] as num).toDouble();
    }
    return total;
  }

  Future<int> getCantidadVentasHoy() async {
    final ventas = await getVentasHoy();
    return ventas.length;
  }

  Future<List<Map<String, dynamic>>> getClientes() async {
    try {
      final response = await Supabase.instance.client
          .from('clientes')
          .select()
          .order('nombre');
      final clientes = List<Map<String, dynamic>>.from(response as List);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('clientes_local', jsonEncode(clientes));

      return clientes;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('clientes_local');
      if (data != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(data));
      }
      return [];
    }
  }

  Future<Map<String, dynamic>?> buscarClientePorCedula(String cedula) async {
    try {
      final response = await Supabase.instance.client
          .from('clientes')
          .select()
          .eq('identificacion', cedula)
          .single();
      return response as Map<String, dynamic>;
    } catch (e) {
      final clientes = await getClientes();
      for (var c in clientes) {
        if (c['identificacion'] == cedula) return c;
      }
      return null;
    }
  }

  Future<void> crearCliente(Map<String, dynamic> cliente) async {
    try {
      await Supabase.instance.client.from('clientes').insert(cliente);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final clientes = await getClientes();
      cliente['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      clientes.add(cliente);
      await prefs.setString('clientes_local', jsonEncode(clientes));
    }
  }

  Future<void> actualizarCliente(
      String id, Map<String, dynamic> cliente) async {
    try {
      await Supabase.instance.client
          .from('clientes')
          .update(cliente)
          .eq('id', id);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final clientes = await getClientes();
      final index = clientes.indexWhere((c) => c['id'].toString() == id);
      if (index >= 0) {
        clientes[index] = {...clientes[index], ...cliente};
        await prefs.setString('clientes_local', jsonEncode(clientes));
      }
    }
  }

  Future<void> eliminarCliente(String id) async {
    try {
      await Supabase.instance.client.from('clientes').delete().eq('id', id);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final clientes = await getClientes();
      clientes.removeWhere((c) => c['id'].toString() == id);
      await prefs.setString('clientes_local', jsonEncode(clientes));
    }
  }

  Future<List<Map<String, dynamic>>> getCategorias() async {
    try {
      final response = await Supabase.instance.client
          .from('categorias')
          .select()
          .order('nombre');
      final categorias = List<Map<String, dynamic>>.from(response as List);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('categorias_local', jsonEncode(categorias));

      return categorias;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('categorias_local');
      if (data != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(data));
      }
      return [
        {
          'id': 1,
          'nombre': 'General',
          'descripcion': 'Categoria general',
          'activo': true
        }
      ];
    }
  }

  Future<void> crearCategoria(Map<String, dynamic> categoria) async {
    try {
      await Supabase.instance.client.from('categorias').insert(categoria);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final categorias = await getCategorias();
      categorias.add(categoria);
      await prefs.setString('categorias_local', jsonEncode(categorias));
    }
  }

  Future<void> actualizarCategoria(
      String id, Map<String, dynamic> categoria) async {
    try {
      await Supabase.instance.client
          .from('categorias')
          .update(categoria)
          .eq('id', id);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final categorias = await getCategorias();
      final index = categorias.indexWhere((c) => c['id'].toString() == id);
      if (index >= 0) {
        categorias[index] = {...categorias[index], ...categoria};
        await prefs.setString('categorias_local', jsonEncode(categorias));
      }
    }
  }

  Future<void> eliminarCategoria(String id) async {
    try {
      await Supabase.instance.client.from('categorias').delete().eq('id', id);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final categorias = await getCategorias();
      categorias.removeWhere((c) => c['id'].toString() == id);
      await prefs.setString('categorias_local', jsonEncode(categorias));
    }
  }

  Future<List<Map<String, dynamic>>> getMetodosPago() async {
    try {
      final response = await Supabase.instance.client
          .from('metodos_pago')
          .select()
          .order('nombre');
      final metodos = List<Map<String, dynamic>>.from(response as List);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('metodos_pago_local', jsonEncode(metodos));

      return metodos;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('metodos_pago_local');
      if (data != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(data));
      }
      return [
        {'id': 1, 'nombre': 'Efectivo', 'activo': true},
        {'id': 2, 'nombre': 'Tarjeta', 'activo': true},
        {'id': 3, 'nombre': 'Transferencia', 'activo': true},
        {'id': 4, 'nombre': 'Pago Movil', 'activo': true},
      ];
    }
  }

  Future<void> crearMetodoPago(Map<String, dynamic> metodo) async {
    try {
      await Supabase.instance.client.from('metodos_pago').insert(metodo);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final metodos = await getMetodosPago();
      metodos.add(metodo);
      await prefs.setString('metodos_pago_local', jsonEncode(metodos));
    }
  }

  Future<void> actualizarMetodoPago(
      String id, Map<String, dynamic> metodo) async {
    try {
      await Supabase.instance.client
          .from('metodos_pago')
          .update(metodo)
          .eq('id', id);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final metodos = await getMetodosPago();
      final index = metodos.indexWhere((m) => m['id'].toString() == id);
      if (index >= 0) {
        metodos[index] = {...metodos[index], ...metodo};
        await prefs.setString('metodos_pago_local', jsonEncode(metodos));
      }
    }
  }

  Future<void> eliminarMetodoPago(String id) async {
    try {
      await Supabase.instance.client.from('metodos_pago').delete().eq('id', id);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final metodos = await getMetodosPago();
      metodos.removeWhere((m) => m['id'].toString() == id);
      await prefs.setString('metodos_pago_local', jsonEncode(metodos));
    }
  }

  Future<List<Map<String, dynamic>>> getVendedores() async {
    try {
      final response = await Supabase.instance.client
          .from('vendedores')
          .select()
          .order('nombre');
      final vendedores = List<Map<String, dynamic>>.from(response as List);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vendedores_local', jsonEncode(vendedores));

      return vendedores;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('vendedores_local');
      if (data != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(data));
      }
      return [];
    }
  }

  Future<void> crearVendedor(Map<String, dynamic> vendedor) async {
    try {
      await Supabase.instance.client.from('vendedores').insert(vendedor);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final vendedores = await getVendedores();
      vendedores.add(vendedor);
      await prefs.setString('vendedores_local', jsonEncode(vendedores));
    }
  }

  Future<void> actualizarVendedor(
      String id, Map<String, dynamic> vendedor) async {
    try {
      await Supabase.instance.client
          .from('vendedores')
          .update(vendedor)
          .eq('id', id);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final vendedores = await getVendedores();
      final index = vendedores.indexWhere((v) => v['id'].toString() == id);
      if (index >= 0) {
        vendedores[index] = {...vendedores[index], ...vendedor};
        await prefs.setString('vendedores_local', jsonEncode(vendedores));
      }
    }
  }

  Future<void> eliminarVendedor(String id) async {
    try {
      await Supabase.instance.client.from('vendedores').delete().eq('id', id);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final vendedores = await getVendedores();
      vendedores.removeWhere((v) => v['id'].toString() == id);
      await prefs.setString('vendedores_local', jsonEncode(vendedores));
    }
  }

  Future<Map<String, dynamic>?> getConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('configuracion_local');
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> guardarConfiguracion(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('configuracion_local', jsonEncode(config));
    try {
      await Supabase.instance.client.from('configuracion').upsert(config);
    } catch (e) {
      // Silencioso - guardado localmente
    }
  }

  Future<String?> subirImagenSupabase(Uint8List bytes, String path) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fullPath = '$path/$fileName';
      await Supabase.instance.client.storage
          .from('imagenes')
          .uploadBinary(fullPath, bytes);
      final url = Supabase.instance.client.storage
          .from('imagenes')
          .getPublicUrl(fullPath);
      return url;
    } catch (e) {
      debugPrint('Error subiendo imagen: $e');
      return null;
    }
  }

  Future<void> registrarMovimientoInventario(Map<String, dynamic> mov) async {
    try {
      await Supabase.instance.client.from('movimientos_inventario').insert(mov);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final movimientosData = prefs.getString('movimientos_inventario_local');
      List<Map<String, dynamic>> movimientos = [];
      if (movimientosData != null) {
        movimientos =
            List<Map<String, dynamic>>.from(jsonDecode(movimientosData));
      }
      mov['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      mov['fecha'] = DateTime.now().toIso8601String();
      movimientos.add(mov);
      await prefs.setString(
          'movimientos_inventario_local', jsonEncode(movimientos));
    }
  }

  Future<List<Map<String, dynamic>>> getMovimientosInventario() async {
    try {
      final response = await Supabase.instance.client
          .from('movimientos_inventario')
          .select()
          .order('fecha', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('movimientos_inventario_local');
      if (data != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(data));
      }
      return [];
    }
  }

  Future<Map<String, dynamic>> getReporteGeneral(
      DateTime inicio, DateTime fin) async {
    final ventas = await getVentasHoy();
    double total = 0;
    for (var v in ventas) {
      total += (v['total'] as num).toDouble();
    }
    return {
      'total_ventas': total,
      'cantidad_ventas': ventas.length,
      'ventas': ventas,
    };
  }

  Future<Map<String, dynamic>?> getPerfilUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('perfil_usuario');
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return {
      'id': 1,
      'email': 'admin@sinthetix.com',
      'nombre': 'Admin',
      'rol': 'admin'
    };
  }

  Future<void> actualizarPerfil(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final perfilActual = await getPerfilUsuario() ?? {};
    final nuevoPerfil = {...perfilActual, ...data};
    await prefs.setString('perfil_usuario', jsonEncode(nuevoPerfil));
  }

  Future<void> cambiarPassword(String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password_local', newPassword);
  }
}

class CajaService {
  final _prefsKey = 'caja_actual';
  final _historialKey = 'caja_historial';

  Future<Map<String, dynamic>?> getCajaAbierta() async {
    try {
      final response = await Supabase.instance.client
          .from('cierres_caja')
          .select()
          .eq('estado', 'Abierta')
          .single();
      return response as Map<String, dynamic>;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_prefsKey);
      if (data != null) return jsonDecode(data) as Map<String, dynamic>;
      return null;
    }
  }

  Future<void> abrirCaja(double montoInicial) async {
    try {
      await Supabase.instance.client.from('cierres_caja').insert({
        'monto_inicial': montoInicial,
        'estado': 'Abierta',
      });
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final caja = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'fecha_apertura': DateTime.now().toIso8601String(),
        'monto_inicial': montoInicial,
        'total_ventas': 0.0,
        'estado': 'Abierta',
        'movimientos': []
      };
      await prefs.setString(_prefsKey, jsonEncode(caja));
    }
  }

  Future<void> cerrarCaja(double montoFinal) async {
    try {
      final caja = await getCajaAbierta();
      if (caja != null) {
        await Supabase.instance.client.from('cierres_caja').update({
          'monto_final': montoFinal,
          'estado': 'Cerrada',
          'fecha_cierre': DateTime.now().toIso8601String(),
        }).eq('id', caja['id']);
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    }
  }

  Future<void> agregarVentaACaja(double monto) async {
    try {
      final caja = await getCajaAbierta();
      if (caja != null) {
        final nuevoTotal = (caja['total_ventas'] as num).toDouble() + monto;
        await Supabase.instance.client
            .from('cierres_caja')
            .update({'total_ventas': nuevoTotal}).eq('id', caja['id']);
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_prefsKey);
      if (data != null) {
        final caja = jsonDecode(data) as Map<String, dynamic>;
        caja['total_ventas'] = (caja['total_ventas'] as num).toDouble() + monto;
        await prefs.setString(_prefsKey, jsonEncode(caja));
      }
    }
  }

  Future<void> registrarMovimiento(
      String tipo, double monto, String descripcion) async {
    try {
      final caja = await getCajaAbierta();
      if (caja != null) {
        await Supabase.instance.client.from('gastos').insert({
          'caja_id': caja['id'],
          'descripcion': descripcion,
          'monto': monto,
        });
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_prefsKey);
      if (data != null) {
        final caja = jsonDecode(data) as Map<String, dynamic>;
        final movimientos = caja['movimientos'] as List? ?? [];
        movimientos.add({
          'tipo': tipo,
          'monto': monto,
          'descripcion': descripcion,
          'fecha': DateTime.now().toIso8601String()
        });
        caja['movimientos'] = movimientos;
        await prefs.setString(_prefsKey, jsonEncode(caja));
      }
    }
  }

  Future<List<Map<String, dynamic>>> getMovimientosHoy() async {
    final caja = await getCajaAbierta();
    if (caja != null) {
      return List<Map<String, dynamic>>.from(caja['movimientos'] ?? []);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getHistorialCajas() async {
    try {
      final response = await Supabase.instance.client
          .from('cierres_caja')
          .select()
          .eq('estado', 'Cerrada')
          .order('fecha_cierre', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final historial = prefs.getStringList(_historialKey) ?? [];
      return historial
          .map((h) => jsonDecode(h) as Map<String, dynamic>)
          .toList();
    }
  }
}

class DatosPrueba {
  static int facturaCounter = 1;
  static String generarNumeroFactura() =>
      'FAC-${(facturaCounter++).toString().padLeft(8, '0')}';
}

class MiApp extends StatefulWidget {
  const MiApp({super.key});
  @override
  State<MiApp> createState() => _MiAppState();
}

class _MiAppState extends State<MiApp> {
  bool _modoOscuro = false;
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _abrirSidebar() => _scaffoldKey.currentState?.openDrawer();

  void _toggleModoOscuro() {
    setState(() => _modoOscuro = !_modoOscuro);
  }

  void _navegar(String ruta) {
    _scaffoldKey.currentState?.closeDrawer();
    final m = {
      'pos': 0,
      'dashboard': 1,
      'configuracion': 2,
      'categorias': 3,
      'metodos_pago': 4,
      'vendedores': 5,
      'clientes': 6,
      'reportes': 7,
      'impresora': 8,
      'backup': 9,
      'caja': 10,
      'perfil': 11,
      'inventario': 12,
      'tienda': 13,
      'proveedores': 14,
      'promociones': 15,
      'compras': 16,
      'roles': 17
    };
    setState(() => _currentIndex = m[ruta] ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SINTHETIX PRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textLight),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background(true),
      ),
      themeMode: _modoOscuro ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background(_modoOscuro),
        drawer: SidebarMenu(
          modoOscuro: _modoOscuro,
          onToggleModoOscuro: _toggleModoOscuro,
          onNavigate: _navegar,
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            EscanerVentas(
              onAbrirSidebar: _abrirSidebar,
              onNavigateToDashboard: () => setState(() => _currentIndex = 1),
              modoOscuro: _modoOscuro,
              onToggleModoOscuro: _toggleModoOscuro,
            ),
            DashboardScreen(
              onAbrirSidebar: _abrirSidebar,
              onNavigateToPOS: () => setState(() => _currentIndex = 0),
              modoOscuro: _modoOscuro,
              onToggleModoOscuro: _toggleModoOscuro,
            ),
            ConfiguracionScreen(
              onAbrirSidebar: _abrirSidebar,
              modoOscuro: _modoOscuro,
            ),
            CategoriasScreen(
              onAbrirSidebar: _abrirSidebar,
              modoOscuro: _modoOscuro,
            ),
            MetodosPagoScreen(
              onAbrirSidebar: _abrirSidebar,
              modoOscuro: _modoOscuro,
            ),
            VendedoresScreen(
              onAbrirSidebar: _abrirSidebar,
              modoOscuro: _modoOscuro,
            ),
            ClientesScreen(
              onAbrirSidebar: _abrirSidebar,
              modoOscuro: _modoOscuro,
            ),
            ReportesScreen(
              onAbrirSidebar: _abrirSidebar,
              modoOscuro: _modoOscuro,
            ),
            ImpresoraScreen(
              onAbrirSidebar: _abrirSidebar,
              modoOscuro: _modoOscuro,
            ),
            BackupScreen(
              onAbrirSidebar: _abrirSidebar,
              modoOscuro: _modoOscuro,
            ),
            CajaScreen(
              onAbrirSidebar: _abrirSidebar,
              modoOscuro: _modoOscuro,
            ),
            PerfilScreen(
              onAbrirSidebar: _abrirSidebar,
              modoOscuro: _modoOscuro,
            ),
            InventarioScreen(
              onAbrirSidebar: _abrirSidebar,
              modoOscuro: _modoOscuro,
            ),
            UniversalFlyCartStore(onAbrirSidebar: _abrirSidebar),
            ProveedoresScreen(
              onAbrirSidebar: _abrirSidebar,
              modoOscuro: _modoOscuro,
            ),
            PromocionesScreen(
              onAbrirSidebar: _abrirSidebar,
              modoOscuro: _modoOscuro,
            ),
            ComprasScreen(
              onAbrirSidebar: _abrirSidebar,
              modoOscuro: _modoOscuro,
            ),
            RolesScreen(
              onAbrirSidebar: _abrirSidebar,
              modoOscuro: _modoOscuro,
            ),
          ],
        ),
        bottomNavigationBar: _currentIndex <= 1
            ? CurvedNavigationBar(
                backgroundColor: Colors.transparent,
                color: _modoOscuro
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE0E0E0),
                buttonBackgroundColor: _modoOscuro
                    ? const Color(0xFF3A3A3A)
                    : const Color(0xFFBDBDBD),
                height: 65,
                animationDuration: const Duration(milliseconds: 300),
                animationCurve: Curves.easeInOut,
                index: _currentIndex,
                items: [
                  CurvedNavigationBarItem(
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size: 26,
                      color: _currentIndex == 0
                          ? (_modoOscuro ? Colors.white : Colors.black)
                          : AppColors.subtext(_modoOscuro),
                    ),
                    label: 'POS',
                    labelStyle: TextStyle(
                      color: _currentIndex == 0
                          ? (_modoOscuro ? Colors.white : Colors.black)
                          : AppColors.subtext(_modoOscuro),
                      fontSize: 10,
                      fontWeight: _currentIndex == 0
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                  CurvedNavigationBarItem(
                    child: Icon(
                      Icons.dashboard_outlined,
                      size: 26,
                      color: _currentIndex == 1
                          ? (_modoOscuro ? Colors.white : Colors.black)
                          : AppColors.subtext(_modoOscuro),
                    ),
                    label: 'Dashboard',
                    labelStyle: TextStyle(
                      color: _currentIndex == 1
                          ? (_modoOscuro ? Colors.white : Colors.black)
                          : AppColors.subtext(_modoOscuro),
                      fontSize: 10,
                      fontWeight: _currentIndex == 1
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              )
            : null,
      ),
    );
  }
}

class SidebarMenu extends StatelessWidget {
  final bool modoOscuro;
  final VoidCallback onToggleModoOscuro;
  final Function(String) onNavigate;
  const SidebarMenu(
      {super.key,
      required this.modoOscuro,
      required this.onToggleModoOscuro,
      required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.drawerBg(modoOscuro),
      width: MediaQuery.of(context).size.width * 0.8,
      child: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.divider(modoOscuro)))),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.store_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SINTHETIX PRO',
                        style: TextStyle(
                            color: AppColors.text(modoOscuro),
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    Text('Sistema POS + Tienda',
                        style: TextStyle(
                            color: AppColors.subtext(modoOscuro),
                            fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                    modoOscuro
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: AppColors.subtext(modoOscuro),
                    size: 22),
                onPressed: onToggleModoOscuro,
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sec('PRINCIPAL', modoOscuro),
                _item(Icons.shopping_cart_outlined, 'Punto de Venta',
                    () => onNavigate('pos'), modoOscuro),
                _item(Icons.dashboard_outlined, 'Dashboard',
                    () => onNavigate('dashboard'), modoOscuro),
                _item(Icons.storefront, 'TIENDA SINTHETIX',
                    () => onNavigate('tienda'), modoOscuro),
                const SizedBox(height: 16),
                _sec('ADMINISTRACION', modoOscuro),
                _item(Icons.store_mall_directory_outlined, 'Mi Negocio',
                    () => onNavigate('configuracion'), modoOscuro),
                _item(Icons.category_outlined, 'Categorias',
                    () => onNavigate('categorias'), modoOscuro),
                _item(Icons.payment_outlined, 'Metodos de Pago',
                    () => onNavigate('metodos_pago'), modoOscuro),
                _item(Icons.people_outline, 'Vendedores',
                    () => onNavigate('vendedores'), modoOscuro),
                _item(Icons.person_outline, 'Clientes',
                    () => onNavigate('clientes'), modoOscuro),
                _item(Icons.inventory_2_outlined, 'Inventario',
                    () => onNavigate('inventario'), modoOscuro),
                _item(Icons.local_shipping_outlined, 'Proveedores',
                    () => onNavigate('proveedores'), modoOscuro),
                _item(Icons.shopping_cart_checkout, 'Compras',
                    () => onNavigate('compras'), modoOscuro),
                _item(Icons.local_offer_outlined, 'Promociones',
                    () => onNavigate('promociones'), modoOscuro),
                _item(Icons.admin_panel_settings, 'Usuarios y Roles',
                    () => onNavigate('roles'), modoOscuro),
                const SizedBox(height: 16),
                _sec('FINANZAS', modoOscuro),
                _item(Icons.point_of_sale, 'Caja', () => onNavigate('caja'),
                    modoOscuro),
                _item(Icons.receipt_long_outlined, 'Reportes',
                    () => onNavigate('reportes'), modoOscuro),
                const SizedBox(height: 16),
                _sec('HERRAMIENTAS', modoOscuro),
                _item(Icons.print_outlined, 'Impresora',
                    () => onNavigate('impresora'), modoOscuro),
                _item(Icons.backup_outlined, 'Respaldo',
                    () => onNavigate('backup'), modoOscuro),
                _item(Icons.person_outline, 'Mi Perfil',
                    () => onNavigate('perfil'), modoOscuro),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('v5.1.0 - SINTHETIX PRO',
                style: TextStyle(
                    color: AppColors.subtext(modoOscuro), fontSize: 11),
                textAlign: TextAlign.center),
          ),
        ]),
      ),
    );
  }

  Widget _sec(String t, bool isDark) => Padding(
        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
        child: Text(t,
            style: TextStyle(
                color: AppColors.subtext(isDark),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2)),
      );

  Widget _item(IconData ic, String t, VoidCallback tap, bool isDark) =>
      Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(ic, color: AppColors.subtext(isDark), size: 22),
          title: Text(t,
              style: TextStyle(color: AppColors.text(isDark), fontSize: 14)),
          onTap: tap,
          dense: true,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}

class EscanerVentas extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final VoidCallback onNavigateToDashboard;
  final bool modoOscuro;
  final VoidCallback onToggleModoOscuro;
  const EscanerVentas(
      {super.key,
      required this.onAbrirSidebar,
      required this.onNavigateToDashboard,
      required this.modoOscuro,
      required this.onToggleModoOscuro});
  @override
  State<EscanerVentas> createState() => _EscanerVentasState();
}

class _EscanerVentasState extends State<EscanerVentas> {
  final cameraController = MobileScannerController(
    formats: [BarcodeFormat.all],
    detectionSpeed: DetectionSpeed.normal,
  );
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _escuchando = false;
  String _textoVoz = '';
  final _buscador = TextEditingController();
  final _db = DatabaseService();
  final _cajaService = CajaService();
  final SoundService _soundService = SoundService();
  List<Map<String, dynamic>> carrito = [];
  List<Map<String, dynamic>> listaProductos = [];
  List<Map<String, dynamic>> busqueda = [];
  bool _camara = false;
  bool _mostrarBusqueda = false;
  bool _mostrarTodos = false;
  bool _cargando = true;
  bool _sonando = false;
  String? _ultimoCodigoEscaneado;
  DateTime? _ultimoEscaneo;

  bool get _isTablet => MediaQuery.of(context).size.width >= 600;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 1024;

  void _vibrar() => HapticFeedback.heavyImpact();

  void _sonidoExito() {
    if (_sonando) return;
    _sonando = true;

    _soundService.playBeep();
    _vibrar();

    Future.delayed(const Duration(milliseconds: 500), () {
      _sonando = false;
    });
  }

  String _precio(double pre) {
    final sim = simbolosMoneda['USD'] ?? '\$';
    return '$sim ${pre.toStringAsFixed(2)}';
  }

  void _mostrarSnackbarProductoAgregado(Map<String, dynamic> prod,
      {double? peso}) {
    if (!mounted) return;

    final mensaje = peso != null
        ? '${prod['nombre']} (${peso.toStringAsFixed(2)}kg) agregado'
        : '${prod['nombre']} agregado';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Producto Agregado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    mensaje,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _agregar(Map<String, dynamic> prod) {
    if (prod['tipo'] == 'kilo') {
      _agregarPorKilo(prod);
      return;
    }
    setState(() {
      final i = carrito
          .indexWhere((x) => x['codigo_barras'] == prod['codigo_barras']);
      if (i >= 0) {
        carrito[i]['cantidad'] += 1;
      } else {
        carrito.add({
          'id': prod['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'codigo_barras': prod['codigo_barras'],
          'nombre': prod['nombre'],
          'precio': (prod['precio'] as num).toDouble(),
          'imagen_url': prod['imagen_url'] ?? '',
          'cantidad': 1,
          'tipo': prod['tipo'] ?? 'unidad',
          'peso': 0.0,
        });
      }
    });

    _sonidoExito();
    _mostrarSnackbarProductoAgregado(prod);
  }

  void _agregarPorKilo(Map<String, dynamic> prod) {
    final pesoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(widget.modoOscuro),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.scale, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prod['nombre'],
                    style: TextStyle(
                      color: AppColors.text(widget.modoOscuro),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Producto por kilo',
                    style: TextStyle(
                      color: AppColors.subtext(widget.modoOscuro),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '\$${(prod['precio'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    ' / kg',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.subtext(widget.modoOscuro),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pesoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: AppColors.text(widget.modoOscuro),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Peso (kg)',
                labelStyle:
                    TextStyle(color: AppColors.subtext(widget.modoOscuro)),
                hintText: 'Ej: 0.5 = medio kilo, 0.25 = 250 gramos',
                hintStyle: TextStyle(
                  color: AppColors.subtext(widget.modoOscuro),
                  fontSize: 11,
                ),
                prefixIcon:
                    Icon(Icons.scale_outlined, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background(widget.modoOscuro),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: AppColors.divider(widget.modoOscuro)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.subtext(widget.modoOscuro)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final peso = double.tryParse(pesoCtrl.text) ?? 0;
              if (peso <= 0) return;

              setState(() {
                carrito.add({
                  'id': prod['id'] ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  'codigo_barras': prod['codigo_barras'],
                  'nombre': prod['nombre'],
                  'precio': (prod['precio'] as num).toDouble() * peso,
                  'imagen_url': prod['imagen_url'] ?? '',
                  'cantidad': 1,
                  'tipo': 'kilo',
                  'peso': peso,
                });
              });

              Navigator.pop(ctx);
              _sonidoExito();
              _mostrarSnackbarProductoAgregado(prod, peso: peso);
            },
            icon: const Icon(Icons.add_shopping_cart,
                color: Colors.white, size: 18),
            label: const Text(
              'Agregar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _verFotoGrande(Map<String, dynamic> prod) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: ImagenProducto(
                imagenUrl: prod['imagen_url']?.toString(),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _iniciarEscucha() async {
    try {
      final disponible = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _escuchando = false);
          }
        },
        onError: (error) {
          setState(() => _escuchando = false);
        },
      );

      if (disponible) {
        setState(() => _escuchando = true);
        _buscador.clear();
        await _speech.listen(
          onResult: (result) {
            setState(() {
              _textoVoz = result.recognizedWords;
              _buscador.text = _textoVoz;
              _buscar(_textoVoz);
            });
          },
          localeId: 'es_ES',
          listenFor: const Duration(seconds: 5),
          pauseFor: const Duration(seconds: 3),
        );
      } else {
        _snack('Reconocimiento de voz no disponible', AppColors.warning);
      }
    } catch (e) {
      _snack('Error al iniciar voz: $e', AppColors.danger);
    }
  }

  Future<void> _detenerEscucha() async {
    await _speech.stop();
    setState(() => _escuchando = false);
  }

  void _buscar(String q) {
    setState(() {
      if (q.isEmpty) {
        busqueda.clear();
        _mostrarBusqueda = false;
        _mostrarTodos = false;
      } else {
        final f = q.toLowerCase();
        busqueda = listaProductos
            .where((prod) =>
                (prod['nombre'] as String).toLowerCase().contains(f) ||
                (prod['codigo_barras'] as String).toLowerCase().contains(f))
            .toList();
        _mostrarBusqueda = busqueda.isNotEmpty;
        _mostrarTodos = false;
      }
    });
  }

  void _verTodos() {
    setState(() {
      _mostrarTodos = true;
      _mostrarBusqueda = false;
      busqueda.clear();
      _buscador.clear();
    });
  }

  void _limpiarBusqueda() {
    setState(() {
      _mostrarBusqueda = false;
      _mostrarTodos = false;
      busqueda.clear();
      _buscador.clear();
    });
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      listaProductos = await _db.getProductos();
    } catch (e) {
      listaProductos = [];
    }
    setState(() => _cargando = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cargar();
  }

  double get total {
    double t = 0;
    for (var i in carrito) {
      t += i['precio'] * i['cantidad'];
    }
    return t;
  }

  void _snack(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, style: const TextStyle(color: Colors.white)),
        backgroundColor: c,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _cobrar() {
    if (carrito.isEmpty) {
      _snack('Carrito vacio', AppColors.warning);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PantallaCobro(
        carrito: carrito,
        total: total,
        formatearPrecio: _precio,
        onVentaCompletada: (m, mt, n, t, c) => _venta(m, mt, n, t, c),
        modoOscuro: widget.modoOscuro,
      ),
    );
  }

  Future<void> _venta(String metodo, String monto, String nombre,
      String telefono, String cedula) async {
    try {
      final fac = DatosPrueba.generarNumeroFactura();
      final venta = {
        'numero_factura': fac,
        'total': total,
        'metodo_pago': metodo,
        'moneda': 'USD',
        'cliente_nombre': nombre.isNotEmpty ? nombre : 'Publico General',
        'cliente_telefono': telefono,
        'cliente_cedula': cedula,
        'estado': 'Pagada',
        'fecha': DateTime.now().toIso8601String(),
      };
      final ventaGuardada = await _db.crearVenta(venta);
      if (ventaGuardada != null) {
        for (var i in carrito) {
          await _db.crearDetalleVenta({
            'venta_id': ventaGuardada['id'],
            'codigo_barras': i['codigo_barras'],
            'nombre': i['nombre'],
            'precio': i['precio'],
            'cantidad': i['cantidad'],
            'subtotal': i['precio'] * i['cantidad'],
          });
        }
        await _cajaService.agregarVentaACaja(total);

        if (nombre.isNotEmpty) {
          try {
            final clientes = await _db.getClientes();
            final clienteExistente = clientes
                .where((c) =>
                    (c['nombre']?.toString().toLowerCase() ?? '') ==
                    nombre.toLowerCase())
                .toList();

            if (clienteExistente.isNotEmpty) {
              final cliente = clienteExistente.first;
              final puntosGanados = total.floor();
              final puntosActuales = (cliente['puntos'] ?? 0) as int;
              final totalCompras = (cliente['total_compras'] ?? 0) as num;

              await _db.actualizarCliente(cliente['id'].toString(), {
                'puntos': puntosActuales + puntosGanados,
                'total_compras': totalCompras.toDouble() + total,
                'fecha_ultima_compra': DateTime.now().toIso8601String(),
              });
            }
          } catch (e) {
            // Silencioso
          }
        }

        setState(() => carrito.clear());
        Navigator.pop(context);
        _snack('Venta exitosa - $fac', AppColors.success);

        _mostrarNotificacionVenta(fac, nombre, telefono, total);
      }
    } catch (e) {
      _snack('Error: $e', AppColors.danger);
    }
  }

  void _mostrarNotificacionVenta(
      String factura, String nombre, String telefono, double totalVenta) {
    final isDark = widget.modoOscuro;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: isTablet ? 420 : double.infinity,
          padding: EdgeInsets.all(isTablet ? 28 : 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F222B) : Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 28 : 22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isTablet ? 72 : 60,
                height: isTablet ? 72 : 60,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: isTablet ? 40 : 32,
                ),
              ),
              SizedBox(height: isTablet ? 20 : 16),
              Text(
                '¡VENTA EXITOSA!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: AppColors.background(isDark),
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                  border: Border.all(
                    color: AppColors.divider(isDark),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildDetalleVenta(
                      icon: Icons.receipt_long_rounded,
                      label: 'Factura',
                      value: factura,
                      isDark: isDark,
                    ),
                    SizedBox(height: 8),
                    _buildDetalleVenta(
                      icon: Icons.person_outline_rounded,
                      label: 'Cliente',
                      value: nombre.isEmpty ? 'Público General' : nombre,
                      isDark: isDark,
                    ),
                    SizedBox(height: 8),
                    Divider(color: AppColors.divider(isDark)),
                    SizedBox(height: 8),
                    _buildDetalleVenta(
                      icon: Icons.payment_rounded,
                      label: 'Total',
                      value: '\$${totalVenta.toStringAsFixed(2)}',
                      isDark: isDark,
                      esTotal: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isTablet ? 24 : 20),
              Row(
                children: [
                  Expanded(
                    child: _buildBotonAccionPremium(
                      icon: Icons.chat_rounded,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: () {
                        Navigator.pop(ctx);
                        _enviarWhatsAppCliente(
                            nombre, telefono, factura, totalVenta);
                      },
                      isTablet: isTablet,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildBotonAccionPremium(
                      icon: Icons.print_rounded,
                      label: 'Imprimir',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(ctx);
                        _snack('Imprimiendo ticket...', AppColors.primary);
                      },
                      isTablet: isTablet,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 12 : 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
                    ),
                    backgroundColor: AppColors.background(isDark),
                  ),
                  child: Text(
                    'CERRAR',
                    style: TextStyle(
                      color: AppColors.subtext(isDark),
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalleVenta({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool esTotal = false,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 16,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.subtext(isDark),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: esTotal ? AppColors.success : AppColors.text(isDark),
                  fontSize: esTotal ? 18 : 14,
                  fontWeight: esTotal ? FontWeight.w800 : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotonAccionPremium({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 14 : 10,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: isTablet ? 18 : 15,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: isTablet ? 13 : 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _enviarWhatsAppCliente(
      String nombre, String telefono, String factura, double totalVenta) {
    if (telefono.isEmpty) {
      _snack('El cliente no tiene número de teléfono', AppColors.warning);
      return;
    }
    String phone = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) {
      phone = '58' + phone.substring(1);
    }
    String message = "🛍️ *SINTHETIX - COMPROBANTE DE VENTA*\n\n";
    message += "📄 Factura: $factura\n";
    message += "👤 Cliente: $nombre\n";
    message += "💰 Total: \$${totalVenta.toStringAsFixed(2)}\n";
    message +=
        "📅 Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}\n\n";
    message += "¡Gracias por su compra! 🎉";

    final whatsappUrl =
        "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
    launchURL(whatsappUrl);
    _snack('Enviando WhatsApp a $telefono...', AppColors.whatsapp);
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    cameraController.dispose();
    _buscador.dispose();
    _speech.stop();
    _soundService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: _buildAppBar(isDark),
      body: SafeArea(
        child: Column(children: [
          _buildSearchBar(isDark),
          if (_mostrarBusqueda || _mostrarTodos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                if (_mostrarBusqueda)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _verTodos,
                      icon: const Icon(Icons.grid_view,
                          color: AppColors.primary, size: 18),
                      label: const Text('VER TODOS',
                          style: TextStyle(
                              color: AppColors.primary, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                if (_mostrarBusqueda) const SizedBox(width: 8),
                if (_mostrarBusqueda || _mostrarTodos)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _limpiarBusqueda,
                      icon: Icon(Icons.close,
                          color: AppColors.danger.withValues(alpha: 0.8),
                          size: 18),
                      label: Text('LIMPIAR',
                          style: TextStyle(
                              color: AppColors.danger.withValues(alpha: 0.8),
                              fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.danger.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
              ]),
            ),
          if (_camara)
            Container(
              height: _isDesktop ? 280 : 220,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: cameraController,
                      onDetect: (capture) {
                        if (_sonando) return;
                        final barcodes = capture.barcodes;
                        if (barcodes.isEmpty) return;

                        final barcode = barcodes.first;
                        final rawValue = barcode.rawValue;

                        if (rawValue == null || rawValue.isEmpty) return;

                        // Evitar lecturas duplicadas del mismo código
                        final ahora = DateTime.now();
                        if (_ultimoCodigoEscaneado == rawValue &&
                            _ultimoEscaneo != null &&
                            ahora.difference(_ultimoEscaneo!) <
                                const Duration(seconds: 2)) {
                          return;
                        }

                        _ultimoCodigoEscaneado = rawValue;
                        _ultimoEscaneo = ahora;

                        _procesarCodigoEscaneado(rawValue);
                      },
                    ),
                    Center(
                      child: Container(
                        width: 180,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _camara = false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Apunte el código de barras',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_cargando)
            Expanded(
                child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))),
          if (!_cargando && listaProductos.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_bag_outlined,
                          size: 50, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text('NO HAY PRODUCTOS',
                        style: TextStyle(
                            color: AppColors.text(isDark),
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Ve al Dashboard para cargar tu primer producto',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.subtext(isDark), fontSize: 14)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: widget.onNavigateToDashboard,
                      icon: const Icon(Icons.dashboard_outlined,
                          color: Colors.white),
                      label: const Text('IR AL DASHBOARD',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!_cargando &&
              listaProductos.isNotEmpty &&
              !_mostrarBusqueda &&
              !_mostrarTodos)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _verTodos,
                  icon: const Icon(Icons.grid_view,
                      color: Colors.white, size: 20),
                  label: const Text('VER PRODUCTOS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          if (!_cargando &&
              (_mostrarTodos || _mostrarBusqueda) &&
              listaProductos.isNotEmpty)
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(_isDesktop ? 24 : 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _isDesktop ? 4 : (_isTablet ? 3 : 2),
                  childAspectRatio:
                      _isDesktop ? 0.75 : (_isTablet ? 0.7 : 0.68),
                  crossAxisSpacing: _isDesktop ? 16 : 12,
                  mainAxisSpacing: _isDesktop ? 16 : 12,
                ),
                itemCount:
                    _mostrarTodos ? listaProductos.length : busqueda.length,
                itemBuilder: (_, i) {
                  final prod = _mostrarTodos ? listaProductos[i] : busqueda[i];
                  return _buildProductCard(prod, isDark);
                },
              ),
            ),
          if (carrito.isNotEmpty) _buildCartPreview(isDark),
        ]),
      ),
    );
  }

  Future<void> _procesarCodigoEscaneado(String codigo) async {
    final prod = await _db.buscarPorCodigo(codigo);
    if (prod != null) {
      _agregar(prod);
      _snack('${prod['nombre']} agregado', AppColors.success);
      setState(() => _camara = false);
    } else {
      _snack('Producto no encontrado: $codigo', AppColors.danger);
    }
  }

  AppBar _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(children: [
        GestureDetector(
          onTap: widget.onAbrirSidebar,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(Icons.menu_rounded,
                color: AppColors.primary, size: 22),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SINTHETIX POS',
              style: TextStyle(
                color: AppColors.text(isDark),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${listaProductos.length} productos disponibles',
                  style: TextStyle(
                    color: AppColors.subtext(isDark),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ]),
      actions: [
        _buildActionButton(
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          onTap: widget.onToggleModoOscuro,
          isDark: isDark,
        ),
        _buildActionButton(
          icon: Icons.dashboard_outlined,
          onTap: widget.onNavigateToDashboard,
          isDark: isDark,
        ),
        _buildActionButton(
          icon: Icons.refresh_rounded,
          onTap: () {
            _cargar();
            _snack('Productos actualizados', AppColors.primary);
          },
          isDark: isDark,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.divider(isDark),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.text(isDark), size: 20),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      margin: EdgeInsets.all(_isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.divider(isDark),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        const SizedBox(width: 16),
        Icon(Icons.search_rounded, color: AppColors.subtext(isDark), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _buscador,
            style: TextStyle(
              color: AppColors.text(isDark),
              fontSize: _isDesktop ? 16 : 15,
              fontWeight: FontWeight.w500,
            ),
            onChanged: _buscar,
            decoration: InputDecoration(
              hintText: 'Buscar producto o escanear...',
              hintStyle: TextStyle(
                  color: AppColors.subtext(isDark),
                  fontSize: _isDesktop ? 15 : 14),
              border: InputBorder.none,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: _escuchando
                ? AppColors.danger
                : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0)),
            shape: BoxShape.circle,
            border: Border.all(
              color: _escuchando ? AppColors.danger : AppColors.divider(isDark),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              _escuchando ? Icons.mic : Icons.mic_none,
              color: _escuchando ? Colors.white : AppColors.primary,
              size: 20,
            ),
            onPressed: _escuchando ? _detenerEscucha : _iniciarEscucha,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: _camara
                ? AppColors.primary
                : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0)),
            shape: BoxShape.circle,
            border: Border.all(
              color: _camara ? AppColors.primary : AppColors.divider(isDark),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              _camara ? Icons.qr_code_scanner : Icons.qr_code_scanner_rounded,
              color: _camara ? Colors.white : AppColors.primary,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _camara = !_camara;
                _vibrar();
              });
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> prod, bool isDark) {
    final stock = prod['stock'] ?? 0;
    final stockMin = prod['stock_minimo'] ?? 5;
    final descuento = prod['descuento'] ?? 0;
    final categoria = prod['categoria'] ?? 'General';
    final destacado = prod['destacado'] == 1;
    final precio = (prod['precio'] as num).toDouble();
    final precioFinal = descuento > 0 ? precio * (1 - descuento / 100) : precio;

    final stockColor = stock == 0
        ? AppColors.danger
        : stock < stockMin
            ? AppColors.warning
            : AppColors.success;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: destacado
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.divider(isDark),
          width: destacado ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _verFotoGrande(prod),
              child: ImagenProducto(
                imagenUrl: prod['imagen_url']?.toString(),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    const Color(0xCC000000),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.2, 0.5, 0.8, 1.0],
                ),
              ),
            ),
          ),
          if (destacado)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('TOP',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: stockColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: stockColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    stock == 0 ? Icons.block : Icons.check_circle,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    stock == 0 ? 'AGOTADO' : '$stock',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (descuento > 0)
            Positioned(
              top: 48,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '-$descuento%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prod['nombre'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        categoria,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (descuento > 0)
                          Text(
                            '\$${precio.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          prod['tipo'] == 'kilo'
                              ? '\$${precioFinal.toStringAsFixed(2)}/kg'
                              : '\$${precioFinal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.logoCyan,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _agregar(prod),
                      child: Container(
                        width: _isDesktop ? 44 : 40,
                        height: _isDesktop ? 44 : 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.add_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCartPreview(bool isDark) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        _isDesktop ? 24 : 16,
        0,
        _isDesktop ? 24 : 16,
        _isDesktop ? 24 : 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F222B) : Colors.white,
        borderRadius: BorderRadius.circular(_isDesktop ? 28 : 22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isDesktop ? 24 : 20,
              vertical: _isDesktop ? 18 : 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_isDesktop ? 28 : 22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    color: Colors.white,
                    size: _isDesktop ? 22 : 18,
                  ),
                ),
                SizedBox(width: _isDesktop ? 14 : 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARRITO DE COMPRAS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _isDesktop ? 16 : 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${carrito.length} producto${carrito.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: _isDesktop ? 13 : 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => carrito.clear());
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isDesktop ? 14 : 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: _isDesktop ? 18 : 15,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Vaciar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _isDesktop ? 13 : 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: _isDesktop ? 24 : 16,
                vertical: _isDesktop ? 16 : 12,
              ),
              itemCount: carrito.length,
              itemBuilder: (_, i) {
                final item = carrito[i];
                return Container(
                  margin: EdgeInsets.only(bottom: _isDesktop ? 12 : 8),
                  padding: EdgeInsets.all(_isDesktop ? 14 : 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF161820)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.divider(isDark).withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: _isDesktop ? 50 : 40,
                        height: _isDesktop ? 50 : 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: ImagenProducto(
                            imagenUrl: item['imagen_url']?.toString(),
                            width: _isDesktop ? 50 : 40,
                            height: _isDesktop ? 50 : 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: _isDesktop ? 14 : 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['tipo'] == 'kilo'
                                  ? '${item['nombre']} (${item['peso']}kg)'
                                  : item['nombre'],
                              style: TextStyle(
                                color: AppColors.text(isDark),
                                fontSize: _isDesktop ? 15 : 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '\$${(item['precio'] * item['cantidad']).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: _isDesktop ? 16 : 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1F222B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildQuantityButton(
                              icon: Icons.remove_rounded,
                              onTap: () {
                                setState(() {
                                  if (item['cantidad'] > 1) {
                                    item['cantidad'] -= 1;
                                  } else {
                                    carrito.removeAt(i);
                                  }
                                });
                              },
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 8),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item['cantidad']}',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: _isDesktop ? 16 : 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            _buildQuantityButton(
                              icon: Icons.add_rounded,
                              onTap: () {
                                setState(() {
                                  item['cantidad'] += 1;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(_isDesktop ? 24 : 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161820) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(_isDesktop ? 28 : 22),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL A PAGAR',
                      style: TextStyle(
                        color: AppColors.subtext(isDark),
                        fontSize: _isDesktop ? 13 : 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.text(isDark),
                        fontSize: _isDesktop ? 32 : 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _cobrar,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isDesktop ? 36 : 28,
                      vertical: _isDesktop ? 18 : 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(_isDesktop ? 18 : 14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payment_rounded,
                          color: Colors.white,
                          size: _isDesktop ? 22 : 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'COBRAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _isDesktop ? 16 : 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _isDesktop ? 32 : 28,
        height: _isDesktop ? 32 : 28,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: _isDesktop ? 18 : 16,
        ),
      ),
    );
  }
}

class PantallaCobro extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final double total;
  final String Function(double) formatearPrecio;
  final Function(String, String, String, String, String) onVentaCompletada;
  final bool modoOscuro;
  const PantallaCobro(
      {super.key,
      required this.carrito,
      required this.total,
      required this.formatearPrecio,
      required this.onVentaCompletada,
      required this.modoOscuro});
  @override
  State<PantallaCobro> createState() => _PantallaCobroState();
}

class _PantallaCobroState extends State<PantallaCobro> {
  final _db = DatabaseService();
  String _metodo = 'Efectivo';
  String _moneda = 'USD';
  final _montoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  String _clienteSel = '';
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _metodosPago = [];
  bool _cargandoMetodos = true;
  bool _buscandoCliente = false;

  bool get _isTablet => MediaQuery.of(context).size.width >= 600;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 1024;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final clientes = await _db.getClientes();
      final metodos = await _db.getMetodosPago();
      if (metodos.isEmpty) {
        _metodosPago = [
          {'id': '1', 'nombre': 'Efectivo', 'icono': Icons.payments_outlined},
          {'id': '2', 'nombre': 'Tarjeta', 'icono': Icons.credit_card_outlined},
          {
            'id': '3',
            'nombre': 'Transferencia',
            'icono': Icons.swap_horiz_rounded
          },
          {
            'id': '4',
            'nombre': 'Pago Movil',
            'icono': Icons.phone_android_rounded
          },
        ];
      } else {
        _metodosPago = metodos;
      }
      setState(() {
        _clientes = clientes;
        _cargandoMetodos = false;
      });
    } catch (e) {
      setState(() {
        _cargandoMetodos = false;
      });
    }
  }

  Future<void> _buscarClientePorCedula() async {
    final cedula = _cedulaCtrl.text.trim();
    if (cedula.isEmpty) return;
    setState(() => _buscandoCliente = true);
    final cliente = await _db.buscarClientePorCedula(cedula);
    if (cliente != null) {
      setState(() {
        _clienteSel = cliente['id'].toString();
        _nombreCtrl.text = cliente['nombre'] ?? '';
        _telefonoCtrl.text = cliente['telefono'] ?? '';
        _direccionCtrl.text = cliente['direccion'] ?? '';
      });
      _mostrarSnackbar('Cliente encontrado', AppColors.success);
    } else {
      setState(() {
        _clienteSel = '';
      });
      _mostrarSnackbar(
          'Cliente nuevo - se registrará automáticamente', AppColors.primary);
    }
    setState(() => _buscandoCliente = false);
  }

  double _totalEnMoneda() {
    final tasa = tasasCambio[_moneda] ?? 1.0;
    return widget.total * tasa;
  }

  double _vuelto() {
    if (_montoCtrl.text.isEmpty) return 0;
    final m = double.tryParse(_montoCtrl.text) ?? 0;
    return m - _totalEnMoneda();
  }

  Future<void> _confirmarVenta() async {
    if (_cedulaCtrl.text.trim().isEmpty ||
        _nombreCtrl.text.trim().isEmpty ||
        _telefonoCtrl.text.trim().isEmpty) {
      _mostrarSnackbar(
          'Debe ingresar Cédula, Nombre y Teléfono', AppColors.danger);
      return;
    }

    if (_metodo == 'Efectivo' && _vuelto() < 0) {
      _mostrarSnackbar('Monto insuficiente', AppColors.danger);
      return;
    }

    final clienteExistente =
        await _db.buscarClientePorCedula(_cedulaCtrl.text.trim());
    if (clienteExistente == null) {
      await _db.crearCliente({
        'nombre': _nombreCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'identificacion': _cedulaCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
        'tipo': 'Regular',
      });
    }

    widget.onVentaCompletada(
      _metodo,
      _montoCtrl.text,
      _nombreCtrl.text.trim(),
      _telefonoCtrl.text.trim(),
      _cedulaCtrl.text.trim(),
    );
  }

  void _mostrarSnackbar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * (_isDesktop ? 0.85 : 0.92),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_isDesktop ? 32 : 24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: _isDesktop ? 60 : 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.subtext(isDark).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _isDesktop ? 32 : 20,
              vertical: _isDesktop ? 16 : 12,
            ),
            child: Row(
              children: [
                Container(
                  width: _isDesktop ? 48 : 40,
                  height: _isDesktop ? 48 : 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.point_of_sale_rounded,
                    color: Colors.white,
                    size: _isDesktop ? 24 : 20,
                  ),
                ),
                SizedBox(width: _isDesktop ? 16 : 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FINALIZAR VENTA',
                      style: TextStyle(
                        color: AppColors.text(isDark),
                        fontSize: _isDesktop ? 20 : 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${widget.carrito.length} producto${widget.carrito.length != 1 ? 's' : ''} en el carrito',
                      style: TextStyle(
                        color: AppColors.subtext(isDark),
                        fontSize: _isDesktop ? 13 : 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: _isDesktop ? 40 : 36,
                    height: _isDesktop ? 40 : 36,
                    decoration: BoxDecoration(
                      color: AppColors.background(isDark),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.divider(isDark),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.text(isDark),
                      size: _isDesktop ? 22 : 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.divider(isDark), height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: _isDesktop ? 32 : 20,
                vertical: _isDesktop ? 20 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelectorMoneda(isDark),
                  SizedBox(height: _isDesktop ? 20 : 16),
                  _buildTotalPagar(isDark),
                  SizedBox(height: _isDesktop ? 24 : 20),
                  _buildTituloSeccion('INFORMACIÓN DEL CLIENTE', isDark),
                  SizedBox(height: _isDesktop ? 14 : 10),
                  _buildFormularioCliente(isDark),
                  SizedBox(height: _isDesktop ? 24 : 20),
                  _buildTituloSeccion('MÉTODO DE PAGO', isDark),
                  SizedBox(height: _isDesktop ? 14 : 10),
                  _buildMetodosPago(isDark),
                  if (_metodo == 'Efectivo') ...[
                    SizedBox(height: _isDesktop ? 24 : 20),
                    _buildTituloSeccion('MONTO RECIBIDO', isDark),
                    SizedBox(height: _isDesktop ? 14 : 10),
                    _buildMontoRecibido(isDark),
                  ],
                  SizedBox(height: _isDesktop ? 24 : 20),
                  _buildTituloSeccion('RESUMEN DE COMPRA', isDark),
                  SizedBox(height: _isDesktop ? 14 : 10),
                  _buildResumenCompra(isDark),
                  SizedBox(height: _isDesktop ? 24 : 20),
                  _buildBotonConfirmar(isDark),
                  SizedBox(height: _isDesktop ? 24 : 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorMoneda(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.divider(isDark),
          width: 1,
        ),
      ),
      child: Row(
        children: ['USD', 'COP', 'VES'].map((moneda) {
          final sel = _moneda == moneda;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _moneda = moneda),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: _isDesktop ? 14 : 10,
                ),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    moneda,
                    style: TextStyle(
                      color: sel ? Colors.white : AppColors.subtext(isDark),
                      fontSize: _isDesktop ? 15 : 13,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalPagar(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_isDesktop ? 24 : 18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(_isDesktop ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL A PAGAR',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: _isDesktop ? 14 : 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${simbolosMoneda[_moneda] ?? '\$'} ${_totalEnMoneda().toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _isDesktop ? 36 : 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(_isDesktop ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.payments_rounded,
              color: Colors.white,
              size: _isDesktop ? 32 : 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTituloSeccion(String titulo, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: _isDesktop ? 20 : 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Text(
          titulo,
          style: TextStyle(
            color: AppColors.subtext(isDark),
            fontSize: _isDesktop ? 13 : 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormularioCliente(bool isDark) {
    return Container(
      padding: EdgeInsets.all(_isDesktop ? 20 : 14),
      decoration: BoxDecoration(
        color: AppColors.background(isDark),
        borderRadius: BorderRadius.circular(_isDesktop ? 18 : 14),
        border: Border.all(
          color: AppColors.divider(isDark),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCampoTexto(
                  controller: _cedulaCtrl,
                  label: 'Cédula *',
                  icon: Icons.badge_outlined,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _buscarClientePorCedula(),
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: _buscandoCliente ? null : _buscarClientePorCedula,
                child: Container(
                  width: _isDesktop ? 52 : 46,
                  height: _isDesktop ? 52 : 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _buscandoCliente
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: _isDesktop ? 24 : 20,
                          ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _isDesktop ? 14 : 10),
          _buildCampoTexto(
            controller: _nombreCtrl,
            label: 'Nombre completo *',
            icon: Icons.person_outline_rounded,
            isDark: isDark,
          ),
          SizedBox(height: _isDesktop ? 14 : 10),
          _buildCampoTexto(
            controller: _telefonoCtrl,
            label: 'Teléfono *',
            icon: Icons.phone_outlined,
            isDark: isDark,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: _isDesktop ? 14 : 10),
          _buildCampoTexto(
            controller: _direccionCtrl,
            label: 'Dirección',
            icon: Icons.location_on_outlined,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: AppColors.text(isDark),
        fontSize: _isDesktop ? 15 : 13,
        fontWeight: FontWeight.w500,
      ),
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.subtext(isDark),
          fontSize: _isDesktop ? 13 : 12,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
          size: _isDesktop ? 22 : 18,
        ),
        filled: true,
        fillColor: AppColors.card(isDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.divider(isDark),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildMetodosPago(bool isDark) {
    if (_cargandoMetodos) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _isDesktop ? 4 : 2,
        childAspectRatio: _isDesktop ? 1.5 : 1.3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _metodosPago.length,
      itemBuilder: (_, i) {
        final mp = _metodosPago[i];
        final nombre = mp['nombre'] ?? '';
        final sel = _metodo == nombre;
        final icono = mp['icono'] ?? Icons.payment_rounded;

        return GestureDetector(
          onTap: () => setState(() => _metodo = nombre),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isDesktop ? 14 : 10,
              vertical: _isDesktop ? 14 : 10,
            ),
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : AppColors.background(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? AppColors.primary : AppColors.divider(isDark),
                width: sel ? 2 : 1,
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icono,
                  color: sel ? Colors.white : AppColors.primary,
                  size: _isDesktop ? 24 : 20,
                ),
                SizedBox(height: 6),
                Text(
                  nombre,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: sel ? Colors.white : AppColors.text(isDark),
                    fontSize: _isDesktop ? 12 : 10,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMontoRecibido(bool isDark) {
    return Column(
      children: [
        TextField(
          controller: _montoCtrl,
          style: TextStyle(
            color: AppColors.text(isDark),
            fontSize: _isDesktop ? 28 : 24,
            fontWeight: FontWeight.w600,
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(
              color: AppColors.subtext(isDark),
              fontSize: _isDesktop ? 28 : 24,
            ),
            prefixText: '${simbolosMoneda[_moneda] ?? '\$'} ',
            prefixStyle: TextStyle(
              color: AppColors.primary,
              fontSize: _isDesktop ? 28 : 24,
              fontWeight: FontWeight.w700,
            ),
            prefixIcon: Icon(
              Icons.payments_outlined,
              color: AppColors.primary,
              size: _isDesktop ? 28 : 24,
            ),
            filled: true,
            fillColor: AppColors.background(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.divider(isDark),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
        if (_montoCtrl.text.isNotEmpty) ...[
          SizedBox(height: _isDesktop ? 14 : 10),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(_isDesktop ? 18 : 14),
            decoration: BoxDecoration(
              color: _vuelto() >= 0
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _vuelto() >= 0
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.danger.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _vuelto() >= 0
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color:
                          _vuelto() >= 0 ? AppColors.success : AppColors.danger,
                      size: _isDesktop ? 22 : 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Vuelto',
                      style: TextStyle(
                        color: AppColors.subtext(isDark),
                        fontSize: _isDesktop ? 15 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${simbolosMoneda[_moneda] ?? '\$'} ${_vuelto().toStringAsFixed(2)}',
                  style: TextStyle(
                    color:
                        _vuelto() >= 0 ? AppColors.success : AppColors.danger,
                    fontSize: _isDesktop ? 22 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResumenCompra(bool isDark) {
    return Container(
      padding: EdgeInsets.all(_isDesktop ? 18 : 14),
      decoration: BoxDecoration(
        color: AppColors.background(isDark),
        borderRadius: BorderRadius.circular(_isDesktop ? 18 : 14),
        border: Border.all(
          color: AppColors.divider(isDark),
          width: 1,
        ),
      ),
      child: Column(
        children: widget.carrito.map((item) {
          return Container(
            padding: EdgeInsets.symmetric(
              vertical: _isDesktop ? 10 : 8,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.divider(isDark),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['tipo'] == 'kilo'
                            ? '${item['cantidad']}x ${item['nombre']} (${item['peso']}kg)'
                            : '${item['cantidad']}x ${item['nombre']}',
                        style: TextStyle(
                          color: AppColors.text(isDark),
                          fontSize: _isDesktop ? 14 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Precio unitario: \$${(item['precio'] / item['cantidad']).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppColors.subtext(isDark),
                          fontSize: _isDesktop ? 11 : 10,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '\$${(item['precio'] * item['cantidad']).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: _isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBotonConfirmar(bool isDark) {
    return Container(
      width: double.infinity,
      height: _isDesktop ? 60 : 52,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(_isDesktop ? 18 : 14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _confirmarVenta,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_isDesktop ? 18 : 14),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: _isDesktop ? 32 : 24,
            vertical: _isDesktop ? 16 : 12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: _isDesktop ? 26 : 22,
            ),
            SizedBox(width: _isDesktop ? 12 : 8),
            Text(
              'CONFIRMAR PAGO',
              style: TextStyle(
                color: Colors.white,
                fontSize: _isDesktop ? 17 : 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final VoidCallback onNavigateToPOS;
  final bool modoOscuro;
  final VoidCallback onToggleModoOscuro;
  const DashboardScreen(
      {super.key,
      required this.onAbrirSidebar,
      required this.onNavigateToPOS,
      this.modoOscuro = false,
      required this.onToggleModoOscuro});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> ventasHoy = [];
  List<Map<String, dynamic>> ventasFiltradas = [];
  double totalVentasHoy = 0;
  int cantidadVentasHoy = 0;
  bool cargando = true;
  String searchQuery = '';
  int seccionActual = 0;
  final _db = DatabaseService();
  final _cajaService = CajaService();
  Map<String, dynamic>? _cajaActual;

  String _filtroCategoria = 'Todas';
  String _filtroStock = 'Todos';
  String _filtroFechaVentas = 'Hoy';
  List<Map<String, dynamic>> _categorias = [];
  Map<String, dynamic> _productoStockBajo = {};
  double _promedioVenta = 0;
  int _totalStock = 0;
  int _productosAgotados = 0;
  int _productosStockBajo = 0;
  double _totalInventarioValor = 0;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);
    try {
      productos = await _db.getProductos();
      ventasHoy = await _db.getVentasHoy();
      totalVentasHoy = await _db.getTotalVentasHoy();
      cantidadVentasHoy = await _db.getCantidadVentasHoy();
      _cajaActual = await _cajaService.getCajaAbierta();
      _categorias = await _db.getCategorias();
      _calcularMetricas();
      _aplicarFiltroVentas();
    } catch (e) {
      debugPrint('Error cargando dashboard: $e');
      productos = [];
      ventasHoy = [];
      totalVentasHoy = 0;
      cantidadVentasHoy = 0;
    }
    setState(() => cargando = false);
  }

  void _calcularMetricas() {
    _totalStock =
        productos.fold(0, (sum, p) => sum + ((p['stock'] ?? 0) as int));
    _productosAgotados = productos.where((p) => (p['stock'] ?? 0) == 0).length;
    _productosStockBajo = productos
        .where((p) =>
            (p['stock'] ?? 0) > 0 &&
            (p['stock'] ?? 0) < (p['stock_minimo'] ?? 5))
        .length;

    List<Map<String, dynamic>> conStock =
        productos.where((p) => (p['stock'] ?? 0) > 0).toList();
    if (conStock.isNotEmpty) {
      conStock.sort((a, b) =>
          ((a['stock'] ?? 0) as int).compareTo((b['stock'] ?? 0) as int));
      _productoStockBajo = conStock.first;
    }

    _totalInventarioValor = productos.fold(
        0.0, (sum, p) => sum + ((p['precio'] ?? 0) * (p['stock'] ?? 0)));

    if (cantidadVentasHoy > 0) {
      _promedioVenta = totalVentasHoy / cantidadVentasHoy;
    }
  }

  void _aplicarFiltroVentas() {
    final ahora = DateTime.now();
    setState(() {
      ventasFiltradas = ventasHoy.where((v) {
        final fechaVenta =
            v['fecha'] != null ? DateTime.parse(v['fecha'].toString()) : ahora;
        switch (_filtroFechaVentas) {
          case 'Hoy':
            return fechaVenta.day == ahora.day &&
                fechaVenta.month == ahora.month &&
                fechaVenta.year == ahora.year;
          case 'Ayer':
            final ayer = ahora.subtract(const Duration(days: 1));
            return fechaVenta.day == ayer.day &&
                fechaVenta.month == ayer.month &&
                fechaVenta.year == ayer.year;
          case 'Esta Semana':
            final inicioSemana =
                ahora.subtract(Duration(days: ahora.weekday - 1));
            return fechaVenta
                .isAfter(inicioSemana.subtract(const Duration(days: 1)));
          case 'Este Mes':
            return fechaVenta.month == ahora.month &&
                fechaVenta.year == ahora.year;
          case 'Todo':
            return true;
          default:
            return true;
        }
      }).toList();

      totalVentasHoy = ventasFiltradas.fold(
          0.0, (sum, v) => sum + ((v['total'] ?? 0) as num).toDouble());
      cantidadVentasHoy = ventasFiltradas.length;
    });
  }

  List<Map<String, dynamic>> get productosFiltrados {
    var lista = List<Map<String, dynamic>>.from(productos);

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      lista = lista
          .where((prod) =>
              (prod['nombre'] as String).toLowerCase().contains(q) ||
              (prod['codigo_barras'] as String).toLowerCase().contains(q))
          .toList();
    }

    if (_filtroCategoria != 'Todas') {
      lista =
          lista.where((prod) => prod['categoria'] == _filtroCategoria).toList();
    }

    if (_filtroStock == 'Con Stock') {
      lista = lista.where((prod) => (prod['stock'] ?? 0) > 0).toList();
    } else if (_filtroStock == 'Stock Bajo') {
      lista = lista
          .where((prod) =>
              (prod['stock'] ?? 0) > 0 &&
              (prod['stock'] ?? 0) < (prod['stock_minimo'] ?? 5))
          .toList();
    } else if (_filtroStock == 'Agotados') {
      lista = lista.where((prod) => (prod['stock'] ?? 0) == 0).toList();
    }

    return lista;
  }

  void mostrarSnackBar(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, style: const TextStyle(color: Colors.white)),
        backgroundColor: c,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void eliminarProducto(String id) {
    final isDark = widget.modoOscuro;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar producto',
            style: TextStyle(
                color: AppColors.text(isDark), fontWeight: FontWeight.w700)),
        content: Text('¿Estás seguro de eliminar este producto?',
            style: TextStyle(color: AppColors.subtext(isDark))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          TextButton(
            onPressed: () async {
              await _db.eliminarProducto(id);
              await cargarDatos();
              Navigator.pop(ctx);
              mostrarSnackBar('Producto eliminado', AppColors.primary);
            },
            child: const Text('Eliminar',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void abrirCaja() {
    final isDark = widget.modoOscuro;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Abrir Caja',
            style: TextStyle(
                color: AppColors.text(isDark), fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: AppColors.text(isDark)),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Monto Inicial',
            labelStyle: TextStyle(color: AppColors.subtext(isDark)),
            prefixText: '\$ ',
            prefixStyle: TextStyle(color: AppColors.text(isDark)),
            filled: true,
            fillColor: AppColors.background(isDark),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          TextButton(
            onPressed: () async {
              final m = double.tryParse(ctrl.text) ?? 0;
              if (m <= 0) return;
              await _cajaService.abrirCaja(m);
              Navigator.pop(ctx);
              cargarDatos();
              mostrarSnackBar(
                  'Caja abierta: \$${m.toStringAsFixed(2)}', AppColors.success);
            },
            child: const Text('Abrir',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void cerrarCaja() {
    if (_cajaActual == null) return;
    final isDark = widget.modoOscuro;
    final montoFinalCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cerrar Caja',
            style: TextStyle(
                color: AppColors.text(isDark), fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen:',
                style: TextStyle(color: AppColors.subtext(isDark))),
            const SizedBox(height: 12),
            _row(
                'Monto Inicial:',
                '\$${(_cajaActual!['monto_inicial'] as double).toStringAsFixed(2)}',
                isDark),
            const SizedBox(height: 8),
            _row(
                'Total Ventas:',
                '\$${(_cajaActual!['total_ventas'] as double).toStringAsFixed(2)}',
                isDark),
            const SizedBox(height: 16),
            TextField(
              controller: montoFinalCtrl,
              style: TextStyle(color: AppColors.text(isDark)),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monto Final Contado',
                labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: AppColors.text(isDark)),
                filled: true,
                fillColor: AppColors.background(isDark),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          TextButton(
            onPressed: () async {
              final m = double.tryParse(montoFinalCtrl.text) ?? 0;
              await _cajaService.cerrarCaja(m);
              Navigator.pop(ctx);
              cargarDatos();
              mostrarSnackBar('Caja cerrada', AppColors.primary);
            },
            child: const Text('Cerrar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v, bool isDark) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l,
              style: TextStyle(color: AppColors.subtext(isDark), fontSize: 13)),
          Text(v,
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      );

  Future<String?> _escanearCodigoBarras(BuildContext dialogContext) async {
    final result = await showDialog<String>(
      context: dialogContext,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: SizedBox(
          width: double.infinity,
          height: 400,
          child: Stack(
            children: [
              MobileScanner(
                onDetect: (capture) async {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                    Navigator.pop(ctx, barcodes.first.rawValue);
                  }
                },
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, null),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 220,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Apunte el código de barras',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return result;
  }

  void mostrarDialogoProducto({Map<String, dynamic>? productoEditar}) {
    final isDark = widget.modoOscuro;
    final esEdicion = productoEditar != null;

    final nombreCtrl =
        TextEditingController(text: productoEditar?['nombre'] ?? '');
    final codigoCtrl =
        TextEditingController(text: productoEditar?['codigo_barras'] ?? '');
    final precioCtrl = TextEditingController(
        text: productoEditar?['precio']?.toString() ?? '');
    final costoCtrl =
        TextEditingController(text: productoEditar?['costo']?.toString() ?? '');
    final stockCtrl =
        TextEditingController(text: productoEditar?['stock']?.toString() ?? '');
    final stockMinCtrl = TextEditingController(
        text: productoEditar?['stock_minimo']?.toString() ?? '5');
    final descCtrl =
        TextEditingController(text: productoEditar?['descripcion'] ?? '');
    final proveedorCtrl =
        TextEditingController(text: productoEditar?['proveedor'] ?? '');
    final ubicacionCtrl =
        TextEditingController(text: productoEditar?['ubicacion'] ?? '');

    String tipoProducto = productoEditar?['tipo'] ?? 'unidad';
    String categoriaSeleccionada = productoEditar?['categoria'] ?? 'General';
    bool activo = productoEditar?['activo'] == 1;
    bool destacado = productoEditar?['destacado'] == 1;
    bool tieneDescuento = (productoEditar?['descuento'] ?? 0) > 0;
    double descuento = (productoEditar?['descuento'] ?? 0).toDouble();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final ValueNotifier<String> imagenUrlNotifier =
            ValueNotifier(productoEditar?['imagen_url'] ?? '');
        Uint8List? imagenBytes;
        bool subiendo = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> subirImagen(XFile imagen) async {
              setDialogState(() => subiendo = true);
              try {
                final bytes = await imagen.readAsBytes();
                final base64String = base64Encode(bytes);
                setDialogState(() {
                  imagenBytes = bytes;
                  imagenUrlNotifier.value =
                      'data:image/jpeg;base64,$base64String';
                  subiendo = false;
                });
              } catch (e) {
                setDialogState(() => subiendo = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error al subir imagen: $e",
                        style: const TextStyle(color: Colors.white)),
                    backgroundColor: AppColors.danger,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.card(isDark),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                Icon(esEdicion ? Icons.edit : Icons.add_circle_outline,
                    color: AppColors.primary),
                const SizedBox(width: 10),
                Text(esEdicion ? 'Editar Producto' : 'Nuevo Producto',
                    style: TextStyle(
                        color: AppColors.text(isDark),
                        fontWeight: FontWeight.w700,
                        fontSize: 18)),
              ]),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable: imagenUrlNotifier,
                      builder: (context, url, child) {
                        if (imagenBytes != null || url.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppColors.divider(isDark)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: imagenBytes != null
                                  ? Image.memory(imagenBytes!,
                                      fit: BoxFit.contain)
                                  : ImagenProducto(
                                      imagenUrl: url,
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.contain,
                                      icono: Icons.image_not_supported_outlined,
                                    ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    if (subiendo)
                      Column(children: [
                        const CircularProgressIndicator(
                            color: AppColors.primary),
                        const SizedBox(height: 8),
                        Text('Procesando imagen...',
                            style: TextStyle(
                                color: AppColors.subtext(isDark),
                                fontSize: 12)),
                      ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: subiendo
                              ? null
                              : () async {
                                  final f = await ImagePicker().pickImage(
                                      source: ImageSource.camera,
                                      imageQuality: 80);
                                  if (f != null) await subirImagen(f);
                                },
                          icon: const Icon(Icons.photo_camera,
                              color: AppColors.primary, size: 20),
                          label: const Text('Foto',
                              style: TextStyle(
                                  color: AppColors.primary, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.background(isDark),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: subiendo
                              ? null
                              : () async {
                                  final f = await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 80);
                                  if (f != null) await subirImagen(f);
                                },
                          icon: const Icon(Icons.photo_library,
                              color: AppColors.primary, size: 20),
                          label: const Text('Galería',
                              style: TextStyle(
                                  color: AppColors.primary, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.background(isDark),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.divider(isDark)),
                    const SizedBox(height: 8),
                    _buildSectionTitle('Información Básica'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nombreCtrl,
                      style: TextStyle(color: AppColors.text(isDark)),
                      decoration: _inputDecoration('Nombre del Producto *',
                          Icons.inventory_2_outlined, isDark),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: codigoCtrl,
                          style: TextStyle(color: AppColors.text(isDark)),
                          decoration: _inputDecoration(
                              'Código de Barras *', Icons.qr_code, isDark),
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final scannedCode =
                              await _escanearCodigoBarras(dialogContext);
                          if (scannedCode != null && scannedCode.isNotEmpty) {
                            setDialogState(() {
                              codigoCtrl.text = scannedCode;
                            });
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background(isDark),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        Icon(Icons.category_outlined,
                            color: AppColors.subtext(isDark), size: 20),
                        const SizedBox(width: 10),
                        Text('Tipo de producto: ',
                            style: TextStyle(color: AppColors.text(isDark))),
                        const Spacer(),
                        DropdownButton<String>(
                          value: tipoProducto,
                          dropdownColor: AppColors.card(isDark),
                          style: TextStyle(color: AppColors.text(isDark)),
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                                value: 'unidad', child: Text('Por Unidad')),
                            DropdownMenuItem(
                                value: 'kilo', child: Text('Por Kilo')),
                          ],
                          onChanged: (v) => setDialogState(
                              () => tipoProducto = v ?? 'unidad'),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background(isDark),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        Icon(Icons.folder_outlined,
                            color: AppColors.subtext(isDark), size: 20),
                        const SizedBox(width: 10),
                        Text('Categoría: ',
                            style: TextStyle(color: AppColors.text(isDark))),
                        const Spacer(),
                        DropdownButton<String>(
                          value: categoriaSeleccionada,
                          dropdownColor: AppColors.card(isDark),
                          style: TextStyle(
                              color: AppColors.text(isDark), fontSize: 13),
                          underline: const SizedBox(),
                          items: _categorias
                              .map((cat) => DropdownMenuItem(
                                    value:
                                        cat['nombre']?.toString() ?? 'General',
                                    child: Text(
                                        cat['nombre']?.toString() ?? 'General',
                                        style: const TextStyle(fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (v) => setDialogState(
                              () => categoriaSeleccionada = v ?? 'General'),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.divider(isDark)),
                    const SizedBox(height: 8),
                    _buildSectionTitle('Precios y Stock'),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: precioCtrl,
                          style: TextStyle(
                              color: AppColors.text(isDark),
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _inputDecoration(
                              tipoProducto == 'kilo'
                                  ? 'Precio por Kilo *'
                                  : 'Precio de Venta *',
                              Icons.attach_money,
                              isDark),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: costoCtrl,
                          style: TextStyle(color: AppColors.text(isDark)),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _inputDecoration(
                              'Costo', Icons.money_off, isDark),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: stockCtrl,
                          style: TextStyle(color: AppColors.text(isDark)),
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                              'Stock Actual', Icons.inventory, isDark),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: stockMinCtrl,
                          style: TextStyle(color: AppColors.text(isDark)),
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                              'Stock Mínimo', Icons.warning_amber, isDark),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.divider(isDark)),
                    const SizedBox(height: 8),
                    _buildSectionTitle('Información Adicional'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: proveedorCtrl,
                      style: TextStyle(color: AppColors.text(isDark)),
                      decoration: _inputDecoration(
                          'Proveedor', Icons.local_shipping_outlined, isDark),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ubicacionCtrl,
                      style: TextStyle(color: AppColors.text(isDark)),
                      decoration: _inputDecoration(
                          'Ubicación en almacén', Icons.place_outlined, isDark),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      style: TextStyle(color: AppColors.text(isDark)),
                      decoration: _inputDecoration(
                          'Descripción', Icons.description_outlined, isDark),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.divider(isDark)),
                    const SizedBox(height: 8),
                    _buildSectionTitle('Opciones'),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: Text('Producto Activo',
                          style: TextStyle(
                              color: AppColors.text(isDark), fontSize: 14)),
                      value: activo,
                      onChanged: (v) => setDialogState(() => activo = v),
                      activeThumbColor: AppColors.primary,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: Text('Producto Destacado',
                          style: TextStyle(
                              color: AppColors.text(isDark), fontSize: 14)),
                      value: destacado,
                      onChanged: (v) => setDialogState(() => destacado = v),
                      activeThumbColor: AppColors.primary,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: Text('Aplicar Descuento',
                          style: TextStyle(
                              color: AppColors.text(isDark), fontSize: 14)),
                      value: tieneDescuento,
                      onChanged: (v) =>
                          setDialogState(() => tieneDescuento = v),
                      activeThumbColor: AppColors.primary,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (tieneDescuento) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller:
                            TextEditingController(text: descuento.toString()),
                        style: TextStyle(color: AppColors.text(isDark)),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: _inputDecoration(
                            'Porcentaje de descuento (%)',
                            Icons.percent,
                            isDark),
                        onChanged: (v) => descuento = double.tryParse(v) ?? 0,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancelar',
                      style: TextStyle(color: AppColors.subtext(isDark))),
                ),
                TextButton(
                  onPressed: () async {
                    if (nombreCtrl.text.isEmpty ||
                        codigoCtrl.text.isEmpty ||
                        precioCtrl.text.isEmpty) {
                      mostrarSnackBar(
                          'Campos requeridos incompletos', AppColors.warning);
                      return;
                    }
                    if (subiendo) {
                      mostrarSnackBar(
                          'Espera a que la imagen termine', AppColors.warning);
                      return;
                    }

                    final codigoExistente = productos.any((p) =>
                        p['codigo_barras'] == codigoCtrl.text &&
                        (productoEditar == null ||
                            p['id'] != productoEditar['id']));
                    if (codigoExistente) {
                      mostrarSnackBar(
                          'El código de barras ya existe', AppColors.danger);
                      return;
                    }

                    final urlFinal = imagenUrlNotifier.value;
                    final precio = double.parse(precioCtrl.text);
                    final costo = double.tryParse(costoCtrl.text) ?? 0;

                    final prod = {
                      'codigo_barras': codigoCtrl.text,
                      'nombre': nombreCtrl.text,
                      'precio': precio,
                      'costo': costo,
                      'stock': int.tryParse(stockCtrl.text) ?? 0,
                      'stock_minimo': int.tryParse(stockMinCtrl.text) ?? 5,
                      'categoria': categoriaSeleccionada,
                      'descripcion': descCtrl.text,
                      'proveedor': proveedorCtrl.text,
                      'ubicacion': ubicacionCtrl.text,
                      'imagen_url': urlFinal.isEmpty ? null : urlFinal,
                      'activo': activo ? 1 : 0,
                      'destacado': destacado ? 1 : 0,
                      'tipo': tipoProducto,
                      'descuento': tieneDescuento ? descuento : 0,
                      'margen':
                          costo > 0 ? ((precio - costo) / costo * 100) : 0,
                    };

                    dynamic r;
                    if (esEdicion) {
                      r = await _db.actualizarProducto(
                          productoEditar['id'].toString(), prod);
                    } else {
                      r = await _db.crearProducto(prod);
                    }

                    if (r != null) {
                      Navigator.pop(dialogContext);
                      await cargarDatos();
                      mostrarSnackBar(
                          esEdicion
                              ? 'Producto actualizado'
                              : 'Producto creado',
                          AppColors.success);
                    } else {
                      mostrarSnackBar('Error al guardar', AppColors.danger);
                    }
                  },
                  child: Text(esEdicion ? 'Actualizar' : 'Crear',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.subtext(isDark)),
      prefixIcon: Icon(icon, color: AppColors.subtext(isDark), size: 20),
      filled: true,
      fillColor: AppColors.background(isDark),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider(isDark))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(children: [
      Container(
        width: 4,
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    ]);
  }

  Widget _buildGraficoVentas(bool isDark) {
    if (ventasFiltradas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card(isDark),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('No hay datos para mostrar',
              style: TextStyle(color: AppColors.subtext(isDark))),
        ),
      );
    }

    final ventasPorHora = <int, double>{};
    for (var i = 8; i <= 20; i++) {
      ventasPorHora[i] = 0;
    }

    for (var v in ventasFiltradas) {
      if (v['fecha'] != null) {
        final fecha = DateTime.parse(v['fecha'].toString());
        final hora = fecha.hour;
        if (ventasPorHora.containsKey(hora)) {
          ventasPorHora[hora] = (ventasPorHora[hora] ?? 0) +
              ((v['total'] ?? 0) as num).toDouble();
        }
      }
    }

    final maxY =
        ventasPorHora.values.fold<double>(0, (max, v) => v > max ? v : max) +
            10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('VENTAS POR HORA',
                  style: TextStyle(
                      color: AppColors.text(isDark),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '\$${rod.toY.toStringAsFixed(2)}',
                        TextStyle(
                          color: AppColors.text(isDark),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${value.toInt()}',
                              style: TextStyle(
                                  color: AppColors.subtext(isDark),
                                  fontSize: 9)),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text('\$${value.toInt()}',
                            style: TextStyle(
                                color: AppColors.subtext(isDark), fontSize: 8));
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.divider(isDark),
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: ventasPorHora.entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: AppColors.primary,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    final ca = _cajaActual != null;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DASHBOARD',
                  style: TextStyle(
                      color: AppColors.text(isDark),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5)),
              if (!cargando)
                Text('${productos.length} productos',
                    style: TextStyle(
                        color: AppColors.subtext(isDark), fontSize: 11)),
            ],
          ),
        ]),
        actions: [
          _buildActionButton(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: AppColors.text(isDark),
            onTap: widget.onToggleModoOscuro,
          ),
          _buildActionButton(
            icon: ca ? Icons.lock_open_rounded : Icons.lock_rounded,
            color: ca ? AppColors.success : AppColors.subtext(isDark),
            onTap: ca ? cerrarCaja : abrirCaja,
          ),
          _buildActionButton(
            icon: Icons.refresh_rounded,
            color: AppColors.text(isDark),
            onTap: () {
              cargarDatos();
              mostrarSnackBar('Actualizado', AppColors.primary);
            },
          ),
          _buildActionButton(
            icon: Icons.shopping_cart_outlined,
            color: AppColors.text(isDark),
            onTap: widget.onNavigateToPOS,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            if (cargando)
              const Expanded(
                  child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary)))
            else ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(children: [
                  _tab('Resumen', 0, isDark),
                  _tab('Productos', 1, isDark),
                  _tab('Ventas', 2, isDark),
                ]),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: seccionActual == 0
                    ? _resumen(isDark)
                    : seccionActual == 1
                        ? _productosWidget(isDark)
                        : _ventasWidget(isDark),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon, required VoidCallback onTap, Color? color}) {
    final isDark = widget.modoOscuro;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.divider(isDark),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color ?? AppColors.text(isDark), size: 20),
        ),
      ),
    );
  }

  Widget _tab(String l, int i, bool isDark) {
    final sel = seccionActual == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => seccionActual = i),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              l,
              style: TextStyle(
                color: sel ? Colors.white : AppColors.subtext(isDark),
                fontSize: 12,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resumen(bool isDark) {
    if (productos.isEmpty) {
      return _emptyState(isDark);
    }

    return SingleChildScrollView(
      child: Column(children: [
        GestureDetector(
          onTap: () => mostrarDialogoProducto(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AGREGAR PRODUCTO',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                    Text('${productos.length} productos registrados',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          _kpi(
              'Ventas Hoy',
              '\$${totalVentasHoy.toStringAsFixed(2)}',
              '$cantidadVentasHoy transacciones',
              Icons.trending_up,
              AppColors.success,
              isDark),
          const SizedBox(width: 8),
          _kpi('Productos', '${productos.length}', 'Stock: $_totalStock',
              Icons.inventory_2_outlined, AppColors.primary, isDark),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _kpi('Stock Bajo', '$_productosStockBajo', 'Bajo el mínimo',
              Icons.warning_amber, AppColors.warning, isDark),
          const SizedBox(width: 8),
          _kpi('Agotados', '$_productosAgotados', 'Sin stock',
              Icons.error_outline, AppColors.danger, isDark),
        ]),
        const SizedBox(height: 12),
        if (_productoStockBajo.isNotEmpty) _buildAlertaStockBajo(isDark),
        const SizedBox(height: 12),
        _buildEstadoCaja(isDark),
        const SizedBox(height: 16),
        _buildAccesosRapidos(isDark),
        const SizedBox(height: 16),
        _buildGraficoVentas(isDark),
        const SizedBox(height: 16),
        if (ventasFiltradas.isNotEmpty) _buildUltimasVentas(isDark),
      ]),
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront,
                  size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text('¡BIENVENIDO A SINTHETIX POS!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.text(isDark),
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('No tienes productos registrados todavía.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.subtext(isDark), fontSize: 14)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => mostrarDialogoProducto(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CARGAR PRIMER PRODUCTO',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                        Text('Toca aquí para comenzar',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _cajaActual != null ? cerrarCaja : abrirCaja,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _cajaActual != null
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _cajaActual != null ? 'CERRAR CAJA' : 'ABRIR CAJA',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertaStockBajo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded,
            color: AppColors.warning, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ALERTA DE STOCK',
                  style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(
                  '${_productoStockBajo['nombre'] ?? ''} tiene solo ${_productoStockBajo['stock']} unidades',
                  style: TextStyle(
                      color: AppColors.text(isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              seccionActual = 1;
              _filtroStock = 'Stock Bajo';
            });
          },
          child: const Icon(Icons.chevron_right, color: AppColors.warning),
        ),
      ]),
    );
  }

  Widget _buildEstadoCaja(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cajaActual != null
                    ? AppColors.success
                    : AppColors.subtext(isDark),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cajaActual != null ? 'Caja Abierta' : 'Caja Cerrada',
                  style: TextStyle(
                    color: _cajaActual != null
                        ? AppColors.success
                        : AppColors.subtext(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_cajaActual != null)
                  Text(
                    'Total: \$${((_cajaActual!['monto_inicial'] as double) + (_cajaActual!['total_ventas'] as double)).toStringAsFixed(2)}',
                    style: TextStyle(
                        color: AppColors.subtext(isDark), fontSize: 12),
                  ),
              ],
            ),
          ]),
          GestureDetector(
            onTap: _cajaActual != null ? cerrarCaja : abrirCaja,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color:
                    _cajaActual != null ? AppColors.primary : AppColors.success,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _cajaActual != null ? 'CERRAR' : 'ABRIR',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccesosRapidos(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACCESOS RÁPIDOS',
              style: TextStyle(
                  color: AppColors.subtext(isDark),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _accesoRapido(Icons.add_shopping_cart, 'Nueva Venta',
                  widget.onNavigateToPOS, isDark),
              _accesoRapido(Icons.receipt_long, 'Reportes',
                  () => setState(() => seccionActual = 2), isDark),
              _accesoRapido(Icons.inventory, 'Inventario',
                  () => setState(() => seccionActual = 1), isDark),
              _accesoRapido(Icons.point_of_sale, 'Caja',
                  () => setState(() => seccionActual = 0), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accesoRapido(
      IconData icon, String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(color: AppColors.subtext(isDark), fontSize: 10)),
      ]),
    );
  }

  Widget _buildUltimasVentas(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ÚLTIMAS VENTAS',
                  style: TextStyle(
                      color: AppColors.text(isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => setState(() => seccionActual = 2),
                child: const Text('Ver todas',
                    style: TextStyle(color: AppColors.primary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...ventasFiltradas.take(5).map((v) {
            final fecha = v['fecha'] != null
                ? DateTime.parse(v['fecha'].toString())
                : DateTime.now();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    v['numero_factura'] ?? 'Venta #${v['id']}',
                    style:
                        TextStyle(color: AppColors.text(isDark), fontSize: 13),
                  ),
                  Text(
                    DateFormat('HH:mm').format(fecha),
                    style: TextStyle(
                        color: AppColors.subtext(isDark), fontSize: 11),
                  ),
                  Text(
                    '\$${(v['total'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _kpi(
      String t, String v, String s, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card(isDark),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(t,
                    style: TextStyle(
                        color: AppColors.subtext(isDark),
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
              ),
            ]),
            const SizedBox(height: 6),
            Text(v,
                style: TextStyle(
                    color: AppColors.text(isDark),
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(s,
                style:
                    TextStyle(color: AppColors.subtext(isDark), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _productosWidget(bool isDark) {
    final filtrados = productosFiltrados;
    return Column(children: [
      Container(
        decoration: BoxDecoration(
          color: AppColors.card(isDark),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.background(isDark),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search_rounded,
                      color: AppColors.subtext(isDark), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: TextStyle(
                          color: AppColors.text(isDark), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar...',
                        hintStyle: TextStyle(
                            color: AppColors.subtext(isDark), fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onChanged: (v) => setState(() => searchQuery = v),
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: AppColors.subtext(isDark), size: 18),
                      onPressed: () => setState(() => searchQuery = ''),
                    ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 22),
                onPressed: () => mostrarDialogoProducto(),
                padding: EdgeInsets.zero,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _buildFiltroDropdown(
                _filtroCategoria,
                [
                  'Todas',
                  ..._categorias.map((c) => c['nombre'].toString()).toList()
                ],
                (v) => setState(() => _filtroCategoria = v ?? 'Todas'),
                isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFiltroDropdown(
                _filtroStock,
                ['Todos', 'Con Stock', 'Stock Bajo', 'Agotados'],
                (v) => setState(() => _filtroStock = v ?? 'Todos'),
                isDark,
              ),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: filtrados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 48, color: AppColors.subtext(isDark)),
                      const SizedBox(height: 12),
                      Text('No hay productos',
                          style: TextStyle(
                              color: AppColors.subtext(isDark),
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => mostrarDialogoProducto(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Agregar producto'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (_, i) {
                    final prod = filtrados[i];
                    final stock = prod['stock'] ?? 0;
                    final stockMin = prod['stock_minimo'] ?? 5;
                    final sc = stock == 0
                        ? AppColors.danger
                        : stock < stockMin
                            ? AppColors.warning
                            : AppColors.success;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background(isDark),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: ImagenProducto(
                              imagenUrl: prod['imagen_url']?.toString(),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(prod['nombre'] ?? '',
                                  style: TextStyle(
                                      color: AppColors.text(isDark),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(children: [
                                Text(
                                    prod['tipo'] == 'kilo'
                                        ? '\$${(prod['precio'] as num).toStringAsFixed(2)}/kg'
                                        : '\$${(prod['precio'] as num).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: sc.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('Stock: $stock',
                                      style: TextStyle(
                                          color: sc,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ]),
                            ],
                          ),
                        ),
                        Row(children: [
                          IconButton(
                            icon: Icon(Icons.edit_rounded,
                                color: AppColors.subtext(isDark), size: 18),
                            onPressed: () =>
                                mostrarDialogoProducto(productoEditar: prod),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: AppColors.danger.withValues(alpha: 0.7),
                                size: 18),
                            onPressed: () =>
                                eliminarProducto(prod['id'].toString()),
                          ),
                        ]),
                      ]),
                    );
                  },
                ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => mostrarDialogoProducto(),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          label: const Text('AGREGAR NUEVO PRODUCTO',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildFiltroDropdown(String value, List<String> options,
      Function(String?) onChanged, bool isDark) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background(isDark),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.card(isDark),
        style: TextStyle(color: AppColors.text(isDark), fontSize: 11),
        items: options
            .map((op) => DropdownMenuItem(
                  value: op,
                  child: Text(op,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _ventasWidget(bool isDark) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VENTAS',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('\$${totalVentasHoy.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('$cantidadVentasHoy transacciones',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: Colors.white, size: 36),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          Expanded(
            child: _buildFiltroDropdown(
              _filtroFechaVentas,
              ['Hoy', 'Ayer', 'Esta Semana', 'Este Mes', 'Todo'],
              (v) {
                setState(() => _filtroFechaVentas = v ?? 'Hoy');
                _aplicarFiltroVentas();
              },
              isDark,
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ventasFiltradas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_outlined,
                          size: 48, color: AppColors.subtext(isDark)),
                      const SizedBox(height: 12),
                      Text('No hay ventas',
                          style: TextStyle(color: AppColors.subtext(isDark))),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: ventasFiltradas.length,
                  itemBuilder: (_, i) {
                    final v = ventasFiltradas[i];
                    final fecha = v['fecha'] != null
                        ? DateTime.parse(v['fecha'].toString())
                        : DateTime.now();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background(isDark),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_rounded,
                              color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v['numero_factura'] ?? 'Venta #${v['id']}',
                                  style: TextStyle(
                                      color: AppColors.text(isDark),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                  '${DateFormat('dd/MM/yyyy').format(fecha)} - ${DateFormat('hh:mm a').format(fecha)}',
                                  style: TextStyle(
                                      color: AppColors.subtext(isDark),
                                      fontSize: 11)),
                              if (v['cliente_nombre'] != null)
                                Text(v['cliente_nombre'],
                                    style: TextStyle(
                                        color: AppColors.subtext(isDark),
                                        fontSize: 11)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${(v['total'] as num).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            if (v['metodo_pago'] != null)
                              Text(v['metodo_pago'],
                                  style: TextStyle(
                                      color: AppColors.subtext(isDark),
                                      fontSize: 10)),
                          ],
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

class ConfiguracionScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const ConfiguracionScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _db = DatabaseService();
  final _nombreCtrl = TextEditingController();
  final _rifCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _tasaCOPCtrl = TextEditingController();
  final _tasaVESCtrl = TextEditingController();
  String? _logoUrl;
  Uint8List? _logoBytes;
  bool _cargando = true;
  bool _guardando = false;
  bool _subiendoLogo = false;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    final config = await _db.getConfiguracion();
    final prefs = await SharedPreferences.getInstance();
    if (config != null) {
      _nombreCtrl.text = config['nombre_negocio'] ?? '';
      _rifCtrl.text = config['rif'] ?? '';
      _direccionCtrl.text = config['direccion'] ?? '';
      _telefonoCtrl.text = config['telefono'] ?? '';
      _correoCtrl.text = config['correo'] ?? '';
      _logoUrl = config['logo_url'];
    }
    _tasaCOPCtrl.text = (prefs.getDouble('tasa_cop') ?? 4500.0).toString();
    _tasaVESCtrl.text = (prefs.getDouble('tasa_ves') ?? 60.0).toString();
    setState(() => _cargando = false);
  }

  Future<void> _subirLogo() async {
    final f = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (f == null) return;
    setState(() => _subiendoLogo = true);
    try {
      final bytes = await f.readAsBytes();
      setState(() {
        _logoBytes = bytes;
      });
      // Subir a Supabase
      final url = await _db.subirImagenSupabase(bytes, 'logos');
      if (url != null) {
        _logoUrl = url;
      }
    } catch (e) {
      debugPrint('Error subiendo logo: $e');
    }
    setState(() => _subiendoLogo = false);
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
        'tasa_cop', double.tryParse(_tasaCOPCtrl.text) ?? 4500.0);
    await prefs.setDouble(
        'tasa_ves', double.tryParse(_tasaVESCtrl.text) ?? 60.0);
    tasasCambio['COP'] = double.tryParse(_tasaCOPCtrl.text) ?? 4500.0;
    tasasCambio['VES'] = double.tryParse(_tasaVESCtrl.text) ?? 60.0;
    await _db.guardarConfiguracion({
      'nombre_negocio': _nombreCtrl.text,
      'rif': _rifCtrl.text,
      'direccion': _direccionCtrl.text,
      'telefono': _telefonoCtrl.text,
      'correo': _correoCtrl.text,
      'logo_url': _logoUrl,
    });
    setState(() => _guardando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Configuracion guardada',
              style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('MI NEGOCIO',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _cargando
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : ListView(
                  children: [
                    // LOGO
                    Center(
                      child: GestureDetector(
                        onTap: _subiendoLogo ? null : _subirLogo,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.background(isDark),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: _subiendoLogo
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary))
                              : _logoBytes != null
                                  ? ClipOval(
                                      child: Image.memory(_logoBytes!,
                                          fit: BoxFit.cover))
                                  : _logoUrl != null && _logoUrl!.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(_logoUrl!,
                                              fit: BoxFit.cover))
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.store_rounded,
                                              color: AppColors.primary,
                                              size: 48,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Subir Logo',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_nombreCtrl, 'Nombre del Negocio', isDark),
                    const SizedBox(height: 12),
                    _buildTextField(_rifCtrl, 'RIF / Cedula', isDark),
                    const SizedBox(height: 12),
                    _buildTextField(_direccionCtrl, 'Direccion', isDark,
                        maxLines: 2),
                    const SizedBox(height: 12),
                    _buildTextField(_telefonoCtrl, 'Telefono', isDark,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildTextField(_correoCtrl, 'Correo Electronico', isDark,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 24),
                    Text('TIPO DE CAMBIO',
                        style: TextStyle(
                            color: AppColors.subtext(isDark),
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: _buildTextField(
                            _tasaCOPCtrl, '1 USD = ? COP', isDark,
                            keyboardType: TextInputType.number),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                            _tasaVESCtrl, '1 USD = ? VES', isDark,
                            keyboardType: TextInputType.number),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _guardando ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _guardando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('GUARDAR CAMBIOS',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                    color: Colors.white)),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, bool isDark,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: AppColors.text(isDark)),
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.subtext(isDark)),
        filled: true,
        fillColor: AppColors.card(isDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

class CategoriasScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const CategoriasScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final _db = DatabaseService();
  List<Map<String, dynamic>> _categorias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    setState(() => _cargando = true);
    _categorias = await _db.getCategorias();
    setState(() => _cargando = false);
  }

  void _mostrarDialogo({Map<String, dynamic>? categoria}) {
    final isDark = widget.modoOscuro;
    final nombreCtrl = TextEditingController(text: categoria?['nombre'] ?? '');
    final descCtrl =
        TextEditingController(text: categoria?['descripcion'] ?? '');
    String? imagenUrl = categoria?['imagen_url'];
    Uint8List? imagenBytes;
    bool subiendo = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            categoria != null ? 'Editar Categoria' : 'Nueva Categoria',
            style: TextStyle(
                color: AppColors.text(isDark), fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // FOTO OPCIONAL
                Center(
                  child: GestureDetector(
                    onTap: subiendo
                        ? null
                        : () async {
                            final f = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 70,
                            );
                            if (f != null) {
                              setDialogState(() => subiendo = true);
                              final bytes = await f.readAsBytes();
                              final base64String = base64Encode(bytes);
                              setDialogState(() {
                                imagenBytes = bytes;
                                imagenUrl =
                                    'data:image/jpeg;base64,$base64String';
                                subiendo = false;
                              });
                            }
                          },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.background(isDark),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: subiendo
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2))
                          : imagenBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.memory(imagenBytes!,
                                      fit: BoxFit.cover))
                              : imagenUrl != null && imagenUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: ImagenProducto(
                                        imagenUrl: imagenUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.photo_camera_outlined,
                                          color: AppColors.primary,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Foto',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nombreCtrl,
                  style: TextStyle(color: AppColors.text(isDark)),
                  decoration: InputDecoration(
                    labelText: 'Nombre *',
                    labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                    filled: true,
                    fillColor: AppColors.background(isDark),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style: TextStyle(color: AppColors.text(isDark)),
                  decoration: InputDecoration(
                    labelText: 'Descripcion',
                    labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                    filled: true,
                    fillColor: AppColors.background(isDark),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar',
                    style: TextStyle(color: AppColors.subtext(isDark)))),
            TextButton(
              onPressed: () async {
                if (nombreCtrl.text.isEmpty) return;
                final data = {
                  'nombre': nombreCtrl.text,
                  'descripcion': descCtrl.text,
                  'imagen_url': imagenUrl,
                };
                if (categoria != null) {
                  await _db.actualizarCategoria(
                    categoria['id'].toString(),
                    data,
                  );
                } else {
                  await _db.crearCategoria(data);
                }
                Navigator.pop(ctx);
                _cargarCategorias();
              },
              child: const Text('Guardar',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('CATEGORIAS',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_cargando)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _categorias.length,
                    itemBuilder: (_, i) {
                      final cat = _categorias[i];
                      final imagenUrl = cat['imagen_url'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: imagenUrl != null && imagenUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: ImagenProducto(
                                      imagenUrl: imagenUrl.toString(),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.category_outlined,
                                    color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(cat['nombre'] ?? '',
                                style: TextStyle(
                                    color: AppColors.text(isDark),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_rounded,
                                color: AppColors.subtext(isDark), size: 18),
                            onPressed: () => _mostrarDialogo(categoria: cat),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: AppColors.danger.withValues(alpha: 0.7),
                                size: 18),
                            onPressed: () async {
                              await _db.eliminarCategoria(cat['id'].toString());
                              _cargarCategorias();
                            },
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogo(),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text('AGREGAR CATEGORIA',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MetodosPagoScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const MetodosPagoScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<MetodosPagoScreen> createState() => _MetodosPagoScreenState();
}

class _MetodosPagoScreenState extends State<MetodosPagoScreen> {
  final _db = DatabaseService();
  List<Map<String, dynamic>> _metodos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarMetodos();
  }

  Future<void> _cargarMetodos() async {
    setState(() => _cargando = true);
    _metodos = await _db.getMetodosPago();
    setState(() => _cargando = false);
  }

  void _mostrarDialogo({Map<String, dynamic>? metodo}) {
    final isDark = widget.modoOscuro;
    final nombreCtrl = TextEditingController(text: metodo?['nombre'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          metodo != null ? 'Editar Metodo' : 'Nuevo Metodo',
          style: TextStyle(
              color: AppColors.text(isDark), fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: nombreCtrl,
          style: TextStyle(color: AppColors.text(isDark)),
          decoration: InputDecoration(
            labelText: 'Nombre *',
            labelStyle: TextStyle(color: AppColors.subtext(isDark)),
            filled: true,
            fillColor: AppColors.background(isDark),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          TextButton(
            onPressed: () async {
              if (nombreCtrl.text.isEmpty) return;
              if (metodo != null) {
                await _db.actualizarMetodoPago(
                  metodo['id'].toString(),
                  {'nombre': nombreCtrl.text},
                );
              } else {
                await _db
                    .crearMetodoPago({'nombre': nombreCtrl.text, 'activo': 1});
              }
              Navigator.pop(ctx);
              _cargarMetodos();
            },
            child: const Text('Guardar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('METODOS DE PAGO',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_cargando)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _metodos.length,
                    itemBuilder: (_, i) {
                      final metodo = _metodos[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(metodo['nombre'] ?? '',
                                style: TextStyle(
                                    color: AppColors.text(isDark),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Switch(
                            value: metodo['activo'] == 1 ||
                                metodo['activo'] == true,
                            onChanged: (val) async {
                              await _db.actualizarMetodoPago(
                                metodo['id'].toString(),
                                {'activo': val ? 1 : 0},
                              );
                              _cargarMetodos();
                            },
                            activeThumbColor: AppColors.primary,
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_rounded,
                                color: AppColors.subtext(isDark), size: 18),
                            onPressed: () => _mostrarDialogo(metodo: metodo),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: AppColors.danger.withValues(alpha: 0.7),
                                size: 18),
                            onPressed: () async {
                              await _db
                                  .eliminarMetodoPago(metodo['id'].toString());
                              _cargarMetodos();
                            },
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogo(),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text('AGREGAR METODO',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VendedoresScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const VendedoresScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<VendedoresScreen> createState() => _VendedoresScreenState();
}

class _VendedoresScreenState extends State<VendedoresScreen> {
  final _db = DatabaseService();
  List<Map<String, dynamic>> _vendedores = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarVendedores();
  }

  Future<void> _cargarVendedores() async {
    setState(() => _cargando = true);
    _vendedores = await _db.getVendedores();
    setState(() => _cargando = false);
  }

  void _mostrarDialogo({Map<String, dynamic>? vendedor}) {
    final isDark = widget.modoOscuro;
    final nombreCtrl = TextEditingController(text: vendedor?['nombre'] ?? '');
    final telefonoCtrl =
        TextEditingController(text: vendedor?['telefono'] ?? '');
    final comisionCtrl =
        TextEditingController(text: vendedor?['comision']?.toString() ?? '0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          vendedor != null ? 'Editar Vendedor' : 'Nuevo Vendedor',
          style: TextStyle(
              color: AppColors.text(isDark), fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              style: TextStyle(color: AppColors.text(isDark)),
              decoration: InputDecoration(
                labelText: 'Nombre *',
                labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                filled: true,
                fillColor: AppColors.background(isDark),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: telefonoCtrl,
              style: TextStyle(color: AppColors.text(isDark)),
              decoration: InputDecoration(
                labelText: 'Telefono',
                labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                filled: true,
                fillColor: AppColors.background(isDark),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: comisionCtrl,
              style: TextStyle(color: AppColors.text(isDark)),
              decoration: InputDecoration(
                labelText: 'Comision (%)',
                labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                filled: true,
                fillColor: AppColors.background(isDark),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          TextButton(
            onPressed: () async {
              if (nombreCtrl.text.isEmpty) return;
              final data = {
                'nombre': nombreCtrl.text,
                'telefono': telefonoCtrl.text,
                'comision': double.tryParse(comisionCtrl.text) ?? 0,
              };
              if (vendedor != null) {
                await _db.actualizarVendedor(vendedor['id'].toString(), data);
              } else {
                await _db.crearVendedor(data);
              }
              Navigator.pop(ctx);
              _cargarVendedores();
            },
            child: const Text('Guardar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('VENDEDORES',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_cargando)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _vendedores.length,
                    itemBuilder: (_, i) {
                      final v = _vendedores[i];
                      final nombre = v['nombre'] ?? '';
                      final comision = v['comision'] ?? 0;
                      final inicial =
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                                child: Text(inicial,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nombre,
                                    style: TextStyle(
                                        color: AppColors.text(isDark),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                Text('Comision: $comision%',
                                    style: TextStyle(
                                        color: AppColors.subtext(isDark),
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_rounded,
                                color: AppColors.subtext(isDark), size: 18),
                            onPressed: () => _mostrarDialogo(vendedor: v),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: AppColors.danger.withValues(alpha: 0.7),
                                size: 18),
                            onPressed: () async {
                              await _db.eliminarVendedor(v['id'].toString());
                              _cargarVendedores();
                            },
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogo(),
                  icon:
                      const Icon(Icons.person_add_rounded, color: Colors.white),
                  label: const Text('AGREGAR VENDEDOR',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClientesScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const ClientesScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _db = DatabaseService();
  List<Map<String, dynamic>> _clientes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    setState(() => _cargando = true);
    _clientes = await _db.getClientes();
    setState(() => _cargando = false);
  }

  void _mostrarDialogo({Map<String, dynamic>? cliente}) {
    final isDark = widget.modoOscuro;
    final nombreCtrl = TextEditingController(text: cliente?['nombre'] ?? '');
    final telefonoCtrl =
        TextEditingController(text: cliente?['telefono'] ?? '');
    final correoCtrl = TextEditingController(text: cliente?['email'] ?? '');
    final direccionCtrl =
        TextEditingController(text: cliente?['direccion'] ?? '');
    final cedulaCtrl =
        TextEditingController(text: cliente?['identificacion'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          cliente != null ? 'Editar Cliente' : 'Nuevo Cliente',
          style: TextStyle(
              color: AppColors.text(isDark), fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                decoration: InputDecoration(
                  labelText: 'Nombre *',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cedulaCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                decoration: InputDecoration(
                  labelText: 'Cédula',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: telefonoCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                decoration: InputDecoration(
                  labelText: 'Telefono',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: correoCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                decoration: InputDecoration(
                  labelText: 'Correo',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: direccionCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                decoration: InputDecoration(
                  labelText: 'Direccion',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              if (cliente != null && cliente['puntos'] != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background(isDark),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.star, color: AppColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Text('Puntos: ${cliente['puntos']}',
                        style: TextStyle(
                            color: AppColors.text(isDark),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('Total: \$${cliente['total_compras'] ?? 0}',
                        style: TextStyle(
                            color: AppColors.subtext(isDark), fontSize: 12)),
                  ]),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          TextButton(
            onPressed: () async {
              if (nombreCtrl.text.isEmpty) return;
              final data = {
                'nombre': nombreCtrl.text,
                'telefono': telefonoCtrl.text,
                'email': correoCtrl.text,
                'direccion': direccionCtrl.text,
                'identificacion': cedulaCtrl.text,
              };
              if (cliente != null) {
                await _db.actualizarCliente(cliente['id'].toString(), data);
              } else {
                await _db.crearCliente(data);
              }
              Navigator.pop(ctx);
              _cargarClientes();
            },
            child: const Text('Guardar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('CLIENTES',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_cargando)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _clientes.length,
                    itemBuilder: (_, i) {
                      final c = _clientes[i];
                      final nombre = c['nombre'] ?? '';
                      final telefono = c['telefono'] ?? '';
                      final cedula = c['identificacion'] ?? '';
                      final puntos = c['puntos'] ?? 0;
                      final inicial =
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                                child: Text(inicial,
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nombre,
                                    style: TextStyle(
                                        color: AppColors.text(isDark),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                Text(telefono,
                                    style: TextStyle(
                                        color: AppColors.subtext(isDark),
                                        fontSize: 11)),
                                if (cedula.isNotEmpty)
                                  Text('CI: $cedula',
                                      style: TextStyle(
                                          color: AppColors.subtext(isDark),
                                          fontSize: 11)),
                                if (puntos > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star,
                                            color: AppColors.warning, size: 12),
                                        const SizedBox(width: 4),
                                        Text('$puntos pts',
                                            style: const TextStyle(
                                                color: AppColors.warning,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_rounded,
                                color: AppColors.subtext(isDark), size: 18),
                            onPressed: () => _mostrarDialogo(cliente: c),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: AppColors.danger.withValues(alpha: 0.7),
                                size: 18),
                            onPressed: () async {
                              await _db.eliminarCliente(c['id'].toString());
                              _cargarClientes();
                            },
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogo(),
                  icon:
                      const Icon(Icons.person_add_rounded, color: Colors.white),
                  label: const Text('AGREGAR CLIENTE',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportesScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const ReportesScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _db = DatabaseService();
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();
  Map<String, dynamic>? _reporte;
  bool _cargando = false;

  Future<void> _generarReporte() async {
    setState(() => _cargando = true);
    _reporte = await _db.getReporteGeneral(_fechaInicio, _fechaFin);
    setState(() => _cargando = false);
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
        } else {
          _fechaFin = fecha;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('REPORTES',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _seleccionarFecha(true),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background(isDark),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.divider(isDark),
                              width: 1,
                            ),
                          ),
                          child: Column(children: [
                            Text('Desde',
                                style: TextStyle(
                                    color: AppColors.subtext(isDark),
                                    fontSize: 10)),
                            const SizedBox(height: 4),
                            Text(DateFormat('dd/MM/yyyy').format(_fechaInicio),
                                style: TextStyle(
                                    color: AppColors.text(isDark),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _seleccionarFecha(false),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background(isDark),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.divider(isDark),
                              width: 1,
                            ),
                          ),
                          child: Column(children: [
                            Text('Hasta',
                                style: TextStyle(
                                    color: AppColors.subtext(isDark),
                                    fontSize: 10)),
                            const SizedBox(height: 4),
                            Text(DateFormat('dd/MM/yyyy').format(_fechaFin),
                                style: TextStyle(
                                    color: AppColors.text(isDark),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _generarReporte,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _cargando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('GENERAR REPORTE',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              if (_reporte != null)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card(isDark),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(children: [
                                const Text('Total Ventas',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(
                                    '\$${(_reporte!['total_ventas'] as double).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background(isDark),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.divider(isDark),
                                  width: 1,
                                ),
                              ),
                              child: Column(children: [
                                Text('Transacciones',
                                    style: TextStyle(
                                        color: AppColors.subtext(isDark),
                                        fontSize: 11)),
                                const SizedBox(height: 4),
                                Text('${_reporte!['cantidad_ventas']}',
                                    style: TextStyle(
                                        color: AppColors.text(isDark),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Text('Ultimas Ventas',
                            style: TextStyle(
                                color: AppColors.text(isDark),
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: (_reporte!['ventas'] as List).length,
                            itemBuilder: (_, i) {
                              final v = (_reporte!['ventas'] as List)[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.background(isDark),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        v['numero_factura'] ??
                                            'Venta #${v['id']}',
                                        style: TextStyle(
                                            color: AppColors.text(isDark),
                                            fontSize: 12)),
                                    Text(
                                        '\$${(v['total'] as num).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!_cargando)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48, color: AppColors.subtext(isDark)),
                        const SizedBox(height: 12),
                        Text('Selecciona un rango de fechas',
                            style: TextStyle(color: AppColors.subtext(isDark))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImpresoraScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const ImpresoraScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<ImpresoraScreen> createState() => _ImpresoraScreenState();
}

class _ImpresoraScreenState extends State<ImpresoraScreen> {
  int _copias = 1;
  String _tamanoPapel = '80mm';
  bool _mostrarLogo = true;
  bool _mostrarQR = false;
  bool _impresoraConectada = false;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _copias = prefs.getInt('impresora_copias') ?? 1;
      _tamanoPapel = prefs.getString('impresora_tamano') ?? '80mm';
      _mostrarLogo = prefs.getBool('impresora_logo') ?? true;
      _mostrarQR = prefs.getBool('impresora_qr') ?? false;
    });
  }

  Future<void> _guardarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('impresora_copias', _copias);
    await prefs.setString('impresora_tamano', _tamanoPapel);
    await prefs.setBool('impresora_logo', _mostrarLogo);
    await prefs.setBool('impresora_qr', _mostrarQR);
    _mostrarExito('Configuracion guardada');
  }

  void _mostrarExito(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('IMPRESORA',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _impresoraConectada
                          ? AppColors.success
                          : AppColors.subtext(isDark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _impresoraConectada ? 'Conectado' : 'Desconectado',
                    style: TextStyle(
                      color: _impresoraConectada
                          ? AppColors.success
                          : AppColors.subtext(isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _impresoraConectada
                        ? null
                        : () => setState(() => _impresoraConectada = true),
                    icon: const Icon(Icons.bluetooth, color: Colors.white),
                    label: const Text('Conectar',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _impresoraConectada
                        ? () => setState(() => _impresoraConectada = false)
                        : null,
                    icon: const Icon(Icons.bluetooth_disabled,
                        color: Colors.white),
                    label: const Text('Desconectar',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              Text('CONFIGURACION',
                  style: TextStyle(
                      color: AppColors.subtext(isDark),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Numero de copias',
                          style: TextStyle(
                              color: AppColors.text(isDark), fontSize: 14)),
                      Row(children: [
                        IconButton(
                          icon: Icon(Icons.remove,
                              color: AppColors.text(isDark), size: 20),
                          onPressed: () {
                            if (_copias > 1) setState(() => _copias--);
                          },
                        ),
                        Text('$_copias',
                            style: TextStyle(
                                color: AppColors.text(isDark),
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        IconButton(
                          icon: Icon(Icons.add,
                              color: AppColors.text(isDark), size: 20),
                          onPressed: () {
                            if (_copias < 5) setState(() => _copias++);
                          },
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tamano de papel',
                          style: TextStyle(
                              color: AppColors.text(isDark), fontSize: 14)),
                      DropdownButton<String>(
                        value: _tamanoPapel,
                        style: TextStyle(
                            color: AppColors.text(isDark), fontSize: 14),
                        dropdownColor: AppColors.card(isDark),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: '58mm', child: Text('58mm')),
                          DropdownMenuItem(value: '80mm', child: Text('80mm')),
                        ],
                        onChanged: (v) =>
                            setState(() => _tamanoPapel = v ?? '80mm'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text('Mostrar logo',
                        style: TextStyle(
                            color: AppColors.text(isDark), fontSize: 14)),
                    value: _mostrarLogo,
                    onChanged: (v) => setState(() => _mostrarLogo = v),
                    activeThumbColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: Text('Mostrar codigo QR',
                        style: TextStyle(
                            color: AppColors.text(isDark), fontSize: 14)),
                    value: _mostrarQR,
                    onChanged: (v) => setState(() => _mostrarQR = v),
                    activeThumbColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _impresoraConectada
                      ? () => _mostrarExito('Imprimiendo...')
                      : null,
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: const Text('Imprimir Ticket de Prueba',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _guardarConfiguracion,
                  icon: const Icon(Icons.save, color: AppColors.primary),
                  label: const Text('Guardar Configuracion',
                      style: TextStyle(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BackupScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const BackupScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _db = DatabaseService();
  bool _exportando = false;

  Future<void> _exportarDatos() async {
    setState(() => _exportando = true);
    final productos = await _db.getProductos();
    final ventas = await _db.getVentasHoy();
    final clientes = await _db.getClientes();
    final data = {
      'productos': productos,
      'ventas': ventas,
      'clientes': clientes,
      'fecha_exportacion': DateTime.now().toIso8601String(),
      'version': '5.1.0',
    };
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    await Share.share(jsonStr,
        subject:
            'Backup SINTHETIX PRO - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}');
    _mostrarExito('Datos exportados correctamente');
    setState(() => _exportando = false);
  }

  Future<void> _exportarPDF() async {
    final productos = await _db.getProductos();
    final ventas = await _db.getVentasHoy();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('SINTHETIX PRO - Reporte',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
              'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 20),
          pw.Text('PRODUCTOS',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Nombre', 'Código', 'Precio', 'Stock'],
            data: productos
                .map((p) => [
                      p['nombre']?.toString() ?? '',
                      p['codigo_barras']?.toString() ?? '',
                      '\$${p['precio']?.toString() ?? '0'}',
                      p['stock']?.toString() ?? '0',
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.purple100),
            cellHeight: 25,
          ),
          pw.SizedBox(height: 30),
          pw.Text('VENTAS',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Factura', 'Fecha', 'Total', 'Método'],
            data: ventas
                .map((v) => [
                      v['numero_factura']?.toString() ?? '',
                      v['fecha']?.toString().substring(0, 10) ?? '',
                      '\$${v['total']?.toString() ?? '0'}',
                      v['metodo_pago']?.toString() ?? '',
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.cyan100),
            cellHeight: 25,
          ),
        ],
      ),
    );

    try {
      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/Reporte_SINTHETIX_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Reporte SINTHETIX PRO',
      );

      _mostrarExito('PDF generado correctamente');
    } catch (e) {
      _mostrarExito('Error al generar PDF: $e');
    }
  }

  void _mostrarExito(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('RESPALDO DE DATOS',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.upload_file,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Exportar Datos',
                                style: TextStyle(
                                    color: AppColors.text(isDark),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            Text('Productos, ventas, clientes',
                                style: TextStyle(
                                    color: AppColors.subtext(isDark),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _exportando ? null : _exportarDatos,
                        icon: _exportando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.upload_file,
                                color: Colors.white),
                        label: Text(
                            _exportando ? 'Exportando...' : 'Exportar JSON',
                            style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _exportarPDF,
                        icon: const Icon(Icons.picture_as_pdf,
                            color: AppColors.danger),
                        label: const Text('Exportar PDF',
                            style: TextStyle(color: AppColors.danger)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Se recomienda hacer un respaldo diario al cerrar la caja.',
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CajaScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const CajaScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> {
  final CajaService _cajaService = CajaService();
  final DatabaseService _db = DatabaseService();
  Map<String, dynamic>? _cajaActual;
  List<Map<String, dynamic>> _historialCajas = [];
  List<Map<String, dynamic>> _movimientos = [];
  List<Map<String, dynamic>> _ventasHoy = [];
  bool _cargando = true;
  int _tabActual = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    _cajaActual = await _cajaService.getCajaAbierta();
    _historialCajas = await _cajaService.getHistorialCajas();
    _movimientos = await _cajaService.getMovimientosHoy();
    _ventasHoy = await _db.getVentasHoy();
    setState(() => _cargando = false);
  }

  void _abrirCaja() {
    final isDark = widget.modoOscuro;
    final montoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Abrir Caja',
            style: TextStyle(
                color: AppColors.text(isDark), fontWeight: FontWeight.w700)),
        content: TextField(
          controller: montoCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: AppColors.text(isDark)),
          decoration: InputDecoration(
            labelText: 'Monto Inicial',
            labelStyle: TextStyle(color: AppColors.subtext(isDark)),
            prefixText: '\$ ',
            prefixStyle: TextStyle(color: AppColors.text(isDark)),
            filled: true,
            fillColor: AppColors.background(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          TextButton(
            onPressed: () async {
              final monto = double.tryParse(montoCtrl.text) ?? 0;
              if (monto <= 0) return;
              await _cajaService.abrirCaja(monto);
              Navigator.pop(ctx);
              _cargarDatos();
            },
            child: const Text('Abrir',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _cerrarCaja() {
    if (_cajaActual == null) return;
    final isDark = widget.modoOscuro;
    final montoFinalCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cerrar Caja',
            style: TextStyle(
                color: AppColors.text(isDark), fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen:',
                style: TextStyle(color: AppColors.subtext(isDark))),
            const SizedBox(height: 12),
            _infoRow(
                'Monto Inicial:',
                '\$${(_cajaActual!['monto_inicial'] as double).toStringAsFixed(2)}',
                isDark),
            _infoRow(
                'Total Ventas:',
                '\$${(_cajaActual!['total_ventas'] as double).toStringAsFixed(2)}',
                isDark),
            const SizedBox(height: 16),
            TextField(
              controller: montoFinalCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: AppColors.text(isDark)),
              decoration: InputDecoration(
                labelText: 'Monto Final Contado',
                labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: AppColors.text(isDark)),
                filled: true,
                fillColor: AppColors.background(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          TextButton(
            onPressed: () async {
              final montoFinal = double.tryParse(montoFinalCtrl.text) ?? 0;
              await _cajaService.cerrarCaja(montoFinal);
              Navigator.pop(ctx);
              _cargarDatos();
            },
            child: const Text('Cerrar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _registrarMovimiento(String tipo) {
    final isDark = widget.modoOscuro;
    final montoCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Registrar $tipo',
            style: TextStyle(
                color: AppColors.text(isDark), fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: montoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: AppColors.text(isDark)),
              decoration: InputDecoration(
                labelText: 'Monto',
                labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: AppColors.text(isDark)),
                filled: true,
                fillColor: AppColors.background(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              style: TextStyle(color: AppColors.text(isDark)),
              decoration: InputDecoration(
                labelText: 'Descripcion',
                labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                filled: true,
                fillColor: AppColors.background(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          TextButton(
            onPressed: () async {
              final monto = double.tryParse(montoCtrl.text) ?? 0;
              if (monto <= 0) return;
              await _cajaService.registrarMovimiento(
                  tipo, monto, descCtrl.text);
              Navigator.pop(ctx);
              _cargarDatos();
            },
            child: const Text('Registrar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    TextStyle(color: AppColors.subtext(isDark), fontSize: 13)),
            Text(value,
                style: TextStyle(
                    color: AppColors.text(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _tab(String l, int i, bool isDark) {
    final sel = _tabActual == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabActual = i),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              l,
              style: TextStyle(
                color: sel ? Colors.white : AppColors.subtext(isDark),
                fontSize: 12,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCajaVacia(bool isDark) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.point_of_sale,
                size: 64, color: AppColors.subtext(isDark)),
            const SizedBox(height: 16),
            Text('La caja esta cerrada',
                style:
                    TextStyle(color: AppColors.subtext(isDark), fontSize: 16)),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: _abrirCaja,
                icon: const Icon(Icons.lock_open, color: Colors.white),
                label: const Text('Abrir Caja',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildCajaAbierta() {
    final montoInicial = (_cajaActual!['monto_inicial'] as double);
    final totalVentas = (_cajaActual!['total_ventas'] as double);
    final totalCaja = montoInicial + totalVentas;
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Text('Total en Caja',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
            const SizedBox(height: 8),
            Text('\$${totalCaja.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  Text('Inicial',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11)),
                  Text('\$${montoInicial.toStringAsFixed(2)}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                ]),
                Column(children: [
                  Text('Ventas',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11)),
                  Text('\$${totalVentas.toStringAsFixed(2)}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                ]),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 16),
        // GRÁFICO DE VENTAS POR HORA
        _buildGraficoVentasHora(),
        const SizedBox(height: 16),
        // GRÁFICO CIRCULAR DE MÉTODOS DE PAGO
        _buildGraficoMetodosPago(),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _registrarMovimiento('Ingreso'),
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label:
                  const Text('Ingreso', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _registrarMovimiento('Egreso'),
              icon:
                  const Icon(Icons.remove_circle_outline, color: Colors.white),
              label:
                  const Text('Egreso', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _cerrarCaja,
            icon: const Icon(Icons.lock, color: Colors.white),
            label: const Text('CERRAR CAJA',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGraficoVentasHora() {
    final isDark = widget.modoOscuro;
    if (_ventasHoy.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card(isDark),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('No hay ventas hoy',
              style: TextStyle(color: AppColors.subtext(isDark))),
        ),
      );
    }

    final ventasPorHora = <int, double>{};
    for (var i = 8; i <= 20; i++) {
      ventasPorHora[i] = 0;
    }

    for (var v in _ventasHoy) {
      if (v['fecha'] != null) {
        final fecha = DateTime.parse(v['fecha'].toString());
        final hora = fecha.hour;
        if (ventasPorHora.containsKey(hora)) {
          ventasPorHora[hora] = (ventasPorHora[hora] ?? 0) +
              ((v['total'] ?? 0) as num).toDouble();
        }
      }
    }

    final maxY =
        ventasPorHora.values.fold<double>(0, (max, v) => v > max ? v : max) +
            10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('VENTAS POR HORA',
                  style: TextStyle(
                      color: AppColors.text(isDark),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}',
                            style: TextStyle(
                                color: AppColors.subtext(isDark), fontSize: 8));
                      },
                      reservedSize: 20,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text('\$${value.toInt()}',
                            style: TextStyle(
                                color: AppColors.subtext(isDark), fontSize: 7));
                      },
                      reservedSize: 35,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.divider(isDark),
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: ventasPorHora.entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: AppColors.primary,
                        width: 6,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoMetodosPago() {
    final isDark = widget.modoOscuro;
    if (_ventasHoy.isEmpty) {
      return const SizedBox.shrink();
    }

    final metodosMap = <String, double>{};
    for (var v in _ventasHoy) {
      final metodo = v['metodo_pago'] ?? 'Desconocido';
      metodosMap[metodo] =
          (metodosMap[metodo] ?? 0) + ((v['total'] ?? 0) as num).toDouble();
    }

    final totalVentas = metodosMap.values.fold<double>(0, (a, b) => a + b);
    if (totalVentas == 0) return const SizedBox.shrink();

    final colores = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.danger,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MÉTODOS DE PAGO',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 16),
          ...metodosMap.entries.map((entry) {
            final porcentaje = (entry.value / totalVentas) * 100;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(
                  child: Text(entry.key,
                      style: TextStyle(
                          color: AppColors.text(isDark), fontSize: 12)),
                ),
                Text(
                  '\$${entry.value.toStringAsFixed(2)} (${porcentaje.toStringAsFixed(1)}%)',
                  style:
                      TextStyle(color: AppColors.subtext(isDark), fontSize: 11),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMovimientos(bool isDark) {
    if (_movimientos.isEmpty) {
      return Center(
          child: Text('No hay movimientos',
              style: TextStyle(color: AppColors.subtext(isDark))));
    }
    return ListView.builder(
      itemCount: _movimientos.length,
      itemBuilder: (_, i) {
        final m = _movimientos[i];
        final esIngreso = m['tipo'] == 'Ingreso';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: esIngreso
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                esIngreso
                    ? Icons.add_circle_outline
                    : Icons.remove_circle_outline,
                color: esIngreso ? AppColors.success : AppColors.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['descripcion'] ?? m['tipo'],
                      style: TextStyle(
                          color: AppColors.text(isDark), fontSize: 14)),
                  Text(m['fecha']?.toString().substring(0, 19) ?? '',
                      style: TextStyle(
                          color: AppColors.subtext(isDark), fontSize: 10)),
                ],
              ),
            ),
            Text(
              '\$${(m['monto'] as num).toStringAsFixed(2)}',
              style: TextStyle(
                color: esIngreso ? AppColors.success : AppColors.danger,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildHistorial(bool isDark) {
    if (_historialCajas.isEmpty) {
      return Center(
          child: Text('No hay historial',
              style: TextStyle(color: AppColors.subtext(isDark))));
    }
    return ListView.builder(
      itemCount: _historialCajas.length,
      itemBuilder: (_, i) {
        final c = _historialCajas[i];
        final fecha = c['fecha_apertura']?.toString().substring(0, 10) ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.point_of_sale,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Caja del $fecha',
                      style: TextStyle(
                          color: AppColors.text(isDark), fontSize: 14)),
                  Text(
                    'Inicial: \$${(c['monto_inicial'] as num).toStringAsFixed(2)} | Final: \$${(c['monto_final'] as num).toStringAsFixed(2)}',
                    style: TextStyle(
                        color: AppColors.subtext(isDark), fontSize: 11),
                  ),
                ],
              ),
            ),
            if (c['diferencia'] != null)
              Text(
                'Dif: \$${(c['diferencia'] as num).toStringAsFixed(2)}',
                style: TextStyle(
                  color: (c['diferencia'] as num) >= 0
                      ? AppColors.success
                      : AppColors.danger,
                  fontSize: 11,
                ),
              ),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('CAJA',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _cajaActual != null
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.subtext(isDark).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _cajaActual != null
                        ? AppColors.success
                        : AppColors.subtext(isDark),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _cajaActual != null ? 'ABIERTA' : 'CERRADA',
                  style: TextStyle(
                    color: _cajaActual != null
                        ? AppColors.success
                        : AppColors.subtext(isDark),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(children: [
                  _tab('Caja', 0, isDark),
                  _tab('Movimientos', 1, isDark),
                  _tab('Historial', 2, isDark),
                ]),
              ),
              const SizedBox(height: 16),
              if (_cargando)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)))
              else
                Expanded(
                  child: _tabActual == 0
                      ? (_cajaActual == null
                          ? _buildCajaVacia(isDark)
                          : _buildCajaAbierta())
                      : _tabActual == 1
                          ? _buildMovimientos(isDark)
                          : _buildHistorial(isDark),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PerfilScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const PerfilScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _db = DatabaseService();
  Map<String, dynamic>? _perfil;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _cargando = true);
    _perfil = await _db.getPerfilUsuario();
    setState(() => _cargando = false);
  }

  void _cambiarNombre() {
    final isDark = widget.modoOscuro;
    final ctrl = TextEditingController(text: _perfil?['nombre'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cambiar Nombre',
            style: TextStyle(
                color: AppColors.text(isDark), fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: AppColors.text(isDark)),
          decoration: InputDecoration(
            labelText: 'Nombre',
            labelStyle: TextStyle(color: AppColors.subtext(isDark)),
            filled: true,
            fillColor: AppColors.background(isDark),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          TextButton(
            onPressed: () async {
              await _db.actualizarPerfil({'nombre': ctrl.text});
              Navigator.pop(ctx);
              _cargarPerfil();
            },
            child: const Text('Guardar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _cambiarPassword() {
    final isDark = widget.modoOscuro;
    final ctrl1 = TextEditingController();
    final ctrl2 = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cambiar Contrasena',
            style: TextStyle(
                color: AppColors.text(isDark), fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl1,
              obscureText: true,
              style: TextStyle(color: AppColors.text(isDark)),
              decoration: InputDecoration(
                labelText: 'Nueva Contrasena',
                labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                filled: true,
                fillColor: AppColors.background(isDark),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl2,
              obscureText: true,
              style: TextStyle(color: AppColors.text(isDark)),
              decoration: InputDecoration(
                labelText: 'Confirmar Contrasena',
                labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                filled: true,
                fillColor: AppColors.background(isDark),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          TextButton(
            onPressed: () async {
              if (ctrl1.text != ctrl2.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Las contrasenas no coinciden'),
                      backgroundColor: AppColors.danger),
                );
                return;
              }
              if (ctrl1.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Minimo 6 caracteres'),
                      backgroundColor: AppColors.danger),
                );
                return;
              }
              await _db.cambiarPassword(ctrl1.text);
              Navigator.pop(ctx);
            },
            child: const Text('Cambiar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('MI PERFIL',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _cargando
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card(isDark),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(40)),
                          child: Center(
                            child: Text(
                              (_perfil?['nombre'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(_perfil?['nombre'] ?? 'Usuario',
                            style: TextStyle(
                                color: AppColors.text(isDark),
                                fontSize: 20,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(_perfil?['email'] ?? '',
                            style: TextStyle(
                                color: AppColors.subtext(isDark),
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _perfil?['rol'] == 'admin'
                                ? 'Administrador'
                                : 'Vendedor',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: AppColors.card(isDark),
                      borderRadius: BorderRadius.circular(16),
                      child: Column(children: [
                        ListTile(
                          leading: Icon(Icons.person,
                              color: AppColors.subtext(isDark), size: 22),
                          title: Text('Cambiar Nombre',
                              style: TextStyle(
                                  color: AppColors.text(isDark), fontSize: 14)),
                          trailing: Icon(Icons.chevron_right,
                              color: AppColors.subtext(isDark), size: 20),
                          onTap: _cambiarNombre,
                        ),
                        Divider(color: AppColors.divider(isDark), height: 1),
                        ListTile(
                          leading: Icon(Icons.lock,
                              color: AppColors.subtext(isDark), size: 22),
                          title: Text('Cambiar Contrasena',
                              style: TextStyle(
                                  color: AppColors.text(isDark), fontSize: 14)),
                          trailing: Icon(Icons.chevron_right,
                              color: AppColors.subtext(isDark), size: 20),
                          onTap: _cambiarPassword,
                        ),
                      ]),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class InventarioScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const InventarioScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _db = DatabaseService();
  List<Map<String, dynamic>> _movimientos = [];
  List<Map<String, dynamic>> _productos = [];
  bool _cargando = true;
  int _tabActual = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    _movimientos = await _db.getMovimientosInventario();
    _productos = await _db.getProductos();
    setState(() => _cargando = false);
  }

  void _registrarMovimiento(String tipo) {
    final isDark = widget.modoOscuro;
    String? productoSeleccionado;
    final cantidadCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Registrar $tipo',
              style: TextStyle(
                  color: AppColors.text(isDark), fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: productoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Producto *',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                items: _productos
                    .map((prod) => DropdownMenuItem(
                          value: prod['id'].toString(),
                          child: Text(prod['nombre'] ?? '',
                              style: TextStyle(color: AppColors.text(isDark))),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => productoSeleccionado = v),
                dropdownColor: AppColors.card(isDark),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cantidadCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppColors.text(isDark)),
                decoration: InputDecoration(
                  labelText: 'Cantidad *',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: motivoCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                decoration: InputDecoration(
                  labelText: 'Motivo',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar',
                    style: TextStyle(color: AppColors.subtext(isDark)))),
            TextButton(
              onPressed: () async {
                if (productoSeleccionado == null || cantidadCtrl.text.isEmpty) {
                  return;
                }
                final producto = _productos.firstWhere(
                    (prod) => prod['id'].toString() == productoSeleccionado);
                final cantidad = int.tryParse(cantidadCtrl.text) ?? 0;
                if (cantidad <= 0) return;
                await _db.registrarMovimientoInventario({
                  'producto_id': productoSeleccionado,
                  'producto_nombre': producto['nombre'],
                  'tipo': tipo,
                  'cantidad': cantidad,
                  'motivo': motivoCtrl.text,
                  'fecha': DateTime.now().toIso8601String(),
                });
                final nuevoStock = tipo == 'Entrada'
                    ? (producto['stock'] ?? 0) + cantidad
                    : (producto['stock'] ?? 0) - cantidad;
                await _db.actualizarProducto(
                    productoSeleccionado!, {'stock': nuevoStock});
                Navigator.pop(ctx);
                _cargarDatos();
              },
              child: const Text('Registrar',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String l, int i, bool isDark) {
    final sel = _tabActual == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabActual = i),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              l,
              style: TextStyle(
                color: sel ? Colors.white : AppColors.subtext(isDark),
                fontSize: 12,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovimientos(bool isDark) {
    if (_movimientos.isEmpty) {
      return Center(
          child: Text('No hay movimientos',
              style: TextStyle(color: AppColors.subtext(isDark))));
    }
    return ListView.builder(
      itemCount: _movimientos.length,
      itemBuilder: (_, i) {
        final m = _movimientos[i];
        final esEntrada = m['tipo'] == 'Entrada';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: esEntrada
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                esEntrada
                    ? Icons.add_circle_outline
                    : Icons.remove_circle_outline,
                color: esEntrada ? AppColors.success : AppColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['producto_nombre'] ?? '',
                      style: TextStyle(
                          color: AppColors.text(isDark),
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(m['motivo'] ?? m['tipo'],
                      style: TextStyle(
                          color: AppColors.subtext(isDark), fontSize: 11)),
                ],
              ),
            ),
            Text(
              '${esEntrada ? '+' : '-'}${m['cantidad']}',
              style: TextStyle(
                color: esEntrada ? AppColors.success : AppColors.warning,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildStock(bool isDark) {
    if (_productos.isEmpty) {
      return Center(
          child: Text('No hay productos',
              style: TextStyle(color: AppColors.subtext(isDark))));
    }
    return ListView.builder(
      itemCount: _productos.length,
      itemBuilder: (_, i) {
        final prod = _productos[i];
        final stock = prod['stock'] ?? 0;
        final stockMin = prod['stock_minimo'] ?? 5;
        final sc = stock == 0
            ? AppColors.danger
            : stock < stockMin
                ? AppColors.warning
                : AppColors.success;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prod['nombre'] ?? '',
                      style: TextStyle(
                          color: AppColors.text(isDark),
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text('Codigo: ${prod['codigo_barras']}',
                      style: TextStyle(
                          color: AppColors.subtext(isDark), fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sc.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Stock: $stock',
                  style: TextStyle(
                      color: sc, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('INVENTARIO',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(children: [
                  _tab('Movimientos', 0, isDark),
                  _tab('Stock', 1, isDark),
                ]),
              ),
              const SizedBox(height: 16),
              if (_cargando)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)))
              else
                Expanded(
                    child: _tabActual == 0
                        ? _buildMovimientos(isDark)
                        : _buildStock(isDark)),
              if (_tabActual == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _registrarMovimiento('Entrada'),
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.white),
                        label: const Text('Entrada',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _registrarMovimiento('Salida'),
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.white),
                        label: const Text('Salida',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// TIENDA SINTHETIX
// ============================================
class UniversalFlyCartStore extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  const UniversalFlyCartStore({super.key, required this.onAbrirSidebar});
  @override
  _UniversalFlyCartStoreState createState() => _UniversalFlyCartStoreState();
}

class _UniversalFlyCartStoreState extends State<UniversalFlyCartStore> {
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _categorias = [];
  bool _cargando = true;
  String _categoriaSeleccionada = 'Todas';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final productosResponse = await Supabase.instance.client
          .from('productos')
          .select()
          .eq('activo', true)
          .order('nombre');
      _productos = List<Map<String, dynamic>>.from(productosResponse as List);

      final categoriasResponse = await Supabase.instance.client
          .from('categorias')
          .select()
          .order('nombre');
      _categorias = List<Map<String, dynamic>>.from(categoriasResponse as List);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('productos_local', jsonEncode(_productos));
      await prefs.setString('categorias_local', jsonEncode(_categorias));
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final productosData = prefs.getString('productos_local');
      final categoriasData = prefs.getString('categorias_local');
      if (productosData != null) {
        _productos = List<Map<String, dynamic>>.from(jsonDecode(productosData));
      } else {
        _productos = [];
      }
      if (categoriasData != null) {
        _categorias =
            List<Map<String, dynamic>>.from(jsonDecode(categoriasData));
      } else {
        _categorias = [];
      }
    }
    setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = false;
    final productosFiltrados = _categoriaSeleccionada == 'Todas'
        ? _productos
        : _productos
            .where((p) => p['categoria'] == _categoriaSeleccionada)
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('TIENDA SINTHETIX',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : Column(children: [
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categorias.length + 1,
                    itemBuilder: (_, i) {
                      final nombre =
                          i == 0 ? 'Todas' : _categorias[i - 1]['nombre'] ?? '';
                      final sel = _categoriaSeleccionada == nombre;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _categoriaSeleccionada = nombre),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary
                                : AppColors.card(isDark),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.divider(isDark),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            nombre,
                            style: TextStyle(
                              color:
                                  sel ? Colors.white : AppColors.text(isDark),
                              fontSize: 13,
                              fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: productosFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storefront,
                                  size: 60, color: AppColors.subtext(isDark)),
                              const SizedBox(height: 16),
                              Text('No hay productos en esta categoría',
                                  style: TextStyle(
                                      color: AppColors.subtext(isDark))),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: productosFiltrados.length,
                          itemBuilder: (_, i) {
                            final prod = productosFiltrados[i];
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.card(isDark),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: AppColors.divider(isDark),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ImagenProducto(
                                        imagenUrl:
                                            prod['imagen_url']?.toString(),
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(prod['nombre'] ?? '',
                                              style: TextStyle(
                                                  color: AppColors.text(isDark),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${(prod['precio'] as num).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ]),
      ),
    );
  }
}

// ============================================
// PANTALLA DE PROVEEDORES
// ============================================
class ProveedoresScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const ProveedoresScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  List<Map<String, dynamic>> _proveedores = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarProveedores();
  }

  Future<void> _cargarProveedores() async {
    setState(() => _cargando = true);
    try {
      final response = await Supabase.instance.client
          .from('proveedores')
          .select()
          .order('nombre');
      _proveedores = List<Map<String, dynamic>>.from(response as List);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('proveedores_local', jsonEncode(_proveedores));
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('proveedores_local');
      if (data != null) {
        _proveedores = List<Map<String, dynamic>>.from(jsonDecode(data));
      } else {
        _proveedores = [];
      }
    }
    setState(() => _cargando = false);
  }

  void _mostrarDialogo({Map<String, dynamic>? proveedor}) {
    final isDark = widget.modoOscuro;
    final nombreCtrl = TextEditingController(text: proveedor?['nombre'] ?? '');
    final contactoCtrl =
        TextEditingController(text: proveedor?['contacto'] ?? '');
    final telefonoCtrl =
        TextEditingController(text: proveedor?['telefono'] ?? '');
    final emailCtrl = TextEditingController(text: proveedor?['email'] ?? '');
    final direccionCtrl =
        TextEditingController(text: proveedor?['direccion'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          proveedor != null ? 'Editar Proveedor' : 'Nuevo Proveedor',
          style: TextStyle(
              color: AppColors.text(isDark), fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                decoration: InputDecoration(
                  labelText: 'Nombre *',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contactoCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                decoration: InputDecoration(
                  labelText: 'Contacto',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: telefonoCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: direccionCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: AppColors.subtext(isDark))),
          ),
          TextButton(
            onPressed: () async {
              if (nombreCtrl.text.isEmpty) return;
              final data = {
                'nombre': nombreCtrl.text,
                'contacto': contactoCtrl.text,
                'telefono': telefonoCtrl.text,
                'email': emailCtrl.text,
                'direccion': direccionCtrl.text,
              };
              try {
                if (proveedor != null) {
                  await Supabase.instance.client
                      .from('proveedores')
                      .update(data)
                      .eq('id', proveedor['id']);
                } else {
                  await Supabase.instance.client
                      .from('proveedores')
                      .insert(data);
                }
              } catch (e) {
                final prefs = await SharedPreferences.getInstance();
                final proveedores = _proveedores;
                if (proveedor != null) {
                  final index = proveedores.indexWhere(
                      (p) => p['id'].toString() == proveedor['id'].toString());
                  if (index >= 0) {
                    proveedores[index] = {...proveedores[index], ...data};
                  }
                } else {
                  data['id'] = DateTime.now().millisecondsSinceEpoch.toString();
                  proveedores.add(data);
                }
                await prefs.setString(
                    'proveedores_local', jsonEncode(proveedores));
              }
              Navigator.pop(ctx);
              _cargarProveedores();
            },
            child: const Text('Guardar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('PROVEEDORES',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_cargando)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)))
              else if (_proveedores.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            size: 60, color: AppColors.subtext(isDark)),
                        const SizedBox(height: 16),
                        Text('No hay proveedores registrados',
                            style: TextStyle(
                                color: AppColors.subtext(isDark),
                                fontSize: 14)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _proveedores.length,
                    itemBuilder: (_, i) {
                      final proveedor = _proveedores[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.local_shipping,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(proveedor['nombre'] ?? '',
                                    style: TextStyle(
                                        color: AppColors.text(isDark),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                if (proveedor['telefono'] != null &&
                                    proveedor['telefono'].toString().isNotEmpty)
                                  Text(proveedor['telefono'].toString(),
                                      style: TextStyle(
                                          color: AppColors.subtext(isDark),
                                          fontSize: 11)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_rounded,
                                color: AppColors.subtext(isDark), size: 18),
                            onPressed: () =>
                                _mostrarDialogo(proveedor: proveedor),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: AppColors.danger.withValues(alpha: 0.7),
                                size: 18),
                            onPressed: () async {
                              try {
                                await Supabase.instance.client
                                    .from('proveedores')
                                    .delete()
                                    .eq('id', proveedor['id']);
                              } catch (e) {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                _proveedores.removeWhere((p) =>
                                    p['id'].toString() ==
                                    proveedor['id'].toString());
                                await prefs.setString('proveedores_local',
                                    jsonEncode(_proveedores));
                              }
                              _cargarProveedores();
                            },
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogo(),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text('AGREGAR PROVEEDOR',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// PANTALLA DE PROMOCIONES
// ============================================
class PromocionesScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const PromocionesScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<PromocionesScreen> createState() => _PromocionesScreenState();
}

class _PromocionesScreenState extends State<PromocionesScreen> {
  List<Map<String, dynamic>> _promociones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPromociones();
  }

  Future<void> _cargarPromociones() async {
    setState(() => _cargando = true);
    try {
      final response = await Supabase.instance.client
          .from('promociones')
          .select()
          .order('nombre');
      _promociones = List<Map<String, dynamic>>.from(response as List);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('promociones_local', jsonEncode(_promociones));
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('promociones_local');
      if (data != null) {
        _promociones = List<Map<String, dynamic>>.from(jsonDecode(data));
      } else {
        _promociones = [];
      }
    }
    setState(() => _cargando = false);
  }

  void _mostrarDialogo({Map<String, dynamic>? promocion}) {
    final isDark = widget.modoOscuro;
    final nombreCtrl = TextEditingController(text: promocion?['nombre'] ?? '');
    final valorCtrl =
        TextEditingController(text: promocion?['valor']?.toString() ?? '');
    String tipo = promocion?['tipo'] ?? 'porcentaje';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            promocion != null ? 'Editar Promoción' : 'Nueva Promoción',
            style: TextStyle(
                color: AppColors.text(isDark), fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                decoration: InputDecoration(
                  labelText: 'Nombre *',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.divider(isDark),
                    width: 1,
                  ),
                ),
                child: Row(children: [
                  Text('Tipo: ',
                      style: TextStyle(color: AppColors.text(isDark))),
                  const Spacer(),
                  DropdownButton<String>(
                    value: tipo,
                    dropdownColor: AppColors.card(isDark),
                    style: TextStyle(color: AppColors.text(isDark)),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                          value: 'porcentaje', child: Text('Porcentaje')),
                      DropdownMenuItem(
                          value: 'monto_fijo', child: Text('Monto Fijo')),
                      DropdownMenuItem(value: '2x1', child: Text('2x1')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => tipo = v ?? 'porcentaje'),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: valorCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: tipo == '2x1' ? 'Valor (opcional)' : 'Valor *',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar',
                    style: TextStyle(color: AppColors.subtext(isDark)))),
            TextButton(
              onPressed: () async {
                if (nombreCtrl.text.isEmpty) return;
                final data = {
                  'nombre': nombreCtrl.text,
                  'tipo': tipo,
                  'valor': double.tryParse(valorCtrl.text) ?? 0,
                  'activo': true,
                };
                try {
                  if (promocion != null) {
                    await Supabase.instance.client
                        .from('promociones')
                        .update(data)
                        .eq('id', promocion['id']);
                  } else {
                    await Supabase.instance.client
                        .from('promociones')
                        .insert(data);
                  }
                } catch (e) {
                  final prefs = await SharedPreferences.getInstance();
                  final promociones = _promociones;
                  if (promocion != null) {
                    final index = promociones.indexWhere((p) =>
                        p['id'].toString() == promocion['id'].toString());
                    if (index >= 0) {
                      promociones[index] = {...promociones[index], ...data};
                    }
                  } else {
                    data['id'] =
                        DateTime.now().millisecondsSinceEpoch.toString();
                    promociones.add(data);
                  }
                  await prefs.setString(
                      'promociones_local', jsonEncode(promociones));
                }
                Navigator.pop(ctx);
                _cargarPromociones();
              },
              child: const Text('Guardar',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('PROMOCIONES',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_cargando)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)))
              else if (_promociones.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 60, color: AppColors.subtext(isDark)),
                        const SizedBox(height: 16),
                        Text('No hay promociones activas',
                            style: TextStyle(
                                color: AppColors.subtext(isDark),
                                fontSize: 14)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _promociones.length,
                    itemBuilder: (_, i) {
                      final promo = _promociones[i];
                      final tipoIcono = promo['tipo'] == 'porcentaje'
                          ? Icons.percent
                          : promo['tipo'] == 'monto_fijo'
                              ? Icons.attach_money
                              : Icons.card_giftcard;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                Icon(tipoIcono, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(promo['nombre'] ?? '',
                                    style: TextStyle(
                                        color: AppColors.text(isDark),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  '${promo['tipo']} - ${promo['valor'] ?? ''}',
                                  style: TextStyle(
                                      color: AppColors.subtext(isDark),
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: promo['activo'] == true,
                            onChanged: (val) async {
                              try {
                                await Supabase.instance.client
                                    .from('promociones')
                                    .update({'activo': val}).eq(
                                        'id', promo['id']);
                              } catch (e) {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final index = _promociones.indexWhere((p) =>
                                    p['id'].toString() ==
                                    promo['id'].toString());
                                if (index >= 0) {
                                  _promociones[index]['activo'] = val;
                                }
                                await prefs.setString('promociones_local',
                                    jsonEncode(_promociones));
                              }
                              _cargarPromociones();
                            },
                            activeThumbColor: AppColors.primary,
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: AppColors.danger.withValues(alpha: 0.7),
                                size: 18),
                            onPressed: () async {
                              try {
                                await Supabase.instance.client
                                    .from('promociones')
                                    .delete()
                                    .eq('id', promo['id']);
                              } catch (e) {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                _promociones.removeWhere((p) =>
                                    p['id'].toString() ==
                                    promo['id'].toString());
                                await prefs.setString('promociones_local',
                                    jsonEncode(_promociones));
                              }
                              _cargarPromociones();
                            },
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogo(),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text('AGREGAR PROMOCIÓN',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// PANTALLA DE COMPRAS
// ============================================
class ComprasScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const ComprasScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  List<Map<String, dynamic>> _compras = [];
  List<Map<String, dynamic>> _proveedores = [];
  List<Map<String, dynamic>> _productos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final comprasResponse = await Supabase.instance.client
          .from('compras')
          .select()
          .order('fecha', ascending: false);
      _compras = List<Map<String, dynamic>>.from(comprasResponse as List);

      final proveedoresResponse = await Supabase.instance.client
          .from('proveedores')
          .select()
          .order('nombre');
      _proveedores =
          List<Map<String, dynamic>>.from(proveedoresResponse as List);

      final productosResponse = await Supabase.instance.client
          .from('productos')
          .select()
          .order('nombre');
      _productos = List<Map<String, dynamic>>.from(productosResponse as List);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('compras_local', jsonEncode(_compras));
      await prefs.setString('proveedores_local', jsonEncode(_proveedores));
      await prefs.setString('productos_local', jsonEncode(_productos));
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final comprasData = prefs.getString('compras_local');
      final proveedoresData = prefs.getString('proveedores_local');
      final productosData = prefs.getString('productos_local');

      if (comprasData != null) {
        _compras = List<Map<String, dynamic>>.from(jsonDecode(comprasData));
      } else {
        _compras = [];
      }
      if (proveedoresData != null) {
        _proveedores =
            List<Map<String, dynamic>>.from(jsonDecode(proveedoresData));
      } else {
        _proveedores = [];
      }
      if (productosData != null) {
        _productos = List<Map<String, dynamic>>.from(jsonDecode(productosData));
      } else {
        _productos = [];
      }
    }
    setState(() => _cargando = false);
  }

  void _mostrarNuevaCompra() {
    final isDark = widget.modoOscuro;
    String? proveedorSeleccionado;
    final numeroFacturaCtrl = TextEditingController();
    List<Map<String, dynamic>> detalles = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Nueva Compra',
              style: TextStyle(
                  color: AppColors.text(isDark), fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: proveedorSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Proveedor *',
                    labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                    filled: true,
                    fillColor: AppColors.background(isDark),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  items: _proveedores
                      .map((p) => DropdownMenuItem(
                            value: p['id'].toString(),
                            child: Text(p['nombre'] ?? '',
                                style:
                                    TextStyle(color: AppColors.text(isDark))),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => proveedorSeleccionado = v),
                  dropdownColor: AppColors.card(isDark),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: numeroFacturaCtrl,
                  style: TextStyle(color: AppColors.text(isDark)),
                  decoration: InputDecoration(
                    labelText: 'Número de Factura',
                    labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                    filled: true,
                    fillColor: AppColors.background(isDark),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Text('AGREGAR PRODUCTOS',
                    style: TextStyle(
                        color: AppColors.subtext(isDark),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                const SizedBox(height: 8),
                ...detalles.map((d) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background(isDark),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Text(d['nombre'] ?? '',
                              style: TextStyle(
                                  color: AppColors.text(isDark), fontSize: 12)),
                        ),
                        Text('x${d['cantidad']}',
                            style: TextStyle(
                                color: AppColors.subtext(isDark),
                                fontSize: 12)),
                        const SizedBox(width: 8),
                        Text(
                            '\$${((d['costo_unitario'] ?? 0) as num).toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: AppColors.primary, fontSize: 12)),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: AppColors.danger.withValues(alpha: 0.7),
                              size: 16),
                          onPressed: () {
                            setDialogState(() => detalles.remove(d));
                          },
                        ),
                      ]),
                    )),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final resultado = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (dialogCtx) => _SelectorProductoCompra(
                        productos: _productos,
                        isDark: isDark,
                      ),
                    );
                    if (resultado != null) {
                      setDialogState(() {
                        detalles.add(resultado);
                      });
                    }
                  },
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text('Agregar Producto',
                      style: TextStyle(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar',
                    style: TextStyle(color: AppColors.subtext(isDark)))),
            TextButton(
              onPressed: () async {
                if (proveedorSeleccionado == null || detalles.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Selecciona proveedor y agrega productos'),
                        backgroundColor: AppColors.warning),
                  );
                  return;
                }
                final total = detalles.fold<double>(
                    0,
                    (sum, d) =>
                        sum +
                        ((d['costo_unitario'] as num).toDouble() *
                            (d['cantidad'] as int)));
                final compra = {
                  'proveedor_id': int.tryParse(proveedorSeleccionado!),
                  'numero_factura': numeroFacturaCtrl.text,
                  'total': total,
                  'subtotal': total,
                  'impuesto': 0,
                  'estado': 'recibida',
                  'fecha': DateTime.now().toIso8601String(),
                };
                try {
                  final response = await Supabase.instance.client
                      .from('compras')
                      .insert(compra)
                      .select()
                      .single();
                  final compraId = (response as Map<String, dynamic>)['id'];
                  for (final d in detalles) {
                    await Supabase.instance.client
                        .from('detalle_compra')
                        .insert({
                      'compra_id': compraId,
                      'producto_id': d['producto_id'],
                      'codigo_barras': d['codigo_barras'],
                      'nombre': d['nombre'],
                      'cantidad': d['cantidad'],
                      'costo_unitario': d['costo_unitario'],
                      'subtotal': (d['costo_unitario'] as num).toDouble() *
                          (d['cantidad'] as int),
                    });
                    final producto = _productos.firstWhere((p) =>
                        p['id'].toString() == d['producto_id'].toString());
                    final nuevoStock =
                        (producto['stock'] ?? 0) + (d['cantidad'] as int);
                    await Supabase.instance.client.from('productos').update(
                        {'stock': nuevoStock}).eq('id', d['producto_id']);
                  }
                } catch (e) {
                  final prefs = await SharedPreferences.getInstance();
                  compra['id'] =
                      DateTime.now().millisecondsSinceEpoch.toString();
                  _compras.insert(0, compra);
                  await prefs.setString('compras_local', jsonEncode(_compras));

                  for (final d in detalles) {
                    final producto = _productos.firstWhere((p) =>
                        p['id'].toString() == d['producto_id'].toString());
                    final nuevoStock =
                        (producto['stock'] ?? 0) + (d['cantidad'] as int);
                    producto['stock'] = nuevoStock;
                  }
                  await prefs.setString(
                      'productos_local', jsonEncode(_productos));
                }
                Navigator.pop(ctx);
                _cargarDatos();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Compra registrada con éxito'),
                      backgroundColor: AppColors.success),
                );
              },
              child: const Text('Guardar',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('COMPRAS',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_cargando)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)))
              else if (_compras.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_checkout,
                            size: 60, color: AppColors.subtext(isDark)),
                        const SizedBox(height: 16),
                        Text('No hay compras registradas',
                            style: TextStyle(
                                color: AppColors.subtext(isDark),
                                fontSize: 14)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _compras.length,
                    itemBuilder: (_, i) {
                      final compra = _compras[i];
                      final proveedor = _proveedores.firstWhere(
                        (p) =>
                            p['id'].toString() ==
                            compra['proveedor_id']?.toString(),
                        orElse: () => {'nombre': 'Proveedor desconocido'},
                      );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shopping_cart_checkout,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(proveedor['nombre'] ?? 'Proveedor',
                                    style: TextStyle(
                                        color: AppColors.text(isDark),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  compra['fecha']
                                          ?.toString()
                                          .substring(0, 10) ??
                                      '',
                                  style: TextStyle(
                                      color: AppColors.subtext(isDark),
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${((compra['total'] ?? 0) as num).toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _mostrarNuevaCompra,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text('REGISTRAR COMPRA',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Selector de producto para compras
class _SelectorProductoCompra extends StatefulWidget {
  final List<Map<String, dynamic>> productos;
  final bool isDark;
  const _SelectorProductoCompra(
      {required this.productos, required this.isDark});

  @override
  State<_SelectorProductoCompra> createState() =>
      _SelectorProductoCompraState();
}

class _SelectorProductoCompraState extends State<_SelectorProductoCompra> {
  String _busqueda = '';
  int _cantidad = 1;
  double _costo = 0;

  @override
  Widget build(BuildContext context) {
    final filtrados = widget.productos.where((p) {
      final nombre = (p['nombre'] ?? '').toString().toLowerCase();
      final codigo = (p['codigo_barras'] ?? '').toString().toLowerCase();
      return nombre.contains(_busqueda.toLowerCase()) ||
          codigo.contains(_busqueda.toLowerCase());
    }).toList();

    return AlertDialog(
      backgroundColor: AppColors.card(widget.isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Seleccionar Producto',
          style: TextStyle(
              color: AppColors.text(widget.isDark),
              fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(children: [
          TextField(
            style: TextStyle(color: AppColors.text(widget.isDark)),
            onChanged: (v) => setState(() => _busqueda = v),
            decoration: InputDecoration(
              hintText: 'Buscar...',
              hintStyle: TextStyle(color: AppColors.subtext(widget.isDark)),
              prefixIcon:
                  Icon(Icons.search, color: AppColors.subtext(widget.isDark)),
              filled: true,
              fillColor: AppColors.background(widget.isDark),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: filtrados.length,
              itemBuilder: (_, i) {
                final prod = filtrados[i];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2,
                        color: AppColors.primary, size: 20),
                  ),
                  title: Text(prod['nombre'] ?? '',
                      style: TextStyle(
                          color: AppColors.text(widget.isDark),
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      'Stock: ${prod['stock'] ?? 0} | Costo: \$${prod['costo'] ?? 0}',
                      style: TextStyle(
                          color: AppColors.subtext(widget.isDark),
                          fontSize: 11)),
                  onTap: () {
                    setState(() {
                      _costo = (prod['costo'] as num?)?.toDouble() ?? 0;
                    });
                    Navigator.pop(context, {
                      'producto_id': prod['id'],
                      'codigo_barras': prod['codigo_barras'],
                      'nombre': prod['nombre'],
                      'cantidad': _cantidad,
                      'costo_unitario': _costo,
                    });
                  },
                );
              },
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(color: AppColors.subtext(widget.isDark)))),
      ],
    );
  }
}

// ============================================
// PANTALLA DE USUARIOS Y ROLES
// ============================================
class RolesScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const RolesScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  List<Map<String, dynamic>> _usuarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    try {
      final response = await Supabase.instance.client
          .from('usuarios')
          .select()
          .order('nombre');
      _usuarios = List<Map<String, dynamic>>.from(response as List);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('usuarios_local', jsonEncode(_usuarios));
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('usuarios_local');
      if (data != null) {
        _usuarios = List<Map<String, dynamic>>.from(jsonDecode(data));
      } else {
        _usuarios = [];
      }
    }
    setState(() => _cargando = false);
  }

  void _mostrarDialogo({Map<String, dynamic>? usuario}) {
    final isDark = widget.modoOscuro;
    final nombreCtrl = TextEditingController(text: usuario?['nombre'] ?? '');
    final emailCtrl = TextEditingController(text: usuario?['email'] ?? '');
    final passwordCtrl = TextEditingController();
    String rol = usuario?['rol'] ?? 'vendedor';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            usuario != null ? 'Editar Usuario' : 'Nuevo Usuario',
            style: TextStyle(
                color: AppColors.text(isDark), fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                decoration: InputDecoration(
                  labelText: 'Nombre *',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email *',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                obscureText: true,
                decoration: InputDecoration(
                  labelText:
                      usuario != null ? 'Nueva Contraseña' : 'Contraseña *',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.divider(isDark),
                    width: 1,
                  ),
                ),
                child: Row(children: [
                  Text('Rol: ',
                      style: TextStyle(color: AppColors.text(isDark))),
                  const Spacer(),
                  DropdownButton<String>(
                    value: rol,
                    dropdownColor: AppColors.card(isDark),
                    style: TextStyle(color: AppColors.text(isDark)),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                          value: 'admin', child: Text('Administrador')),
                      DropdownMenuItem(
                          value: 'vendedor', child: Text('Vendedor')),
                      DropdownMenuItem(value: 'cajero', child: Text('Cajero')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => rol = v ?? 'vendedor'),
                  ),
                ]),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar',
                    style: TextStyle(color: AppColors.subtext(isDark)))),
            TextButton(
              onPressed: () async {
                if (nombreCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
                if (usuario == null && passwordCtrl.text.isEmpty) return;

                final data = {
                  'nombre': nombreCtrl.text,
                  'email': emailCtrl.text,
                  'rol': rol,
                  'activo': true,
                };

                if (passwordCtrl.text.isNotEmpty) {
                  data['password_hash'] = passwordCtrl.text;
                }

                try {
                  if (usuario != null) {
                    await Supabase.instance.client
                        .from('usuarios')
                        .update(data)
                        .eq('id', usuario['id']);
                  } else {
                    await Supabase.instance.client
                        .from('usuarios')
                        .insert(data);
                  }
                } catch (e) {
                  final prefs = await SharedPreferences.getInstance();
                  if (usuario != null) {
                    final index = _usuarios.indexWhere(
                        (u) => u['id'].toString() == usuario['id'].toString());
                    if (index >= 0) {
                      _usuarios[index] = {..._usuarios[index], ...data};
                    }
                  } else {
                    data['id'] =
                        DateTime.now().millisecondsSinceEpoch.toString();
                    _usuarios.add(data);
                  }
                  await prefs.setString(
                      'usuarios_local', jsonEncode(_usuarios));
                }
                Navigator.pop(ctx);
                _cargarUsuarios();
              },
              child: const Text('Guardar',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(children: [
          GestureDetector(
            onTap: widget.onAbrirSidebar,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('USUARIOS Y ROLES',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_cargando)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)))
              else if (_usuarios.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 60, color: AppColors.subtext(isDark)),
                        const SizedBox(height: 16),
                        Text('No hay usuarios registrados',
                            style: TextStyle(
                                color: AppColors.subtext(isDark),
                                fontSize: 14)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _usuarios.length,
                    itemBuilder: (_, i) {
                      final usuario = _usuarios[i];
                      final rolColor = usuario['rol'] == 'admin'
                          ? AppColors.danger
                          : usuario['rol'] == 'vendedor'
                              ? AppColors.primary
                              : AppColors.warning;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: rolColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              usuario['rol'] == 'admin'
                                  ? Icons.admin_panel_settings
                                  : usuario['rol'] == 'vendedor'
                                      ? Icons.person
                                      : Icons.point_of_sale,
                              color: rolColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(usuario['nombre'] ?? '',
                                    style: TextStyle(
                                        color: AppColors.text(isDark),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                Text(usuario['email'] ?? '',
                                    style: TextStyle(
                                        color: AppColors.subtext(isDark),
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: rolColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (usuario['rol'] ?? 'vendedor')
                                  .toString()
                                  .toUpperCase(),
                              style: TextStyle(
                                  color: rolColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_rounded,
                                color: AppColors.subtext(isDark), size: 18),
                            onPressed: () => _mostrarDialogo(usuario: usuario),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: AppColors.danger.withValues(alpha: 0.7),
                                size: 18),
                            onPressed: () async {
                              try {
                                await Supabase.instance.client
                                    .from('usuarios')
                                    .delete()
                                    .eq('id', usuario['id']);
                              } catch (e) {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                _usuarios.removeWhere((u) =>
                                    u['id'].toString() ==
                                    usuario['id'].toString());
                                await prefs.setString(
                                    'usuarios_local', jsonEncode(_usuarios));
                              }
                              _cargarUsuarios();
                            },
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogo(),
                  icon:
                      const Icon(Icons.person_add_rounded, color: Colors.white),
                  label: const Text('AGREGAR USUARIO',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
