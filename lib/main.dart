import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Map<String, double> tasasCambio = {'USD': 1.0, 'COP': 4500.0, 'VES': 60.0};
Map<String, String> simbolosMoneda = {'USD': '\$', 'COP': '\$', 'VES': 'Bs.'};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  tasasCambio['COP'] = prefs.getDouble('tasa_cop') ?? 4500.0;
  tasasCambio['VES'] = prefs.getDouble('tasa_ves') ?? 60.0;
  runApp(const MiApp());
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
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('productos_local');
    if (data != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    }
    return [];
  }

  Future<Map<String, dynamic>?> crearProducto(Map<String, dynamic> prod) async {
    final prefs = await SharedPreferences.getInstance();
    final productos = await getProductos();
    prod['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    prod['creado_en'] = DateTime.now().toIso8601String();
    productos.add(prod);
    await prefs.setString('productos_local', jsonEncode(productos));
    return prod;
  }

  Future<Map<String, dynamic>?> actualizarProducto(
      String id, Map<String, dynamic> prod) async {
    final prefs = await SharedPreferences.getInstance();
    final productos = await getProductos();
    final index = productos.indexWhere((p) => p['id'] == id);
    if (index >= 0) {
      productos[index] = {...productos[index], ...prod};
      await prefs.setString('productos_local', jsonEncode(productos));
    }
    return prod;
  }

  Future<void> eliminarProducto(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final productos = await getProductos();
    productos.removeWhere((p) => p['id'] == id);
    await prefs.setString('productos_local', jsonEncode(productos));
  }

  Future<Map<String, dynamic>?> buscarPorCodigo(String codigo) async {
    final productos = await getProductos();
    for (var p in productos) {
      if (p['codigo_barras'] == codigo) return p;
    }
    return null;
  }

  Future<Map<String, dynamic>?> crearVenta(Map<String, dynamic> venta) async {
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

  Future<void> crearDetalleVenta(Map<String, dynamic> detalle) async {}

  Future<List<Map<String, dynamic>>> getVentasHoy() async {
    final prefs = await SharedPreferences.getInstance();
    final ventasData = prefs.getString('ventas_local');
    if (ventasData != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(ventasData));
    }
    return [];
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
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('clientes_local');
    if (data != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    }
    return [];
  }

  Future<void> crearCliente(Map<String, dynamic> cliente) async {
    final prefs = await SharedPreferences.getInstance();
    final clientes = await getClientes();
    cliente['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    clientes.add(cliente);
    await prefs.setString('clientes_local', jsonEncode(clientes));
  }

  Future<void> actualizarCliente(
      String id, Map<String, dynamic> cliente) async {
    final prefs = await SharedPreferences.getInstance();
    final clientes = await getClientes();
    final index = clientes.indexWhere((c) => c['id'] == id);
    if (index >= 0) {
      clientes[index] = {...clientes[index], ...cliente};
      await prefs.setString('clientes_local', jsonEncode(clientes));
    }
  }

  Future<void> eliminarCliente(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final clientes = await getClientes();
    clientes.removeWhere((c) => c['id'] == id);
    await prefs.setString('clientes_local', jsonEncode(clientes));
  }

  Future<List<Map<String, dynamic>>> getCategorias() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('categorias_local');
    if (data != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    }
    return [
      {
        'id': '1',
        'nombre': 'General',
        'descripcion': 'Categoria general',
        'activo': 1
      }
    ];
  }

  Future<void> crearCategoria(Map<String, dynamic> categoria) async {
    final prefs = await SharedPreferences.getInstance();
    final categorias = await getCategorias();
    categoria['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    categorias.add(categoria);
    await prefs.setString('categorias_local', jsonEncode(categorias));
  }

  Future<void> actualizarCategoria(
      String id, Map<String, dynamic> categoria) async {
    final prefs = await SharedPreferences.getInstance();
    final categorias = await getCategorias();
    final index = categorias.indexWhere((c) => c['id'] == id);
    if (index >= 0) {
      categorias[index] = {...categorias[index], ...categoria};
      await prefs.setString('categorias_local', jsonEncode(categorias));
    }
  }

  Future<void> eliminarCategoria(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final categorias = await getCategorias();
    categorias.removeWhere((c) => c['id'] == id);
    await prefs.setString('categorias_local', jsonEncode(categorias));
  }

  Future<List<Map<String, dynamic>>> getMetodosPago() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('metodos_pago_local');
    if (data != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    }
    return [
      {'id': '1', 'nombre': 'Efectivo', 'activo': 1},
      {'id': '2', 'nombre': 'Tarjeta', 'activo': 1},
      {'id': '3', 'nombre': 'Transferencia', 'activo': 1},
      {'id': '4', 'nombre': 'Pago Movil', 'activo': 1},
    ];
  }

  Future<void> crearMetodoPago(Map<String, dynamic> metodo) async {
    final prefs = await SharedPreferences.getInstance();
    final metodos = await getMetodosPago();
    metodo['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    metodos.add(metodo);
    await prefs.setString('metodos_pago_local', jsonEncode(metodos));
  }

  Future<void> actualizarMetodoPago(
      String id, Map<String, dynamic> metodo) async {
    final prefs = await SharedPreferences.getInstance();
    final metodos = await getMetodosPago();
    final index = metodos.indexWhere((m) => m['id'] == id);
    if (index >= 0) {
      metodos[index] = {...metodos[index], ...metodo};
      await prefs.setString('metodos_pago_local', jsonEncode(metodos));
    }
  }

  Future<void> eliminarMetodoPago(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final metodos = await getMetodosPago();
    metodos.removeWhere((m) => m['id'] == id);
    await prefs.setString('metodos_pago_local', jsonEncode(metodos));
  }

  Future<List<Map<String, dynamic>>> getVendedores() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('vendedores_local');
    if (data != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    }
    return [];
  }

  Future<void> crearVendedor(Map<String, dynamic> vendedor) async {
    final prefs = await SharedPreferences.getInstance();
    final vendedores = await getVendedores();
    vendedor['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    vendedores.add(vendedor);
    await prefs.setString('vendedores_local', jsonEncode(vendedores));
  }

  Future<void> actualizarVendedor(
      String id, Map<String, dynamic> vendedor) async {
    final prefs = await SharedPreferences.getInstance();
    final vendedores = await getVendedores();
    final index = vendedores.indexWhere((v) => v['id'] == id);
    if (index >= 0) {
      vendedores[index] = {...vendedores[index], ...vendedor};
      await prefs.setString('vendedores_local', jsonEncode(vendedores));
    }
  }

  Future<void> eliminarVendedor(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final vendedores = await getVendedores();
    vendedores.removeWhere((v) => v['id'] == id);
    await prefs.setString('vendedores_local', jsonEncode(vendedores));
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
  }

  Future<void> registrarMovimientoInventario(Map<String, dynamic> mov) async {
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

  Future<List<Map<String, dynamic>>> getMovimientosInventario() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('movimientos_inventario_local');
    if (data != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    }
    return [];
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
    return {
      'id': '1',
      'email': 'admin@sinthetix.com',
      'nombre': 'Admin',
      'rol': 'admin'
    };
  }

  Future<void> actualizarPerfil(Map<String, dynamic> data) async {}
  Future<void> cambiarPassword(String newPassword) async {}
}

class CajaService {
  final _prefsKey = 'caja_actual';
  final _historialKey = 'caja_historial';

  Future<Map<String, dynamic>?> getCajaAbierta() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefsKey);
    if (data != null) return jsonDecode(data) as Map<String, dynamic>;
    return null;
  }

  Future<void> abrirCaja(double montoInicial) async {
    final prefs = await SharedPreferences.getInstance();
    final caja = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'fecha_apertura': DateTime.now().toIso8601String(),
      'monto_inicial': montoInicial,
      'total_ventas': 0.0,
      'total_ingresos': 0.0,
      'total_egresos': 0.0,
      'estado': 'Abierta',
      'movimientos': []
    };
    await prefs.setString(_prefsKey, jsonEncode(caja));
  }

  Future<void> cerrarCaja(double montoFinal) async {
    final prefs = await SharedPreferences.getInstance();
    final cajaData = prefs.getString(_prefsKey);
    if (cajaData == null) return;
    final caja = jsonDecode(cajaData) as Map<String, dynamic>;
    caja['fecha_cierre'] = DateTime.now().toIso8601String();
    caja['monto_final'] = montoFinal;
    caja['estado'] = 'Cerrada';
    caja['diferencia'] = montoFinal -
        ((caja['monto_inicial'] as num).toDouble() +
            (caja['total_ventas'] as num).toDouble() +
            (caja['total_ingresos'] as num).toDouble() -
            (caja['total_egresos'] as num).toDouble());
    final historial = prefs.getStringList(_historialKey) ?? [];
    historial.add(jsonEncode(caja));
    await prefs.setStringList(_historialKey, historial);
    await prefs.remove(_prefsKey);
  }

  Future<void> agregarVentaACaja(double monto) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefsKey);
    if (data != null) {
      final caja = jsonDecode(data) as Map<String, dynamic>;
      caja['total_ventas'] = (caja['total_ventas'] as num).toDouble() + monto;
      await prefs.setString(_prefsKey, jsonEncode(caja));
    }
  }

  Future<void> registrarMovimiento(
      String tipo, double monto, String descripcion) async {
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
      if (tipo == 'Ingreso') {
        caja['total_ingresos'] =
            (caja['total_ingresos'] as num).toDouble() + monto;
      } else {
        caja['total_egresos'] =
            (caja['total_egresos'] as num).toDouble() + monto;
      }
      await prefs.setString(_prefsKey, jsonEncode(caja));
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
    final prefs = await SharedPreferences.getInstance();
    final historial = prefs.getStringList(_historialKey) ?? [];
    return historial.map((h) => jsonDecode(h) as Map<String, dynamic>).toList()
      ..sort((a, b) => (b['fecha_apertura'] as String)
          .compareTo(a['fecha_apertura'] as String));
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
      'tienda': 13
    };
    setState(() => _currentIndex = m[ruta] ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
          ],
        ),
        bottomNavigationBar: _currentIndex <= 1
            ? BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                backgroundColor:
                    _modoOscuro ? const Color(0xFF1F222B) : Colors.white,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.subtext(_modoOscuro),
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.shopping_cart_outlined), label: 'POS'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
                ],
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
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
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
            child: Text('v5.0.0 - SINTHETIX PRO',
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
  final cameraController = MobileScannerController();
  final _buscador = TextEditingController();
  final _db = DatabaseService();
  final _cajaService = CajaService();
  List<Map<String, dynamic>> carrito = [];
  List<Map<String, dynamic>> listaProductos = [];
  List<Map<String, dynamic>> busqueda = [];
  bool _camara = false;
  bool _mostrarBusqueda = false;
  bool _cargando = true;
  bool _sonando = false;

  void _vibrar() => HapticFeedback.heavyImpact();

  void _sonidoExito() {
    if (_sonando) return;
    _sonando = true;
    SystemSound.play(SystemSoundType.alert);
    _vibrar();
    Future.delayed(const Duration(milliseconds: 800), () {
      _sonando = false;
    });
  }

  String _precio(double pre) {
    final sim = simbolosMoneda['USD'] ?? '\$';
    return '$sim ${pre.toStringAsFixed(2)}';
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
      busqueda.clear();
      _mostrarBusqueda = false;
      _buscador.clear();
      _vibrar();
    });
  }

  void _agregarPorKilo(Map<String, dynamic> prod) {
    final pesoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(widget.modoOscuro),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${prod['nombre']} - Por Kilo',
            style: TextStyle(
                color: AppColors.text(widget.modoOscuro),
                fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Precio por kilo: \$${(prod['precio'] as num).toStringAsFixed(2)}',
                style: TextStyle(color: AppColors.subtext(widget.modoOscuro))),
            const SizedBox(height: 16),
            TextField(
              controller: pesoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: AppColors.text(widget.modoOscuro)),
              decoration: InputDecoration(
                labelText: 'Peso (kg)',
                labelStyle:
                    TextStyle(color: AppColors.subtext(widget.modoOscuro)),
                hintText: 'Ej: 0.5 = medio kilo, 0.25 = 250 gramos',
                hintStyle: TextStyle(
                    color: AppColors.subtext(widget.modoOscuro), fontSize: 11),
                filled: true,
                fillColor: AppColors.background(widget.modoOscuro),
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
                  style:
                      TextStyle(color: AppColors.subtext(widget.modoOscuro)))),
          TextButton(
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
              _vibrar();
            },
            child: const Text('Agregar',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
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

  void _buscar(String q) {
    setState(() {
      if (q.isEmpty) {
        busqueda.clear();
        _mostrarBusqueda = false;
      } else {
        final f = q.toLowerCase();
        busqueda = listaProductos
            .where((prod) =>
                (prod['nombre'] as String).toLowerCase().contains(f) ||
                (prod['codigo_barras'] as String).toLowerCase().contains(f))
            .toList();
        _mostrarBusqueda = busqueda.isNotEmpty;
      }
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
        onVentaCompletada: (m, mt, n, t) => _venta(m, mt, n, t),
        modoOscuro: widget.modoOscuro,
      ),
    );
  }

  Future<void> _venta(
      String metodo, String monto, String nombre, String telefono) async {
    try {
      final fac = DatosPrueba.generarNumeroFactura();
      final venta = {
        'numero_factura': fac,
        'total': total,
        'metodo_pago': metodo,
        'moneda': 'USD',
        'cliente_nombre': nombre.isNotEmpty ? nombre : 'Publico General',
        'cliente_telefono': telefono,
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
        setState(() => carrito.clear());
        Navigator.pop(context);
        _snack('Venta exitosa - $fac', AppColors.success);
      }
    } catch (e) {
      _snack('Error: $e', AppColors.danger);
    }
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
    super.dispose();
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
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
              Text('SINTHETIX POS',
                  style: TextStyle(
                      color: AppColors.text(isDark),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5)),
              Text('${listaProductos.length} productos',
                  style: TextStyle(
                      color: AppColors.subtext(isDark),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
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
              _snack('Actualizado', AppColors.primary);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          _buildSearchBar(isDark),
          if (_mostrarBusqueda && busqueda.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.card(isDark),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: busqueda.length,
                itemBuilder: (_, i) {
                  final prod = busqueda[i];
                  return ListTile(
                    leading: GestureDetector(
                      onTap: () => _verFotoGrande(prod),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ImagenProducto(
                          imagenUrl: prod['imagen_url']?.toString(),
                          width: 45,
                          height: 45,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(prod['nombre'] ?? '',
                        style: TextStyle(
                            color: AppColors.text(isDark),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        prod['tipo'] == 'kilo'
                            ? '\$${(prod['precio'] as num).toStringAsFixed(2)}/kg'
                            : '\$${(prod['precio'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    trailing: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 22),
                    ),
                    onTap: () => _agregar(prod),
                  );
                },
              ),
            ),
          if (_camara)
            Container(
              height: 220,
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
                      onDetect: (cap) async {
                        if (_sonando) return;
                        if (cap.barcodes.isEmpty) return;
                        final barcode = cap.barcodes.first;
                        if (barcode.rawValue != null &&
                            barcode.rawValue!.isNotEmpty) {
                          final prod =
                              await _db.buscarPorCodigo(barcode.rawValue!);
                          if (prod != null) {
                            _agregar(prod);
                            _sonidoExito();
                            _snack('${prod['nombre']} agregado',
                                AppColors.success);
                            setState(() => _camara = false);
                          } else {
                            _snack(
                                'Producto no encontrado: ${barcode.rawValue}',
                                AppColors.danger);
                          }
                        }
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
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.1),
                            AppColors.secondary.withValues(alpha: 0.1),
                          ],
                        ),
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
          if (!_cargando && !_mostrarBusqueda && listaProductos.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: listaProductos.length,
                itemBuilder: (_, i) =>
                    _buildProductCard(listaProductos[i], isDark),
              ),
            ),
          if (carrito.isNotEmpty) _buildCartPreview(isDark),
        ]),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required VoidCallback onTap,
      required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 8,
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
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                fontSize: 15,
                fontWeight: FontWeight.w500),
            onChanged: _buscar,
            decoration: InputDecoration(
              hintText: 'Buscar producto o escanear...',
              hintStyle:
                  TextStyle(color: AppColors.subtext(isDark), fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.secondary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded,
                color: AppColors.primary, size: 22),
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
    final stockColor = stock == 0
        ? AppColors.danger
        : stock < 5
            ? AppColors.warning
            : AppColors.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(children: [
          GestureDetector(
            onTap: () => _verFotoGrande(prod),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05),
                    AppColors.secondary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ImagenProducto(
                imagenUrl: prod['imagen_url']?.toString(),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _agregar(prod),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prod['nombre'] ?? '',
                        style: TextStyle(
                            color: AppColors.text(isDark),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                            prod['tipo'] == 'kilo'
                                ? '\$${(prod['precio'] as num).toStringAsFixed(2)}/kg'
                                : '\$${(prod['precio'] as num).toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: stockColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          stock == 0 ? 'Agotado' : 'Stock: $stock',
                          style: TextStyle(
                              color: stockColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () => _agregar(prod),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCartPreview(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: carrito.length,
            itemBuilder: (_, i) {
              final item = carrito[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['tipo'] == 'kilo'
                            ? '${item['nombre']} (${item['peso']}kg)'
                            : item['nombre'],
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (item['cantidad'] > 1) {
                            item['cantidad'] -= 1;
                          } else {
                            carrito.removeAt(i);
                          }
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.remove,
                            color: AppColors.primary, size: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('${item['cantidad']}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          item['cantidad'] += 1;
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add,
                            color: AppColors.primary, size: 14),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: _cobrar,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('COBRAR',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PantallaCobro extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final double total;
  final String Function(double) formatearPrecio;
  final Function(String, String, String, String) onVentaCompletada;
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
  String _clienteSel = '';
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _metodosPago = [];
  bool _cargandoMetodos = true;

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
          {'id': '1', 'nombre': 'Efectivo'},
          {'id': '2', 'nombre': 'Tarjeta'},
          {'id': '3', 'nombre': 'Transferencia'},
          {'id': '4', 'nombre': 'Pago Movil'},
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

  double _totalEnMoneda() {
    final tasa = tasasCambio[_moneda] ?? 1.0;
    return widget.total * tasa;
  }

  double _vuelto() {
    if (_montoCtrl.text.isEmpty) return 0;
    final m = double.tryParse(_montoCtrl.text) ?? 0;
    return m - _totalEnMoneda();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.subtext(isDark),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('COBRAR',
                  style: TextStyle(
                      color: AppColors.text(isDark),
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              IconButton(
                icon: Icon(Icons.close_rounded, color: AppColors.text(isDark)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: ['USD', 'COP', 'VES'].map((moneda) {
              final sel = _moneda == moneda;
              return GestureDetector(
                onTap: () => setState(() => _moneda = moneda),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color:
                        sel ? AppColors.primary : AppColors.background(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel
                            ? AppColors.primary
                            : AppColors.divider(isDark)),
                  ),
                  child: Text(
                    moneda,
                    style: TextStyle(
                      color: sel ? Colors.white : AppColors.subtext(isDark),
                      fontSize: 14,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL ${simbolosMoneda[_moneda] ?? '\$'}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12)),
              Text(
                  '${simbolosMoneda[_moneda] ?? '\$'} ${_totalEnMoneda().toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _clienteSel.isEmpty ? null : _clienteSel,
                  decoration: InputDecoration(
                    labelText: 'Cliente',
                    labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: AppColors.subtext(isDark), size: 20),
                    filled: true,
                    fillColor: AppColors.background(isDark),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: '', child: Text('Sin cliente')),
                    ..._clientes.map((c) => DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text(c['nombre'] ?? '',
                              style: TextStyle(color: AppColors.text(isDark))),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _clienteSel = v ?? '';
                      if (_clienteSel.isNotEmpty) {
                        final c = _clientes.firstWhere(
                            (x) => x['id'].toString() == _clienteSel);
                        _nombreCtrl.text = c['nombre'] ?? '';
                        _telefonoCtrl.text = c['telefono'] ?? '';
                      }
                    });
                  },
                  style: TextStyle(color: AppColors.text(isDark)),
                  dropdownColor: AppColors.card(isDark),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _nombreCtrl,
                      style: TextStyle(color: AppColors.text(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                        filled: true,
                        fillColor: AppColors.background(isDark),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _telefonoCtrl,
                      style: TextStyle(color: AppColors.text(isDark)),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Telefono',
                        labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                        filled: true,
                        fillColor: AppColors.background(isDark),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Text('METODO DE PAGO',
                    style: TextStyle(
                        color: AppColors.subtext(isDark),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5)),
                const SizedBox(height: 8),
                if (_cargandoMetodos)
                  const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                else
                  Wrap(
                    children: _metodosPago.map((mp) {
                      final nombre = mp['nombre'] ?? '';
                      final sel = _metodo == nombre;
                      return GestureDetector(
                        onTap: () => setState(() => _metodo = nombre),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary
                                : AppColors.background(isDark),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.divider(isDark)),
                          ),
                          child: Text(
                            nombre,
                            style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : AppColors.subtext(isDark),
                              fontSize: 12,
                              fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                if (_metodo == 'Efectivo') ...[
                  Text('MONTO RECIBIDO (${simbolosMoneda[_moneda] ?? '\$'})',
                      style: TextStyle(
                          color: AppColors.subtext(isDark),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _montoCtrl,
                    style: TextStyle(
                        color: AppColors.text(isDark),
                        fontSize: 24,
                        fontWeight: FontWeight.w300),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                          color: AppColors.subtext(isDark), fontSize: 24),
                      prefixText: '${simbolosMoneda[_moneda] ?? '\$'} ',
                      prefixStyle: TextStyle(
                          color: AppColors.text(isDark), fontSize: 24),
                      filled: true,
                      fillColor: AppColors.background(isDark),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_montoCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background(isDark),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _vuelto() >= 0
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Vuelto',
                              style: TextStyle(
                                  color: AppColors.subtext(isDark),
                                  fontSize: 14)),
                          Text(
                            '${simbolosMoneda[_moneda] ?? '\$'} ${_vuelto().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: _vuelto() >= 0
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                Text('RESUMEN',
                    style: TextStyle(
                        color: AppColors.subtext(isDark),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background(isDark),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: widget.carrito
                        .map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['tipo'] == 'kilo'
                                          ? '${item['cantidad']}x ${item['nombre']} (${item['peso']}kg)'
                                          : '${item['cantidad']}x ${item['nombre']}',
                                      style: TextStyle(
                                          color: AppColors.text(isDark),
                                          fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '\$${(item['precio'] * item['cantidad']).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: AppColors.primary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_metodo == 'Efectivo' && _vuelto() < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Monto insuficiente'),
                              backgroundColor: AppColors.danger),
                        );
                        return;
                      }
                      widget.onVentaCompletada(_metodo, _montoCtrl.text,
                          _nombreCtrl.text, _telefonoCtrl.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Text('CONFIRMAR',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ]),
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
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
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
                          productoEditar['id'], prod);
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
          gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary]),
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
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
                      color: AppColors.primary.withValues(alpha: 0.04),
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
            color: AppColors.card(isDark),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
            gradient: sel
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary])
                : null,
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
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
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
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
            color: AppColors.primary.withValues(alpha: 0.04),
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
                gradient: LinearGradient(
                  colors: _cajaActual != null
                      ? [AppColors.primary, AppColors.secondary]
                      : [AppColors.success, AppColors.secondary],
                ),
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
            color: AppColors.primary.withValues(alpha: 0.04),
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
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.secondary.withValues(alpha: 0.1),
              ],
            ),
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
            color: AppColors.primary.withValues(alpha: 0.04),
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
              color: AppColors.primary.withValues(alpha: 0.04),
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
              color: AppColors.primary.withValues(alpha: 0.04),
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
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary]),
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
                color: AppColors.primary.withValues(alpha: 0.04),
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
                            onPressed: () => eliminarProducto(prod['id']),
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
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
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
                color: AppColors.primary.withValues(alpha: 0.04),
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

// ============================================
// PANTALLAS RESTANTES CON MODO OSCURO GLOBAL
// ============================================

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
  bool _cargando = true;
  bool _guardando = false;

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
    }
    _tasaCOPCtrl.text = (prefs.getDouble('tasa_cop') ?? 4500.0).toString();
    _tasaVESCtrl.text = (prefs.getDouble('tasa_ves') ?? 60.0).toString();
    setState(() => _cargando = false);
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
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
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          categoria != null ? 'Editar Categoria' : 'Nueva Categoria',
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
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          TextButton(
            onPressed: () async {
              if (nombreCtrl.text.isEmpty) return;
              if (categoria != null) {
                await _db.actualizarCategoria(
                  categoria['id'].toString(),
                  {'nombre': nombreCtrl.text, 'descripcion': descCtrl.text},
                );
              } else {
                await _db.crearCategoria(
                    {'nombre': nombreCtrl.text, 'descripcion': descCtrl.text});
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
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
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.04),
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
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.1),
                                  AppColors.secondary.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.category_outlined,
                                color: AppColors.primary, size: 20),
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
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
                              color: AppColors.primary.withValues(alpha: 0.04),
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
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.1),
                                  AppColors.secondary.withValues(alpha: 0.1),
                                ],
                              ),
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
                            value: metodo['activo'] == 1,
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
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
                              color: AppColors.primary.withValues(alpha: 0.04),
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
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary
                                ],
                              ),
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
    final correoCtrl = TextEditingController(text: cliente?['correo'] ?? '');
    final direccionCtrl =
        TextEditingController(text: cliente?['direccion'] ?? '');
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
                'correo': correoCtrl.text,
                'direccion': direccionCtrl.text,
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
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
                              color: AppColors.primary.withValues(alpha: 0.04),
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
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.1),
                                  AppColors.secondary.withValues(alpha: 0.1),
                                ],
                              ),
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
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
                      color: AppColors.primary.withValues(alpha: 0.04),
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
                          color: AppColors.primary.withValues(alpha: 0.04),
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
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secondary
                                  ],
                                ),
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
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
                      color: AppColors.primary.withValues(alpha: 0.04),
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
                      color: AppColors.primary.withValues(alpha: 0.04),
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
      'version': '5.0.0',
    };
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    await Share.share(jsonStr,
        subject:
            'Backup SINTHETIX PRO - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}');
    _mostrarExito('Datos exportados correctamente');
    setState(() => _exportando = false);
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
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
                      color: AppColors.primary.withValues(alpha: 0.04),
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
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
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
                            _exportando ? 'Exportando...' : 'Exportar Ahora',
                            style: const TextStyle(color: Colors.white)),
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
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.04),
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
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.secondary.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.download,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Importar Datos',
                                style: TextStyle(
                                    color: AppColors.text(isDark),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            Text('Restaurar desde un archivo',
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
                      child: OutlinedButton.icon(
                        onPressed: () => _mostrarExito('Funcion en desarrollo'),
                        icon: const Icon(Icons.download,
                            color: AppColors.primary),
                        label: const Text('Importar Archivo',
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
  Map<String, dynamic>? _cajaActual;
  List<Map<String, dynamic>> _historialCajas = [];
  List<Map<String, dynamic>> _movimientos = [];
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
            gradient: sel
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary])
                : null,
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
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
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
                color: AppColors.primary.withValues(alpha: 0.04),
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
                color: AppColors.primary.withValues(alpha: 0.04),
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
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
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
                      color: AppColors.primary.withValues(alpha: 0.04),
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
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
                            color: AppColors.primary.withValues(alpha: 0.04),
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
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary
                                ],
                              ),
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
            gradient: sel
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary])
                : null,
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
                color: AppColors.primary.withValues(alpha: 0.04),
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
                color: AppColors.primary.withValues(alpha: 0.04),
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
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
                      color: AppColors.primary.withValues(alpha: 0.04),
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
// TIENDA PRINCIPAL SINTHETIX
// ============================================
class UniversalFlyCartStore extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  const UniversalFlyCartStore(
      {super.key,
      required this.onAbrirSidebar,
      this.width,
      this.height,
      this.onProductTap});
  final double? width;
  final double? height;
  final Future<dynamic> Function(dynamic selectedProduct)? onProductTap;
  @override
  _UniversalFlyCartStoreState createState() => _UniversalFlyCartStoreState();
}

class _UniversalFlyCartStoreState extends State<UniversalFlyCartStore>
    with TickerProviderStateMixin {
  late AnimationController _marqueeController;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  bool _showAnnouncementBar = true;
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _isDarkMode = false;

  List<Map<String, dynamic>> _categories = [];
  int _selectedCategoryIndex = 0;
  List<Map<String, dynamic>> _allProducts = [];

  final Set<String> _favoriteIds = {};
  final List<Map<String, dynamic>> _favorites = [];

  final ValueNotifier<double> _cartExtentNotifier = ValueNotifier<double>(0.15);
  final List<Map<String, dynamic>> _cart = [];
  final List<String> _cartImages = [];
  final GlobalKey _cartTargetKey = GlobalKey();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _marqueeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        int next = (_currentBannerIndex + 1) % 3;
        _bannerController.animateToPage(next,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    });
    _loadSavedCart();
    _fetchData();
  }

  Future<void> _loadSavedCart() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? cartJson = prefs.getStringList('saved_cart');
      if (cartJson != null && cartJson.isNotEmpty) {
        setState(() {
          _cart.clear();
          _cartImages.clear();
          for (String item in cartJson) {
            Map<String, dynamic> product =
                Map<String, dynamic>.from(jsonDecode(item));
            _cart.add(product);
            _cartImages.add(product['image'] ?? '');
          }
        });
      }
    } catch (e) {
      debugPrint("Error cargando carrito: $e");
    }
  }

  Future<void> _saveCart() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> cartJson = _cart.map((item) => jsonEncode(item)).toList();
      await prefs.setStringList('saved_cart', cartJson);
    } catch (e) {
      debugPrint("Error guardando carrito: $e");
    }
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _cartExtentNotifier.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final db = DatabaseService();
      final catResponse = await db.getCategorias();
      final prodResponse = await db.getProductos();

      List<Map<String, dynamic>> loadedCategories = [];
      if (catResponse.isNotEmpty) {
        loadedCategories = List<Map<String, dynamic>>.from(catResponse);
        bool hasTodos = loadedCategories
            .any((cat) => cat['nombre']?.toString().toLowerCase() == 'todos');
        if (!hasTodos) {
          loadedCategories
              .insert(0, {'id': 0, 'nombre': 'Todos', 'imagen_url': null});
        }
      }

      List<Map<String, dynamic>> allProds = [];

      for (var item in prodResponse) {
        String imageUrl = item['imagen_url']?.toString() ?? '';

        final Map<String, dynamic> product = {
          'id': item['id']?.toString() ?? '',
          'name': item['nombre'] ?? 'Producto',
          'category': item['categoria'] ?? 'General',
          'subcategory': '',
          'price': (item['precio'] ?? 0).toDouble(),
          'image': imageUrl,
          'images': imageUrl.isNotEmpty ? [imageUrl] : [],
          'description': item['descripcion'] ?? '',
          'isNew': false,
          'isOffer': false,
          'isDestacado': item['destacado'] == 1,
          'isRecomendado': false,
          'rawRow': item,
        };

        allProds.add(product);
      }

      setState(() {
        _categories = loadedCategories;
        _allProducts = allProds;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error en _fetchData: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleDarkMode() => setState(() => _isDarkMode = !_isDarkMode);

  void _toggleFavorite(Map<String, dynamic> product) {
    setState(() {
      final id = product['id'];
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
        _favorites.removeWhere((p) => p['id'] == id);
      } else {
        _favoriteIds.add(id);
        _favorites.add(product);
      }
    });
  }

  bool _isFavorite(String id) => _favoriteIds.contains(id);

  void _executePurchase(GlobalKey itemKey, Map<String, dynamic> product) {
    setState(() {
      int index = _cart.indexWhere((element) => element['id'] == product['id']);
      if (index != -1) {
        _cart[index]['quantity'] = ((_cart[index]['quantity'] ?? 1) as int) +
            (product['quantity'] ?? 1);
      } else {
        _cart.add({...product, 'quantity': product['quantity'] ?? 1});
        _cartImages.add(product['image'] ?? '');
      }
    });
    _saveCart();
  }

  void _addToCartSilent(GlobalKey itemKey, Map<String, dynamic> product) {
    setState(() {
      int index = _cart.indexWhere((element) => element['id'] == product['id']);
      if (index != -1) {
        _cart[index]['quantity'] = ((_cart[index]['quantity'] ?? 1) as int) +
            (product['quantity'] ?? 1);
      } else {
        _cart.add({...product, 'quantity': product['quantity'] ?? 1});
        _cartImages.add(product['image'] ?? '');
      }
    });
    _saveCart();
  }

  void _openWhatsApp(String message) async {
    String phone = "584241234567";
    var whatsappUrl =
        "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
    debugPrint("WhatsApp URL: $whatsappUrl");
  }

  int get _cartTotalUnits =>
      _cart.fold(0, (acc, item) => acc + ((item['quantity'] ?? 1) as int));

  void _navigateToCart() {
    Navigator.push(context,
            MaterialPageRoute(builder: (context) => FullCartPage(cart: _cart)))
        .then((_) => setState(() {}));
  }

  void _updateCartFromDetail() {
    setState(() {});
    _saveCart();
  }

  void _showCheckoutDialog() {
    _nombreController.text = '';
    _telefonoController.text = '';
    _direccionController.text = '';
    final scaffoldContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card(_isDarkMode),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.shopping_cart_rounded,
              color: AppColors.logoCyan, size: 28),
          const SizedBox(width: 10),
          Text("Datos del Cliente",
              style: TextStyle(
                  color: AppColors.text(_isDarkMode),
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
        ]),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("Completa tus datos para enviar el pedido a SINTHETIX",
                style: TextStyle(
                    color: AppColors.subtext(_isDarkMode), fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              style: TextStyle(color: AppColors.text(_isDarkMode)),
              decoration: InputDecoration(
                labelText: "Nombre completo *",
                labelStyle: TextStyle(color: AppColors.subtext(_isDarkMode)),
                prefixIcon:
                    const Icon(Icons.person_outline, color: AppColors.logoCyan),
                enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.divider(_isDarkMode)),
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: AppColors.logoCyan, width: 2),
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: AppColors.text(_isDarkMode)),
              decoration: InputDecoration(
                labelText: "Teléfono",
                labelStyle: TextStyle(color: AppColors.subtext(_isDarkMode)),
                prefixIcon:
                    const Icon(Icons.phone_outlined, color: AppColors.logoCyan),
                enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.divider(_isDarkMode)),
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: AppColors.logoCyan, width: 2),
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _direccionController,
              style: TextStyle(color: AppColors.text(_isDarkMode)),
              decoration: InputDecoration(
                labelText: "Dirección de entrega",
                labelStyle: TextStyle(color: AppColors.subtext(_isDarkMode)),
                prefixIcon: const Icon(Icons.location_on_outlined,
                    color: AppColors.logoCyan),
                enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.divider(_isDarkMode)),
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: AppColors.logoCyan, width: 2),
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancelar",
                  style: TextStyle(color: AppColors.subtext(_isDarkMode)))),
          ElevatedButton(
            onPressed: () {
              if (_nombreController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                      content: Text("Por favor ingresa tu nombre"),
                      backgroundColor: AppColors.danger),
                );
                return;
              }
              Navigator.pop(dialogContext);
              _enviarPedidoWhatsApp(scaffoldContext);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.logoCyan,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text("Enviar Pedido",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _enviarPedidoWhatsApp(BuildContext scaffoldContext) async {
    double totalPrice = _cart.fold(
        0.0,
        (acc, item) =>
            acc +
            ((item['price'] as double) * ((item['quantity'] ?? 1) as int)));
    String nombreCliente = _nombreController.text.trim();
    String telefonoCliente = _telefonoController.text.trim();
    String direccionCliente = _direccionController.text.trim();
    String message =
        "🛍️ *SINTHETIX - NUEVO PEDIDO* 🛍️\n\n👤 *Cliente:* $nombreCliente\n";
    if (telefonoCliente.isNotEmpty) {
      message += "📱 *Teléfono:* $telefonoCliente\n";
    }
    if (direccionCliente.isNotEmpty) {
      message += "📍 *Dirección:* $direccionCliente\n";
    }
    message += "\n📦 *PRODUCTOS:*\n";
    for (var item in _cart) {
      double itemTotal =
          (item['price'] as double) * ((item['quantity'] ?? 1) as int);
      message +=
          "• ${item['name']} x${item['quantity'] ?? 1} = \$${itemTotal.toStringAsFixed(2)}\n";
    }
    message +=
        "\n💰 *TOTAL:* \$${totalPrice.toStringAsFixed(2)}\n📅 *Fecha:* ${DateTime.now().toString().substring(0, 10)}\n\n✅ *Estado:* Pendiente\n\n¡Gracias por tu compra en SINTHETIX! 🛍️";
    _openWhatsApp(message);
    setState(() {
      _cart.clear();
      _cartImages.clear();
    });
    _saveCart();
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      SnackBar(
        content: const Text("¡Pedido enviado con éxito a SINTHETIX! 🎉🛍️"),
        backgroundColor: AppColors.logoCyan,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCartIcon({double iconSize = 20}) {
    return GestureDetector(
      onTap: _navigateToCart,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.iconBgHeader(_isDarkMode),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.shopping_bag_outlined,
                size: iconSize, color: AppColors.headerIcon(_isDarkMode)),
          ),
          if (_cart.isNotEmpty)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: AppColors.logoRed, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Text(
                  "$_cartTotalUnits",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalUnits = _cartTotalUnits;
    double totalPrice = _cart.fold(
        0.0,
        (acc, item) =>
            acc +
            ((item['price'] as double) * ((item['quantity'] ?? 1) as int)));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) return;
      },
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background(_isDarkMode),
          drawer: _buildDrawer(),
          body: Stack(
            children: [
              SafeArea(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.logoCyan))
                    : RefreshIndicator(
                        key: _refreshIndicatorKey,
                        color: AppColors.logoCyan,
                        backgroundColor: AppColors.card(_isDarkMode),
                        onRefresh: _fetchData,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics()),
                          slivers: [
                            if (_showAnnouncementBar)
                              _buildSliverAnnouncementBar(),
                            _buildSliverHeader(),
                            _buildSliverBanner(),
                            _buildSliverCategories(),
                            if (_allProducts.isNotEmpty) ...[
                              _buildSliverSectionTitle(
                                  "🛍️ Todos los Productos"),
                              _buildSliverHorizontalList(_allProducts),
                              _buildSeeAllButton(
                                  _allProducts, "Todos los Productos"),
                            ],
                            _buildSliverMiddlePromoBanner(),
                            _buildSliverFooter(),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 180)),
                          ],
                        ),
                      ),
              ),
              _buildWhatsAppFloatingButton(),
              if (_cart.isNotEmpty) _buildDraggableCart(totalUnits, totalPrice),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeeAllButton(List<Map<String, dynamic>> products, String title) {
    if (products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryViewPage(
                  title: title,
                  products: products,
                  cartItemCount: _cartTotalUnits,
                  cartItems: _cart,
                  favorites: _favoriteIds,
                  isDarkMode: _isDarkMode,
                  allProducts: _allProducts,
                  onAddToCart: _addToCartSilent,
                  onToggleFavorite: _toggleFavorite,
                  onWhatsAppTap: _openWhatsApp,
                  onCartTap: _navigateToCart,
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: AppColors.logoCyan,
                borderRadius: BorderRadius.circular(12)),
            child: const Center(
              child: Text("VER TODOS",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Text(
          title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: AppColors.text(_isDarkMode)),
        ),
      ),
    );
  }

  Widget _buildWhatsAppFloatingButton() {
    return Positioned(
      bottom: _cart.isEmpty ? 32 : 132,
      right: 24,
      child: GestureDetector(
        onTap: () => _openWhatsApp(
            "Hola SINTHETIX, necesito información sobre sus productos"),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF25D366),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF25D366).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: const Center(
              child: FaIcon(FontAwesomeIcons.whatsapp,
                  color: Colors.white, size: 30)),
        ),
      ),
    );
  }

  Widget _buildSliverBanner() {
    final List<String> imageUrls = [
      "https://i.postimg.cc/nhy8FSZb/Messenger-creation-C45C1B69-8F69-4D54-A5D8-F2B1FECCD24B.jpg",
      "https://i.postimg.cc/QC4PR0Sg/Messenger-creation-15D98706-C78D-4AAD-B9FD-ADE892AA5E51.jpg",
      "https://i.postimg.cc/GtcsTjFs/Messenger-creation-942DCA75-52C7-411F-96CC-826ACAC3952A.png",
    ];
    return SliverToBoxAdapter(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _bannerController,
              onPageChanged: (index) =>
                  setState(() => _currentBannerIndex = index),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) =>
                  Image.network(imageUrls[index], fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentBannerIndex == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentBannerIndex == index
                        ? Colors.white
                        : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverCategories() {
    if (_categories.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 70,
          child: Center(
              child:
                  Text("Cargando...", style: TextStyle(color: Colors.white54))),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = _selectedCategoryIndex == index;
            String categoryName = cat['nombre'] ?? 'Categoría';
            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategoryIndex = index);
                if (categoryName != 'Todos') {
                  List<Map<String, dynamic>> catProducts = _allProducts
                      .where((prod) =>
                          prod['category'].toString().toLowerCase() ==
                          categoryName.toLowerCase())
                      .toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryViewPage(
                        title: categoryName,
                        products: catProducts,
                        cartItemCount: _cartTotalUnits,
                        cartItems: _cart,
                        favorites: _favoriteIds,
                        isDarkMode: _isDarkMode,
                        allProducts: _allProducts,
                        onAddToCart: _addToCartSilent,
                        onToggleFavorite: _toggleFavorite,
                        onWhatsAppTap: _openWhatsApp,
                        onCartTap: _navigateToCart,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                width: 150,
                height: 60,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  border: isSelected
                      ? Border.all(color: AppColors.logoCyan, width: 3)
                      : null,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: isSelected
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.5),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      shadows: [
                        Shadow(
                            blurRadius: 4,
                            color: Colors.black,
                            offset: Offset(1, 1))
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverHorizontalList(List<Map<String, dynamic>> productsList) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 240,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: productsList.length,
          itemBuilder: (context, index) {
            final product = productsList[index];
            final GlobalKey itemKey = GlobalKey();
            final bool isFav = _isFavorite(product['id']);
            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsPage(
                    productData:
                        convertToMapStringDynamic(product['rawRow'] ?? product),
                    isDarkMode: _isDarkMode,
                    allProducts: _allProducts,
                    onAddToCart: _addToCartSilent,
                    onToggleFavorite: _toggleFavorite,
                    favoriteIds: _favoriteIds,
                    onCartTap: _navigateToCart,
                    cartItemCount: _cartTotalUnits,
                    onCartChanged: _updateCartFromDetail,
                  ),
                ),
              ),
              child: Container(
                key: itemKey,
                width: 165,
                margin: const EdgeInsets.only(right: 16, bottom: 4),
                decoration: BoxDecoration(
                  color: AppColors.card(_isDarkMode),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.shadow(_isDarkMode),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(children: [
                    Positioned.fill(
                      child: ImagenProducto(
                        imagenUrl: product['image']?.toString(),
                        width: 165,
                        height: 240,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xCC000000),
                              Colors.black
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.4, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Column(children: [
                        GestureDetector(
                          onTap: () => _toggleFavorite(product),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                shape: BoxShape.circle),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? AppColors.logoRed : Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _openWhatsApp(
                              "Hola SINTHETIX, quiero info de ${product['name']}"),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                                color: Color(0xFF25D366),
                                shape: BoxShape.circle),
                            child: const FaIcon(FontAwesomeIcons.whatsapp,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ]),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] as String,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "\$${(product['price'] as double).toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xB3FFFFFF)),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: GestureDetector(
                        onTap: () => _executePurchase(itemKey, product),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                          child: const Center(
                              child: Icon(Icons.add,
                                  color: Colors.black, size: 18)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverMiddlePromoBanner() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bannerBg(_isDarkMode),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrustItem(Icons.local_shipping_outlined, "Envío Exprés"),
              Container(
                  width: 1, height: 30, color: AppColors.divider(_isDarkMode)),
              _buildTrustItem(Icons.verified_user_outlined, "Garantía"),
              Container(
                  width: 1, height: 30, color: AppColors.divider(_isDarkMode)),
              _buildTrustItem(Icons.support_agent_rounded, "Soporte 24/7"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.text(_isDarkMode)),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.subtext(_isDarkMode))),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.drawerBg(_isDarkMode),
      child: Column(children: [
        DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.logoFuchsia.withValues(alpha: 0.3),
                AppColors.logoCyan.withValues(alpha: 0.1)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    'https://i.postimg.cc/282g7rQf/Messenger-creation-5A84A1A2-42B1-48D1-BCC6-589895D739A9-removebg-preview.png',
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const Icon(Icons.store_rounded,
                        color: AppColors.logoCyan, size: 70),
                  ),
                ),
                const SizedBox(height: 8),
                Text("SINTHETIX",
                    style: TextStyle(
                        color: AppColors.text(_isDarkMode),
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _drawerTile(
                  Icons.home_rounded, "Inicio", () => Navigator.pop(context)),
              _drawerTile(Icons.shopping_cart_rounded, "Carrito", () {
                Navigator.pop(context);
                _navigateToCart();
              }),
              _drawerTile(Icons.favorite_rounded, "Favoritos", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavoritesPage(
                      favorites: _favorites,
                      favoriteIds: _favoriteIds,
                      cartItemCount: _cartTotalUnits,
                      cartItems: _cart,
                      isDarkMode: _isDarkMode,
                      allProducts: _allProducts,
                      onAddToCart: _addToCartSilent,
                      onToggleFavorite: _toggleFavorite,
                      onWhatsAppTap: _openWhatsApp,
                      onCartTap: _navigateToCart,
                    ),
                  ),
                );
              }),
              _drawerTile(Icons.search_rounded, "Todos los Productos", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchPage(
                      allProducts: _allProducts,
                      categories: _categories
                          .where((c) => c['nombre'] != 'Todos')
                          .toList(),
                      cartItemCount: _cartTotalUnits,
                      cartItems: _cart,
                      favorites: _favoriteIds,
                      isDarkMode: _isDarkMode,
                      onAddToCart: _addToCartSilent,
                      onToggleFavorite: _toggleFavorite,
                      onWhatsAppTap: _openWhatsApp,
                      onCartTap: _navigateToCart,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 90),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Text("Síguenos",
                style: TextStyle(
                    color: AppColors.subtext(_isDarkMode),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialCircle(FontAwesomeIcons.facebook,
                    () => launchURL('https://www.facebook.com/')),
                const SizedBox(width: 8),
                _buildSocialCircle(FontAwesomeIcons.instagram,
                    () => launchURL('https://www.instagram.com/')),
                const SizedBox(width: 8),
                _buildSocialCircle(FontAwesomeIcons.whatsapp, () {
                  _openWhatsApp("Hola SINTHETIX, necesito información");
                }),
              ],
            ),
            const SizedBox(height: 16),
            Text("© 2026 SINTHETIX",
                style: TextStyle(
                    color: AppColors.subtext(_isDarkMode), fontSize: 10)),
          ]),
        ),
      ]),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: AppColors.text(_isDarkMode)),
        title:
            Text(title, style: TextStyle(color: AppColors.text(_isDarkMode))),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => widget.onAbrirSidebar(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.iconBgHeader(_isDarkMode),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.menu_rounded,
                    size: 20, color: AppColors.headerIcon(_isDarkMode)),
              ),
            ),
            Text(
              "SINTHETIX",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: AppColors.text(_isDarkMode)),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _toggleDarkMode,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.iconBgHeader(_isDarkMode),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      _isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 20,
                      color: _isDarkMode
                          ? Colors.amber
                          : AppColors.headerIcon(_isDarkMode),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchPage(
                          allProducts: _allProducts,
                          categories: _categories
                              .where((c) => c['nombre'] != 'Todos')
                              .toList(),
                          cartItemCount: _cartTotalUnits,
                          cartItems: _cart,
                          favorites: _favoriteIds,
                          isDarkMode: _isDarkMode,
                          onAddToCart: _addToCartSilent,
                          onToggleFavorite: _toggleFavorite,
                          onWhatsAppTap: _openWhatsApp,
                          onCartTap: _navigateToCart,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.iconBgHeader(_isDarkMode),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.search,
                        size: 20, color: AppColors.headerIcon(_isDarkMode)),
                  ),
                ),
                const SizedBox(width: 6),
                _buildCartIcon(iconSize: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAnnouncementBar() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        height: 40,
        color: AppColors.announcementBg(_isDarkMode),
        child: Row(children: [
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _marqueeController,
              builder: (context, child) {
                return FractionalTranslation(
                  translation:
                      Offset(1.0 - (_marqueeController.value * 2.0), 0.0),
                  child: child,
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store_rounded,
                      color: AppColors.logoCyan, size: 14),
                  SizedBox(width: 8),
                  Text(
                    "¡Bienvenido a SINTHETIX! • Catálogo Premium • Envíos a todo el país",
                    style: TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showAnnouncementBar = false),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Icon(Icons.close_rounded, color: Colors.white60, size: 16),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSliverFooter() {
    return SliverToBoxAdapter(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Divider(
              color: AppColors.divider(_isDarkMode), thickness: 1, height: 40),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  'https://i.postimg.cc/282g7rQf/Messenger-creation-5A84A1A2-42B1-48D1-BCC6-589895D739A9-removebg-preview.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Icon(Icons.store_rounded,
                      color: AppColors.logoCyan, size: 50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "SINTHETIX",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: AppColors.text(_isDarkMode)),
              ),
              const SizedBox(height: 6),
              Text(
                "Catálogo Premium",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subtext(_isDarkMode)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialCircle(FontAwesomeIcons.facebook,
                      () => launchURL('https://www.facebook.com/')),
                  const SizedBox(width: 12),
                  _buildSocialCircle(FontAwesomeIcons.instagram,
                      () => launchURL('https://www.instagram.com/')),
                  const SizedBox(width: 12),
                  _buildSocialCircle(FontAwesomeIcons.whatsapp, () {
                    _openWhatsApp("Hola SINTHETIX, necesito información");
                  }),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                  width: double.infinity,
                  height: 1,
                  color: AppColors.divider(_isDarkMode)),
              const SizedBox(height: 16),
              Text(
                "© 2026 SINTHETIX. Todos los derechos reservados.",
                style: TextStyle(
                    color: AppColors.subtext(_isDarkMode), fontSize: 10),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildSocialCircle(dynamic icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.iconBg(_isDarkMode),
            border: Border.all(color: AppColors.divider(_isDarkMode), width: 1),
          ),
          child: Center(
              child:
                  FaIcon(icon, size: 18, color: AppColors.text(_isDarkMode))),
        ),
      );

  Widget _buildDraggableCart(int totalUnits, double totalPrice) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        _cartExtentNotifier.value = notification.extent;
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.15,
        minChildSize: 0.15,
        maxChildSize: 0.85,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.cartBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                    color: Color(0xAA000000),
                    blurRadius: 25,
                    offset: Offset(0, -8))
              ],
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                ValueListenableBuilder<double>(
                  valueListenable: _cartExtentNotifier,
                  builder: (context, extent, child) =>
                      _buildCartHeader(totalUnits),
                ),
                _buildCartList(),
                _buildCheckoutSummary(totalPrice),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartHeader(int totalUnits) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            key: _cartTargetKey,
            children: [
              const Icon(Icons.shopping_cart_rounded,
                  color: AppColors.blue, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CART",
                      style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                  Text("$totalUnits Items",
                      style: const TextStyle(
                          color: AppColors.subtextLight, fontSize: 11)),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              reverse: true,
              itemCount: _cartImages.length,
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(right: -10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cartBg, width: 2),
                ),
                width: 40,
                child: ClipOval(
                  child: ImagenProducto(
                    imagenUrl: _cartImages[index],
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cart.length,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemBuilder: (context, index) {
        final item = _cart[index];
        final int qty = (item['quantity'] ?? 1) as int;
        final double price = (item['price'] as double);
        return Dismissible(
          key: ValueKey(item['id']),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 28),
          ),
          onDismissed: (direction) {
            setState(() {
              _cart.removeAt(index);
              _cartImages.removeAt(index);
            });
            _saveCart();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cartCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ImagenProducto(
                  imagenUrl: item['image']?.toString(),
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'],
                        style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                        maxLines: 1),
                    const SizedBox(height: 4),
                    Text("\$${price.toStringAsFixed(2)}",
                        style: const TextStyle(
                            color: AppColors.subtextLight, fontSize: 13)),
                  ],
                ),
              ),
              Row(children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (qty > 1) {
                        _cart[index]['quantity'] = qty - 1;
                      } else {
                        _cart.removeAt(index);
                        _cartImages.removeAt(index);
                      }
                    });
                    _saveCart();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        color: Color(0xFFF0F0F0), shape: BoxShape.circle),
                    child: const Icon(Icons.remove,
                        color: AppColors.textLight, size: 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text("$qty",
                      style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _cart[index]['quantity'] = qty + 1);
                    _saveCart();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        color: Color(0xFFF0F0F0), shape: BoxShape.circle),
                    child: const Icon(Icons.add,
                        color: AppColors.textLight, size: 14),
                  ),
                ),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildCheckoutSummary(double totalPrice) {
    if (_cart.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("TOTAL ESTIMADO",
                style: TextStyle(
                    color: AppColors.subtextLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            Text("\$${totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _showCheckoutDialog,
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18)),
            child: const Center(
              child: Text("FINALIZAR PEDIDO",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ============================================
// PÁGINAS DE BÚSQUEDA, CATEGORÍAS, FAVORITOS, CARRITO Y DETALLES
// ============================================

class SearchPage extends StatefulWidget {
  final List<Map<String, dynamic>> allProducts;
  final List<Map<String, dynamic>> categories;
  final int cartItemCount;
  final List<Map<String, dynamic>> cartItems;
  final Set<String> favorites;
  final bool isDarkMode;
  final Function(GlobalKey, Map<String, dynamic>) onAddToCart;
  final Function(Map<String, dynamic>) onToggleFavorite;
  final Function(String) onWhatsAppTap;
  final VoidCallback onCartTap;
  const SearchPage({
    super.key,
    required this.allProducts,
    required this.categories,
    required this.cartItemCount,
    required this.cartItems,
    required this.favorites,
    required this.isDarkMode,
    required this.onAddToCart,
    required this.onToggleFavorite,
    required this.onWhatsAppTap,
    required this.onCartTap,
  });
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  List<Map<String, dynamic>> _filteredProducts = [];
  Set<String> _localFavorites = {};

  @override
  void initState() {
    super.initState();
    _localFavorites = Set<String>.from(widget.favorites);
    _filteredProducts = widget.allProducts;
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = widget.allProducts.where((prod) {
        final nameMatch = prod['name']
                ?.toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ??
            false;
        final categoryMatch = _selectedCategory == 'Todos' ||
            prod['category']?.toString() == _selectedCategory;
        return nameMatch && categoryMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(widget.isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(widget.isDarkMode),
        elevation: 0,
        title: Text("Buscar Productos",
            style: TextStyle(
                color: AppColors.text(widget.isDarkMode),
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: AppColors.text(widget.isDarkMode)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          GestureDetector(
            onTap: widget.onCartTap,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Stack(children: [
                Icon(Icons.shopping_bag_outlined,
                    color: AppColors.text(widget.isDarkMode), size: 24),
                if (widget.cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: AppColors.logoRed, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        "${widget.cartItemCount}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
              style: TextStyle(color: AppColors.text(widget.isDarkMode)),
              decoration: InputDecoration(
                hintText: "Buscar por nombre...",
                hintStyle:
                    TextStyle(color: AppColors.subtext(widget.isDarkMode)),
                prefixIcon: Icon(Icons.search,
                    color: AppColors.subtext(widget.isDarkMode)),
                filled: true,
                fillColor: AppColors.card(widget.isDarkMode),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close,
                            color: AppColors.subtext(widget.isDarkMode),
                            size: 18),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _filterProducts();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
                _filterProducts();
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.categories.length + 1,
                itemBuilder: (context, index) {
                  String categoryName = index == 0
                      ? 'Todos'
                      : widget.categories[index - 1]['nombre'] ?? 'Categoría';
                  bool isSelected = _selectedCategory == categoryName;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = categoryName;
                        _filterProducts();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.logoCyan
                            : AppColors.card(widget.isDarkMode),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSelected
                                ? AppColors.logoCyan
                                : AppColors.divider(widget.isDarkMode)),
                      ),
                      child: Text(
                        categoryName,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.text(widget.isDarkMode),
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
        Expanded(
          child: _filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          color: AppColors.subtext(widget.isDarkMode),
                          size: 60),
                      const SizedBox(height: 16),
                      Text("Sin resultados",
                          style: TextStyle(
                              color: AppColors.subtext(widget.isDarkMode),
                              fontSize: 16)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    final GlobalKey itemKey = GlobalKey();
                    final bool isFav = _localFavorites.contains(product['id']);
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsPage(
                              productData: convertToMapStringDynamic(
                                  product['rawRow'] ?? product),
                              isDarkMode: widget.isDarkMode,
                              allProducts: widget.allProducts,
                              onAddToCart: widget.onAddToCart,
                              onToggleFavorite: widget.onToggleFavorite,
                              favoriteIds: _localFavorites,
                              onCartTap: widget.onCartTap,
                              cartItemCount: widget.cartItemCount,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        key: itemKey,
                        decoration: BoxDecoration(
                          color: AppColors.card(widget.isDarkMode),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.shadow(widget.isDarkMode),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(children: [
                            Positioned.fill(
                              child: ImagenProducto(
                                imagenUrl: product['image']?.toString(),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Color(0xCC000000),
                                      Colors.black
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: [0.4, 0.8, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Column(children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_localFavorites
                                          .contains(product['id'])) {
                                        _localFavorites.remove(product['id']);
                                      } else {
                                        _localFavorites.add(product['id']);
                                      }
                                    });
                                    widget.onToggleFavorite(product);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
                                        shape: BoxShape.circle),
                                    child: Icon(
                                      isFav
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFav
                                          ? AppColors.logoRed
                                          : Colors.white,
                                      size: 19,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => widget.onWhatsAppTap(
                                      "Hola SINTHETIX, quiero info de ${product['name']}"),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                        color: Color(0xFF25D366),
                                        shape: BoxShape.circle),
                                    child: const FaIcon(
                                        FontAwesomeIcons.whatsapp,
                                        color: Colors.white,
                                        size: 16),
                                  ),
                                ),
                              ]),
                            ),
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 14,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] as String,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "\$${(product['price'] as double).toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.logoCyan),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: GestureDetector(
                                onTap: () {
                                  widget.onAddToCart(itemKey, product);
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.logoCyan,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: AppColors.logoCyan
                                              .withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3))
                                    ],
                                  ),
                                  child: const Center(
                                      child: Icon(Icons.add,
                                          color: Colors.white, size: 20)),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class CategoryViewPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> products;
  final int cartItemCount;
  final List<Map<String, dynamic>> cartItems;
  final Set<String> favorites;
  final bool isDarkMode;
  final List<Map<String, dynamic>> allProducts;
  final Function(GlobalKey, Map<String, dynamic>) onAddToCart;
  final Function(Map<String, dynamic>) onToggleFavorite;
  final Function(String) onWhatsAppTap;
  final VoidCallback onCartTap;
  const CategoryViewPage({
    super.key,
    required this.title,
    required this.products,
    required this.cartItemCount,
    required this.cartItems,
    required this.favorites,
    required this.isDarkMode,
    required this.allProducts,
    required this.onAddToCart,
    required this.onToggleFavorite,
    required this.onWhatsAppTap,
    required this.onCartTap,
  });
  @override
  _CategoryViewPageState createState() => _CategoryViewPageState();
}

class _CategoryViewPageState extends State<CategoryViewPage> {
  Set<String> _localFavorites = {};

  @override
  void initState() {
    super.initState();
    _localFavorites = Set<String>.from(widget.favorites);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(widget.isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(widget.isDarkMode),
        elevation: 0,
        title: Text(widget.title,
            style: TextStyle(
                color: AppColors.text(widget.isDarkMode),
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: AppColors.text(widget.isDarkMode)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          GestureDetector(
            onTap: widget.onCartTap,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Stack(children: [
                Icon(Icons.shopping_bag_outlined,
                    color: AppColors.text(widget.isDarkMode), size: 24),
                if (widget.cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: AppColors.logoRed, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        "${widget.cartItemCount}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: widget.products.length,
        itemBuilder: (context, index) {
          final product = widget.products[index];
          final GlobalKey itemKey = GlobalKey();
          final bool isFav = _localFavorites.contains(product['id']);
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsPage(
                    productData:
                        convertToMapStringDynamic(product['rawRow'] ?? product),
                    isDarkMode: widget.isDarkMode,
                    allProducts: widget.allProducts,
                    onAddToCart: widget.onAddToCart,
                    onToggleFavorite: widget.onToggleFavorite,
                    favoriteIds: _localFavorites,
                    onCartTap: widget.onCartTap,
                    cartItemCount: widget.cartItemCount,
                  ),
                ),
              );
            },
            child: Container(
              key: itemKey,
              decoration: BoxDecoration(
                color: AppColors.card(widget.isDarkMode),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.shadow(widget.isDarkMode),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(children: [
                  Positioned.fill(
                    child: ImagenProducto(
                      imagenUrl: product['image']?.toString(),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xCC000000),
                            Colors.black
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.4, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Column(children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_localFavorites.contains(product['id'])) {
                              _localFavorites.remove(product['id']);
                            } else {
                              _localFavorites.add(product['id']);
                            }
                          });
                          widget.onToggleFavorite(product);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? AppColors.logoRed : Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => widget.onWhatsAppTap(
                            "Hola SINTHETIX, quiero info de ${product['name']}"),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                              color: Color(0xFF25D366), shape: BoxShape.circle),
                          child: const FaIcon(FontAwesomeIcons.whatsapp,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ]),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] as String,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "\$${(product['price'] as double).toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.logoCyan),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: GestureDetector(
                      onTap: () {
                        widget.onAddToCart(itemKey, product);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.logoCyan,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color:
                                    AppColors.logoCyan.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: const Center(
                            child:
                                Icon(Icons.add, color: Colors.white, size: 20)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  final List<Map<String, dynamic>> favorites;
  final Set<String> favoriteIds;
  final int cartItemCount;
  final List<Map<String, dynamic>> cartItems;
  final bool isDarkMode;
  final List<Map<String, dynamic>> allProducts;
  final Function(GlobalKey, Map<String, dynamic>) onAddToCart;
  final Function(Map<String, dynamic>) onToggleFavorite;
  final Function(String) onWhatsAppTap;
  final VoidCallback onCartTap;
  const FavoritesPage({
    super.key,
    required this.favorites,
    required this.favoriteIds,
    required this.cartItemCount,
    required this.cartItems,
    required this.isDarkMode,
    required this.allProducts,
    required this.onAddToCart,
    required this.onToggleFavorite,
    required this.onWhatsAppTap,
    required this.onCartTap,
  });
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Set<String> _localFavorites = {};

  @override
  void initState() {
    super.initState();
    _localFavorites = Set<String>.from(widget.favoriteIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(widget.isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(widget.isDarkMode),
        elevation: 0,
        title: Text("Favoritos",
            style: TextStyle(
                color: AppColors.text(widget.isDarkMode),
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: AppColors.text(widget.isDarkMode)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          GestureDetector(
            onTap: widget.onCartTap,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Stack(children: [
                Icon(Icons.shopping_bag_outlined,
                    color: AppColors.text(widget.isDarkMode), size: 24),
                if (widget.cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: AppColors.logoRed, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        "${widget.cartItemCount}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
      body: widget.favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      color: AppColors.subtext(widget.isDarkMode), size: 60),
                  const SizedBox(height: 16),
                  Text("No tienes productos favoritos",
                      style: TextStyle(
                          color: AppColors.subtext(widget.isDarkMode),
                          fontSize: 16)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: widget.favorites.length,
              itemBuilder: (context, index) {
                final product = widget.favorites[index];
                final GlobalKey itemKey = GlobalKey();
                final bool isFav = _localFavorites.contains(product['id']);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsPage(
                          productData: convertToMapStringDynamic(
                              product['rawRow'] ?? product),
                          isDarkMode: widget.isDarkMode,
                          allProducts: widget.allProducts,
                          onAddToCart: widget.onAddToCart,
                          onToggleFavorite: widget.onToggleFavorite,
                          favoriteIds: _localFavorites,
                          onCartTap: widget.onCartTap,
                          cartItemCount: widget.cartItemCount,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    key: itemKey,
                    decoration: BoxDecoration(
                      color: AppColors.card(widget.isDarkMode),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.shadow(widget.isDarkMode),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(children: [
                        Positioned.fill(
                          child: ImagenProducto(
                            imagenUrl: product['image']?.toString(),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Color(0xCC000000),
                                  Colors.black
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.4, 0.8, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Column(children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_localFavorites.contains(product['id'])) {
                                    _localFavorites.remove(product['id']);
                                  } else {
                                    _localFavorites.add(product['id']);
                                  }
                                });
                                widget.onToggleFavorite(product);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    shape: BoxShape.circle),
                                child: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      isFav ? AppColors.logoRed : Colors.white,
                                  size: 19,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => widget.onWhatsAppTap(
                                  "Hola SINTHETIX, quiero info de ${product['name']}"),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                    color: Color(0xFF25D366),
                                    shape: BoxShape.circle),
                                child: const FaIcon(FontAwesomeIcons.whatsapp,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ]),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] as String,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "\$${(product['price'] as double).toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.logoCyan),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: GestureDetector(
                            onTap: () {
                              widget.onAddToCart(itemKey, product);
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.logoCyan,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.logoCyan
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ],
                              ),
                              child: const Center(
                                  child: Icon(Icons.add,
                                      color: Colors.white, size: 20)),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class FullCartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  const FullCartPage({super.key, required this.cart});
  @override
  _FullCartPageState createState() => _FullCartPageState();
}

class _FullCartPageState extends State<FullCartPage> {
  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.cart.fold(
        0.0,
        (acc, item) =>
            acc +
            ((item['price'] as double) * ((item['quantity'] ?? 1) as int)));
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Carrito",
            style: TextStyle(
                color: AppColors.textLight, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: widget.cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      color: AppColors.subtextLight, size: 60),
                  const SizedBox(height: 16),
                  Text("El carrito está vacío",
                      style: TextStyle(
                          color: AppColors.subtextLight, fontSize: 16)),
                ],
              ),
            )
          : Column(children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.cart.length,
                  itemBuilder: (context, index) {
                    final item = widget.cart[index];
                    final int qty = (item['quantity'] ?? 1) as int;
                    final double price = (item['price'] as double);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ImagenProducto(
                            imagenUrl: item['image']?.toString(),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'],
                                  style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text("\$${price.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      color: AppColors.subtextLight,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        Text("x$qty",
                            style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Text(
                          "\$${(price * qty).toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ]),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("TOTAL",
                            style: TextStyle(
                                color: AppColors.subtextLight, fontSize: 12)),
                        Text("\$${totalPrice.toStringAsFixed(2)}",
                            style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("VOLVER",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ]),
    );
  }
}

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> productData;
  final bool isDarkMode;
  final List<Map<String, dynamic>> allProducts;
  final Function(GlobalKey, Map<String, dynamic>) onAddToCart;
  final Function(Map<String, dynamic>) onToggleFavorite;
  final Set<String> favoriteIds;
  final VoidCallback onCartTap;
  final int cartItemCount;
  final VoidCallback? onCartChanged;
  const ProductDetailsPage({
    super.key,
    required this.productData,
    required this.isDarkMode,
    required this.allProducts,
    required this.onAddToCart,
    required this.onToggleFavorite,
    required this.favoriteIds,
    required this.onCartTap,
    required this.cartItemCount,
    this.onCartChanged,
  });
  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _quantity = 1;
  Set<String> _localFavorites = {};
  int _localCartCount = 0;

  @override
  void initState() {
    super.initState();
    _localFavorites = Set<String>.from(widget.favoriteIds);
    _localCartCount = widget.cartItemCount;
  }

  @override
  Widget build(BuildContext context) {
    final prod = widget.productData;
    final String name = prod['nombre']?.toString() ?? 'Producto';
    final double price = (prod['precio'] ?? 0).toDouble();
    final String description =
        prod['descripcion']?.toString() ?? 'Sin descripción';
    final String image = prod['imagen_url']?.toString() ?? '';
    final String? productId = prod['id']?.toString();
    final bool isFav = productId != null && _localFavorites.contains(productId);

    return Scaffold(
      backgroundColor: AppColors.background(widget.isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(widget.isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: AppColors.text(widget.isDarkMode)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          name,
          style: TextStyle(
              color: AppColors.text(widget.isDarkMode),
              fontSize: 16,
              fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          GestureDetector(
            onTap: () {
              if (productId != null) {
                widget.onToggleFavorite(prod);
                setState(() {
                  if (_localFavorites.contains(productId)) {
                    _localFavorites.remove(productId);
                  } else {
                    _localFavorites.add(productId);
                  }
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav
                    ? AppColors.logoRed
                    : AppColors.text(widget.isDarkMode),
                size: 24,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onCartTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Stack(children: [
                Icon(Icons.shopping_bag_outlined,
                    color: AppColors.text(widget.isDarkMode), size: 24),
                if (_localCartCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: AppColors.logoRed, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        "$_localCartCount",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              width: double.infinity,
              child: ImagenProducto(
                imagenUrl: image.isEmpty ? null : image,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                icono: Icons.image_not_supported,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(widget.isDarkMode))),
                  const SizedBox(height: 8),
                  Text("\$${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.logoCyan)),
                  const SizedBox(height: 16),
                  Text("Descripción",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text(widget.isDarkMode))),
                  const SizedBox(height: 8),
                  Text(description,
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.subtext(widget.isDarkMode))),
                  const SizedBox(height: 24),
                  Row(children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card(widget.isDarkMode),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            if (_quantity > 1) _quantity--;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Icon(Icons.remove,
                                color: AppColors.text(widget.isDarkMode),
                                size: 20),
                          ),
                        ),
                        Text(
                          "$_quantity",
                          style: TextStyle(
                              color: AppColors.text(widget.isDarkMode),
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _quantity++),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Icon(Icons.add,
                                color: AppColors.text(widget.isDarkMode),
                                size: 20),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final GlobalKey key = GlobalKey();
                          widget.onAddToCart(
                              key, {...prod, 'quantity': _quantity});
                          setState(() => _localCartCount += _quantity);
                          if (widget.onCartChanged != null) {
                            widget.onCartChanged!();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.logoCyan,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Agregar al Carrito",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
