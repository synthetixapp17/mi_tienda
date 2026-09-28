// ============================================
// SINTHETIX PRO - POS + DASHBOARD V9 PROFESIONAL
// Versión 6.2.0 - 100% LOCAL - TOTALMENTE FUNCIONAL
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

// ============================================
// VARIABLES GLOBALES
// ============================================
Map<String, double> tasasCambio = {'USD': 1.0, 'COP': 4500.0, 'VES': 60.0};
Map<String, String> simbolosMoneda = {'USD': '\$', 'COP': '\$', 'VES': 'Bs.'};

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ============================================
// COLORES DE LA APLICACIÓN - DISEÑO PROFESIONAL
// ============================================
class AppColors {
  static Color background(bool isDark) =>
      isDark ? const Color(0xFF0D1117) : const Color(0xFFF7F8FC);
  static Color card(bool isDark) =>
      isDark ? const Color(0xFF161B22) : Colors.white;
  static Color text(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF1A1D26);
  static Color subtext(bool isDark) =>
      isDark ? const Color(0xFF8B949E) : const Color(0xFF64748B);
  static Color drawerBg(bool isDark) =>
      isDark ? const Color(0xFF0D1117) : Colors.white;
  static Color divider(bool isDark) =>
      isDark ? Colors.white10 : const Color(0xFFE2E8F0);
  static Color shadow(bool isDark) =>
      isDark ? Colors.black : const Color(0xFF3B82F6).withValues(alpha: 0.05);

  // Paleta profesional
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);
  static const Color whatsapp = Color(0xFF25D366);
  static const Color dark = Color(0xFF111827);
  static const Color darkSecondary = Color(0xFF1F2937);

  // Gradientes profesionales
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientDark = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF374151)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientDanger = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientWarning = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientVioleta = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientCian = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0E7490)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color subtextLight = Color(0xFF64748B);
  static const Color textLight = Color(0xFF1A1D26);
  static const Color backgroundLight = Color(0xFFF7F8FC);
  static const Color dividerLight = Color(0xFFE2E8F0);
}

// ============================================
// FUNCIONES UTILITARIAS
// ============================================
Color hexToColor(String hex) {
  final hexClean = hex.replaceAll('#', '');
  return Color(int.parse('FF$hexClean', radix: 16));
}

String colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

Future<void> launchURL(String url) async {
  try {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    debugPrint('Error abriendo URL: $e');
  }
}

// ============================================
// SERVICIO DE SONIDO
// ============================================
class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  Future<void> playBeep() async {
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Error sonido: $e');
    }
  }

  Future<void> playSuccess() async {
    try {
      SystemSound.play(SystemSoundType.click);
      await Future.delayed(const Duration(milliseconds: 50));
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Error sonido: $e');
    }
  }

  void dispose() {}
}

// ============================================
// BASE DE DATOS LOCAL (SQLITE) - CORREGIDA
// ============================================
class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._();
  factory LocalDatabase() => _instance;
  LocalDatabase._();

  static Database? _database;
  static Future<Database>? _databaseOpening;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _databaseOpening ??= _initDatabase();
    try {
      _database = await _databaseOpening!;
      return _database!;
    } catch (e) {
      _databaseOpening = null;
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    // WEB: sqflite no puede usar una ruta de archivos del sistema.
    // Usamos SQLite WASM + IndexedDB para que los datos sobrevivan
    // al refresh y queden asociados al navegador/origen.
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        'sinthetix_pro_web.db',
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _createTables,
          onUpgrade: (db, oldVersion, newVersion) async {
            // Mantener datos existentes.
          },
        ),
      );
    }

    // ANDROID/iOS/DESKTOP: SQLite nativo con archivo persistente.
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(dir.path, 'sinthetix_pro.db');

    return await openDatabase(
      dbPath,
      version: 2,
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Mantener datos existentes.
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS productos (
        id TEXT PRIMARY KEY,
        codigo_barras TEXT UNIQUE,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL DEFAULT 0,
        costo REAL DEFAULT 0,
        stock INTEGER DEFAULT 0,
        stock_minimo INTEGER DEFAULT 5,
        categoria TEXT DEFAULT 'General',
        descripcion TEXT,
        imagen_base64 TEXT,
        activo INTEGER DEFAULT 1,
        destacado INTEGER DEFAULT 0,
        unidad_medida TEXT DEFAULT 'pieza',
        talla TEXT,
        color TEXT,
        color_hex TEXT,
        tiene_variantes INTEGER DEFAULT 0,
        descuento REAL DEFAULT 0,
        margen REAL DEFAULT 0,
        creado_en TEXT,
        actualizado_en TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categorias (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        imagen_base64 TEXT,
        activo INTEGER DEFAULT 1,
        creado_en TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clientes (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        telefono TEXT,
        email TEXT,
        direccion TEXT,
        identificacion TEXT UNIQUE,
        tipo TEXT DEFAULT 'Regular',
        puntos INTEGER DEFAULT 0,
        total_compras REAL DEFAULT 0,
        fecha_ultima_compra TEXT,
        creado_en TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ventas (
        id TEXT PRIMARY KEY,
        numero_factura TEXT UNIQUE NOT NULL,
        total REAL NOT NULL DEFAULT 0,
        subtotal REAL DEFAULT 0,
        costo_total REAL DEFAULT 0,
        ganancia_total REAL DEFAULT 0,
        metodo_pago TEXT DEFAULT 'Efectivo',
        moneda TEXT DEFAULT 'USD',
        cliente_nombre TEXT DEFAULT 'Publico General',
        cliente_telefono TEXT,
        cliente_cedula TEXT,
        estado TEXT DEFAULT 'Pagada',
        fecha TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS detalle_venta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id TEXT NOT NULL,
        codigo_barras TEXT,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        cantidad INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        costo_unitario REAL DEFAULT 0,
        ganancia REAL DEFAULT 0,
        variante TEXT,
        unidad_medida TEXT DEFAULT 'pieza',
        descuento_aplicado REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS metodos_pago (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        banco TEXT,
        numero_cuenta TEXT,
        telefono_pago_movil TEXT,
        titular TEXT,
        datos_adicionales TEXT,
        activo INTEGER DEFAULT 1,
        creado_en TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vendedores (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        telefono TEXT,
        comision REAL DEFAULT 0,
        activo INTEGER DEFAULT 1,
        creado_en TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS configuracion (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        nombre_negocio TEXT DEFAULT 'SINTHETIX PRO',
        rif TEXT,
        direccion TEXT,
        telefono TEXT,
        correo TEXT,
        logo_base64 TEXT,
        tasa_cop REAL DEFAULT 4500,
        tasa_ves REAL DEFAULT 60,
        actualizado_en TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS configuracion_ticket (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        nombre_negocio TEXT DEFAULT 'SINTHETIX PRO',
        eslogan TEXT,
        rif TEXT,
        direccion TEXT,
        telefono TEXT,
        email TEXT,
        logo_base64 TEXT,
        mostrar_logo INTEGER DEFAULT 1,
        mostrar_eslogan INTEGER DEFAULT 1,
        mostrar_rif INTEGER DEFAULT 1,
        mostrar_direccion INTEGER DEFAULT 1,
        mostrar_telefono INTEGER DEFAULT 1,
        mostrar_email INTEGER DEFAULT 0,
        mostrar_vendedor INTEGER DEFAULT 1,
        mostrar_cliente INTEGER DEFAULT 1,
        mostrar_descuento INTEGER DEFAULT 1,
        mostrar_impuesto INTEGER DEFAULT 1,
        mostrar_codigo_barras INTEGER DEFAULT 1,
        mostrar_qr INTEGER DEFAULT 1,
        tamano_papel TEXT DEFAULT '80mm',
        color_ticket TEXT DEFAULT 'bn',
        numero_copias INTEGER DEFAULT 1,
        usar_misma_impresora INTEGER DEFAULT 1,
        tamano_etiqueta TEXT DEFAULT '40x30mm',
        mensaje_pie TEXT DEFAULT '¡Gracias por su compra!',
        mensaje_adicional TEXT,
        actualizado_en TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS variantes (
        id TEXT PRIMARY KEY,
        tipo TEXT NOT NULL,
        valor TEXT NOT NULL,
        color_hex TEXT,
        activo INTEGER DEFAULT 1,
        creado_en TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS movimientos_inventario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id TEXT,
        producto_nombre TEXT,
        tipo TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        motivo TEXT,
        fecha TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cierres_caja (
        id TEXT PRIMARY KEY,
        monto_inicial REAL DEFAULT 0,
        monto_final REAL DEFAULT 0,
        total_ventas REAL DEFAULT 0,
        total_gastos REAL DEFAULT 0,
        total_ingresos REAL DEFAULT 0,
        estado TEXT DEFAULT 'Abierta',
        fecha_apertura TEXT,
        fecha_cierre TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS gastos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        caja_id TEXT,
        tipo TEXT DEFAULT 'Egreso',
        descripcion TEXT,
        monto REAL DEFAULT 0,
        fecha TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        email TEXT UNIQUE,
        password_hash TEXT,
        rol TEXT DEFAULT 'vendedor',
        activo INTEGER DEFAULT 1,
        creado_en TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS proveedores (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        contacto TEXT,
        telefono TEXT,
        email TEXT,
        activo INTEGER DEFAULT 1,
        creado_en TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS promociones (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        tipo TEXT DEFAULT 'porcentaje',
        valor REAL DEFAULT 0,
        activo INTEGER DEFAULT 1,
        creado_en TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS compras (
        id TEXT PRIMARY KEY,
        proveedor_id TEXT,
        total REAL DEFAULT 0,
        fecha TEXT NOT NULL,
        creado_en TEXT
      )
    ''');

    // Insertar datos por defecto solo si no existen
    final configExist =
        await db.query('configuracion', where: 'id = ?', whereArgs: [1]);
    if (configExist.isEmpty) {
      await db.insert('configuracion', {
        'id': 1,
        'nombre_negocio': 'SINTHETIX PRO',
        'actualizado_en': DateTime.now().toIso8601String(),
      });
    }

    final ticketExist =
        await db.query('configuracion_ticket', where: 'id = ?', whereArgs: [1]);
    if (ticketExist.isEmpty) {
      await db.insert('configuracion_ticket', {
        'id': 1,
        'nombre_negocio': 'SINTHETIX PRO',
        'actualizado_en': DateTime.now().toIso8601String(),
      });
    }

    final metodosExist = await db.query('metodos_pago');
    if (metodosExist.isEmpty) {
      await db.insert('metodos_pago', {
        'id': 'mp_efectivo',
        'nombre': 'Efectivo',
        'activo': 1,
        'creado_en': DateTime.now().toIso8601String(),
      });
      await db.insert('metodos_pago', {
        'id': 'mp_tarjeta',
        'nombre': 'Tarjeta',
        'activo': 1,
        'creado_en': DateTime.now().toIso8601String(),
      });
      await db.insert('metodos_pago', {
        'id': 'mp_pago_movil',
        'nombre': 'Pago Móvil',
        'activo': 1,
        'creado_en': DateTime.now().toIso8601String(),
      });
    }

    final usuariosExist = await db.query('usuarios');
    if (usuariosExist.isEmpty) {
      await db.insert('usuarios', {
        'id': 'admin001',
        'nombre': 'Administrador',
        'email': 'admin@sinthetix.com',
        'password_hash': 'admin123',
        'rol': 'admin',
        'activo': 1,
        'creado_en': DateTime.now().toIso8601String(),
      });
    }

    final categoriasExist = await db.query('categorias');
    if (categoriasExist.isEmpty) {
      final categoriasDefault = [
        'General',
        'Ropa',
        'Calzado',
        'Accesorios',
        'Electrónica',
        'Alimentos'
      ];
      for (var i = 0; i < categoriasDefault.length; i++) {
        await db.insert('categorias', {
          'id': 'cat_default_$i',
          'nombre': categoriasDefault[i],
          'activo': 1,
          'creado_en': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> getAll(String table,
      {String? orderBy}) async {
    try {
      final db = await database;
      if (orderBy != null) {
        return await db.query(table, orderBy: orderBy);
      }
      return await db.query(table);
    } catch (e) {
      debugPrint('Error getAll($table): $e');
      return [];
    }
  }

  Future<int> insert(String table, Map<String, dynamic> data,
      {bool replace = false}) async {
    try {
      final db = await database;
      if (replace) {
        return await db.insert(table, data,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      return await db.insert(table, data);
    } catch (e) {
      debugPrint('Error insert($table): $e');
      return 0;
    }
  }

  Future<int> update(String table, Map<String, dynamic> data, String where,
      List<dynamic> whereArgs) async {
    try {
      final db = await database;
      return await db.update(table, data, where: where, whereArgs: whereArgs);
    } catch (e) {
      debugPrint('Error update($table): $e');
      return 0;
    }
  }

  Future<int> delete(
      String table, String where, List<dynamic> whereArgs) async {
    try {
      final db = await database;
      return await db.delete(table, where: where, whereArgs: whereArgs);
    } catch (e) {
      debugPrint('Error delete($table): $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> query(String sql,
      [List<dynamic>? args]) async {
    try {
      final db = await database;
      return await db.rawQuery(sql, args);
    } catch (e) {
      debugPrint('Error query: $e');
      return [];
    }
  }
}

// ============================================
// SERVICIO DE BASE DE DATOS - CORREGIDO CON GUARDADO AUTOMÁTICO
// ============================================
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._();
  factory DatabaseService() => _instance;
  DatabaseService._();

  final LocalDatabase _db = LocalDatabase();

  String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextInt(9999).toString();

  // ============ PRODUCTOS ============
  Future<List<Map<String, dynamic>>> getProductos() async {
    final result = await _db.getAll('productos', orderBy: 'nombre');
    debugPrint('Productos cargados: ${result.length}');
    return result;
  }

  Future<Map<String, dynamic>?> crearProducto(Map<String, dynamic> prod) async {
    try {
      prod['id'] = prod['id'] ?? _generateId();
      prod['creado_en'] = DateTime.now().toIso8601String();
      prod['actualizado_en'] = DateTime.now().toIso8601String();
      final codigo = prod['codigo_barras']?.toString().trim() ?? '';
      prod['codigo_barras'] =
          codigo.isEmpty ? await BarcodeService().generarCodigoEAN13() : codigo;
      prod['nombre'] = prod['nombre']?.toString().trim() ?? '';
      prod['precio'] = (prod['precio'] as num?)?.toDouble() ??
          double.tryParse(prod['precio']?.toString() ?? '') ??
          0.0;
      prod['costo'] = (prod['costo'] as num?)?.toDouble() ??
          double.tryParse(prod['costo']?.toString() ?? '') ??
          0.0;
      prod['stock'] = (prod['stock'] as num?)?.toInt() ??
          int.tryParse(prod['stock']?.toString() ?? '') ??
          0;
      prod['stock_minimo'] = (prod['stock_minimo'] as num?)?.toInt() ??
          int.tryParse(prod['stock_minimo']?.toString() ?? '') ??
          5;
      final result = await _db.insert('productos', prod);
      debugPrint(
          'Producto insertado con ID: ${prod['id']}, resultado: $result');
      if (result > 0) {
        productosVersion.value++;
        return prod;
      }
      return null;
    } catch (e) {
      debugPrint('Error creando producto: $e');
      return null;
    }
  }

  Future<bool> actualizarProducto(String id, Map<String, dynamic> prod) async {
    try {
      prod['actualizado_en'] = DateTime.now().toIso8601String();
      final result = await _db.update('productos', prod, 'id = ?', [id]);
      debugPrint('Producto actualizado: $id, filas: $result');
      return result > 0;
    } catch (e) {
      debugPrint('Error actualizando producto: $e');
      return false;
    }
  }

  Future<void> eliminarProducto(String id) async {
    try {
      await _db.delete('productos', 'id = ?', [id]);
      productosVersion.value++;
      debugPrint('Producto eliminado: $id');
    } catch (e) {
      debugPrint('Error eliminando producto: $e');
    }
  }

  Future<Map<String, dynamic>?> buscarPorCodigo(String codigo) async {
    try {
      final results = await _db.query(
        'SELECT * FROM productos WHERE codigo_barras = ?',
        [codigo],
      );
      if (results.isEmpty) return null;
      return results.first;
    } catch (e) {
      return null;
    }
  }

  Future<void> actualizarStock(String productoId, int nuevoStock) async {
    try {
      await _db.update(
          'productos', {'stock': nuevoStock}, 'id = ?', [productoId]);
      productosVersion.value++;
    } catch (e) {
      debugPrint('Error actualizando stock: $e');
    }
  }

  // ============ CATEGORÍAS ============
  Future<List<Map<String, dynamic>>> getCategorias() async {
    final result = await _db.getAll('categorias', orderBy: 'nombre');
    debugPrint('Categorías cargadas: ${result.length}');
    return result;
  }

  Future<void> crearCategoria(Map<String, dynamic> categoria) async {
    try {
      categoria['id'] = categoria['id'] ?? _generateId();
      categoria['creado_en'] = DateTime.now().toIso8601String();
      final result = await _db.insert('categorias', categoria);
      debugPrint(
          'Categoría guardada: ${categoria['nombre']} - Resultado: $result');
    } catch (e) {
      debugPrint('Error creando categoría: $e');
    }
  }

  Future<void> actualizarCategoria(
      String id, Map<String, dynamic> categoria) async {
    try {
      await _db.update('categorias', categoria, 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error actualizando categoría: $e');
    }
  }

  Future<void> eliminarCategoria(String id) async {
    try {
      await _db.delete('categorias', 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error eliminando categoría: $e');
    }
  }

  // ============ MÉTODOS DE PAGO ============
  Future<List<Map<String, dynamic>>> getMetodosPago() async {
    return await _db.getAll('metodos_pago', orderBy: 'nombre');
  }

  Future<void> crearMetodoPago(Map<String, dynamic> metodo) async {
    try {
      metodo['id'] = metodo['id'] ?? _generateId();
      metodo['creado_en'] = DateTime.now().toIso8601String();
      await _db.insert('metodos_pago', metodo);
      debugPrint('Método de pago guardado: ${metodo['nombre']}');
    } catch (e) {
      debugPrint('Error creando método de pago: $e');
    }
  }

  Future<void> actualizarMetodoPago(
      String id, Map<String, dynamic> metodo) async {
    try {
      await _db.update('metodos_pago', metodo, 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error actualizando método de pago: $e');
    }
  }

  Future<void> eliminarMetodoPago(String id) async {
    try {
      await _db.delete('metodos_pago', 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error eliminando método de pago: $e');
    }
  }

  // ============ CLIENTES ============
  Future<List<Map<String, dynamic>>> getClientes() async {
    final result = await _db.getAll('clientes', orderBy: 'nombre');
    debugPrint('Clientes cargados: ${result.length}');
    return result;
  }

  Future<Map<String, dynamic>?> buscarClientePorCedula(String cedula) async {
    try {
      final results = await _db.query(
        'SELECT * FROM clientes WHERE identificacion = ?',
        [cedula],
      );
      if (results.isEmpty) return null;
      return results.first;
    } catch (e) {
      return null;
    }
  }

  Future<void> crearCliente(Map<String, dynamic> cliente) async {
    try {
      cliente['id'] = cliente['id'] ?? _generateId();
      cliente['creado_en'] = DateTime.now().toIso8601String();
      final result = await _db.insert('clientes', cliente);
      debugPrint('Cliente guardado: ${cliente['nombre']} - Resultado: $result');
    } catch (e) {
      debugPrint('Error creando cliente: $e');
    }
  }

  Future<void> actualizarCliente(
      String id, Map<String, dynamic> cliente) async {
    try {
      await _db.update('clientes', cliente, 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error actualizando cliente: $e');
    }
  }

  Future<void> eliminarCliente(String id) async {
    try {
      await _db.delete('clientes', 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error eliminando cliente: $e');
    }
  }

  // ============ VENDEDORES ============
  Future<List<Map<String, dynamic>>> getVendedores() async {
    return await _db.getAll('vendedores', orderBy: 'nombre');
  }

  Future<void> crearVendedor(Map<String, dynamic> vendedor) async {
    try {
      vendedor['id'] = vendedor['id'] ?? _generateId();
      vendedor['creado_en'] = DateTime.now().toIso8601String();
      await _db.insert('vendedores', vendedor);
      debugPrint('Vendedor guardado: ${vendedor['nombre']}');
    } catch (e) {
      debugPrint('Error creando vendedor: $e');
    }
  }

  Future<void> actualizarVendedor(
      String id, Map<String, dynamic> vendedor) async {
    try {
      await _db.update('vendedores', vendedor, 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error actualizando vendedor: $e');
    }
  }

  Future<void> eliminarVendedor(String id) async {
    try {
      await _db.delete('vendedores', 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error eliminando vendedor: $e');
    }
  }

  // ============ VARIANTES ============
  Future<List<Map<String, dynamic>>> getVariantes({String? tipo}) async {
    if (tipo != null) {
      return await _db.query(
          'SELECT * FROM variantes WHERE tipo = ? AND activo = 1', [tipo]);
    }
    return await _db.getAll('variantes');
  }

  Future<List<Map<String, dynamic>>> getTallas() => getVariantes(tipo: 'talla');
  Future<List<Map<String, dynamic>>> getColores() =>
      getVariantes(tipo: 'color');

  Future<void> crearVariante(Map<String, dynamic> variante) async {
    try {
      variante['id'] = variante['id'] ?? _generateId();
      variante['creado_en'] = DateTime.now().toIso8601String();
      await _db.insert('variantes', variante);
      debugPrint('Variante guardada: ${variante['valor']}');
    } catch (e) {
      debugPrint('Error creando variante: $e');
    }
  }

  Future<void> actualizarVariante(
      String id, Map<String, dynamic> variante) async {
    try {
      await _db.update('variantes', variante, 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error actualizando variante: $e');
    }
  }

  Future<void> eliminarVariante(String id) async {
    try {
      await _db.delete('variantes', 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error eliminando variante: $e');
    }
  }

  // ============ VENTAS ============
  Future<Map<String, dynamic>?> crearVenta(Map<String, dynamic> venta) async {
    try {
      venta['id'] = venta['id'] ?? _generateId();
      final result = await _db.insert('ventas', venta);
      if (result <= 0) {
        debugPrint('Venta NO insertada. Resultado SQLite: $result');
        return null;
      }

      // Verificación real: evita mostrar una venta como exitosa si SQLite/Web
      // no la dejó persistida.
      final verificada = await _db.query(
        'SELECT * FROM ventas WHERE id = ?',
        [venta['id']],
      );
      if (verificada.isEmpty) {
        debugPrint('Venta insertada pero no verificada: ${venta['id']}');
        return null;
      }
      return verificada.first;
    } catch (e) {
      debugPrint('Error creando venta: $e');
      return null;
    }
  }

  Future<bool> crearDetalleVenta(Map<String, dynamic> detalle) async {
    try {
      final result = await _db.insert('detalle_venta', detalle);
      if (result <= 0) {
        debugPrint('Detalle NO insertado para venta: ${detalle['venta_id']}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error creando detalle venta: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getVentasHoy() async {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();
    return await _db.query(
        'SELECT * FROM ventas WHERE fecha >= ? ORDER BY fecha DESC', [inicio]);
  }

  Future<List<Map<String, dynamic>>> getVentasPorFecha(
      DateTime inicio, DateTime fin) async {
    return await _db.query(
      'SELECT * FROM ventas WHERE fecha >= ? AND fecha <= ? ORDER BY fecha DESC',
      [inicio.toIso8601String(), fin.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> getDetalleVenta(String ventaId) async {
    return await _db
        .query('SELECT * FROM detalle_venta WHERE venta_id = ?', [ventaId]);
  }

  Future<double> getTotalVentasHoy() async {
    final ventas = await getVentasHoy();
    double total = 0;
    for (var v in ventas) {
      total += (v['total'] as num? ?? 0).toDouble();
    }
    return total;
  }

  Future<int> getCantidadVentasHoy() async {
    final ventas = await getVentasHoy();
    return ventas.length;
  }

  Future<double> getTotalVentasMes() async {
    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month, 1);
    final ventas = await getVentasPorFecha(inicioMes, ahora);
    double total = 0;
    for (var v in ventas) {
      total += (v['total'] as num? ?? 0).toDouble();
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> getProductosMasVendidos() async {
    return await _db.query('''
      SELECT nombre, SUM(cantidad) as cantidad 
      FROM detalle_venta 
      GROUP BY nombre 
      ORDER BY cantidad DESC 
      LIMIT 5
    ''');
  }

  // ============ MOVIMIENTOS INVENTARIO ============
  Future<void> registrarMovimientoInventario(Map<String, dynamic> mov) async {
    try {
      await _db.insert('movimientos_inventario', mov);
    } catch (e) {
      debugPrint('Error registrando movimiento: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMovimientosInventario() async {
    return await _db.getAll('movimientos_inventario', orderBy: 'fecha DESC');
  }

  // ============ CONFIGURACIÓN ============
  Future<Map<String, dynamic>?> getConfiguracion() async {
    final results = await _db.query('SELECT * FROM configuracion WHERE id = 1');
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<void> guardarConfiguracion(Map<String, dynamic> config) async {
    try {
      config['id'] = 1;
      config['actualizado_en'] = DateTime.now().toIso8601String();
      await _db.insert('configuracion', config, replace: true);
      debugPrint('Configuración guardada correctamente');
    } catch (e) {
      debugPrint('Error guardando configuración: $e');
    }
  }

  Future<Map<String, dynamic>?> getConfiguracionTicket() async {
    final results =
        await _db.query('SELECT * FROM configuracion_ticket WHERE id = 1');
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<void> guardarConfiguracionTicket(Map<String, dynamic> config) async {
    try {
      config['id'] = 1;
      config['actualizado_en'] = DateTime.now().toIso8601String();
      await _db.insert('configuracion_ticket', config, replace: true);
      debugPrint('Configuración ticket guardada');
    } catch (e) {
      debugPrint('Error guardando configuración ticket: $e');
    }
  }

  // ============ REPORTES ============
  Future<Map<String, dynamic>> getReporteGeneral(
      DateTime inicio, DateTime fin) async {
    final ventas = await getVentasPorFecha(inicio, fin);
    double total = 0;
    double costoTotal = 0;
    double gananciaTotal = 0;
    for (var v in ventas) {
      total += (v['total'] as num? ?? 0).toDouble();
      costoTotal += (v['costo_total'] as num? ?? 0).toDouble();
      gananciaTotal += (v['ganancia_total'] as num? ?? 0).toDouble();
    }
    return {
      'total_ventas': total,
      'costo_total': costoTotal,
      'ganancia_total': gananciaTotal,
      'cantidad_ventas': ventas.length,
      'ventas': ventas,
    };
  }

  // ============ PROVEEDORES ============
  Future<List<Map<String, dynamic>>> getProveedores() async {
    return await _db.getAll('proveedores', orderBy: 'nombre');
  }

  Future<void> crearProveedor(Map<String, dynamic> proveedor) async {
    try {
      proveedor['id'] = proveedor['id'] ?? _generateId();
      proveedor['creado_en'] = DateTime.now().toIso8601String();
      await _db.insert('proveedores', proveedor);
      debugPrint('Proveedor guardado: ${proveedor['nombre']}');
    } catch (e) {
      debugPrint('Error creando proveedor: $e');
    }
  }

  Future<void> actualizarProveedor(
      String id, Map<String, dynamic> proveedor) async {
    try {
      await _db.update('proveedores', proveedor, 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error actualizando proveedor: $e');
    }
  }

  Future<void> eliminarProveedor(String id) async {
    try {
      await _db.delete('proveedores', 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error eliminando proveedor: $e');
    }
  }

  // ============ PROMOCIONES ============
  Future<List<Map<String, dynamic>>> getPromociones() async {
    return await _db.getAll('promociones', orderBy: 'nombre');
  }

  Future<void> crearPromocion(Map<String, dynamic> promocion) async {
    try {
      promocion['id'] = promocion['id'] ?? _generateId();
      promocion['creado_en'] = DateTime.now().toIso8601String();
      await _db.insert('promociones', promocion);
      debugPrint('Promoción guardada: ${promocion['nombre']}');
    } catch (e) {
      debugPrint('Error creando promoción: $e');
    }
  }

  Future<void> actualizarPromocion(
      String id, Map<String, dynamic> promocion) async {
    try {
      await _db.update('promociones', promocion, 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error actualizando promoción: $e');
    }
  }

  Future<void> eliminarPromocion(String id) async {
    try {
      await _db.delete('promociones', 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error eliminando promoción: $e');
    }
  }

  // ============ USUARIOS ============
  Future<List<Map<String, dynamic>>> getUsuarios() async {
    return await _db.getAll('usuarios', orderBy: 'nombre');
  }

  Future<void> crearUsuario(Map<String, dynamic> usuario) async {
    try {
      usuario['id'] = usuario['id'] ?? _generateId();
      usuario['creado_en'] = DateTime.now().toIso8601String();
      await _db.insert('usuarios', usuario);
      debugPrint('Usuario guardado: ${usuario['nombre']}');
    } catch (e) {
      debugPrint('Error creando usuario: $e');
    }
  }

  Future<void> actualizarUsuario(
      String id, Map<String, dynamic> usuario) async {
    try {
      await _db.update('usuarios', usuario, 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error actualizando usuario: $e');
    }
  }

  Future<void> eliminarUsuario(String id) async {
    try {
      await _db.delete('usuarios', 'id = ?', [id]);
    } catch (e) {
      debugPrint('Error eliminando usuario: $e');
    }
  }

  // ============ PERFIL ============
  Future<Map<String, dynamic>?> getPerfilUsuario() async {
    final results =
        await _db.query('SELECT * FROM usuarios WHERE id = ?', ['admin001']);
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<void> actualizarPerfil(Map<String, dynamic> data) async {
    try {
      await _db.update('usuarios', data, 'id = ?', ['admin001']);
    } catch (e) {
      debugPrint('Error actualizando perfil: $e');
    }
  }
}

// ============================================
// SERVICIO DE CÓDIGOS DE BARRAS
// ============================================
class BarcodeService {
  static final BarcodeService _instance = BarcodeService._();
  factory BarcodeService() => _instance;
  BarcodeService._();

  Future<String> generarCodigoEAN13() async {
    final random = Random();
    final codigoBase = List.generate(12, (i) => random.nextInt(10)).join();
    final digitoVerificacion = _calcularDigitoVerificacion(codigoBase);
    return '$codigoBase$digitoVerificacion';
  }

  int _calcularDigitoVerificacion(String codigo) {
    int suma = 0;
    for (int i = 0; i < codigo.length; i++) {
      int digito = int.parse(codigo[i]);
      suma += (i % 2 == 0) ? digito : digito * 3;
    }
    return (10 - (suma % 10)) % 10;
  }
}

// ============================================
// SERVICIO DE CAJA
// ============================================
class CajaService {
  final LocalDatabase _db = LocalDatabase();

  Future<Map<String, dynamic>?> getCajaAbierta() async {
    final results = await _db
        .query("SELECT * FROM cierres_caja WHERE estado = 'Abierta' LIMIT 1");
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<void> abrirCaja(double montoInicial) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _db.insert('cierres_caja', {
      'id': id,
      'monto_inicial': montoInicial,
      'estado': 'Abierta',
      'fecha_apertura': DateTime.now().toIso8601String(),
    });
  }

  Future<void> cerrarCaja(double montoFinal) async {
    final caja = await getCajaAbierta();
    if (caja != null) {
      await _db.update(
          'cierres_caja',
          {
            'monto_final': montoFinal,
            'estado': 'Cerrada',
            'fecha_cierre': DateTime.now().toIso8601String(),
          },
          'id = ?',
          [caja['id']]);
    }
  }

  Future<void> agregarVentaACaja(double monto) async {
    final caja = await getCajaAbierta();
    if (caja != null) {
      final nuevoTotal =
          ((caja['total_ventas'] as num? ?? 0).toDouble()) + monto;
      await _db.update(
          'cierres_caja', {'total_ventas': nuevoTotal}, 'id = ?', [caja['id']]);
    }
  }

  Future<void> registrarMovimiento(
      String tipo, double monto, String descripcion) async {
    final caja = await getCajaAbierta();
    if (caja != null) {
      await _db.insert('gastos', {
        'caja_id': caja['id'],
        'tipo': tipo,
        'descripcion': descripcion,
        'monto': monto,
        'fecha': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getMovimientosHoy() async {
    return await _db.getAll('gastos', orderBy: 'fecha DESC');
  }

  Future<List<Map<String, dynamic>>> getHistorialCajas() async {
    return await _db.query(
        "SELECT * FROM cierres_caja WHERE estado = 'Cerrada' ORDER BY fecha_cierre DESC");
  }
}

// ============================================
// SERVICIO DE TICKET
// ============================================
class TicketService {
  static final TicketService _instance = TicketService._();
  factory TicketService() => _instance;
  TicketService._();

  final _db = DatabaseService();

  Future<String?> generarPDFTicket({
    required String numeroFactura,
    required String clienteNombre,
    required String clienteTelefono,
    required String metodoPago,
    required double total,
    required double costoTotal,
    required double gananciaTotal,
    required List<Map<String, dynamic>> productos,
  }) async {
    try {
      final config = await _db.getConfiguracionTicket();
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(10),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    config?['nombre_negocio'] ?? 'SINTHETIX PRO',
                    style: const pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                if (config?['eslogan'] != null &&
                    config!['eslogan'].toString().isNotEmpty)
                  pw.Center(
                      child: pw.Text(config['eslogan'],
                          style: const pw.TextStyle(fontSize: 10))),
                pw.Divider(),
                pw.SizedBox(height: 5),
                pw.Text('FACTURA: $numeroFactura',
                    style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Cliente: $clienteNombre',
                    style: const pw.TextStyle(fontSize: 10)),
                if (clienteTelefono.isNotEmpty)
                  pw.Text('Tel: $clienteTelefono',
                      style: const pw.TextStyle(fontSize: 8)),
                pw.Divider(),
                pw.SizedBox(height: 5),
                ...productos.map((p) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(p['nombre'] ?? '',
                          style: const pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        '${p['cantidad']} x \$${(p['precio'] as num).toStringAsFixed(2)} = \$${((p['precio'] as num) * (p['cantidad'] as num)).toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.SizedBox(height: 3),
                    ],
                  );
                }),
                pw.Divider(),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL:',
                        style: const pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('\$${total.toStringAsFixed(2)}',
                        style: const pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Pago:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(metodoPago, style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Divider(),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    config?['mensaje_pie'] ?? '¡Gracias por su compra!',
                    style: const pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();

      // WEB: path_provider no implementa getTemporaryDirectory() en esta
      // configuración del proyecto. En navegador entregamos el PDF mediante
      // el plugin de impresión, que sí tiene implementación para Web.
      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'ticket_$numeroFactura.pdf',
        );
        return 'web:ticket_$numeroFactura.pdf';
      }

      // ANDROID / DESKTOP: guardamos el PDF en el directorio temporal local.
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ticket_$numeroFactura.pdf');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Error generando PDF: $e');
      return null;
    }
  }
}

// ============================================
// DATOS DE PRUEBA
// ============================================
class DatosPrueba {
  static int facturaCounter = 1;

  static String generarNumeroFactura() {
    final ahora = DateTime.now();
    final timestamp = ahora.millisecondsSinceEpoch.toString();
    final corto = timestamp.substring(timestamp.length - 8);
    final contador = (facturaCounter++).toString().padLeft(4, '0');
    return 'FAC-$corto-$contador';
  }
}

// ============================================
// WIDGET DE IMAGEN DE PRODUCTO
// ============================================
class ImagenProducto extends StatelessWidget {
  final String? imagenBase64;
  final double width;
  final double height;
  final BoxFit fit;
  final IconData icono;

  const ImagenProducto({
    super.key,
    this.imagenBase64,
    this.width = 60,
    this.height = 60,
    this.fit = BoxFit.cover,
    this.icono = Icons.shopping_bag_outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (imagenBase64 != null && imagenBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(imagenBase64!);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (e) {
        return _placeholder();
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(icono, color: AppColors.subtextLight, size: width * 0.4),
    );
  }
}
// ============================================
// CONTINUACIÓN - ETAPA 2 de 6
// ============================================

// ============================================
// WIDGET: SELECTOR DE TALLAS - DISEÑO PROFESIONAL
// ============================================
class SelectorTallas extends StatefulWidget {
  final List<Map<String, dynamic>> tallas;
  final String? tallaInicial;
  final bool isDark;
  final Function(String) onSeleccion;

  const SelectorTallas({
    super.key,
    required this.tallas,
    this.tallaInicial,
    required this.isDark,
    required this.onSeleccion,
  });

  @override
  State<SelectorTallas> createState() => _SelectorTallasState();
}

class _SelectorTallasState extends State<SelectorTallas> {
  String? _seleccionada;

  @override
  void initState() {
    super.initState();
    _seleccionada = widget.tallaInicial;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tallas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background(widget.isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider(widget.isDark)),
        ),
        child: Row(
          children: [
            Icon(Icons.straighten,
                color: AppColors.subtext(widget.isDark), size: 20),
            const SizedBox(width: 10),
            Text('No hay tallas configuradas',
                style: TextStyle(
                    color: AppColors.subtext(widget.isDark), fontSize: 12)),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.tallas.map((talla) {
        final valor = talla['valor'] ?? '';
        final sel = _seleccionada == valor;
        return GestureDetector(
          onTap: () {
            setState(() => _seleccionada = valor);
            widget.onSeleccion(valor);
            HapticFeedback.selectionClick();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: sel ? AppColors.gradientPrimary : null,
              color: sel ? null : AppColors.background(widget.isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    sel ? AppColors.primary : AppColors.divider(widget.isDark),
                width: sel ? 2 : 1,
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              valor,
              style: TextStyle(
                color: sel ? Colors.white : AppColors.text(widget.isDark),
                fontSize: 14,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================
// WIDGET: SELECTOR DE COLORES - DISEÑO PROFESIONAL
// ============================================
class SelectorColores extends StatefulWidget {
  final List<Map<String, dynamic>> colores;
  final String? colorInicial;
  final bool isDark;
  final Function(String) onSeleccion;

  const SelectorColores({
    super.key,
    required this.colores,
    this.colorInicial,
    required this.isDark,
    required this.onSeleccion,
  });

  @override
  State<SelectorColores> createState() => _SelectorColoresState();
}

class _SelectorColoresState extends State<SelectorColores> {
  String? _seleccionado;

  @override
  void initState() {
    super.initState();
    _seleccionado = widget.colorInicial;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.colores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background(widget.isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider(widget.isDark)),
        ),
        child: Row(
          children: [
            Icon(Icons.palette_outlined,
                color: AppColors.subtext(widget.isDark), size: 20),
            const SizedBox(width: 10),
            Text('No hay colores configurados',
                style: TextStyle(
                    color: AppColors.subtext(widget.isDark), fontSize: 12)),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: widget.colores.map((color) {
        final valor = color['valor'] ?? '';
        final hex = color['color_hex'] ?? '#CCCCCC';
        final colorVisual = hexToColor(hex);
        final sel = _seleccionado == valor;
        return GestureDetector(
          onTap: () {
            setState(() => _seleccionado = valor);
            widget.onSeleccion(valor);
            HapticFeedback.selectionClick();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorVisual,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: sel
                        ? AppColors.primary
                        : AppColors.divider(widget.isDark),
                    width: sel ? 3 : 1,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: sel
                    ? Icon(
                        Icons.check,
                        color: colorVisual.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        size: 26,
                      )
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                valor,
                style: TextStyle(
                  color: sel
                      ? AppColors.primary
                      : AppColors.subtext(widget.isDark),
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ============================================
// WIDGET: SCANNER RÁPIDO REUTILIZABLE
// ============================================
class ScannerRapido extends StatefulWidget {
  final bool isDark;
  final Future<void> Function(String) onCodigoDetectado;
  final VoidCallback onCerrar;

  const ScannerRapido({
    super.key,
    required this.isDark,
    required this.onCodigoDetectado,
    required this.onCerrar,
  });

  @override
  State<ScannerRapido> createState() => _ScannerRapidoState();
}

class _ScannerRapidoState extends State<ScannerRapido>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  late final AnimationController _lineaController;
  bool _linternaEncendida = false;
  bool _procesando = false;
  String? _ultimoCodigo;
  DateTime? _ultimoEscaneo;
  // Evita duplicados del mismo cuadro, pero no frena el escaneo continuo.
  final Duration _tiempoDebounce = const Duration(milliseconds: 220);

  @override
  void initState() {
    super.initState();
    _lineaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat(reverse: true);
    _inicializarCamara();
  }

  Future<void> _inicializarCamara() async {
    try {
      final controller = MobileScannerController(
        // Dejamos los formatos habituales de POS. Al limitar formatos,
        // ML Kit tiene menos trabajo que revisar en cada cuadro.
        formats: const [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.itf,
          BarcodeFormat.qrCode,
        ],
        detectionSpeed: DetectionSpeed.unrestricted,
        detectionTimeoutMs: 80,
        facing: CameraFacing.back,
        torchEnabled: false,
        autoZoom: true,
        cameraResolution: const Size(1920, 1080),
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() => _controller = controller);

      // Dejamos que el widget se monte antes de arrancar la cÃ¡mara.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        controller.dispose();
        return;
      }

      await controller.start();
    } catch (e) {
      debugPrint('Error inicializando scanner: $e');
    }
  }

  void _toggleLinterna() {
    final c = _controller;
    if (c == null) return;
    setState(() => _linternaEncendida = !_linternaEncendida);
    c.toggleTorch();
  }

  void _cambiarCamara() {
    _controller?.switchCamera();
  }

  String _normalizarCodigo(String codigo) {
    return codigo
        .trim()
        .replaceAll(RegExp(r'[\s\u200B\uFEFF]'), '')
        .toUpperCase();
  }

  Future<void> _procesarCodigo(String codigo) async {
    final limpio = _normalizarCodigo(codigo);
    if (limpio.isEmpty || _procesando) return;

    if (_ultimoCodigo == limpio && _ultimoEscaneo != null) {
      final diferencia = DateTime.now().difference(_ultimoEscaneo!);
      if (diferencia < _tiempoDebounce) return;
    }

    _ultimoCodigo = limpio;
    _ultimoEscaneo = DateTime.now();

    if (mounted) setState(() => _procesando = true);

    try {
      HapticFeedback.mediumImpact();
      await widget.onCodigoDetectado(limpio);
    } finally {
      // No esperamos 400/800 ms. La cÃ¡mara queda viva para el siguiente
      // producto y el siguiente frame puede volver a detectar enseguida.
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  void dispose() {
    _lineaController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lineProgress = CurvedAnimation(
      parent: _lineaController,
      curve: Curves.easeInOut,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_controller != null)
              MobileScanner(
                controller: _controller!,
                fit: BoxFit.cover,
                onDetect: (capture) {
                  for (final barcode in capture.barcodes) {
                    final raw = barcode.rawValue;
                    if (raw != null && raw.trim().isNotEmpty) {
                      _procesarCodigo(raw);
                      break;
                    }
                  }
                },
              )
            else
              const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),

            // MÃ¡scara: mantiene el centro luminoso y oscurece el resto.
            IgnorePointer(
              child: CustomPaint(
                painter: _ScannerMaskPainter(),
              ),
            ),

            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  final frameW = w < 420 ? w * .82 : 360.0;
                  final frameH = (frameW * .43).clamp(135.0, 190.0);

                  return SizedBox(
                    width: frameW,
                    height: frameH,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ScannerFramePainter(
                              active: _procesando,
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: lineProgress,
                          builder: (context, child) {
                            final top = (frameH - 4) * lineProgress.value;
                            return Positioned(
                              left: 12,
                              right: 12,
                              top: top,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      _procesando
                                          ? Colors.greenAccent
                                          : Colors.blueAccent,
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_procesando
                                              ? Colors.greenAccent
                                              : Colors.blueAccent)
                                          .withValues(alpha: .75),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Positioned(
              top: 14,
              right: 14,
              child: Row(
                children: [
                  _buildControlCamara(
                    icon: _linternaEncendida
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: _linternaEncendida ? Colors.amber : Colors.white,
                    onTap: _toggleLinterna,
                  ),
                  const SizedBox(width: 8),
                  _buildControlCamara(
                    icon: Icons.cameraswitch_rounded,
                    color: Colors.white,
                    onTap: _cambiarCamara,
                  ),
                  const SizedBox(width: 8),
                  _buildControlCamara(
                    icon: Icons.close_rounded,
                    color: Colors.white,
                    onTap: widget.onCerrar,
                  ),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .16),
                    ),
                  ),
                  child: Text(
                    _procesando
                        ? 'CÃ³digo detectado Â· agregando al carrito'
                        : 'Apunta al cÃ³digo de barras',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCamara({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: .58),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _ScannerMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: .38);
    final centerW = size.width < 420 ? size.width * .82 : 360.0;
    final centerH = (centerW * .43).clamp(135.0, 190.0);
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: centerW,
      height: centerH,
    );
    final outer = Path()..addRect(Offset.zero & size);
    final inner = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScannerFramePainter extends CustomPainter {
  final bool active;

  const _ScannerFramePainter({required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final color = active ? Colors.greenAccent : Colors.blueAccent;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const r = Radius.circular(18);
    const corner = 34.0;

    final x = size.width;
    final y = size.height;

    final paths = <Path>[
      Path()
        ..moveTo(0, corner)
        ..lineTo(0, 18)
        ..quadraticBezierTo(0, 0, 18, 0)
        ..lineTo(corner, 0),
      Path()
        ..moveTo(x - corner, 0)
        ..lineTo(x - 18, 0)
        ..quadraticBezierTo(x, 0, x, 18)
        ..lineTo(x, corner),
      Path()
        ..moveTo(0, y - corner)
        ..lineTo(0, y - 18)
        ..quadraticBezierTo(0, y, 18, y)
        ..lineTo(corner, y),
      Path()
        ..moveTo(x - corner, y)
        ..lineTo(x - 18, y)
        ..quadraticBezierTo(x, y, x, y - 18)
        ..lineTo(x, y - corner),
    ];

    for (final p in paths) {
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) =>
      oldDelegate.active != active;
}



class _ScannerRapidoState extends State<ScannerRapido>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  late final AnimationController _lineaController;
  bool _linternaEncendida = false;
  bool _procesando = false;
  String? _ultimoCodigo;
  DateTime? _ultimoEscaneo;
  // Evita duplicados del mismo cuadro, pero no frena el escaneo continuo.
  final Duration _tiempoDebounce = const Duration(milliseconds: 220);

  @override
  void initState() {
    super.initState();
    _lineaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat(reverse: true);
    _inicializarCamara();
  }

  Future<void> _inicializarCamara() async {
    try {
      final controller = MobileScannerController(
        // Dejamos los formatos habituales de POS. Al limitar formatos,
        // ML Kit tiene menos trabajo que revisar en cada cuadro.
        formats: const [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.itf,
          BarcodeFormat.qrCode,
        ],
        detectionSpeed: DetectionSpeed.unrestricted,
        detectionTimeoutMs: 80,
        facing: CameraFacing.back,
        torchEnabled: false,
        autoZoom: true,
        cameraResolution: const Size(1920, 1080),
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() => _controller = controller);

      // Dejamos que el widget se monte antes de arrancar la cámara.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        controller.dispose();
        return;
      }

      await controller.start();
    } catch (e) {
      debugPrint('Error inicializando scanner: $e');
    }
  }

  void _toggleLinterna() {
    final c = _controller;
    if (c == null) return;
    setState(() => _linternaEncendida = !_linternaEncendida);
    c.toggleTorch();
  }

  void _cambiarCamara() {
    _controller?.switchCamera();
  }

  String _normalizarCodigo(String codigo) {
    return codigo
        .trim()
        .replaceAll(RegExp(r'[\s\u200B\uFEFF]'), '')
        .toUpperCase();
  }

  Future<void> _procesarCodigo(String codigo) async {
    final limpio = _normalizarCodigo(codigo);
    if (limpio.isEmpty || _procesando) return;

    if (_ultimoCodigo == limpio && _ultimoEscaneo != null) {
      final diferencia = DateTime.now().difference(_ultimoEscaneo!);
      if (diferencia < _tiempoDebounce) return;
    }

    _ultimoCodigo = limpio;
    _ultimoEscaneo = DateTime.now();

    if (mounted) setState(() => _procesando = true);

    try {
      HapticFeedback.mediumImpact();
      await widget.onCodigoDetectado(limpio);
    } finally {
      // No esperamos 400/800 ms. La cámara queda viva para el siguiente
      // producto y el siguiente frame puede volver a detectar enseguida.
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  void dispose() {
    _lineaController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lineProgress = CurvedAnimation(
      parent: _lineaController,
      curve: Curves.easeInOut,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_controller != null)
              MobileScanner(
                controller: _controller!,
                fit: BoxFit.cover,
                onDetect: (capture) {
                  for (final barcode in capture.barcodes) {
                    final raw = barcode.rawValue;
                    if (raw != null && raw.trim().isNotEmpty) {
                      _procesarCodigo(raw);
                      break;
                    }
                  }
                },
              )
            else
              const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),

            // Máscara: mantiene el centro luminoso y oscurece el resto.
            IgnorePointer(
              child: CustomPaint(
                painter: _ScannerMaskPainter(),
              ),
            ),

            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  final frameW = w < 420 ? w * .82 : 360.0;
                  final frameH = (frameW * .43).clamp(135.0, 190.0);

                  return SizedBox(
                    width: frameW,
                    height: frameH,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ScannerFramePainter(
                              active: _procesando,
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: lineProgress,
                          builder: (context, child) {
                            final top = (frameH - 4) * lineProgress.value;
                            return Positioned(
                              left: 12,
                              right: 12,
                              top: top,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      _procesando
                                          ? Colors.greenAccent
                                          : Colors.blueAccent,
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_procesando
                                              ? Colors.greenAccent
                                              : Colors.blueAccent)
                                          .withValues(alpha: .75),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Positioned(
              top: 14,
              right: 14,
              child: Row(
                children: [
                  _buildControlCamara(
                    icon: _linternaEncendida
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: _linternaEncendida ? Colors.amber : Colors.white,
                    onTap: _toggleLinterna,
                  ),
                  const SizedBox(width: 8),
                  _buildControlCamara(
                    icon: Icons.cameraswitch_rounded,
                    color: Colors.white,
                    onTap: _cambiarCamara,
                  ),
                  const SizedBox(width: 8),
                  _buildControlCamara(
                    icon: Icons.close_rounded,
                    color: Colors.white,
                    onTap: widget.onCerrar,
                  ),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .16),
                    ),
                  ),
                  child: Text(
                    _procesando
                        ? 'Código detectado · agregando al carrito'
                        : 'Apunta al código de barras',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCamara({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: .58),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _ScannerMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: .38);
    final centerW = size.width < 420 ? size.width * .82 : 360.0;
    final centerH = (centerW * .43).clamp(135.0, 190.0);
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: centerW,
      height: centerH,
    );
    final outer = Path()..addRect(Offset.zero & size);
    final inner = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScannerFramePainter extends CustomPainter {
  final bool active;

  const _ScannerFramePainter({required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final color = active ? Colors.greenAccent : Colors.blueAccent;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const r = Radius.circular(18);
    const corner = 34.0;

    final x = size.width;
    final y = size.height;

    final paths = <Path>[
      Path()
        ..moveTo(0, corner)
        ..lineTo(0, 18)
        ..quadraticBezierTo(0, 0, 18, 0)
        ..lineTo(corner, 0),
      Path()
        ..moveTo(x - corner, 0)
        ..lineTo(x - 18, 0)
        ..quadraticBezierTo(x, 0, x, 18)
        ..lineTo(x, corner),
      Path()
        ..moveTo(0, y - corner)
        ..lineTo(0, y - 18)
        ..quadraticBezierTo(0, y, 18, y)
        ..lineTo(corner, y),
      Path()
        ..moveTo(x - corner, y)
        ..lineTo(x - 18, y)
        ..quadraticBezierTo(x, y, x, y - 18)
        ..lineTo(x, y - corner),
    ];

    for (final p in paths) {
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) =>
      oldDelegate.active != active;
}

// ============================================
// APP PRINCIPAL
// ============================================

/// Señal global para sincronizar automáticamente los productos en todas las pantallas.
final ValueNotifier<int> productosVersion = ValueNotifier<int>(0);
final ValueNotifier<int> ventasVersion = ValueNotifier<int>(0);

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
      'configurar_ticket': 9,
      'variantes': 10,
      'codigos_barras': 11,
      'backup': 12,
      'caja': 13,
      'perfil': 14,
      'inventario': 15,
      'tienda': 16,
      'proveedores': 17,
      'promociones': 18,
      'compras': 19,
      'roles': 20,
      'estadisticas': 21,
    };
    if (m.containsKey(ruta)) {
      setState(() => _currentIndex = m[ruta]!);
    }
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
        scaffoldBackgroundColor: AppColors.background(false),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textLight),
          titleTextStyle: TextStyle(
            color: AppColors.textLight,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 3,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background(true),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: Color(0xFF161B22),
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 3,
            shadowColor: AppColors.primary.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
      themeMode: _modoOscuro ? ThemeMode.dark : ThemeMode.light,
      home: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          if (_currentIndex != 0) {
            setState(() => _currentIndex = 0);
          }
        },
        child: Scaffold(
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
              ConfigurarTicketScreen(
                onAbrirSidebar: _abrirSidebar,
                modoOscuro: _modoOscuro,
              ),
              ConfiguracionVariantesScreen(
                onAbrirSidebar: _abrirSidebar,
                modoOscuro: _modoOscuro,
              ),
              CodigosBarrasScreen(
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
              EstadisticasScreen(
                onAbrirSidebar: _abrirSidebar,
                modoOscuro: _modoOscuro,
              ),
            ],
          ),
          bottomNavigationBar: _currentIndex <= 1
              ? CurvedNavigationBar(
                  backgroundColor: Colors.transparent,
                  color: _modoOscuro
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFE5E7EB),
                  buttonBackgroundColor: _modoOscuro
                      ? const Color(0xFF374151)
                      : const Color(0xFFD1D5DB),
                  height: 65,
                  animationDuration: const Duration(milliseconds: 300),
                  animationCurve: Curves.easeInOut,
                  index: _currentIndex,
                  items: [
                    CurvedNavigationBarItem(
                      child: Icon(
                        Icons.call_to_action_outlined,
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
                        Icons.dashboard_rounded,
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
      ),
    );
  }
}

// ============================================
// MENÚ LATERAL (SIDEBAR)
// ============================================
class SidebarMenu extends StatelessWidget {
  final bool modoOscuro;
  final VoidCallback onToggleModoOscuro;
  final Function(String) onNavigate;
  const SidebarMenu({
    super.key,
    required this.modoOscuro,
    required this.onToggleModoOscuro,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.drawerBg(modoOscuro),
      width: MediaQuery.of(context).size.width >= 900
          ? 360
          : MediaQuery.of(context).size.width * 0.86,
      child: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.gradientDark,
              border: Border(
                bottom: BorderSide(color: AppColors.divider(modoOscuro)),
              ),
            ),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.store_rounded,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SINTHETIX PRO',
                        style: TextStyle(
                            color: AppColors.text(modoOscuro),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5)),
                    Text('Sistema POS Offline',
                        style: TextStyle(
                            color: AppColors.subtext(modoOscuro),
                            fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                    modoOscuro
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: AppColors.text(modoOscuro),
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
                _seccion('PRINCIPAL', modoOscuro),
                _item(Icons.call_to_action_outlined, 'Punto de Venta',
                    () => onNavigate('pos'), modoOscuro, AppColors.primary),
                _item(Icons.dashboard_rounded, 'Dashboard',
                    () => onNavigate('dashboard'), modoOscuro, AppColors.info),
                _item(
                    Icons.storefront_rounded,
                    'Tienda Sinthetix',
                    () => onNavigate('tienda'),
                    modoOscuro,
                    AppColors.secondary),
                const SizedBox(height: 16),
                _seccion('ADMINISTRACIÓN', modoOscuro),
                _item(
                    Icons.store_mall_directory_outlined,
                    'Mi Negocio',
                    () => onNavigate('configuracion'),
                    modoOscuro,
                    AppColors.primary),
                _item(
                    Icons.category_outlined,
                    'Categorías',
                    () => onNavigate('categorias'),
                    modoOscuro,
                    AppColors.warning),
                _item(
                    Icons.payment_outlined,
                    'Métodos de Pago',
                    () => onNavigate('metodos_pago'),
                    modoOscuro,
                    AppColors.success),
                _item(
                    Icons.people_outline,
                    'Vendedores',
                    () => onNavigate('vendedores'),
                    modoOscuro,
                    AppColors.primary),
                _item(Icons.person_outline, 'Clientes',
                    () => onNavigate('clientes'), modoOscuro, AppColors.info),
                _item(
                    Icons.inventory_2_outlined,
                    'Inventario',
                    () => onNavigate('inventario'),
                    modoOscuro,
                    AppColors.warning),
                _item(
                    Icons.local_shipping_outlined,
                    'Proveedores',
                    () => onNavigate('proveedores'),
                    modoOscuro,
                    AppColors.primary),
                _item(Icons.shopping_cart_checkout, 'Compras',
                    () => onNavigate('compras'), modoOscuro, AppColors.success),
                _item(
                    Icons.local_offer_outlined,
                    'Promociones',
                    () => onNavigate('promociones'),
                    modoOscuro,
                    AppColors.danger),
                _item(Icons.admin_panel_settings_outlined, 'Usuarios y Roles',
                    () => onNavigate('roles'), modoOscuro, AppColors.primary),
                const SizedBox(height: 16),
                _seccion('FINANZAS', modoOscuro),
                _item(Icons.point_of_sale_rounded, 'Caja',
                    () => onNavigate('caja'), modoOscuro, AppColors.success),
                _item(
                    Icons.bar_chart_rounded,
                    'Estadísticas',
                    () => onNavigate('estadisticas'),
                    modoOscuro,
                    AppColors.info),
                _item(
                    Icons.receipt_long_outlined,
                    'Reportes',
                    () => onNavigate('reportes'),
                    modoOscuro,
                    AppColors.warning),
                const SizedBox(height: 16),
                _seccion('HERRAMIENTAS', modoOscuro),
                _item(
                    Icons.print_outlined,
                    'Impresora',
                    () => onNavigate('impresora'),
                    modoOscuro,
                    AppColors.primary),
                _item(
                    Icons.receipt_rounded,
                    'Configurar Ticket',
                    () => onNavigate('configurar_ticket'),
                    modoOscuro,
                    AppColors.info),
                _item(
                    Icons.straighten,
                    'Tallas y Colores',
                    () => onNavigate('variantes'),
                    modoOscuro,
                    AppColors.primary),
                _item(
                    Icons.qr_code_2_rounded,
                    'Códigos de Barras',
                    () => onNavigate('codigos_barras'),
                    modoOscuro,
                    AppColors.success),
                _item(Icons.backup_outlined, 'Respaldo',
                    () => onNavigate('backup'), modoOscuro, AppColors.warning),
                _item(Icons.person_outline, 'Mi Perfil',
                    () => onNavigate('perfil'), modoOscuro, AppColors.primary),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.divider(modoOscuro)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text('v7.0.0 · Modo Offline',
                    style: TextStyle(
                        color: AppColors.subtext(modoOscuro),
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _seccion(String t, bool isDark) => Padding(
        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
        child: Text(t,
            style: TextStyle(
                color: AppColors.subtext(isDark),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2)),
      );

  Widget _item(
          IconData ic, String t, VoidCallback tap, bool isDark, Color color) =>
      Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ic, color: color, size: 20),
          ),
          title: Text(t,
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          trailing: Icon(Icons.chevron_right_rounded,
              color: AppColors.subtext(isDark), size: 18),
          onTap: tap,
          dense: true,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
// ============================================
// CONTINUACIÓN - ETAPA 3 de 6
// ============================================

// ============================================
// PANTALLA POS - ESCANER DE VENTAS CON SCANNER RÁPIDO
// ============================================
class EscanerVentas extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final VoidCallback onNavigateToDashboard;
  final bool modoOscuro;
  final VoidCallback onToggleModoOscuro;
  const EscanerVentas({
    super.key,
    required this.onAbrirSidebar,
    required this.onNavigateToDashboard,
    required this.modoOscuro,
    required this.onToggleModoOscuro,
  });
  @override
  State<EscanerVentas> createState() => _EscanerVentasState();
}

class _EscanerVentasState extends State<EscanerVentas> {
  MobileScannerController? cameraController;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _escuchando = false;
  String _textoVoz = '';
  final _buscador = TextEditingController();
  final _db = DatabaseService();
  final _cajaService = CajaService();
  final _ticketService = TicketService();
  final SoundService _soundService = SoundService();
  List<Map<String, dynamic>> carrito = [];
  List<Map<String, dynamic>> listaProductos = [];
  List<Map<String, dynamic>> busqueda = [];
  List<Map<String, dynamic>> _tallas = [];
  List<Map<String, dynamic>> _colores = [];
  bool _camara = false;
  bool _mostrarBusqueda = false;
  bool _mostrarTodos = false;
  bool _cargando = true;
  bool _linternaEncendida = false;
  bool _procesandoCodigo = false;
  String _filtroCategoriaPOS = 'Todas';
  bool _soloDisponiblesPOS = false;
  double? _precioMinPOS;
  double? _precioMaxPOS;
  String? _ultimoCodigoEscaneado;
  DateTime? _ultimoEscaneo;
  // Solo bloquea duplicados del mismo código durante un instante.
  final Duration _tiempoDebounce = const Duration(milliseconds: 220);

  bool get _isTablet => MediaQuery.of(context).size.width >= 600;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 1024;

  void _vibrar() => HapticFeedback.heavyImpact();

  void _sonidoExito() {
    _soundService.playBeep();
    _vibrar();
  }

  String _precio(double pre) {
    final sim = simbolosMoneda['USD'] ?? '\$';
    return '$sim ${pre.toStringAsFixed(2)}';
  }

  double get total {
    double t = 0;
    for (var i in carrito) {
      t += i['precio'] * i['cantidad'];
    }
    return t;
  }

  Future<void> _inicializarCamara() async {
    try {
      cameraController = MobileScannerController(
        formats: [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.code128,
          BarcodeFormat.qrCode,
          BarcodeFormat.code39,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
        ],
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
    }
  }

  void _toggleLinterna() {
    if (cameraController == null) return;
    setState(() => _linternaEncendida = !_linternaEncendida);
    cameraController!.toggleTorch();
  }

  void _cambiarCamara() {
    if (cameraController == null) return;
    cameraController!.switchCamera();
  }

  void _agregar(Map<String, dynamic> prod) {
    if (prod['tiene_variantes'] == 1 ||
        prod['tiene_variantes'] == true ||
        (prod['talla'] != null && prod['talla'].toString().isNotEmpty) ||
        (prod['color'] != null && prod['color'].toString().isNotEmpty)) {
      _agregarConVariante(prod);
      return;
    }

    if (prod['unidad_medida'] == 'kg' || prod['unidad_medida'] == 'g') {
      _agregarPorPeso(prod);
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
          'costo': (prod['costo'] as num? ?? 0).toDouble(),
          'imagen_base64': prod['imagen_base64'] ?? '',
          'cantidad': 1,
          'tipo': 'unidad',
          'unidad_medida': prod['unidad_medida'] ?? 'pieza',
          'variante': '',
          'peso': 0.0,
        });
      }
    });

    _sonidoExito();
  }

  void _agregarConVariante(Map<String, dynamic> prod) {
    String tallaSeleccionada = '';
    String colorSeleccionado = '';
    final cantidadCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card(widget.modoOscuro),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            prod['nombre'],
            style: TextStyle(
              color: AppColors.text(widget.modoOscuro),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_tallas.isNotEmpty) ...[
                  Text('TALLA',
                      style: TextStyle(
                          color: AppColors.subtext(widget.modoOscuro),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SelectorTallas(
                    tallas: _tallas,
                    isDark: widget.modoOscuro,
                    onSeleccion: (talla) {
                      setDialogState(() => tallaSeleccionada = talla);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (_colores.isNotEmpty) ...[
                  Text('COLOR',
                      style: TextStyle(
                          color: AppColors.subtext(widget.modoOscuro),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SelectorColores(
                    colores: _colores,
                    isDark: widget.modoOscuro,
                    onSeleccion: (color) {
                      setDialogState(() => colorSeleccionado = color);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: cantidadCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.text(widget.modoOscuro)),
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    filled: true,
                    fillColor: AppColors.background(widget.modoOscuro),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
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
                  style:
                      TextStyle(color: AppColors.subtext(widget.modoOscuro))),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final cantidad = int.tryParse(cantidadCtrl.text) ?? 1;
                if (cantidad <= 0) return;
                final variante =
                    '${tallaSeleccionada.isNotEmpty ? 'Talla: $tallaSeleccionada' : ''}${colorSeleccionado.isNotEmpty ? ' Color: $colorSeleccionado' : ''}'
                        .trim();

                setState(() {
                  carrito.add({
                    'id': prod['id'] ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    'codigo_barras': prod['codigo_barras'],
                    'nombre':
                        '${prod['nombre']}${variante.isNotEmpty ? ' ($variante)' : ''}',
                    'precio': (prod['precio'] as num).toDouble(),
                    'costo': (prod['costo'] as num? ?? 0).toDouble(),
                    'imagen_base64': prod['imagen_base64'] ?? '',
                    'cantidad': cantidad,
                    'tipo': 'variante',
                    'unidad_medida': 'pieza',
                    'variante': variante,
                    'peso': 0.0,
                  });
                });
                Navigator.pop(ctx);
                _sonidoExito();
              },
              icon: const Icon(Icons.add_shopping_cart,
                  color: Colors.white, size: 18),
              label: const Text('Agregar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _agregarPorPeso(Map<String, dynamic> prod) {
    final pesoCtrl = TextEditingController();
    final unidad = prod['unidad_medida'] ?? 'kg';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(widget.modoOscuro),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          prod['nombre'],
          style: TextStyle(
            color: AppColors.text(widget.modoOscuro),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: pesoCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: AppColors.text(widget.modoOscuro),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText: 'Cantidad ($unidad)',
            prefixIcon:
                const Icon(Icons.scale_outlined, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.background(widget.modoOscuro),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: AppColors.subtext(widget.modoOscuro))),
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
                  'costo': (prod['costo'] as num? ?? 0).toDouble() * peso,
                  'imagen_base64': prod['imagen_base64'] ?? '',
                  'cantidad': 1,
                  'tipo': 'peso',
                  'unidad_medida': unidad,
                  'variante': '',
                  'peso': peso,
                });
              });
              Navigator.pop(ctx);
              _sonidoExito();
            },
            icon: const Icon(Icons.add_shopping_cart,
                color: Colors.white, size: 18),
            label: const Text('Agregar',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
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
                (prod['codigo_barras'] as String? ?? '')
                    .toLowerCase()
                    .contains(f))
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

  Future<void> _cargar({bool silencioso = false}) async {
    if (!mounted) return;
    if (!silencioso) setState(() => _cargando = true);
    try {
      final productosActualizados = await _db.getProductos();
      final tallasActualizadas = await _db.getTallas();
      final coloresActualizados = await _db.getColores();

      if (!mounted) return;
      setState(() {
        listaProductos = productosActualizados;
        _tallas = tallasActualizadas;
        _colores = coloresActualizados;

        // Mantener búsqueda/filtros y reconstruir resultados con los datos nuevos.
        final q = _buscador.text.trim().toLowerCase();
        if (q.isNotEmpty) {
          busqueda = listaProductos.where((prod) {
            final nombre = (prod['nombre'] ?? '').toString().toLowerCase();
            final codigo =
                (prod['codigo_barras'] ?? '').toString().toLowerCase();
            return nombre.contains(q) || codigo.contains(q);
          }).toList();
          _mostrarBusqueda = busqueda.isNotEmpty;
          _mostrarTodos = false;
        } else {
          busqueda.clear();
          _mostrarBusqueda = false;
          _mostrarTodos = listaProductos.isNotEmpty;
        }
        _cargando = false;
      });
      debugPrint('Productos cargados en POS: ${listaProductos.length}');
    } catch (e) {
      debugPrint('Error cargando productos: $e');
      if (!mounted) return;
      setState(() {
        if (!silencioso) _cargando = false;
      });
    }
  }

  void _sincronizarProductosAutomaticamente() {
    if (!mounted) return;
    _cargar(silencioso: true);
  }

  @override
  void initState() {
    super.initState();
    productosVersion.addListener(_sincronizarProductosAutomaticamente);
    _inicializarCamara();
    _cargar();
  }

  @override
  void dispose() {
    productosVersion.removeListener(_sincronizarProductosAutomaticamente);
    _buscador.dispose();
    cameraController?.dispose();
    _speech.stop();
    super.dispose();
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
      _snack('Carrito vacío', AppColors.warning);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.90,
        minChildSize: 0.65,
        maxChildSize: 0.98,
        snap: true,
        snapSizes: const [0.90, 0.98],
        builder: (sheetContext, scrollController) {
          return PantallaCobro(
            carrito: carrito,
            total: total,
            formatearPrecio: _precio,
            onVentaCompletada: (m, mt, n, t, c) => _venta(m, mt, n, t, c),
            modoOscuro: widget.modoOscuro,
          );
        },
      ),
    );
  }

  Future<void> _venta(String metodo, String monto, String nombre,
      String telefono, String cedula) async {
    try {
      final fac = DatosPrueba.generarNumeroFactura();
      double costoTotal = 0;
      for (var i in carrito) {
        costoTotal += (i['costo'] ?? 0) * i['cantidad'];
      }
      double gananciaTotal = total - costoTotal;
      final totalVenta = total;

      final venta = {
        'numero_factura': fac,
        'total': totalVenta,
        'subtotal': totalVenta,
        'costo_total': costoTotal,
        'ganancia_total': gananciaTotal,
        'metodo_pago': metodo,
        'moneda': 'USD',
        'cliente_nombre': nombre.isNotEmpty ? nombre : 'Público General',
        'cliente_telefono': telefono,
        'cliente_cedula': cedula,
        'estado': 'Pagada',
        'fecha': DateTime.now().toIso8601String(),
      };

      final ventaGuardada = await _db.crearVenta(venta);

      if (ventaGuardada != null) {
        for (var i in carrito) {
          final detalleGuardado = await _db.crearDetalleVenta({
            'venta_id': ventaGuardada['id'],
            'codigo_barras': i['codigo_barras'],
            'nombre': i['nombre'],
            'precio': i['precio'],
            'cantidad': i['cantidad'],
            'subtotal': i['precio'] * i['cantidad'],
            'costo_unitario': i['costo'] ?? 0,
            'ganancia': (i['precio'] - (i['costo'] ?? 0)) * i['cantidad'],
            'variante': i['variante'] ?? '',
            'unidad_medida': i['unidad_medida'] ?? 'pieza',
            'descuento_aplicado': 0,
          });
          if (!detalleGuardado) {
            throw Exception(
                'No se pudo guardar el detalle de la venta ${fac}.');
          }

          if (i['id'] != null) {
            final productoActual = listaProductos.firstWhere(
              (p) => p['id'].toString() == i['id'].toString(),
              orElse: () => {},
            );
            if (productoActual.isNotEmpty && productoActual['stock'] != null) {
              final stockActual = (productoActual['stock'] as num).toInt();
              final nuevoStock = stockActual - (i['cantidad'] as int);
              await _db.actualizarStock(i['id'].toString(), nuevoStock);

              await _db.registrarMovimientoInventario({
                'producto_id': i['id'],
                'producto_nombre': i['nombre'],
                'tipo': 'Salida',
                'cantidad': i['cantidad'],
                'motivo': 'Venta $fac',
                'fecha': DateTime.now().toIso8601String(),
              });
            }
          }
        }

        await _cajaService.agregarVentaACaja(totalVenta);
        ventasVersion.value++;

        if (nombre.isNotEmpty && cedula.isNotEmpty) {
          final clienteExistente = await _db.buscarClientePorCedula(cedula);
          if (clienteExistente != null) {
            final puntosGanados = totalVenta.floor();
            final puntosActuales = (clienteExistente['puntos'] ?? 0) as int;
            final totalCompras =
                (clienteExistente['total_compras'] ?? 0) as num;

            await _db.actualizarCliente(clienteExistente['id'].toString(), {
              'puntos': puntosActuales + puntosGanados,
              'total_compras': totalCompras.toDouble() + totalVenta,
              'fecha_ultima_compra': DateTime.now().toIso8601String(),
            });
          } else {
            await _db.crearCliente({
              'nombre': nombre,
              'telefono': telefono,
              'identificacion': cedula,
              'tipo': 'Regular',
              'puntos': totalVenta.floor(),
              'total_compras': totalVenta,
              'fecha_ultima_compra': DateTime.now().toIso8601String(),
            });
          }
        }

        String? pdfPath;
        try {
          pdfPath = await _ticketService.generarPDFTicket(
            numeroFactura: fac,
            clienteNombre: nombre.isNotEmpty ? nombre : 'Público General',
            clienteTelefono: telefono,
            metodoPago: metodo,
            total: totalVenta,
            costoTotal: costoTotal,
            gananciaTotal: gananciaTotal,
            productos: carrito,
          );
        } catch (e) {
          debugPrint('Error generando ticket PDF: $e');
        }

        setState(() => carrito.clear());
        Navigator.pop(context);
        _snack(
            'Venta exitosa - $fac - Total: \$${totalVenta.toStringAsFixed(2)}',
            AppColors.success);

        _mostrarNotificacionVenta(fac, nombre, telefono, totalVenta, pdfPath);
      }
    } catch (e) {
      debugPrint('Error en venta: $e');
      _snack('Error: $e', AppColors.danger);
    }
  }

  void _mostrarNotificacionVenta(String factura, String nombre, String telefono,
      double totalVenta, String? pdfPath) {
    final isDark = widget.modoOscuro;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: isTablet ? 450 : double.infinity,
          padding: EdgeInsets.all(isTablet ? 28 : 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 28 : 22),
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
                  gradient: AppColors.gradientSuccess,
                  shape: BoxShape.circle,
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
                style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: AppColors.background(isDark),
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 14),
                ),
                child: Column(
                  children: [
                    _buildDetalleVenta(
                      icon: Icons.receipt_long_rounded,
                      label: 'Factura',
                      value: factura,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildDetalleVenta(
                      icon: Icons.person_outline_rounded,
                      label: 'Cliente',
                      value: nombre.isEmpty ? 'Público General' : nombre,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    Divider(color: AppColors.divider(isDark)),
                    const SizedBox(height: 8),
                    _buildDetalleVenta(
                      icon: Icons.payment_rounded,
                      label: 'TOTAL A PAGAR',
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
                    child: _buildBotonAccion(
                      icon: Icons.chat_rounded,
                      label: 'WhatsApp',
                      color: AppColors.whatsapp,
                      onTap: () {
                        Navigator.pop(ctx);
                        _enviarWhatsAppCliente(
                            nombre, telefono, factura, totalVenta);
                      },
                      isTablet: isTablet,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBotonAccion(
                      icon: Icons.print_rounded,
                      label: 'Imprimir',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(ctx);
                        _imprimirTicket(factura, nombre, totalVenta);
                      },
                      isTablet: isTablet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.background(isDark),
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
                    ),
                  ),
                  child: Text(
                    'CERRAR',
                    style: TextStyle(
                      color: AppColors.subtext(isDark),
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
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
            color: (esTotal ? AppColors.success : AppColors.primary)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: esTotal ? AppColors.success : AppColors.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
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
                  fontSize: esTotal ? 22 : 14,
                  fontWeight: esTotal ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotonAccion({
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
            Icon(icon, color: color, size: isTablet ? 18 : 15),
            const SizedBox(width: 6),
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
      phone = '58${phone.substring(1)}';
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

  void _imprimirTicket(String factura, String nombre, double totalVenta) {
    _snack('Generando ticket para imprimir...', AppColors.primary);
    Future.delayed(const Duration(seconds: 1), () {
      _snack('Ticket listo para imprimir', AppColors.success);
    });
  }

  String _normalizarCodigoPOS(String codigo) {
    return codigo
        .trim()
        .replaceAll(RegExp(r'[\s\u200B\uFEFF]'), '')
        .toUpperCase();
  }

  String _normalizarCodigoPOS(String codigo) {
    return codigo
        .trim()
        .replaceAll(RegExp(r'[\s\u200B\uFEFF]'), '')
        .toUpperCase();
  }

  Future<void> _procesarCodigoConDebounce(String codigo) async {
    final limpio = _normalizarCodigoPOS(codigo);
    if (limpio.isEmpty || _procesandoCodigo) return;

    if (_ultimoCodigoEscaneado == limpio && _ultimoEscaneo != null) {
      final diferencia = DateTime.now().difference(_ultimoEscaneo!);
      if (diferencia < _tiempoDebounce) return;
    }

    _ultimoCodigoEscaneado = limpio;
    _ultimoEscaneo = DateTime.now();
    if (mounted) setState(() => _procesandoCodigo = true);

    try {
      await _procesarCodigo(limpio);
    } finally {
      if (mounted) setState(() => _procesandoCodigo = false);
    }
  }

  Future<void> _procesarCodigo(String codigo) async {
    final limpio = _normalizarCodigoPOS(codigo);
    Map<String, dynamic>? prod;

    for (final p in listaProductos) {
      final valor = _normalizarCodigoPOS((p['codigo_barras'] ?? '').toString());
      if (valor == limpio) {
        prod = p;
        break;
      }
    }

    prod ??= await _db.buscarPorCodigo(limpio);

    if (prod != null) {
      _agregar(prod);
      _sonidoExito();
      if (mounted) _snack('${prod['nombre']} agregado al carrito', AppColors.success);
      // La cÃ¡mara NO se cierra: queda lista para el siguiente producto.
    } else {
      HapticFeedback.vibrate();
      if (mounted) _snack('Producto no encontrado: $limpio', AppColors.danger);
    }
  }
  Widget _buildCamaraEscaneo(bool isDark) {
    return Container(
      height: _isDesktop ? 320 : 260,
      margin: EdgeInsets.symmetric(
        horizontal: _isDesktop ? 24 : 16,
        vertical: 8,
      ),
      child: ScannerRapido(
        isDark: isDark,
        onCodigoDetectado: _procesarCodigoConDebounce,
        onCerrar: () => setState(() => _camara = false),
      ),
    );
  }

  // ============================================
  // TARJETA DE PRODUCTO REDISEÑADA
  // ============================================
  Widget _buildProductCardRedisenada(Map<String, dynamic> prod, bool isDark) {
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

    return GestureDetector(
      onTap: () => _agregar(prod),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(isDark),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEN DEL PRODUCTO
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(19),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: ImagenProducto(
                        imagenBase64: prod['imagen_base64']?.toString(),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // GRADIENTE INFERIOR
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.1, 0.4, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // BADGE DESTACADO
                  if (destacado)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientWarning,
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
                            Icon(Icons.star_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 3),
                            Text('TOP',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),
                  // BADGE STOCK
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: stockColor.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        stock == 0 ? 'AGOTADO' : '$stock',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  // BADGE DESCUENTO
                  if (descuento > 0)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientDanger,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.danger.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '-$descuento%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  // BOTÓN AGREGAR
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _agregar(prod),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // INFORMACIÓN DEL PRODUCTO
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prod['nombre'] ?? '',
                    style: TextStyle(
                      color: AppColors.text(isDark),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          categoria,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    prod['unidad_medida'] == 'kg' ||
                            prod['unidad_medida'] == 'g'
                        ? '\$${precioFinal.toStringAsFixed(2)}/${prod['unidad_medida'] ?? 'kg'}'
                        : '\$${precioFinal.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPreview(bool isDark, {bool embedded = false}) {
    final units = carrito.fold<int>(
      0,
      (sum, item) => sum + ((item['cantidad'] as num?)?.toInt() ?? 0),
    );

    return Column(
      children: [
        // CABECERA DEL PEDIDO
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider(isDark),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: .25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORDEN ACTUAL',
                          style: TextStyle(
                            color: AppColors.text(isDark),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$units unidades  •  ${carrito.length} productos',
                          style: TextStyle(
                            color: AppColors.subtext(isDark),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (carrito.isNotEmpty)
                    IconButton(
                      tooltip: 'Vaciar orden',
                      onPressed: () {
                        setState(() => carrito.clear());
                        _sonidoExito();
                      },
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger.withValues(alpha: .85),
                        size: 21,
                      ),
                    ),
                ],
              ),
              if (carrito.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildCartStatusChip(
                        Icons.check_circle_outline_rounded,
                        'LISTA PARA COBRAR',
                        AppColors.success,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCartMiniBadge(
                      '$units',
                      'UNIDADES',
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildCartMiniBadge(
                      '${carrito.length}',
                      'LÍNEAS',
                      isDark,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // PRODUCTOS
        Expanded(
          child: carrito.isEmpty
              ? _buildEmptyCart(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                  physics: const BouncingScrollPhysics(),
                  itemCount: carrito.length,
                  itemBuilder: (_, i) => _buildCartItem(carrito[i], i, isDark),
                ),
        ),

        // TOTAL / COBRO
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0F14) : const Color(0xFFF7F8FB),
            border: Border(
              top: BorderSide(
                color: AppColors.divider(isDark),
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'TOTAL',
                    style: TextStyle(
                      color: AppColors.subtext(isDark),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Text(
                      _precio(total),
                      key: ValueKey(total),
                      style: TextStyle(
                        color: AppColors.text(isDark),
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.7,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  gradient: carrito.isEmpty ? null : AppColors.gradientPrimary,
                  color: carrito.isEmpty ? AppColors.divider(isDark) : null,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: carrito.isEmpty
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: .30),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(17),
                    onTap: carrito.isEmpty ? null : _cobrar,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: carrito.isEmpty ? 0 : .14,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          carrito.isEmpty ? 'AGREGA PRODUCTOS' : 'COBRAR',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                        if (carrito.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            _precio(total),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .82),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartStatusChip(
    IconData icon,
    String label,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartMiniBadge(
    String value,
    String label,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background(isDark),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.divider(isDark)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.text(isDark),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.subtext(isDark),
              fontSize: 7,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .88, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutBack,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: .07),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: .15),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.primary,
                  size: 43,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tu orden está vacía',
              style: TextStyle(
                color: AppColors.text(isDark),
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona un producto del catálogo\npara comenzar la venta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.subtext(isDark),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(
    Map<String, dynamic> item,
    int index,
    bool isDark,
  ) {
    final cantidad = (item['cantidad'] as num?)?.toInt() ?? 1;
    final precioUnitario = (item['precio'] as num?)?.toDouble() ?? 0;
    final importe = precioUnitario * cantidad;

    return TweenAnimationBuilder<double>(
      key: ValueKey('${item['id']}_${item['nombre']}'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + (index * 45)),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(24 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111820) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.divider(isDark),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark ? .16 : .045,
              ),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // IMAGEN
              Container(
                width: 66,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.background(isDark),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: ImagenProducto(
                  imagenBase64: item['imagen_base64']?.toString(),
                  width: 66,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 11),

              // INFORMACIÓN
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['tipo'] == 'peso'
                          ? '${item['nombre']} (${item['peso']}${item['unidad_medida'] ?? 'kg'})'
                          : item['nombre'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text(isDark),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_precio(precioUnitario)} / unidad',
                      style: TextStyle(
                        color: AppColors.subtext(isDark),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      ),
                      child: Text(
                        _precio(importe),
                        key: ValueKey(importe),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // CONTROL DE CANTIDAD
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background(isDark),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColors.divider(isDark),
                  ),
                ),
                child: Column(
                  children: [
                    _buildQuantityButton(
                      icon: Icons.add_rounded,
                      onTap: () {
                        setState(() => item['cantidad'] = cantidad + 1);
                        _sonidoExito();
                      },
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                      child: Padding(
                        key: ValueKey(cantidad),
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                        ),
                        child: Text(
                          '$cantidad',
                          style: TextStyle(
                            color: AppColors.text(isDark),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        setState(() {
                          if (cantidad > 1) {
                            item['cantidad'] = cantidad - 1;
                          } else {
                            carrito.removeAt(index);
                          }
                        });
                        _sonidoExito();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: _isDesktop ? 32 : 29,
          height: _isDesktop ? 32 : 29,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: _isDesktop ? 18 : 16,
          ),
        ),
      ),
    );
  }
}
// ============================================
// CONTINUACIÓN - ETAPA 4 de 6
// ============================================

// ============================================
// PANTALLA DE COBRO - DISEÑO PROFESIONAL
// ============================================
class PantallaCobro extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final double total;
  final String Function(double) formatearPrecio;
  final Function(String, String, String, String, String) onVentaCompletada;
  final bool modoOscuro;
  const PantallaCobro({
    super.key,
    required this.carrito,
    required this.total,
    required this.formatearPrecio,
    required this.onVentaCompletada,
    required this.modoOscuro,
  });
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
      final metodos = await _db.getMetodosPago();
      if (metodos.isNotEmpty) {
        _metodosPago = metodos;
        _metodo = metodos.first['nombre'] ?? 'Efectivo';
      }
      setState(() => _cargandoMetodos = false);
    } catch (e) {
      debugPrint('Error cargando datos cobro: $e');
      setState(() => _cargandoMetodos = false);
    }
  }

  Future<void> _buscarClientePorCedula() async {
    final cedula = _cedulaCtrl.text.trim();
    if (cedula.isEmpty) return;
    setState(() => _buscandoCliente = true);
    try {
      final cliente = await _db.buscarClientePorCedula(cedula);
      if (cliente != null) {
        setState(() {
          _nombreCtrl.text = cliente['nombre'] ?? '';
          _telefonoCtrl.text = cliente['telefono'] ?? '';
          _direccionCtrl.text = cliente['direccion'] ?? '';
        });
        _mostrarSnackbar('Cliente encontrado', AppColors.success);
      } else {
        _mostrarSnackbar(
            'Cliente nuevo - se registrará automáticamente', AppColors.primary);
      }
    } catch (e) {
      _mostrarSnackbar('Error buscando cliente: $e', AppColors.danger);
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
    if (_metodo == 'Efectivo' && _vuelto() < 0) {
      _mostrarSnackbar('Monto insuficiente', AppColors.danger);
      return;
    }

    if (_cedulaCtrl.text.trim().isNotEmpty) {
      try {
        final clienteExistente =
            await _db.buscarClientePorCedula(_cedulaCtrl.text.trim());
        if (clienteExistente == null && _nombreCtrl.text.trim().isNotEmpty) {
          await _db.crearCliente({
            'nombre': _nombreCtrl.text.trim(),
            'telefono': _telefonoCtrl.text.trim(),
            'identificacion': _cedulaCtrl.text.trim(),
            'direccion': _direccionCtrl.text.trim(),
            'tipo': 'Regular',
          });
        }
      } catch (e) {
        debugPrint('Error registrando cliente: $e');
      }
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
                    gradient: AppColors.gradientPrimary,
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
                      ),
                    ),
                    Text(
                      '${widget.carrito.length} producto${widget.carrito.length != 1 ? 's' : ''}',
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: ['USD', 'COP', 'VES'].map((moneda) {
          final sel = _moneda == moneda;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _moneda = moneda),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: _isDesktop ? 14 : 10),
                decoration: BoxDecoration(
                  gradient: sel ? AppColors.gradientPrimary : null,
                  borderRadius: BorderRadius.circular(12),
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
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(_isDesktop ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                ),
              ),
              const SizedBox(height: 4),
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
          Icon(
            Icons.payments_rounded,
            color: Colors.white.withValues(alpha: 0.5),
            size: _isDesktop ? 40 : 32,
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
        const SizedBox(width: 8),
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
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCampoTexto(
                  controller: _cedulaCtrl,
                  label: 'Cédula (opcional)',
                  icon: Icons.badge_outlined,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _buscarClientePorCedula(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _buscandoCliente ? null : _buscarClientePorCedula,
                child: Container(
                  width: _isDesktop ? 52 : 46,
                  height: _isDesktop ? 52 : 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _buscandoCliente
                        ? const SizedBox(
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
            label: 'Nombre completo (opcional)',
            icon: Icons.person_outline_rounded,
            isDark: isDark,
          ),
          SizedBox(height: _isDesktop ? 14 : 10),
          _buildCampoTexto(
            controller: _telefonoCtrl,
            label: 'Teléfono (opcional)',
            icon: Icons.phone_outlined,
            isDark: isDark,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: _isDesktop ? 14 : 10),
          _buildCampoTexto(
            controller: _direccionCtrl,
            label: 'Dirección (opcional)',
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
        labelStyle: TextStyle(color: AppColors.subtext(isDark)),
        prefixIcon:
            Icon(icon, color: AppColors.primary, size: _isDesktop ? 22 : 18),
        filled: true,
        fillColor: AppColors.card(isDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.divider(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildMetodosPago(bool isDark) {
    if (_cargandoMetodos) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_metodosPago.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background(isDark),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('No hay métodos de pago configurados',
            style: TextStyle(color: AppColors.subtext(isDark), fontSize: 12)),
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
        final icono = _getIconoMetodo(nombre);

        return GestureDetector(
          onTap: () => setState(() => _metodo = nombre),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: _isDesktop ? 14 : 10,
              vertical: _isDesktop ? 14 : 10,
            ),
            decoration: BoxDecoration(
              gradient: sel ? AppColors.gradientPrimary : null,
              color: sel ? null : AppColors.background(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: sel ? AppColors.primary : AppColors.divider(isDark),
                width: sel ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono,
                    color: sel ? Colors.white : AppColors.primary,
                    size: _isDesktop ? 24 : 20),
                const SizedBox(height: 6),
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

  IconData _getIconoMetodo(String nombre) {
    switch (nombre.toLowerCase()) {
      case 'efectivo':
        return Icons.payments_outlined;
      case 'tarjeta':
        return Icons.credit_card_outlined;
      case 'transferencia':
        return Icons.swap_horiz_rounded;
      case 'pago movil':
        return Icons.phone_android_rounded;
      default:
        return Icons.payment_rounded;
    }
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
            hintStyle: TextStyle(color: AppColors.subtext(isDark)),
            prefixText: '${simbolosMoneda[_moneda] ?? '\$'} ',
            prefixStyle: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w700),
            prefixIcon:
                const Icon(Icons.payments_outlined, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.background(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
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
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Vuelto',
                    style: TextStyle(
                        color: AppColors.subtext(isDark),
                        fontSize: _isDesktop ? 15 : 13,
                        fontWeight: FontWeight.w600)),
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

  Widget _buildBotonConfirmar(bool isDark) {
    return Container(
      width: double.infinity,
      height: _isDesktop ? 60 : 52,
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(_isDesktop ? 18 : 14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: Colors.white, size: _isDesktop ? 26 : 22),
            SizedBox(width: _isDesktop ? 12 : 8),
            Text(
              'CONFIRMAR PAGO',
              style: TextStyle(
                color: Colors.white,
                fontSize: _isDesktop ? 17 : 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// PANTALLA: DASHBOARD PROFESIONAL
// ============================================
class DashboardScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final VoidCallback onNavigateToPOS;
  final bool modoOscuro;
  final VoidCallback onToggleModoOscuro;
  const DashboardScreen({
    super.key,
    required this.onAbrirSidebar,
    required this.onNavigateToPOS,
    this.modoOscuro = false,
    required this.onToggleModoOscuro,
  });
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseService();
  final _cajaService = CajaService();

  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> ventasHoy = [];
  List<Map<String, dynamic>> ventasFiltradas = [];
  List<Map<String, dynamic>> productosMasVendidos = [];
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _tallas = [];
  List<Map<String, dynamic>> _colores = [];
  Map<String, dynamic>? _cajaActual;

  double totalVentasHoy = 0;
  double totalVentasMes = 0;
  double gananciaTotalVentas = 0;
  int cantidadVentasHoy = 0;
  int _totalStock = 0;
  int _productosAgotados = 0;
  int _productosStockBajo = 0;
  double _ticketPromedio = 0;
  double _valorInventarioCosto = 0;
  double _valorInventarioVenta = 0;
  double _margenPorcentaje = 0;
  Map<String, double> _ventasPorMetodo = {};

  bool cargando = true;
  String searchQuery = '';
  int seccionActual = 0;
  String _filtroCategoria = 'Todas';
  String _filtroStock = 'Todos';
  String _filtroFechaVentas = 'Hoy';

  @override
  void initState() {
    super.initState();
    ventasVersion.addListener(_sincronizarDashboard);
    productosVersion.addListener(_sincronizarDashboard);
    cargarDatos();
  }

  void _sincronizarDashboard() {
    if (!mounted) return;
    cargarDatos(silencioso: true);
  }

  @override
  void dispose() {
    ventasVersion.removeListener(_sincronizarDashboard);
    productosVersion.removeListener(_sincronizarDashboard);
    super.dispose();
  }

  Future<void> cargarDatos({bool silencioso = false}) async {
    if (!silencioso) setState(() => cargando = true);
    try {
      productos = await _db.getProductos();
      ventasHoy = await _db.getVentasHoy();
      totalVentasHoy = await _db.getTotalVentasHoy();
      totalVentasMes = await _db.getTotalVentasMes();
      cantidadVentasHoy = await _db.getCantidadVentasHoy();
      productosMasVendidos = await _db.getProductosMasVendidos();
      _cajaActual = await _cajaService.getCajaAbierta();
      _categorias = await _db.getCategorias();
      _tallas = await _db.getTallas();
      _colores = await _db.getColores();

      double ganancia = 0;
      for (var v in ventasHoy) {
        ganancia += (v['ganancia_total'] as num? ?? 0).toDouble();
      }
      gananciaTotalVentas = ganancia;

      _calcularMetricas();
      _calcularResumenProfesional();
      _aplicarFiltroVentas();
      debugPrint(
          'Dashboard cargado: ${productos.length} productos, ${ventasHoy.length} ventas');
    } catch (e) {
      debugPrint('Error cargando dashboard: $e');
    }
    if (mounted && !silencioso) setState(() => cargando = false);
    if (mounted && silencioso) setState(() {});
  }

  void _calcularResumenProfesional() {
    final cantidad = ventasHoy.length;
    final total = ventasHoy.fold<double>(
        0, (sum, v) => sum + ((v['total'] as num?)?.toDouble() ?? 0));
    _ticketPromedio = cantidad == 0 ? 0 : total / cantidad;

    final utilidad = ventasHoy.fold<double>(
        0, (sum, v) => sum + ((v['ganancia_total'] as num?)?.toDouble() ?? 0));
    _margenPorcentaje = total <= 0 ? 0 : (utilidad / total) * 100;

    final metodos = <String, double>{};
    for (final v in ventasHoy) {
      final metodo = (v['metodo_pago']?.toString().trim().isNotEmpty ?? false)
          ? v['metodo_pago'].toString()
          : 'Otros';
      metodos[metodo] =
          (metodos[metodo] ?? 0) + ((v['total'] as num?)?.toDouble() ?? 0);
    }
    _ventasPorMetodo = metodos;
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

      double totalVentas = 0;
      double ganancia = 0;
      for (var v in ventasFiltradas) {
        totalVentas += (v['total'] as num? ?? 0).toDouble();
        ganancia += (v['ganancia_total'] as num? ?? 0).toDouble();
      }
      totalVentasHoy = totalVentas;
      gananciaTotalVentas = ganancia;
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
              (prod['codigo_barras'] as String? ?? '')
                  .toLowerCase()
                  .contains(q))
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
            filled: true,
            fillColor: AppColors.background(isDark),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          ElevatedButton(
            onPressed: () async {
              final m = double.tryParse(ctrl.text) ?? 0;
              if (m <= 0) return;
              await _cajaService.abrirCaja(m);
              Navigator.pop(ctx);
              cargarDatos();
              mostrarSnackBar(
                  'Caja abierta: \$${m.toStringAsFixed(2)}', AppColors.success);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Abrir', style: TextStyle(color: Colors.white)),
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
            Text(
                'Monto Inicial: \$${((_cajaActual!['monto_inicial'] ?? 0) as num).toStringAsFixed(2)}',
                style: TextStyle(color: AppColors.text(isDark), fontSize: 13)),
            Text(
                'Total Ventas: \$${((_cajaActual!['total_ventas'] ?? 0) as num).toStringAsFixed(2)}',
                style: TextStyle(color: AppColors.text(isDark), fontSize: 13)),
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
                filled: true,
                fillColor: AppColors.background(isDark),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          ElevatedButton(
            onPressed: () async {
              final m = double.tryParse(montoFinalCtrl.text) ?? 0;
              await _cajaService.cerrarCaja(m);
              Navigator.pop(ctx);
              cargarDatos();
              mostrarSnackBar('Caja cerrada', AppColors.primary);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _tab(String l, int i, bool isDark, IconData icon) {
    final sel = seccionActual == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => seccionActual = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: sel ? AppColors.gradientPrimary : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: sel ? Colors.white : AppColors.subtext(isDark),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  l,
                  style: TextStyle(
                    color: sel ? Colors.white : AppColors.subtext(isDark),
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resumen(bool isDark) {
    final width = MediaQuery.of(context).size.width;
    final desktop = width >= 1180;
    final tablet = width >= 760;

    final ventasHora = <int, double>{};
    for (final v in ventasHoy) {
      try {
        final fecha = v['fecha'] != null
            ? DateTime.parse(v['fecha'].toString()).toLocal()
            : DateTime.now();
        ventasHora[fecha.hour] = (ventasHora[fecha.hour] ?? 0) +
            ((v['total'] as num?)?.toDouble() ?? 0);
      } catch (_) {}
    }
    final maxHora = ventasHora.values.isEmpty
        ? 1.0
        : ventasHora.values.reduce((a, b) => a > b ? a : b);
    final metodosOrdenados = _ventasPorMetodo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => cargarDatos(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding:
            EdgeInsets.fromLTRB(tablet ? 26 : 14, 10, tablet ? 26 : 14, 34),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HERO: aspecto de terminal financiera, claramente separado del resto.
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(desktop ? 26 : 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF111827), const Color(0xFF0B1220)]
                          : [const Color(0xFFF7FAFF), const Color(0xFFFFFFFF)],
                    ),
                    border: Border.all(color: AppColors.divider(isDark)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow(isDark),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: .10),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'CONTROL CENTER',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('ONLINE · LOCAL',
                                        style: TextStyle(
                                          color: AppColors.subtext(isDark),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Resumen del negocio',
                                  style: TextStyle(
                                    color: AppColors.text(isDark),
                                    fontSize: desktop ? 29 : 23,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Todo lo importante de tu operación en una sola vista.',
                                  style: TextStyle(
                                    color: AppColors.subtext(isDark),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (desktop)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('VENTAS HOY',
                                    style: TextStyle(
                                      color: AppColors.subtext(isDark),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                    )),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${totalVentasHoy.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: AppColors.text(isDark),
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text('$cantidadVentasHoy operaciones',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Acciones rápidas.
                      LayoutBuilder(builder: (context, c) {
                        final twoColumns = c.maxWidth >= 680;
                        final items = [
                          _quickAction(
                              'Nueva venta',
                              Icons.point_of_sale_rounded,
                              AppColors.primary,
                              widget.onNavigateToPOS),
                          _quickAction('Inventario', Icons.inventory_2_rounded,
                              AppColors.info, widget.onAbrirSidebar),
                          _quickAction('Clientes', Icons.groups_rounded,
                              AppColors.secondary, widget.onAbrirSidebar),
                          _quickAction(
                              'Caja',
                              Icons.account_balance_wallet_rounded,
                              AppColors.success,
                              widget.onAbrirSidebar),
                        ];
                        if (!twoColumns) {
                          return Column(
                              children: items
                                  .map((e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: SizedBox(
                                          width: double.infinity, child: e)))
                                  .toList());
                        }
                        return GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 3.8,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: items,
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // KPIs grandes, con jerarquía más marcada.
                LayoutBuilder(builder: (context, c) {
                  final count = desktop ? 4 : 2;
                  final gap = 10.0;
                  final w = (c.maxWidth - gap * (count - 1)) / count;
                  final cards = [
                    _executiveMetric(
                        'Ventas',
                        '\$${totalVentasHoy.toStringAsFixed(2)}',
                        '$cantidadVentasHoy transacciones',
                        Icons.trending_up_rounded,
                        AppColors.primary,
                        isDark),
                    _executiveMetric(
                        'Ganancia',
                        '\$${gananciaTotalVentas.toStringAsFixed(2)}',
                        'Margen ${_margenPorcentaje.toStringAsFixed(1)}%',
                        Icons.savings_rounded,
                        AppColors.success,
                        isDark),
                    _executiveMetric(
                        'Este mes',
                        '\$${totalVentasMes.toStringAsFixed(2)}',
                        'Acumulado mensual',
                        Icons.calendar_today_rounded,
                        AppColors.secondary,
                        isDark),
                    _executiveMetric(
                        'Ticket medio',
                        '\$${_ticketPromedio.toStringAsFixed(2)}',
                        'Por operación',
                        Icons.receipt_long_rounded,
                        AppColors.info,
                        isDark),
                  ];
                  return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: cards
                          .map((x) => SizedBox(width: w, child: x))
                          .toList());
                }),
                const SizedBox(height: 14),

                // Zona analítica principal.
                if (desktop)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                        flex: 7,
                        child: _panel(isDark,
                            title: 'Rendimiento de ventas',
                            subtitle: 'Ingresos distribuidos durante el día',
                            icon: Icons.multiline_chart_rounded,
                            child: SizedBox(
                                height: 290,
                                child: _graficoVentasHora(
                                    isDark, ventasHora, maxHora)))),
                    const SizedBox(width: 12),
                    Expanded(flex: 4, child: _inventarioPanel(isDark)),
                  ])
                else ...[
                  _panel(isDark,
                      title: 'Rendimiento de ventas',
                      subtitle: 'Ingresos distribuidos durante el día',
                      icon: Icons.multiline_chart_rounded,
                      child: SizedBox(
                          height: 255,
                          child:
                              _graficoVentasHora(isDark, ventasHora, maxHora))),
                  const SizedBox(height: 12),
                  _inventarioPanel(isDark),
                ],
                const SizedBox(height: 14),

                // Segunda fila: ventas + pagos.
                if (desktop)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _topProductosPanel(isDark)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _metodosPagoPanel(isDark, metodosOrdenados)),
                  ])
                else ...[
                  _topProductosPanel(isDark),
                  const SizedBox(height: 12),
                  _metodosPagoPanel(isDark, metodosOrdenados),
                ],
                const SizedBox(height: 14),

                _panel(
                  isDark,
                  title: 'Centro operativo',
                  subtitle: 'Salud actual de inventario y operación',
                  icon: Icons.radar_rounded,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _statusItem(
                          'Productos',
                          '${productos.length}',
                          Icons.inventory_2_outlined,
                          AppColors.primary,
                          isDark),
                      _statusItem('Unidades', '$_totalStock',
                          Icons.layers_outlined, AppColors.info, isDark),
                      _statusItem(
                          'Stock bajo',
                          '$_productosStockBajo',
                          Icons.warning_amber_rounded,
                          AppColors.warning,
                          isDark),
                      _statusItem(
                          'Agotados',
                          '$_productosAgotados',
                          Icons.remove_shopping_cart_outlined,
                          AppColors.danger,
                          isDark),
                      _statusItem(
                          'Costo',
                          '\$${_valorInventarioCosto.toStringAsFixed(2)}',
                          Icons.price_check_outlined,
                          AppColors.secondary,
                          isDark),
                      _statusItem(
                          'Valor venta',
                          '\$${_valorInventarioVenta.toStringAsFixed(2)}',
                          Icons.sell_outlined,
                          AppColors.success,
                          isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickAction(
      String label, IconData icon, Color accent, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .065),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: .16)),
          ),
          child: Row(children: [
            Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: accent.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 19, color: accent)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: accent))),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: accent.withValues(alpha: .65)),
          ]),
        ),
      ),
    );
  }

  Widget _executiveMetric(String title, String value, String subtitle,
      IconData icon, Color accent, bool isDark) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider(isDark)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: accent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.toUpperCase(),
              style: TextStyle(
                  color: AppColors.subtext(isDark),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1)),
          const Spacer(),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7)),
          const SizedBox(height: 3),
          Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.subtext(isDark), fontSize: 10)),
        ])),
      ]),
    );
  }

  Widget _metricCard(String title, String value, String subtitle, IconData icon,
      Color accent, bool isDark) {
    return Container(
      constraints: const BoxConstraints(minHeight: 126),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider(isDark)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(isDark),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.subtext(isDark),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.text(isDark),
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.subtext(isDark), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _panel(
    bool isDark, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider(isDark)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(isDark),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: AppColors.text(isDark),
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: AppColors.subtext(isDark), fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _graficoVentasHora(
      bool isDark, Map<int, double> ventasHora, double maxHora) {
    final spots = List.generate(
        24, (hora) => FlSpot(hora.toDouble(), ventasHora[hora] ?? 0));

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 23,
        minY: 0,
        maxY: maxHora <= 0 ? 1 : maxHora * 1.18,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxHora <= 4 ? 1 : maxHora / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.divider(isDark),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: maxHora <= 4 ? 1 : maxHora / 2,
              getTitlesWidget: (value, meta) => Text(
                '\$${value.toStringAsFixed(0)}',
                style: TextStyle(color: AppColors.subtext(isDark), fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              getTitlesWidget: (value, meta) {
                final h = value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${h.toString().padLeft(2, '0')}h',
                    style: TextStyle(
                        color: AppColors.subtext(isDark), fontSize: 9),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: isDark ? const Color(0xFF22272E) : Colors.white,
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.x.toInt().toString().padLeft(2, '0')}:00\n\$${spot.y.toStringAsFixed(2)}',
                TextStyle(
                  color: isDark ? Colors.white : AppColors.text(false),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inventarioPanel(bool isDark) {
    final totalProductos = productos.length;
    final disponibles =
        productos.where((p) => ((p['stock'] as num?)?.toInt() ?? 0) > 0).length;
    final categoriasActivas = _categorias.length;
    final unidades = _totalStock;
    final maxStock = productos.isEmpty
        ? 1
        : productos
            .map((p) => ((p['stock'] as num?)?.toInt() ?? 0))
            .fold<int>(0, (a, b) => a > b ? a : b);

    return _panel(
      isDark,
      title: 'Catálogo e inventario',
      subtitle: 'Cantidad y estado de tus productos',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          Row(children: [
            Expanded(
                child: _dashboardCount('Productos', '$totalProductos',
                    Icons.inventory_2_rounded, AppColors.primary, isDark)),
            const SizedBox(width: 8),
            Expanded(
                child: _dashboardCount('Disponibles', '$disponibles',
                    Icons.check_circle_rounded, AppColors.success, isDark)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: _dashboardCount('Categorías', '$categoriasActivas',
                    Icons.category_rounded, AppColors.info, isDark)),
            const SizedBox(width: 8),
            Expanded(
                child: _dashboardCount('Unidades', '$unidades',
                    Icons.all_inbox_rounded, AppColors.secondary, isDark)),
          ]),
          const SizedBox(height: 14),
          _inventoryProgress('Nivel de unidades disponibles', unidades,
              maxStock, AppColors.info, isDark),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _miniStatus('Stock bajo', '$_productosStockBajo',
                    AppColors.warning, isDark)),
            const SizedBox(width: 8),
            Expanded(
                child: _miniStatus('Agotados', '$_productosAgotados',
                    AppColors.danger, isDark)),
          ]),
        ],
      ),
    );
  }

  Widget _dashboardCount(
      String label, String value, IconData icon, Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: .14)),
      ),
      child: Row(children: [
        Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: accent.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: accent, size: 18)),
        const SizedBox(width: 9),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 17,
                  fontWeight: FontWeight.w900)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColors.subtext(isDark),
                  fontSize: 9,
                  fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }

  Widget _inventoryRow(String label, double value, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: AppColors.subtext(isDark), fontSize: 11))),
          Text('\$${value.toStringAsFixed(2)}',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _inventoryProgress(
      String label, int value, int max, Color color, bool isDark) {
    final progress = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: AppColors.subtext(isDark), fontSize: 11))),
          Text('$value',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: AppColors.divider(isDark),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _miniStatus(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(children: [
        Icon(Icons.circle, color: color, size: 8),
        const SizedBox(width: 7),
        Expanded(
            child: Text(label,
                style:
                    TextStyle(color: AppColors.subtext(isDark), fontSize: 10))),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _topProductosPanel(bool isDark) {
    return _panel(
      isDark,
      title: 'Productos más vendidos',
      subtitle: 'Los productos con mayor movimiento',
      icon: Icons.local_fire_department_outlined,
      child: productosMasVendidos.isEmpty
          ? _emptyDashboard('Aún no hay ventas registradas', isDark)
          : Column(
              children: productosMasVendidos
                  .take(7)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final p = entry.value;
                final cantidad = (p['cantidad'] as num?)?.toInt() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index < 3
                            ? AppColors.primary.withValues(alpha: 0.10)
                            : AppColors.background(isDark),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text('${index + 1}',
                          style: TextStyle(
                              color: index < 3
                                  ? AppColors.primary
                                  : AppColors.subtext(isDark),
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(p['nombre']?.toString() ?? 'Producto',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppColors.text(isDark),
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                    Text('$cantidad',
                        style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 4),
                    Text('vendidos',
                        style: TextStyle(
                            color: AppColors.subtext(isDark), fontSize: 9)),
                  ]),
                );
              }).toList(),
            ),
    );
  }

  Widget _metodosPagoPanel(
      bool isDark, List<MapEntry<String, double>> metodos) {
    final total = metodos.fold<double>(0, (sum, e) => sum + e.value);
    return _panel(
      isDark,
      title: 'Métodos de pago',
      subtitle: 'Distribución de las ventas de hoy',
      icon: Icons.payments_outlined,
      child: metodos.isEmpty
          ? _emptyDashboard('Todavía no hay pagos registrados', isDark)
          : Column(
              children: [
                SizedBox(
                  height: 135,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 135,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 38,
                            sections: metodos
                                .take(5)
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final porcentaje =
                                  total <= 0 ? 0.0 : item.value / total * 100;
                              final colores = [
                                AppColors.primary,
                                AppColors.success,
                                AppColors.secondary,
                                AppColors.warning,
                                AppColors.info
                              ];
                              return PieChartSectionData(
                                value: item.value,
                                color: colores[index % colores.length],
                                radius: 24,
                                showTitle: false,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: metodos
                              .take(5)
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final porcentaje =
                                total <= 0 ? 0.0 : item.value / total * 100;
                            final colores = [
                              AppColors.primary,
                              AppColors.success,
                              AppColors.secondary,
                              AppColors.warning,
                              AppColors.info
                            ];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(children: [
                                Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                        color: colores[index % colores.length],
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 7),
                                Expanded(
                                    child: Text(item.key,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: AppColors.subtext(isDark),
                                            fontSize: 10))),
                                Text('${porcentaje.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        color: AppColors.text(isDark),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800)),
                              ]),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 18),
                Row(children: [
                  Expanded(
                      child: Text('Total procesado',
                          style: TextStyle(
                              color: AppColors.subtext(isDark), fontSize: 10))),
                  Text('\$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: AppColors.text(isDark),
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ]),
              ],
            ),
    );
  }

  Widget _statusItem(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.background(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider(isDark)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(color: AppColors.subtext(isDark), fontSize: 9)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }

  Widget _emptyDashboard(String message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Center(
        child: Text(message,
            style: TextStyle(color: AppColors.subtext(isDark), fontSize: 11)),
      ),
    );
  }

  Widget _kpiGradiente(String t, String v, String s, IconData icon,
      LinearGradient gradient, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(t,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
              ),
            ]),
            const SizedBox(height: 6),
            Text(v,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(s,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _productosWidget(bool isDark) {
    final filtrados = productosFiltrados;
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card(isDark),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(isDark),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                        hintText: 'Buscar producto...',
                        hintStyle: TextStyle(
                            color: AppColors.subtext(isDark), fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onChanged: (v) => setState(() => searchQuery = v),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 22),
                onPressed: () => mostrarDialogoProducto(),
                padding: EdgeInsets.zero,
                tooltip: 'Agregar producto',
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _buildFiltroDropdown(
                _filtroCategoria,
                ['Todas', ..._categorias.map((c) => c['nombre'].toString())],
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
                color: AppColors.shadow(isDark),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                              color: AppColors.subtext(isDark), fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Toca el botón + para agregar',
                          style: TextStyle(
                              color: AppColors.subtext(isDark), fontSize: 12)),
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
                        border: Border.all(
                            color: AppColors.divider(isDark), width: 1),
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
                              imagenBase64: prod['imagen_base64']?.toString(),
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
                                    '\$${(prod['precio'] as num).toStringAsFixed(2)}',
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
                    );
                  },
                ),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => mostrarDialogoProducto(),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          label: const Text('AGREGAR NUEVO PRODUCTO',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
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
                  child: Text(op, style: const TextStyle(fontSize: 11)),
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
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
                color: AppColors.shadow(isDark),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ventasFiltradas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined,
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
                    return GestureDetector(
                      onTap: () => _mostrarDetalleVenta(v),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background(isDark),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.divider(isDark), width: 1),
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
                                    DateFormat('dd/MM/yyyy HH:mm')
                                        .format(fecha),
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
                              Text(
                                  '\$${(v['total'] as num).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              Icon(Icons.chevron_right,
                                  color: AppColors.subtext(isDark), size: 20),
                            ],
                          ),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ),
    ]);
  }

  Future<void> _mostrarDetalleVenta(Map<String, dynamic> venta) async {
    final isDark = widget.modoOscuro;
    final detalle = await _db.getDetalleVenta(venta['id'].toString());
    final totalVenta = (venta['total'] as num).toDouble();
    final nombreCliente = venta['cliente_nombre'] ?? 'Público General';
    final telefonoCliente = venta['cliente_telefono'] ?? '';
    final factura = venta['numero_factura'] ?? 'Venta #${venta['id']}';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(factura,
                            style: TextStyle(
                                color: AppColors.text(isDark),
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        Text(nombreCliente,
                            style: TextStyle(
                                color: AppColors.subtext(isDark),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.subtext(isDark)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Divider(color: AppColors.divider(isDark)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: detalle.length,
                  itemBuilder: (_, i) {
                    final d = detalle[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['nombre'] ?? '',
                                    style: TextStyle(
                                        color: AppColors.text(isDark),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    '${d['cantidad']} x \$${(d['precio'] as num).toStringAsFixed(2)}',
                                    style: TextStyle(
                                        color: AppColors.subtext(isDark),
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          Text('\$${(d['subtotal'] as num).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Divider(color: AppColors.divider(isDark)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL:',
                      style: TextStyle(
                          color: AppColors.text(isDark),
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  Text('\$${totalVenta.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _enviarWhatsAppVenta(nombreCliente, telefonoCliente,
                            factura, totalVenta);
                      },
                      icon: const Icon(Icons.chat_rounded,
                          color: Colors.white, size: 18),
                      label: const Text('WhatsApp',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.whatsapp,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        mostrarSnackBar(
                            'Imprimiendo ticket...', AppColors.primary);
                      },
                      icon: const Icon(Icons.print_rounded,
                          color: Colors.white, size: 18),
                      label: const Text('Imprimir',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _enviarWhatsAppVenta(
      String nombre, String telefono, String factura, double totalVenta) {
    if (telefono.isEmpty) {
      mostrarSnackBar(
          'El cliente no tiene número de teléfono', AppColors.warning);
      return;
    }
    String phone = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) {
      phone = '58${phone.substring(1)}';
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

  // ============================================
  // CREAR PRODUCTO PROFESIONAL - CON SCANNER INTEGRADO
  // ============================================
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
    final descuentoCtrl = TextEditingController(
        text: productoEditar?['descuento']?.toString() ?? '0');

    String unidadMedida = productoEditar?['unidad_medida'] ?? 'pieza';
    String categoriaSeleccionada = productoEditar?['categoria'] ?? 'General';
    String? tallaSeleccionada = productoEditar?['talla'];
    String? colorSeleccionado = productoEditar?['color'];
    bool activo =
        productoEditar?['activo'] == 1 || productoEditar?['activo'] == true;
    bool destacado = productoEditar?['destacado'] == 1 ||
        productoEditar?['destacado'] == true;
    bool tieneDescuento = (productoEditar?['descuento'] ?? 0) > 0;
    bool guardando = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final ValueNotifier<String> imagenNotifier =
            ValueNotifier(productoEditar?['imagen_base64'] ?? '');
        bool subiendo = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> subirImagen(XFile imagen) async {
              setDialogState(() => subiendo = true);
              try {
                final bytes = await imagen.readAsBytes();
                final base64 = base64Encode(bytes);
                setDialogState(() {
                  imagenNotifier.value = base64;
                  subiendo = false;
                });
              } catch (e) {
                setDialogState(() => subiendo = false);
              }
            }

            // FUNCIÓN PARA ESCANEAR CÓDIGO
            Future<void> escanearCodigo() async {
              final codigo = await showDialog<String>(
                context: dialogContext,
                barrierDismissible: false,
                builder: (ctx) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    height: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ScannerRapido(
                      isDark: isDark,
                      onCodigoDetectado: (codigo) {
                        Navigator.pop(ctx, codigo);
                      },
                      onCerrar: () => Navigator.pop(ctx, null),
                    ),
                  ),
                ),
              );

              if (codigo != null && codigo.isNotEmpty) {
                setDialogState(() {
                  codigoCtrl.text = codigo;
                });
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.card(isDark),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
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
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // SECCIÓN IMAGEN
                      ValueListenableBuilder<String>(
                        valueListenable: imagenNotifier,
                        builder: (context, base64, child) {
                          if (base64.isNotEmpty) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              width: double.infinity,
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: AppColors.divider(isDark)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: ImagenProducto(
                                  imagenBase64: base64,
                                  width: double.infinity,
                                  height: 160,
                                  fit: BoxFit.contain,
                                  icono: Icons.image_not_supported_outlined,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      if (subiendo) ...[
                        const CircularProgressIndicator(
                            color: AppColors.primary),
                        const SizedBox(height: 8),
                      ],
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
                                side:
                                    const BorderSide(color: AppColors.primary),
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
                                side:
                                    const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      Divider(color: AppColors.divider(isDark)),
                      const SizedBox(height: 8),
                      // SECCIÓN INFORMACIÓN BÁSICA
                      TextField(
                        controller: nombreCtrl,
                        style: TextStyle(color: AppColors.text(isDark)),
                        decoration: _inputDecoration('Nombre del Producto *',
                            Icons.inventory_2_outlined, isDark),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: codigoCtrl,
                            style: TextStyle(color: AppColors.text(isDark)),
                            decoration: _inputDecoration(
                                'Código de Barras', Icons.qr_code, isDark),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.qr_code_scanner_rounded,
                                color: Colors.white, size: 22),
                            onPressed: escanearCodigo,
                            tooltip: 'Escanear código',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.auto_awesome_rounded,
                                color: Colors.white, size: 22),
                            onPressed: () async {
                              final codigo =
                                  await BarcodeService().generarCodigoEAN13();
                              setDialogState(() {
                                codigoCtrl.text = codigo;
                              });
                            },
                            tooltip: 'Generar código',
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background(isDark),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              Icon(Icons.straighten,
                                  color: AppColors.subtext(isDark), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: unidadMedida,
                                  isExpanded: true,
                                  dropdownColor: AppColors.card(isDark),
                                  style: TextStyle(
                                      color: AppColors.text(isDark),
                                      fontSize: 13),
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'pieza', child: Text('Pieza')),
                                    DropdownMenuItem(
                                        value: 'kg', child: Text('Kilogramo')),
                                    DropdownMenuItem(
                                        value: 'g', child: Text('Gramo')),
                                    DropdownMenuItem(
                                        value: 'L', child: Text('Litro')),
                                    DropdownMenuItem(
                                        value: 'ml', child: Text('Mililitro')),
                                    DropdownMenuItem(
                                        value: 'docena', child: Text('Docena')),
                                    DropdownMenuItem(
                                        value: 'caja', child: Text('Caja')),
                                  ],
                                  onChanged: (v) => setDialogState(
                                      () => unidadMedida = v ?? 'pieza'),
                                ),
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background(isDark),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              Icon(Icons.folder_outlined,
                                  color: AppColors.subtext(isDark), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: categoriaSeleccionada,
                                  isExpanded: true,
                                  dropdownColor: AppColors.card(isDark),
                                  style: TextStyle(
                                      color: AppColors.text(isDark),
                                      fontSize: 13),
                                  underline: const SizedBox(),
                                  items: _categorias
                                      .map((cat) => DropdownMenuItem(
                                            value: cat['nombre']?.toString() ??
                                                'General',
                                            child: Text(
                                                cat['nombre']?.toString() ??
                                                    'General',
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setDialogState(() =>
                                      categoriaSeleccionada = v ?? 'General'),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      // SECCIÓN PRECIOS
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
                            decoration: _inputDecoration('Precio de Venta *',
                                Icons.attach_money, isDark),
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
                      const SizedBox(height: 12),
                      // SECCIÓN STOCK
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
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        style: TextStyle(color: AppColors.text(isDark)),
                        decoration: _inputDecoration(
                            'Descripción', Icons.description_outlined, isDark),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      // SECCIÓN VARIANTES
                      if (_tallas.isNotEmpty) ...[
                        Text('TALLA',
                            style: TextStyle(
                                color: AppColors.subtext(isDark),
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        SelectorTallas(
                          tallas: _tallas,
                          tallaInicial: tallaSeleccionada,
                          isDark: isDark,
                          onSeleccion: (talla) {
                            setDialogState(() => tallaSeleccionada = talla);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_colores.isNotEmpty) ...[
                        Text('COLOR',
                            style: TextStyle(
                                color: AppColors.subtext(isDark),
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        SelectorColores(
                          colores: _colores,
                          colorInicial: colorSeleccionado,
                          isDark: isDark,
                          onSeleccion: (color) {
                            setDialogState(() => colorSeleccionado = color);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      // SECCIÓN CONFIGURACIÓN
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          title: Text('Producto Activo',
                              style: TextStyle(
                                  color: AppColors.text(isDark), fontSize: 14)),
                          value: activo,
                          onChanged: (v) => setDialogState(() => activo = v),
                          activeThumbColor: AppColors.primary,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          title: Text('Producto Destacado',
                              style: TextStyle(
                                  color: AppColors.text(isDark), fontSize: 14)),
                          value: destacado,
                          onChanged: (v) => setDialogState(() => destacado = v),
                          activeThumbColor: AppColors.primary,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
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
                      ),
                      if (tieneDescuento) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: descuentoCtrl,
                          style: TextStyle(color: AppColors.text(isDark)),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _inputDecoration(
                              'Porcentaje de descuento (%)',
                              Icons.percent,
                              isDark),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancelar',
                      style: TextStyle(color: AppColors.subtext(isDark))),
                ),
                ElevatedButton.icon(
                  onPressed: guardando
                      ? null
                      : () async {
                          if (nombreCtrl.text.isEmpty ||
                              precioCtrl.text.isEmpty) {
                            mostrarSnackBar('Nombre y precio son obligatorios',
                                AppColors.warning);
                            return;
                          }
                          if (subiendo) {
                            mostrarSnackBar('Espera a que la imagen termine',
                                AppColors.warning);
                            return;
                          }

                          setDialogState(() => guardando = true);

                          try {
                            final imagenFinal = imagenNotifier.value;
                            final precio = double.parse(precioCtrl.text);
                            final costo = double.tryParse(costoCtrl.text) ?? 0;
                            final descuento =
                                double.tryParse(descuentoCtrl.text) ?? 0;
                            final tieneVariantes = tallaSeleccionada != null ||
                                colorSeleccionado != null;

                            final prod = {
                              'codigo_barras': codigoCtrl.text,
                              'nombre': nombreCtrl.text,
                              'precio': precio,
                              'costo': costo,
                              'stock': int.tryParse(stockCtrl.text) ?? 0,
                              'stock_minimo':
                                  int.tryParse(stockMinCtrl.text) ?? 5,
                              'categoria': categoriaSeleccionada,
                              'descripcion': descCtrl.text,
                              'imagen_base64':
                                  imagenFinal.isEmpty ? null : imagenFinal,
                              'activo': activo ? 1 : 0,
                              'destacado': destacado ? 1 : 0,
                              'unidad_medida': unidadMedida,
                              'talla': tallaSeleccionada,
                              'color': colorSeleccionado,
                              'tiene_variantes': tieneVariantes ? 1 : 0,
                              'descuento': tieneDescuento ? descuento : 0,
                              'margen': costo > 0
                                  ? ((precio - costo) / costo * 100)
                                  : 0,
                            };

                            if (esEdicion) {
                              final actualizado = await _db.actualizarProducto(
                                  productoEditar['id'].toString(), prod);
                              if (!actualizado) {
                                throw Exception(
                                    'No se pudo actualizar el producto.');
                              }
                            } else {
                              final creado = await _db.crearProducto(prod);
                              if (creado == null) {
                                throw Exception(
                                    'No se pudo guardar el producto en la base de datos.');
                              }
                            }

                            Navigator.pop(dialogContext);
                            await cargarDatos();
                            mostrarSnackBar(
                                esEdicion
                                    ? 'Producto actualizado'
                                    : 'Producto creado exitosamente',
                                AppColors.success);
                          } catch (e) {
                            setDialogState(() => guardando = false);
                            mostrarSnackBar('Error: $e', AppColors.danger);
                          }
                        },
                  icon: guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded,
                          color: Colors.white, size: 18),
                  label: Text(
                    guardando
                        ? 'GUARDANDO...'
                        : esEdicion
                            ? 'ACTUALIZAR'
                            : 'GUARDAR PRODUCTO',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
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
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: AppColors.background(isDark),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.divider(isDark))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    final ca = _cajaActual != null;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.background(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 14,
        title: Row(
          children: [
            InkWell(
              onTap: widget.onAbrirSidebar,
              borderRadius: BorderRadius.circular(13),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.divider(isDark)),
                ),
                child: const Icon(Icons.menu_rounded,
                    color: AppColors.primary, size: 21),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DASHBOARD',
                    style: TextStyle(
                        color: AppColors.text(isDark),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
                Text(
                    '${productos.length} productos · ${cantidadVentasHoy} ventas hoy',
                    style: TextStyle(
                        color: AppColors.subtext(isDark), fontSize: 10)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
            icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: AppColors.primary,
                size: 21),
            onPressed: widget.onToggleModoOscuro,
          ),
          PopupMenuButton<String>(
            tooltip: 'Acciones',
            icon: Icon(Icons.more_horiz_rounded,
                color: AppColors.subtext(isDark)),
            color: AppColors.card(isDark),
            onSelected: (value) {
              if (value == 'refresh') {
                cargarDatos();
                mostrarSnackBar('Dashboard actualizado', AppColors.primary);
              } else if (value == 'caja') {
                ca ? cerrarCaja() : abrirCaja();
              } else if (value == 'pos') {
                widget.onNavigateToPOS();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'refresh',
                  child: Row(children: [
                    Icon(Icons.refresh_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    const Text('Actualizar')
                  ])),
              PopupMenuItem(
                  value: 'caja',
                  child: Row(children: [
                    Icon(ca ? Icons.lock_open_rounded : Icons.lock_rounded,
                        color: ca ? AppColors.success : AppColors.warning,
                        size: 18),
                    const SizedBox(width: 10),
                    Text(ca ? 'Cerrar caja' : 'Abrir caja')
                  ])),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'pos',
                  child: Row(children: [
                    Icon(Icons.point_of_sale_rounded,
                        color: AppColors.primary, size: 18),
                    SizedBox(width: 10),
                    Text('Ir al POS')
                  ])),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1450),
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider(isDark)),
                ),
                child: Row(children: [
                  _tab('Resumen', 0, isDark, Icons.dashboard_rounded),
                  _tab('Productos', 1, isDark, Icons.inventory_2_outlined),
                  _tab('Ventas', 2, isDark, Icons.receipt_long_outlined),
                ]),
              ),
            ),
            Expanded(
              child: cargando
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : seccionActual == 0
                      ? _resumen(isDark)
                      : seccionActual == 1
                          ? _productosWidget(isDark)
                          : _ventasWidget(isDark),
            ),
          ],
        ),
      ),
    );
  }
}
// ============================================
// CONTINUACIÓN - ETAPA 5 de 6
// ============================================

// ============================================
// FUNCIÓN MAIN
// ============================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final prefs = await SharedPreferences.getInstance();
    tasasCambio['COP'] = prefs.getDouble('tasa_cop') ?? 4500.0;
    tasasCambio['VES'] = prefs.getDouble('tasa_ves') ?? 60.0;
  } catch (e) {
    debugPrint('Error cargando preferencias: $e');
  }

  runApp(const MiApp());
}

// ============================================
// PANTALLA: CONFIGURACIÓN (MI NEGOCIO) - DISEÑO PROFESIONAL
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
  String? _logoBase64;
  bool _cargando = true;
  bool _guardando = false;
  bool _subiendoLogo = false;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    try {
      final config = await _db.getConfiguracion();
      final prefs = await SharedPreferences.getInstance();
      if (config != null) {
        _nombreCtrl.text = config['nombre_negocio'] ?? '';
        _rifCtrl.text = config['rif'] ?? '';
        _direccionCtrl.text = config['direccion'] ?? '';
        _telefonoCtrl.text = config['telefono'] ?? '';
        _correoCtrl.text = config['correo'] ?? '';
        _logoBase64 = config['logo_base64'];
      }
      _tasaCOPCtrl.text = (prefs.getDouble('tasa_cop') ?? 4500.0).toString();
      _tasaVESCtrl.text = (prefs.getDouble('tasa_ves') ?? 60.0).toString();
    } catch (e) {
      debugPrint('Error cargando configuración: $e');
    }
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
        _logoBase64 = base64Encode(bytes);
      });
    } catch (e) {
      debugPrint('Error subiendo logo: $e');
    }
    setState(() => _subiendoLogo = false);
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
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
        'logo_base64': _logoBase64,
        'tasa_cop': double.tryParse(_tasaCOPCtrl.text) ?? 4500.0,
        'tasa_ves': double.tryParse(_tasaVESCtrl.text) ?? 60.0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Configuración guardada exitosamente',
                style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error guardando configuración: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
    setState(() => _guardando = false);
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
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
                  fontWeight: FontWeight.w800,
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _subiendoLogo
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary))
                              : _logoBase64 != null && _logoBase64!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.memory(
                                        base64Decode(_logoBase64!),
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                        errorBuilder: (_, __, ___) =>
                                            const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.store_rounded,
                                                color: AppColors.primary,
                                                size: 48),
                                            SizedBox(height: 4),
                                            Text('Subir Logo',
                                                style: TextStyle(
                                                    color: AppColors.primary,
                                                    fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.store_rounded,
                                            color: AppColors.primary, size: 48),
                                        SizedBox(height: 4),
                                        Text('Subir Logo',
                                            style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_nombreCtrl, 'Nombre del Negocio', isDark),
                    const SizedBox(height: 12),
                    _buildTextField(_rifCtrl, 'RIF / Cédula', isDark),
                    const SizedBox(height: 12),
                    _buildTextField(_direccionCtrl, 'Dirección', isDark,
                        maxLines: 2),
                    const SizedBox(height: 12),
                    _buildTextField(_telefonoCtrl, 'Teléfono', isDark,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildTextField(_correoCtrl, 'Correo Electrónico', isDark,
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
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _guardando ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
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
                                    fontWeight: FontWeight.w700,
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
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.divider(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

// ============================================
// PANTALLA: CATEGORÍAS - CON GUARDADO AUTOMÁTICO
// ============================================
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
    try {
      _categorias = await _db.getCategorias();
      debugPrint('Categorías cargadas: ${_categorias.length}');
    } catch (e) {
      debugPrint('Error cargando categorías: $e');
      _categorias = [];
    }
    setState(() => _cargando = false);
  }

  void _mostrarDialogo({Map<String, dynamic>? categoria}) {
    final isDark = widget.modoOscuro;
    final nombreCtrl = TextEditingController(text: categoria?['nombre'] ?? '');
    final descCtrl =
        TextEditingController(text: categoria?['descripcion'] ?? '');
    String? imagenBase64 = categoria?['imagen_base64'];
    bool subiendo = false;
    bool guardando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            categoria != null ? 'Editar Categoría' : 'Nueva Categoría',
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
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style: TextStyle(color: AppColors.text(isDark)),
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                    filled: true,
                    fillColor: AppColors.background(isDark),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
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
            ElevatedButton.icon(
              onPressed: guardando
                  ? null
                  : () async {
                      if (nombreCtrl.text.isEmpty) {
                        _mostrarSnackbar(
                            'El nombre es obligatorio', AppColors.warning);
                        return;
                      }
                      setDialogState(() => guardando = true);
                      try {
                        final data = {
                          'nombre': nombreCtrl.text,
                          'descripcion': descCtrl.text,
                          'imagen_base64': imagenBase64,
                        };
                        if (categoria != null) {
                          await _db.actualizarCategoria(
                              categoria['id'].toString(), data);
                        } else {
                          await _db.crearCategoria(data);
                        }
                        Navigator.pop(ctx);
                        await _cargarCategorias();
                        _mostrarSnackbar(
                            categoria != null
                                ? 'Categoría actualizada'
                                : 'Categoría creada exitosamente',
                            AppColors.success);
                      } catch (e) {
                        setDialogState(() => guardando = false);
                        _mostrarSnackbar('Error: $e', AppColors.danger);
                      }
                    },
              icon: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                guardando ? 'GUARDANDO...' : 'GUARDAR',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('CATEGORÍAS',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${_categorias.length}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
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
              else if (_categorias.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined,
                            size: 60, color: AppColors.subtext(isDark)),
                        const SizedBox(height: 16),
                        Text('No hay categorías',
                            style: TextStyle(
                                color: AppColors.subtext(isDark),
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Agrega tu primera categoría',
                            style: TextStyle(
                                color: AppColors.subtext(isDark),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _categorias.length,
                    itemBuilder: (_, i) {
                      final cat = _categorias[i];
                      final nombre = cat['nombre'] ?? '';
                      final descripcion = cat['descripcion'] ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
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
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.category_outlined,
                                color: AppColors.primary, size: 24),
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
                                if (descripcion.isNotEmpty)
                                  Text(descripcion,
                                      style: TextStyle(
                                          color: AppColors.subtext(isDark),
                                          fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                              ],
                            ),
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
                              await _cargarCategorias();
                              _mostrarSnackbar(
                                  'Categoría eliminada', AppColors.danger);
                            },
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogo(),
                  icon: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 24),
                  label: const Text('AGREGAR CATEGORÍA',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
// PANTALLA: MÉTODOS DE PAGO - CON GUARDADO AUTOMÁTICO
// ============================================
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
    try {
      _metodos = await _db.getMetodosPago();
    } catch (e) {
      debugPrint('Error cargando métodos de pago: $e');
      _metodos = [];
    }
    setState(() => _cargando = false);
  }

  void _mostrarDialogo({Map<String, dynamic>? metodo}) {
    final isDark = widget.modoOscuro;
    final nombreCtrl = TextEditingController(text: metodo?['nombre'] ?? '');
    final bancoCtrl = TextEditingController(text: metodo?['banco'] ?? '');
    final numeroCuentaCtrl =
        TextEditingController(text: metodo?['numero_cuenta'] ?? '');
    final telefonoCtrl =
        TextEditingController(text: metodo?['telefono_pago_movil'] ?? '');
    final titularCtrl = TextEditingController(text: metodo?['titular'] ?? '');
    final datosCtrl =
        TextEditingController(text: metodo?['datos_adicionales'] ?? '');
    bool guardando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            metodo != null ? 'Editar Método' : 'Nuevo Método',
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
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bancoCtrl,
                  style: TextStyle(color: AppColors.text(isDark)),
                  decoration: InputDecoration(
                    labelText: 'Banco',
                    labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                    filled: true,
                    fillColor: AppColors.background(isDark),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: numeroCuentaCtrl,
                  style: TextStyle(color: AppColors.text(isDark)),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Número de cuenta',
                    labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                    filled: true,
                    fillColor: AppColors.background(isDark),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: telefonoCtrl,
                  style: TextStyle(color: AppColors.text(isDark)),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Teléfono (Pago Móvil)',
                    labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                    filled: true,
                    fillColor: AppColors.background(isDark),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titularCtrl,
                  style: TextStyle(color: AppColors.text(isDark)),
                  decoration: InputDecoration(
                    labelText: 'Titular',
                    labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                    filled: true,
                    fillColor: AppColors.background(isDark),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
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
            ElevatedButton.icon(
              onPressed: guardando
                  ? null
                  : () async {
                      if (nombreCtrl.text.isEmpty) return;
                      setDialogState(() => guardando = true);
                      try {
                        final data = {
                          'nombre': nombreCtrl.text,
                          'banco': bancoCtrl.text,
                          'numero_cuenta': numeroCuentaCtrl.text,
                          'telefono_pago_movil': telefonoCtrl.text,
                          'titular': titularCtrl.text,
                          'datos_adicionales': datosCtrl.text,
                        };
                        if (metodo != null) {
                          await _db.actualizarMetodoPago(
                              metodo['id'].toString(), data);
                        } else {
                          await _db.crearMetodoPago({...data, 'activo': 1});
                        }
                        Navigator.pop(ctx);
                        await _cargarMetodos();
                      } catch (e) {
                        setDialogState(() => guardando = false);
                        debugPrint('Error guardando método: $e');
                      }
                    },
              icon: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                guardando ? 'GUARDANDO...' : 'GUARDAR',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('MÉTODOS DE PAGO',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${_metodos.length}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
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
              else if (_metodos.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment_outlined,
                            size: 60, color: AppColors.subtext(isDark)),
                        const SizedBox(height: 16),
                        Text('No hay métodos de pago',
                            style: TextStyle(
                                color: AppColors.subtext(isDark),
                                fontSize: 16)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _metodos.length,
                    itemBuilder: (_, i) {
                      final metodo = _metodos[i];
                      final nombre = metodo['nombre'] ?? '';
                      final banco = metodo['banco'] ?? '';
                      final numeroCuenta = metodo['numero_cuenta'] ?? '';
                      final telefono = metodo['telefono_pago_movil'] ?? '';

                      IconData iconoMetodo;
                      switch (nombre.toLowerCase()) {
                        case 'efectivo':
                          iconoMetodo = Icons.payments_outlined;
                          break;
                        case 'tarjeta':
                          iconoMetodo = Icons.credit_card_outlined;
                          break;
                        case 'transferencia':
                          iconoMetodo = Icons.swap_horiz_rounded;
                          break;
                        case 'pago movil':
                          iconoMetodo = Icons.phone_android_rounded;
                          break;
                        default:
                          iconoMetodo = Icons.payment_rounded;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
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
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(iconoMetodo,
                                color: AppColors.primary, size: 20),
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
                                if (banco.isNotEmpty)
                                  Text('Banco: $banco',
                                      style: TextStyle(
                                          color: AppColors.subtext(isDark),
                                          fontSize: 10)),
                                if (numeroCuenta.isNotEmpty)
                                  Text('Cuenta: $numeroCuenta',
                                      style: TextStyle(
                                          color: AppColors.subtext(isDark),
                                          fontSize: 10)),
                                if (telefono.isNotEmpty)
                                  Text('Tel: $telefono',
                                      style: TextStyle(
                                          color: AppColors.subtext(isDark),
                                          fontSize: 10)),
                              ],
                            ),
                          ),
                          Switch(
                            value: metodo['activo'] == 1 ||
                                metodo['activo'] == true,
                            onChanged: (val) async {
                              await _db.actualizarMetodoPago(
                                metodo['id'].toString(),
                                {'activo': val ? 1 : 0},
                              );
                              await _cargarMetodos();
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
                              await _cargarMetodos();
                            },
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogo(),
                  icon: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 24),
                  label: const Text('AGREGAR MÉTODO',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
// PANTALLA: VENDEDORES - CON GUARDADO AUTOMÁTICO
// ============================================
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
    try {
      _vendedores = await _db.getVendedores();
    } catch (e) {
      debugPrint('Error cargando vendedores: $e');
      _vendedores = [];
    }
    setState(() => _cargando = false);
  }

  void _mostrarDialogo({Map<String, dynamic>? vendedor}) {
    final isDark = widget.modoOscuro;
    final nombreCtrl = TextEditingController(text: vendedor?['nombre'] ?? '');
    final telefonoCtrl =
        TextEditingController(text: vendedor?['telefono'] ?? '');
    final comisionCtrl =
        TextEditingController(text: vendedor?['comision']?.toString() ?? '0');
    bool guardando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2)),
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
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: comisionCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Comisión (%)',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar',
                    style: TextStyle(color: AppColors.subtext(isDark)))),
            ElevatedButton.icon(
              onPressed: guardando
                  ? null
                  : () async {
                      if (nombreCtrl.text.isEmpty) return;
                      setDialogState(() => guardando = true);
                      try {
                        final data = {
                          'nombre': nombreCtrl.text,
                          'telefono': telefonoCtrl.text,
                          'comision': double.tryParse(comisionCtrl.text) ?? 0,
                        };
                        if (vendedor != null) {
                          await _db.actualizarVendedor(
                              vendedor['id'].toString(), data);
                        } else {
                          await _db.crearVendedor(data);
                        }
                        Navigator.pop(ctx);
                        await _cargarVendedores();
                      } catch (e) {
                        setDialogState(() => guardando = false);
                        debugPrint('Error guardando vendedor: $e');
                      }
                    },
              icon: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                guardando ? 'GUARDANDO...' : 'GUARDAR',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
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
                  fontWeight: FontWeight.w800,
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
              else if (_vendedores.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 60, color: AppColors.subtext(isDark)),
                        const SizedBox(height: 16),
                        Text('No hay vendedores',
                            style: TextStyle(
                                color: AppColors.subtext(isDark),
                                fontSize: 16)),
                      ],
                    ),
                  ),
                )
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
                              color: Colors.black.withValues(alpha: 0.05),
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
                              gradient: AppColors.gradientPrimary,
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
                                Text('Comisión: $comision%',
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
                              await _cargarVendedores();
                            },
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogo(),
                  icon: const Icon(Icons.person_add_rounded,
                      color: Colors.white, size: 24),
                  label: const Text('AGREGAR VENDEDOR',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
// PANTALLA: CLIENTES - CON GUARDADO AUTOMÁTICO
// ============================================
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
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    setState(() => _cargando = true);
    try {
      _clientes = await _db.getClientes();
      debugPrint('Clientes cargados: ${_clientes.length}');
    } catch (e) {
      debugPrint('Error cargando clientes: $e');
      _clientes = [];
    }
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
    bool guardando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cedulaCtrl,
                  style: TextStyle(color: AppColors.text(isDark)),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cédula',
                    labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                    filled: true,
                    fillColor: AppColors.background(isDark),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
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
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: correoCtrl,
                  style: TextStyle(color: AppColors.text(isDark)),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo',
                    labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                    filled: true,
                    fillColor: AppColors.background(isDark),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
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
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
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
            ElevatedButton.icon(
              onPressed: guardando
                  ? null
                  : () async {
                      if (nombreCtrl.text.isEmpty) return;
                      setDialogState(() => guardando = true);
                      try {
                        final data = {
                          'nombre': nombreCtrl.text,
                          'telefono': telefonoCtrl.text,
                          'email': correoCtrl.text,
                          'direccion': direccionCtrl.text,
                          'identificacion': cedulaCtrl.text,
                        };
                        if (cliente != null) {
                          await _db.actualizarCliente(
                              cliente['id'].toString(), data);
                        } else {
                          await _db.crearCliente(data);
                        }
                        Navigator.pop(ctx);
                        await _cargarClientes();
                      } catch (e) {
                        setDialogState(() => guardando = false);
                        debugPrint('Error guardando cliente: $e');
                      }
                    },
              icon: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                guardando ? 'GUARDANDO...' : 'GUARDAR',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    final clientesFiltrados = _busqueda.isEmpty
        ? _clientes
        : _clientes
            .where((c) =>
                (c['nombre'] as String)
                    .toLowerCase()
                    .contains(_busqueda.toLowerCase()) ||
                (c['telefono'] as String? ?? '').contains(_busqueda) ||
                (c['identificacion'] as String? ?? '').contains(_busqueda))
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
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
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${_clientes.length}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
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
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  style: TextStyle(color: AppColors.text(isDark)),
                  onChanged: (v) => setState(() => _busqueda = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, teléfono o cédula...',
                    hintStyle: TextStyle(color: AppColors.subtext(isDark)),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.subtext(isDark)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.card(isDark),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_cargando)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)))
              else if (clientesFiltrados.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 60, color: AppColors.subtext(isDark)),
                        const SizedBox(height: 16),
                        Text('No hay clientes',
                            style: TextStyle(
                                color: AppColors.subtext(isDark),
                                fontSize: 16)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: clientesFiltrados.length,
                    itemBuilder: (_, i) {
                      final c = clientesFiltrados[i];
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
                              color: Colors.black.withValues(alpha: 0.05),
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
                              color: AppColors.primary.withValues(alpha: 0.08),
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
                                if (telefono.isNotEmpty)
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
                              await _cargarClientes();
                            },
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogo(),
                  icon: const Icon(Icons.person_add_rounded,
                      color: Colors.white, size: 24),
                  label: const Text('AGREGAR CLIENTE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
// CONTINUACIÓN - ETAPA 6 de 6 (FINAL)
// ============================================

// ============================================
// PANTALLA: CONFIGURAR TICKET - DISEÑO PROFESIONAL
// ============================================
class ConfigurarTicketScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const ConfigurarTicketScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<ConfigurarTicketScreen> createState() => _ConfigurarTicketScreenState();
}

class _ConfigurarTicketScreenState extends State<ConfigurarTicketScreen> {
  final _db = DatabaseService();

  final _nombreCtrl = TextEditingController();
  final _esloganCtrl = TextEditingController();
  final _rifCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mensajePieCtrl = TextEditingController();
  final _mensajeAdicionalCtrl = TextEditingController();

  String? _logoBase64;
  bool _cargando = true;
  bool _guardando = false;
  bool _subiendoLogo = false;

  bool _mostrarLogo = true;
  bool _mostrarEslogan = true;
  bool _mostrarRif = true;
  bool _mostrarDireccion = true;
  bool _mostrarTelefono = true;
  bool _mostrarEmail = false;
  bool _mostrarCliente = true;
  bool _mostrarQR = true;

  String _tamanoPapel = '80mm';
  int _numeroCopias = 1;
  int _tabActual = 0;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    setState(() => _cargando = true);
    try {
      final config = await _db.getConfiguracionTicket();
      if (config != null) {
        _nombreCtrl.text = config['nombre_negocio'] ?? 'SINTHETIX PRO';
        _esloganCtrl.text = config['eslogan'] ?? '';
        _rifCtrl.text = config['rif'] ?? '';
        _direccionCtrl.text = config['direccion'] ?? '';
        _telefonoCtrl.text = config['telefono'] ?? '';
        _emailCtrl.text = config['email'] ?? '';
        _mensajePieCtrl.text =
            config['mensaje_pie'] ?? '¡Gracias por su compra!';
        _mensajeAdicionalCtrl.text = config['mensaje_adicional'] ?? '';
        _logoBase64 = config['logo_base64'];
        _mostrarLogo =
            config['mostrar_logo'] == 1 || config['mostrar_logo'] == true;
        _mostrarEslogan =
            config['mostrar_eslogan'] == 1 || config['mostrar_eslogan'] == true;
        _mostrarRif =
            config['mostrar_rif'] == 1 || config['mostrar_rif'] == true;
        _mostrarDireccion = config['mostrar_direccion'] == 1 ||
            config['mostrar_direccion'] == true;
        _mostrarTelefono = config['mostrar_telefono'] == 1 ||
            config['mostrar_telefono'] == true;
        _mostrarEmail =
            config['mostrar_email'] == 1 || config['mostrar_email'] == true;
        _mostrarCliente =
            config['mostrar_cliente'] == 1 || config['mostrar_cliente'] == true;
        _mostrarQR = config['mostrar_qr'] == 1 || config['mostrar_qr'] == true;
        _tamanoPapel = config['tamano_papel'] ?? '80mm';
        _numeroCopias = config['numero_copias'] ?? 1;
      }
    } catch (e) {
      debugPrint('Error cargando configuración ticket: $e');
    }
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
        _logoBase64 = base64Encode(bytes);
      });
    } catch (e) {
      debugPrint('Error subiendo logo: $e');
    }
    setState(() => _subiendoLogo = false);
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final config = {
        'nombre_negocio': _nombreCtrl.text,
        'eslogan': _esloganCtrl.text,
        'rif': _rifCtrl.text,
        'direccion': _direccionCtrl.text,
        'telefono': _telefonoCtrl.text,
        'email': _emailCtrl.text,
        'logo_base64': _logoBase64,
        'mostrar_logo': _mostrarLogo ? 1 : 0,
        'mostrar_eslogan': _mostrarEslogan ? 1 : 0,
        'mostrar_rif': _mostrarRif ? 1 : 0,
        'mostrar_direccion': _mostrarDireccion ? 1 : 0,
        'mostrar_telefono': _mostrarTelefono ? 1 : 0,
        'mostrar_email': _mostrarEmail ? 1 : 0,
        'mostrar_cliente': _mostrarCliente ? 1 : 0,
        'mostrar_qr': _mostrarQR ? 1 : 0,
        'tamano_papel': _tamanoPapel,
        'numero_copias': _numeroCopias,
        'mensaje_pie': _mensajePieCtrl.text,
        'mensaje_adicional': _mensajeAdicionalCtrl.text,
      };
      await _db.guardarConfiguracionTicket(config);
      _mostrarSnackbar(
          'Configuración guardada exitosamente', AppColors.success);
    } catch (e) {
      debugPrint('Error guardando ticket: $e');
      _mostrarSnackbar('Error: $e', AppColors.danger);
    }
    setState(() => _guardando = false);
  }

  void _mostrarSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('CONFIGURAR TICKET',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.card(isDark),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(children: [
                      _tab('Configuración', 0, isDark, Icons.settings_rounded),
                      _tab('Vista Previa', 1, isDark, Icons.preview_rounded),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _tabActual == 0
                        ? _buildConfiguracion(isDark)
                        : _buildVistaPrevia(isDark),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _tab(String l, int i, bool isDark, IconData icon) {
    final sel = _tabActual == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabActual = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: sel ? AppColors.gradientPrimary : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: sel ? Colors.white : AppColors.subtext(isDark),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  l,
                  style: TextStyle(
                    color: sel ? Colors.white : AppColors.subtext(isDark),
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfiguracion(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('INFORMACIÓN DEL NEGOCIO',
            style: TextStyle(
                color: AppColors.subtext(isDark),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _subiendoLogo ? null : _subirLogo,
            child: Container(
              width: 100,
              height: 100,
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
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : _logoBase64 != null && _logoBase64!.isNotEmpty
                      ? ClipOval(
                          child: Image.memory(
                            base64Decode(_logoBase64!),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.store_rounded,
                                    color: AppColors.primary, size: 40),
                                SizedBox(height: 4),
                                Text('Subir Logo',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 10)),
                              ],
                            ),
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.store_rounded,
                                color: AppColors.primary, size: 40),
                            SizedBox(height: 4),
                            Text('Subir Logo',
                                style: TextStyle(
                                    color: AppColors.primary, fontSize: 10)),
                          ],
                        ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(_nombreCtrl, 'Nombre del Negocio', isDark),
        const SizedBox(height: 10),
        _buildTextField(_esloganCtrl, 'Eslogan', isDark),
        const SizedBox(height: 10),
        _buildTextField(_rifCtrl, 'RIF', isDark),
        const SizedBox(height: 10),
        _buildTextField(_direccionCtrl, 'Dirección', isDark, maxLines: 2),
        const SizedBox(height: 10),
        _buildTextField(_telefonoCtrl, 'Teléfono', isDark,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 10),
        _buildTextField(_emailCtrl, 'Email', isDark,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 24),
        Text('ELEMENTOS DEL TICKET',
            style: TextStyle(
                color: AppColors.subtext(isDark),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildSwitch('Mostrar Logo', _mostrarLogo,
                  (v) => setState(() => _mostrarLogo = v), isDark),
              _buildSwitch('Mostrar Eslogan', _mostrarEslogan,
                  (v) => setState(() => _mostrarEslogan = v), isDark),
              _buildSwitch('Mostrar RIF', _mostrarRif,
                  (v) => setState(() => _mostrarRif = v), isDark),
              _buildSwitch('Mostrar Dirección', _mostrarDireccion,
                  (v) => setState(() => _mostrarDireccion = v), isDark),
              _buildSwitch('Mostrar Teléfono', _mostrarTelefono,
                  (v) => setState(() => _mostrarTelefono = v), isDark),
              _buildSwitch('Mostrar Email', _mostrarEmail,
                  (v) => setState(() => _mostrarEmail = v), isDark),
              _buildSwitch('Mostrar Cliente', _mostrarCliente,
                  (v) => setState(() => _mostrarCliente = v), isDark),
              _buildSwitch('Mostrar QR', _mostrarQR,
                  (v) => setState(() => _mostrarQR = v), isDark),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('FORMATO',
            style: TextStyle(
                color: AppColors.subtext(isDark),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tamaño de papel',
                      style: TextStyle(
                          color: AppColors.text(isDark), fontSize: 14)),
                  DropdownButton<String>(
                    value: _tamanoPapel,
                    dropdownColor: AppColors.card(isDark),
                    style: TextStyle(color: AppColors.text(isDark)),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: '58mm', child: Text('58mm')),
                      DropdownMenuItem(value: '80mm', child: Text('80mm')),
                      DropdownMenuItem(value: 'A4', child: Text('A4')),
                    ],
                    onChanged: (v) =>
                        setState(() => _tamanoPapel = v ?? '80mm'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Número de copias',
                      style: TextStyle(
                          color: AppColors.text(isDark), fontSize: 14)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppColors.primary, size: 24),
                        onPressed: () {
                          if (_numeroCopias > 1) {
                            setState(() => _numeroCopias--);
                          }
                        },
                      ),
                      Text('$_numeroCopias',
                          style: TextStyle(
                              color: AppColors.text(isDark),
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: AppColors.primary, size: 24),
                        onPressed: () {
                          if (_numeroCopias < 5) {
                            setState(() => _numeroCopias++);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('MENSAJES',
            style: TextStyle(
                color: AppColors.subtext(isDark),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _buildTextField(_mensajePieCtrl, 'Mensaje de pie', isDark),
        const SizedBox(height: 10),
        _buildTextField(_mensajeAdicionalCtrl, 'Mensaje adicional', isDark,
            maxLines: 2),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded, color: Colors.white),
            label: Text(
              _guardando ? 'GUARDANDO...' : 'GUARDAR CONFIGURACIÓN',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
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
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.divider(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildSwitch(
      String label, bool value, Function(bool) onChanged, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        title: Text(label,
            style: TextStyle(color: AppColors.text(isDark), fontSize: 14)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildVistaPrevia(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_mostrarLogo &&
                  _logoBase64 != null &&
                  _logoBase64!.isNotEmpty)
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ClipOval(
                      child: Image.memory(
                        base64Decode(_logoBase64!),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.store,
                              color: Colors.grey, size: 30),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _nombreCtrl.text.isEmpty ? 'SINTHETIX PRO' : _nombreCtrl.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              if (_mostrarEslogan && _esloganCtrl.text.isNotEmpty)
                Center(
                  child: Text(
                    _esloganCtrl.text,
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ),
              if (_mostrarRif && _rifCtrl.text.isNotEmpty)
                Center(
                  child: Text(
                    'RIF: ${_rifCtrl.text}',
                    style: const TextStyle(fontSize: 8, color: Colors.black54),
                  ),
                ),
              if (_mostrarDireccion && _direccionCtrl.text.isNotEmpty)
                Center(
                  child: Text(
                    _direccionCtrl.text,
                    style: const TextStyle(fontSize: 8, color: Colors.black54),
                  ),
                ),
              if (_mostrarTelefono && _telefonoCtrl.text.isNotEmpty)
                Center(
                  child: Text(
                    'Tel: ${_telefonoCtrl.text}',
                    style: const TextStyle(fontSize: 8, color: Colors.black54),
                  ),
                ),
              const Divider(color: Colors.black26, height: 20),
              const Text('FACTURA: FAC-00000001',
                  style: TextStyle(fontSize: 10, color: Colors.black)),
              Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const TextStyle(fontSize: 8, color: Colors.black54)),
              if (_mostrarCliente) ...[
                const Text('Cliente: Público General',
                    style: TextStyle(fontSize: 10, color: Colors.black)),
              ],
              const Divider(color: Colors.black26, height: 20),
              const Text('Producto Ejemplo',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const Text('1 x \$25.00 = \$25.00',
                  style: TextStyle(fontSize: 9, color: Colors.black54)),
              const Divider(color: Colors.black26, height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  Text('\$25.00',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ],
              ),
              const Divider(color: Colors.black26, height: 20),
              Center(
                child: Text(
                  _mensajePieCtrl.text.isEmpty
                      ? '¡Gracias por su compra!'
                      : _mensajePieCtrl.text,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              if (_mostrarQR)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(8),
                    color: Colors.white,
                    child: QrImageView(
                      data: 'FAC-00000001',
                      version: QrVersions.auto,
                      size: 80,
                      backgroundColor: Colors.white,
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
// PANTALLA: CONFIGURACIÓN DE VARIANTES (TALLAS Y COLORES)
// ============================================
class ConfiguracionVariantesScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const ConfiguracionVariantesScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<ConfiguracionVariantesScreen> createState() =>
      _ConfiguracionVariantesScreenState();
}

class _ConfiguracionVariantesScreenState
    extends State<ConfiguracionVariantesScreen> {
  final _db = DatabaseService();
  List<Map<String, dynamic>> _tallas = [];
  List<Map<String, dynamic>> _colores = [];
  bool _cargando = true;
  int _tabActual = 0;

  final List<Color> _paletaColores = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.black,
    Colors.white,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.grey,
    Colors.brown,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      _tallas = await _db.getTallas();
      _colores = await _db.getColores();
      debugPrint('Tallas: ${_tallas.length}, Colores: ${_colores.length}');
    } catch (e) {
      debugPrint('Error cargando variantes: $e');
      _tallas = [];
      _colores = [];
    }
    setState(() => _cargando = false);
  }

  void _mostrarDialogoTalla({Map<String, dynamic>? talla}) {
    final isDark = widget.modoOscuro;
    final valorCtrl = TextEditingController(text: talla?['valor'] ?? '');
    bool guardando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            talla != null ? 'Editar Talla' : 'Nueva Talla',
            style: TextStyle(
                color: AppColors.text(isDark), fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: valorCtrl,
            style: TextStyle(color: AppColors.text(isDark)),
            decoration: InputDecoration(
              labelText: 'Talla (ej: S, M, L, 35, 36...)',
              labelStyle: TextStyle(color: AppColors.subtext(isDark)),
              filled: true,
              fillColor: AppColors.background(isDark),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar',
                    style: TextStyle(color: AppColors.subtext(isDark)))),
            ElevatedButton.icon(
              onPressed: guardando
                  ? null
                  : () async {
                      if (valorCtrl.text.isEmpty) return;
                      setDialogState(() => guardando = true);
                      try {
                        if (talla != null) {
                          await _db.actualizarVariante(talla['id'].toString(), {
                            'valor': valorCtrl.text,
                          });
                        } else {
                          await _db.crearVariante({
                            'tipo': 'talla',
                            'valor': valorCtrl.text,
                            'activo': 1,
                          });
                        }
                        Navigator.pop(ctx);
                        await _cargarDatos();
                      } catch (e) {
                        setDialogState(() => guardando = false);
                        debugPrint('Error guardando talla: $e');
                      }
                    },
              icon: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                guardando ? 'GUARDANDO...' : 'GUARDAR',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoColor({Map<String, dynamic>? color}) {
    final isDark = widget.modoOscuro;
    final valorCtrl = TextEditingController(text: color?['valor'] ?? '');
    Color colorSeleccionado = Colors.red;
    bool guardando = false;

    if (color != null && color['color_hex'] != null) {
      colorSeleccionado = hexToColor(color['color_hex']);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            color != null ? 'Editar Color' : 'Nuevo Color',
            style: TextStyle(
                color: AppColors.text(isDark), fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valorCtrl,
                style: TextStyle(color: AppColors.text(isDark)),
                decoration: InputDecoration(
                  labelText: 'Nombre del color',
                  labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                  filled: true,
                  fillColor: AppColors.background(isDark),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Selecciona el color:',
                  style: TextStyle(
                      color: AppColors.subtext(isDark), fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _paletaColores.map((c) {
                  final sel = colorSeleccionado.toARGB32() == c.toARGB32();
                  return GestureDetector(
                    onTap: () => setDialogState(() => colorSeleccionado = c),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel
                              ? AppColors.primary
                              : AppColors.divider(isDark),
                          width: sel ? 3 : 1,
                        ),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: sel
                          ? Icon(Icons.check,
                              color: c == Colors.white
                                  ? Colors.black
                                  : Colors.white,
                              size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar',
                    style: TextStyle(color: AppColors.subtext(isDark)))),
            ElevatedButton.icon(
              onPressed: guardando
                  ? null
                  : () async {
                      if (valorCtrl.text.isEmpty) return;
                      setDialogState(() => guardando = true);
                      try {
                        final hex = colorToHex(colorSeleccionado);
                        if (color != null) {
                          await _db.actualizarVariante(color['id'].toString(), {
                            'valor': valorCtrl.text,
                            'color_hex': hex,
                          });
                        } else {
                          await _db.crearVariante({
                            'tipo': 'color',
                            'valor': valorCtrl.text,
                            'color_hex': hex,
                            'activo': 1,
                          });
                        }
                        Navigator.pop(ctx);
                        await _cargarDatos();
                      } catch (e) {
                        setDialogState(() => guardando = false);
                        debugPrint('Error guardando color: $e');
                      }
                    },
              icon: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                guardando ? 'GUARDANDO...' : 'GUARDAR',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String l, int i, bool isDark, IconData icon) {
    final sel = _tabActual == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabActual = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: sel ? AppColors.gradientPrimary : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: sel ? Colors.white : AppColors.subtext(isDark),
                    size: 16),
                const SizedBox(width: 6),
                Text(l,
                    style: TextStyle(
                        color: sel ? Colors.white : AppColors.subtext(isDark),
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListaTallas(bool isDark) {
    if (_tallas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.straighten, size: 60, color: AppColors.subtext(isDark)),
            const SizedBox(height: 16),
            Text('No hay tallas configuradas',
                style: TextStyle(color: AppColors.subtext(isDark))),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _tallas.length,
      itemBuilder: (_, i) {
        final talla = _tallas[i];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider(isDark), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                talla['valor'] ?? '',
                style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _mostrarDialogoTalla(talla: talla),
                    child: Icon(Icons.edit_rounded,
                        color: AppColors.subtext(isDark), size: 16),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      await _db.eliminarVariante(talla['id'].toString());
                      await _cargarDatos();
                    },
                    child: Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger.withValues(alpha: 0.7),
                        size: 16),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListaColores(bool isDark) {
    if (_colores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.palette_outlined,
                size: 60, color: AppColors.subtext(isDark)),
            const SizedBox(height: 16),
            Text('No hay colores configurados',
                style: TextStyle(color: AppColors.subtext(isDark))),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _colores.length,
      itemBuilder: (_, i) {
        final color = _colores[i];
        final colorVisual = color['color_hex'] != null
            ? hexToColor(color['color_hex'])
            : Colors.grey;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider(isDark), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorVisual,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorVisual == Colors.white
                        ? Colors.grey
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                color['valor'] ?? '',
                style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _mostrarDialogoColor(color: color),
                    child: Icon(Icons.edit_rounded,
                        color: AppColors.subtext(isDark), size: 14),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () async {
                      await _db.eliminarVariante(color['id'].toString());
                      await _cargarDatos();
                    },
                    child: Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger.withValues(alpha: 0.7),
                        size: 14),
                  ),
                ],
              ),
            ],
          ),
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('TALLAS Y COLORES',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(children: [
                  _tab('Tallas', 0, isDark, Icons.straighten),
                  _tab('Colores', 1, isDark, Icons.palette_outlined),
                ]),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _cargando
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary))
                    : _tabActual == 0
                        ? _buildListaTallas(isDark)
                        : _buildListaColores(isDark),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _tabActual == 0
                      ? () => _mostrarDialogoTalla()
                      : () => _mostrarDialogoColor(),
                  icon: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 24),
                  label: Text(
                    _tabActual == 0 ? 'AGREGAR TALLA' : 'AGREGAR COLOR',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
// RENDERIZADOR EAN-13 SIN DEPENDENCIAS DE IMAGEN
// ============================================
class _EAN13Painter extends CustomPainter {
  final String value;
  _EAN13Painter(this.value);

  static const _leftA = [
    '0001101',
    '0011001',
    '0010011',
    '0111101',
    '0100011',
    '0110001',
    '0101111',
    '0111011',
    '0110111',
    '0001011'
  ];
  static const _leftB = [
    '0100111',
    '0110011',
    '0011011',
    '0100001',
    '0011101',
    '0111001',
    '0000101',
    '0010001',
    '0001001',
    '0010111'
  ];
  static const _right = [
    '1110010',
    '1100110',
    '1101100',
    '1000010',
    '1011100',
    '1001110',
    '1010000',
    '1000100',
    '1001000',
    '1110100'
  ];
  static const _parity = [
    'AAAAAA',
    'AABABB',
    'AABBAB',
    'AABBBA',
    'ABAABB',
    'ABBAAB',
    'ABBBAA',
    'ABABAB',
    'ABABBA',
    'ABBABA'
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final code = value.replaceAll(RegExp(r'\D'), '');
    if (code.length != 13) return;
    final first = int.tryParse(code[0]) ?? 0;
    final p = _parity[first];
    final bits = StringBuffer('101');
    for (var i = 1; i <= 6; i++) {
      final d = int.parse(code[i]);
      bits.write(p[i - 1] == 'A' ? _leftA[d] : _leftB[d]);
    }
    bits.write('01010');
    for (var i = 7; i <= 12; i++) bits.write(_right[int.parse(code[i])]);
    bits.write('101');

    final barPaint = Paint()..style = PaintingStyle.fill;
    final module = size.width / bits.length;
    final barHeight = size.height * 0.78;
    for (var i = 0; i < bits.length; i++) {
      if (bits.toString()[i] == '1') {
        canvas.drawRect(
            Rect.fromLTWH(i * module, 0, module + .35, barHeight), barPaint);
      }
    }
    final tp = TextPainter(
      text: TextSpan(
          text: code, style: const TextStyle(fontSize: 12, letterSpacing: 1.1)),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, barHeight + 4));
  }

  @override
  bool shouldRepaint(covariant _EAN13Painter oldDelegate) =>
      oldDelegate.value != value;
}

// ============================================
// PANTALLA: CÓDIGOS DE BARRAS
// ============================================
class CodigosBarrasScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const CodigosBarrasScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<CodigosBarrasScreen> createState() => _CodigosBarrasScreenState();
}

class _CodigosBarrasScreenState extends State<CodigosBarrasScreen> {
  final _db = DatabaseService();
  final _barcodeService = BarcodeService();
  List<Map<String, dynamic>> _productos = [];
  bool _cargando = true;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      _productos = await _db.getProductos();
    } catch (e) {
      debugPrint('Error cargando productos: $e');
      _productos = [];
    }
    setState(() => _cargando = false);
  }

  Future<void> _generarCodigo(String productoId) async {
    try {
      final nuevoCodigo = await _barcodeService.generarCodigoEAN13();
      await _db.actualizarProducto(productoId, {'codigo_barras': nuevoCodigo});
      await _cargarDatos();
      _mostrarSnackbar('Código generado: $nuevoCodigo', AppColors.success);
    } catch (e) {
      _mostrarSnackbar('Error: $e', AppColors.danger);
    }
  }

  Future<void> _generarCodigosMasivos() async {
    final productosSinCodigo = _productos
        .where((p) =>
            p['codigo_barras'] == null || p['codigo_barras'].toString().isEmpty)
        .toList();

    if (productosSinCodigo.isEmpty) {
      _mostrarSnackbar('Todos los productos tienen código', AppColors.warning);
      return;
    }

    try {
      for (var prod in productosSinCodigo) {
        final nuevoCodigo = await _barcodeService.generarCodigoEAN13();
        await _db.actualizarProducto(prod['id'].toString(), {
          'codigo_barras': nuevoCodigo,
        });
      }
      await _cargarDatos();
      _mostrarSnackbar(
          '${productosSinCodigo.length} códigos generados', AppColors.success);
    } catch (e) {
      _mostrarSnackbar('Error: $e', AppColors.danger);
    }
  }

  void _mostrarSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    final productosFiltrados = _busqueda.isEmpty
        ? _productos
        : _productos
            .where((p) =>
                (p['nombre'] as String)
                    .toLowerCase()
                    .contains(_busqueda.toLowerCase()) ||
                (p['codigo_barras'] as String? ?? '')
                    .toLowerCase()
                    .contains(_busqueda.toLowerCase()))
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('CÓDIGOS DE BARRAS',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.primary, size: 24),
            onPressed: _generarCodigosMasivos,
            tooltip: 'Generar códigos masivos',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  style: TextStyle(color: AppColors.text(isDark)),
                  onChanged: (v) => setState(() => _busqueda = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar producto o código...',
                    hintStyle: TextStyle(color: AppColors.subtext(isDark)),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.subtext(isDark)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.card(isDark),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _cargando
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary))
                    : productosFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_2_rounded,
                                    size: 60, color: AppColors.subtext(isDark)),
                                const SizedBox(height: 16),
                                Text('No hay productos',
                                    style: TextStyle(
                                        color: AppColors.subtext(isDark))),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: productosFiltrados.length,
                            itemBuilder: (_, i) {
                              final prod = productosFiltrados[i];
                              final codigo =
                                  prod['codigo_barras']?.toString() ?? '';
                              final tieneCodigo = codigo.isNotEmpty;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.card(isDark),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(prod['nombre'] ?? '',
                                              style: TextStyle(
                                                  color: AppColors.text(isDark),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 8),
                                          if (tieneCodigo)
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                    color: AppColors.divider(
                                                        isDark)),
                                              ),
                                              child: CustomPaint(
                                                size: const Size(
                                                    double.infinity, 68),
                                                painter: _EAN13Painter(codigo),
                                              ),
                                            )
                                          else
                                            Text('Sin código de barras',
                                                style: TextStyle(
                                                    color: AppColors.danger,
                                                    fontSize: 11)),
                                          if (tieneCodigo) ...[
                                            const SizedBox(height: 5),
                                            Text(codigo,
                                                style: TextStyle(
                                                    color: AppColors.subtext(
                                                        isDark),
                                                    fontSize: 11,
                                                    letterSpacing: 1)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        tieneCodigo
                                            ? Icons.refresh_rounded
                                            : Icons.add_rounded,
                                        color: tieneCodigo
                                            ? AppColors.primary
                                            : AppColors.success,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          _generarCodigo(prod['id'].toString()),
                                      tooltip:
                                          tieneCodigo ? 'Regenerar' : 'Generar',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _generarCodigosMasivos,
                  icon: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 24),
                  label: const Text('GENERAR CÓDIGOS MASIVOS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
// PANTALLA: REPORTES
// ============================================
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
    try {
      _reporte = await _db.getReporteGeneral(_fechaInicio, _fechaFin);
    } catch (e) {
      debugPrint('Error generando reporte: $e');
    }
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
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
                  fontWeight: FontWeight.w800,
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
                      color: Colors.black.withValues(alpha: 0.05),
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
                                color: AppColors.divider(isDark), width: 1),
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
                                color: AppColors.divider(isDark), width: 1),
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
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _generarReporte,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
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
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
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
                          color: Colors.black.withValues(alpha: 0.05),
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
                                gradient: AppColors.gradientPrimary,
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
                                gradient: AppColors.gradientSuccess,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(children: [
                                const Text('Ganancia',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(
                                    '\$${(_reporte!['ganancia_total'] as double).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background(isDark),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.divider(isDark), width: 1),
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background(isDark),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.divider(isDark), width: 1),
                              ),
                              child: Column(children: [
                                Text('Costo Total',
                                    style: TextStyle(
                                        color: AppColors.subtext(isDark),
                                        fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(
                                    '\$${(_reporte!['costo_total'] as double).toStringAsFixed(2)}',
                                    style: TextStyle(
                                        color: AppColors.text(isDark),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Text('Ventas del período',
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
                              final fecha = v['fecha'] != null
                                  ? DateTime.parse(v['fecha'].toString())
                                  : DateTime.now();
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              v['numero_factura'] ??
                                                  'Venta #${v['id']}',
                                              style: TextStyle(
                                                  color: AppColors.text(isDark),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600)),
                                          Text(
                                              DateFormat('dd/MM/yyyy HH:mm')
                                                  .format(fecha),
                                              style: TextStyle(
                                                  color:
                                                      AppColors.subtext(isDark),
                                                  fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\$${(v['total'] as num).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
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

// ============================================
// PANTALLA: IMPRESORA
// ============================================
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
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _copias = prefs.getInt('impresora_copias') ?? 1;
        _tamanoPapel = prefs.getString('impresora_tamano') ?? '80mm';
        _mostrarLogo = prefs.getBool('impresora_logo') ?? true;
        _mostrarQR = prefs.getBool('impresora_qr') ?? false;
      });
    } catch (e) {
      debugPrint('Error cargando configuración impresora: $e');
    }
  }

  Future<void> _guardarConfiguracion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('impresora_copias', _copias);
      await prefs.setString('impresora_tamano', _tamanoPapel);
      await prefs.setBool('impresora_logo', _mostrarLogo);
      await prefs.setBool('impresora_qr', _mostrarQR);
      _mostrarExito('Configuración guardada exitosamente');
    } catch (e) {
      debugPrint('Error guardando configuración impresora: $e');
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
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
                  fontWeight: FontWeight.w800,
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
                      color: Colors.black.withValues(alpha: 0.05),
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
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _impresoraConectada
                          ? null
                          : () => setState(() => _impresoraConectada = true),
                      icon: const Icon(Icons.bluetooth, color: Colors.white),
                      label: const Text('Conectar',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientDanger,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _impresoraConectada
                          ? () => setState(() => _impresoraConectada = false)
                          : null,
                      icon: const Icon(Icons.bluetooth_disabled,
                          color: Colors.white),
                      label: const Text('Desconectar',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              Text('CONFIGURACIÓN',
                  style: TextStyle(
                      color: AppColors.subtext(isDark),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Número de copias',
                          style: TextStyle(
                              color: AppColors.text(isDark), fontSize: 14)),
                      Row(children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.primary, size: 24),
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
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppColors.primary, size: 24),
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
                      Text('Tamaño de papel',
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
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      title: Text('Mostrar logo',
                          style: TextStyle(
                              color: AppColors.text(isDark), fontSize: 14)),
                      value: _mostrarLogo,
                      onChanged: (v) => setState(() => _mostrarLogo = v),
                      activeThumbColor: AppColors.primary,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      title: Text('Mostrar código QR',
                          style: TextStyle(
                              color: AppColors.text(isDark), fontSize: 14)),
                      value: _mostrarQR,
                      onChanged: (v) => setState(() => _mostrarQR = v),
                      activeThumbColor: AppColors.primary,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: _impresoraConectada
                      ? () => _mostrarExito('Imprimiendo...')
                      : null,
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: const Text('Imprimir Ticket de Prueba',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
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
                  label: const Text('Guardar Configuración',
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

// ============================================
// PANTALLA: BACKUP
// ============================================
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
    try {
      final productos = await _db.getProductos();
      final ventas = await _db.getVentasHoy();
      final clientes = await _db.getClientes();
      final data = {
        'productos': productos,
        'ventas': ventas,
        'clientes': clientes,
        'fecha_exportacion': DateTime.now().toIso8601String(),
        'version': '6.2.0',
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      await Share.share(jsonStr,
          subject:
              'Backup SINTHETIX PRO - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}');
      _mostrarExito('Datos exportados correctamente');
    } catch (e) {
      debugPrint('Error exportando datos: $e');
      _mostrarExito('Error al exportar: $e');
    }
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
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
                  fontWeight: FontWeight.w800,
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
                      color: Colors.black.withValues(alpha: 0.05),
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
                          gradient: AppColors.gradientPrimary,
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
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
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

// ============================================
// PANTALLA: CAJA
// ============================================
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
  bool _cargando = true;
  int _tabActual = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      _cajaActual = await _cajaService.getCajaAbierta();
      _historialCajas = await _cajaService.getHistorialCajas();
      _movimientos = await _cajaService.getMovimientosHoy();
    } catch (e) {
      debugPrint('Error cargando datos caja: $e');
    }
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
            prefixStyle: const TextStyle(color: AppColors.primary),
            filled: true,
            fillColor: AppColors.background(isDark),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide.none,
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          ElevatedButton(
            onPressed: () async {
              final monto = double.tryParse(montoCtrl.text) ?? 0;
              if (monto <= 0) return;
              try {
                await _cajaService.abrirCaja(monto);
                Navigator.pop(ctx);
                _cargarDatos();
              } catch (e) {
                debugPrint('Error abriendo caja: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Abrir', style: TextStyle(color: Colors.white)),
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
                '\$${((_cajaActual!['monto_inicial'] ?? 0) as num).toStringAsFixed(2)}',
                isDark),
            _infoRow(
                'Total Ventas:',
                '\$${((_cajaActual!['total_ventas'] ?? 0) as num).toStringAsFixed(2)}',
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
                prefixStyle: const TextStyle(color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background(isDark),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
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
          ElevatedButton(
            onPressed: () async {
              final montoFinal = double.tryParse(montoFinalCtrl.text) ?? 0;
              try {
                await _cajaService.cerrarCaja(montoFinal);
                Navigator.pop(ctx);
                _cargarDatos();
              } catch (e) {
                debugPrint('Error cerrando caja: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
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
                prefixStyle: const TextStyle(color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background(isDark),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              style: TextStyle(color: AppColors.text(isDark)),
              decoration: InputDecoration(
                labelText: 'Descripción',
                labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                filled: true,
                fillColor: AppColors.background(isDark),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
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
          ElevatedButton(
            onPressed: () async {
              final monto = double.tryParse(montoCtrl.text) ?? 0;
              if (monto <= 0) return;
              try {
                await _cajaService.registrarMovimiento(
                    tipo, monto, descCtrl.text);
                Navigator.pop(ctx);
                _cargarDatos();
              } catch (e) {
                debugPrint('Error registrando movimiento: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child:
                const Text('Registrar', style: TextStyle(color: Colors.white)),
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

  Widget _tab(String l, int i, bool isDark, IconData icon) {
    final sel = _tabActual == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabActual = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: sel ? AppColors.gradientPrimary : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: sel ? Colors.white : AppColors.subtext(isDark),
                    size: 16),
                const SizedBox(width: 6),
                Text(
                  l,
                  style: TextStyle(
                    color: sel ? Colors.white : AppColors.subtext(isDark),
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
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
            Text('La caja está cerrada',
                style:
                    TextStyle(color: AppColors.subtext(isDark), fontSize: 16)),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: _abrirCaja,
                icon: const Icon(Icons.lock_open, color: Colors.white),
                label: const Text('Abrir Caja',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildCajaAbierta() {
    final montoInicial =
        ((_cajaActual!['monto_inicial'] ?? 0) as num).toDouble();
    final totalVentas = ((_cajaActual!['total_ventas'] ?? 0) as num).toDouble();
    final totalCaja = montoInicial + totalVentas;
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
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
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.gradientSuccess,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () => _registrarMovimiento('Ingreso'),
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                label: const Text('Ingreso',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.gradientDanger,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () => _registrarMovimiento('Egreso'),
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.white),
                label:
                    const Text('Egreso', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton.icon(
            onPressed: _cerrarCaja,
            icon: const Icon(Icons.lock, color: Colors.white),
            label: const Text('CERRAR CAJA',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
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
                color: Colors.black.withValues(alpha: 0.05),
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
              '\$${((m['monto'] ?? 0) as num).toStringAsFixed(2)}',
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
                color: Colors.black.withValues(alpha: 0.05),
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
                gradient: AppColors.gradientPrimary,
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
                    'Inicial: \$${((c['monto_inicial'] ?? 0) as num).toStringAsFixed(2)} | Final: \$${((c['monto_final'] ?? 0) as num).toStringAsFixed(2)}',
                    style: TextStyle(
                        color: AppColors.subtext(isDark), fontSize: 11),
                  ),
                ],
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
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
                  fontWeight: FontWeight.w800,
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
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(children: [
                  _tab('Caja', 0, isDark, Icons.point_of_sale),
                  _tab('Movimientos', 1, isDark, Icons.receipt_rounded),
                  _tab('Historial', 2, isDark, Icons.history_rounded),
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

// ============================================
// PANTALLA: PERFIL
// ============================================
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
    try {
      _perfil = await _db.getPerfilUsuario();
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
    }
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
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          ElevatedButton(
            onPressed: () async {
              try {
                await _db.actualizarPerfil({'nombre': ctrl.text});
                Navigator.pop(ctx);
                _cargarPerfil();
              } catch (e) {
                debugPrint('Error actualizando nombre: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
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
        title: Text('Cambiar Contraseña',
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
                labelText: 'Nueva Contraseña',
                labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                filled: true,
                fillColor: AppColors.background(isDark),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl2,
              obscureText: true,
              style: TextStyle(color: AppColors.text(isDark)),
              decoration: InputDecoration(
                labelText: 'Confirmar Contraseña',
                labelStyle: TextStyle(color: AppColors.subtext(isDark)),
                filled: true,
                fillColor: AppColors.background(isDark),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.subtext(isDark)))),
          ElevatedButton(
            onPressed: () async {
              if (ctrl1.text != ctrl2.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Las contraseñas no coinciden'),
                      backgroundColor: AppColors.danger),
                );
                return;
              }
              if (ctrl1.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Mínimo 6 caracteres'),
                      backgroundColor: AppColors.danger),
                );
                return;
              }
              try {
                await _db.actualizarPerfil({'password_hash': ctrl1.text});
                Navigator.pop(ctx);
              } catch (e) {
                debugPrint('Error cambiando contraseña: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Cambiar', style: TextStyle(color: Colors.white)),
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
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
                  fontWeight: FontWeight.w800,
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
                            color: Colors.black.withValues(alpha: 0.05),
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
                            gradient: AppColors.gradientPrimary,
                            borderRadius: BorderRadius.circular(40),
                          ),
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
                            color: AppColors.primary.withValues(alpha: 0.08),
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
                          title: Text('Cambiar Contraseña',
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

// ============================================
// PANTALLA: INVENTARIO
// ============================================
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
    try {
      _movimientos = await _db.getMovimientosInventario();
      _productos = await _db.getProductos();
    } catch (e) {
      debugPrint('Error cargando inventario: $e');
      _movimientos = [];
      _productos = [];
    }
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
                      borderRadius: BorderRadius.circular(14),
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
                      borderRadius: BorderRadius.circular(14),
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
                      borderRadius: BorderRadius.circular(14),
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
            ElevatedButton(
              onPressed: () async {
                if (productoSeleccionado == null || cantidadCtrl.text.isEmpty) {
                  return;
                }
                try {
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
                  final stockActual = (producto['stock'] ?? 0) as int;
                  final nuevoStock = tipo == 'Entrada'
                      ? stockActual + cantidad
                      : stockActual - cantidad;
                  await _db.actualizarProducto(
                      productoSeleccionado!, {'stock': nuevoStock});
                  Navigator.pop(ctx);
                  _cargarDatos();
                } catch (e) {
                  debugPrint('Error registrando movimiento: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Registrar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String l, int i, bool isDark, IconData icon) {
    final sel = _tabActual == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabActual = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: sel ? AppColors.gradientPrimary : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: sel ? Colors.white : AppColors.subtext(isDark),
                    size: 16),
                const SizedBox(width: 6),
                Text(l,
                    style: TextStyle(
                        color: sel ? Colors.white : AppColors.subtext(isDark),
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
              ],
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
                color: Colors.black.withValues(alpha: 0.05),
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
        final stock = (prod['stock'] ?? 0) as int;
        final stockMin = (prod['stock_minimo'] ?? 5) as int;
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
                color: Colors.black.withValues(alpha: 0.05),
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
                  Text('Código: ${prod['codigo_barras']}',
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
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
                  fontWeight: FontWeight.w800,
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
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(children: [
                  _tab('Movimientos', 0, isDark, Icons.swap_vert_rounded),
                  _tab('Stock', 1, isDark, Icons.inventory_2_outlined),
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
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientSuccess,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _registrarMovimiento('Entrada'),
                          icon: const Icon(Icons.add_circle_outline,
                              color: Colors.white),
                          label: const Text('Entrada',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientWarning,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _registrarMovimiento('Salida'),
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.white),
                          label: const Text('Salida',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
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
// PANTALLA: TIENDA SINTHETIX
// ============================================
class UniversalFlyCartStore extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  const UniversalFlyCartStore({super.key, required this.onAbrirSidebar});
  @override
  _UniversalFlyCartStoreState createState() => _UniversalFlyCartStoreState();
}

class _UniversalFlyCartStoreState extends State<UniversalFlyCartStore> {
  final _db = DatabaseService();
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
      _productos = await _db.getProductos();
      _categorias = await _db.getCategorias();
    } catch (e) {
      debugPrint('Error cargando tienda: $e');
      _productos = [];
      _categorias = [];
    }
    setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    const isDark = false;
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
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
                  fontWeight: FontWeight.w800,
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: sel ? AppColors.gradientPrimary : null,
                            color: sel ? null : AppColors.card(isDark),
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
                                        imagenBase64:
                                            prod['imagen_base64']?.toString(),
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
// PANTALLA: PROVEEDORES
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
  final _db = DatabaseService();
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
      _proveedores = await _db.getProveedores();
    } catch (e) {
      debugPrint('Error cargando proveedores: $e');
      _proveedores = [];
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
    bool guardando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card(isDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
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
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
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
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
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
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
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
            ElevatedButton.icon(
              onPressed: guardando
                  ? null
                  : () async {
                      if (nombreCtrl.text.isEmpty) return;
                      setDialogState(() => guardando = true);
                      try {
                        final data = {
                          'nombre': nombreCtrl.text,
                          'contacto': contactoCtrl.text,
                          'telefono': telefonoCtrl.text,
                          'email': emailCtrl.text,
                        };
                        if (proveedor != null) {
                          await _db.actualizarProveedor(
                              proveedor['id'].toString(), data);
                        } else {
                          await _db.crearProveedor(data);
                        }
                        Navigator.pop(ctx);
                        _cargarProveedores();
                      } catch (e) {
                        setDialogState(() => guardando = false);
                        debugPrint('Error guardando proveedor: $e');
                      }
                    },
              icon: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                guardando ? 'GUARDANDO...' : 'GUARDAR',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
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
                  fontWeight: FontWeight.w800,
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
                              color: Colors.black.withValues(alpha: 0.05),
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
                              gradient: AppColors.gradientPrimary,
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
                              await _db.eliminarProveedor(
                                  proveedor['id'].toString());
                              _cargarProveedores();
                            },
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogo(),
                  icon: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 24),
                  label: const Text('AGREGAR PROVEEDOR',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
// PANTALLA: PROMOCIONES
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
  final _db = DatabaseService();
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
      _promociones = await _db.getPromociones();
    } catch (e) {
      debugPrint('Error cargando promociones: $e');
      _promociones = [];
    }
    setState(() => _cargando = false);
  }

  void _mostrarDialogo({Map<String, dynamic>? promocion}) {
    final isDark = widget.modoOscuro;
    final nombreCtrl = TextEditingController(text: promocion?['nombre'] ?? '');
    final valorCtrl =
        TextEditingController(text: promocion?['valor']?.toString() ?? '');
    String tipo = promocion?['tipo'] ?? 'porcentaje';
    bool guardando = false;

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
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.divider(isDark), width: 1),
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
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar',
                    style: TextStyle(color: AppColors.subtext(isDark)))),
            ElevatedButton.icon(
              onPressed: guardando
                  ? null
                  : () async {
                      if (nombreCtrl.text.isEmpty) return;
                      setDialogState(() => guardando = true);
                      try {
                        final data = {
                          'nombre': nombreCtrl.text,
                          'tipo': tipo,
                          'valor': double.tryParse(valorCtrl.text) ?? 0,
                          'activo': 1,
                        };
                        if (promocion != null) {
                          await _db.actualizarPromocion(
                              promocion['id'].toString(), data);
                        } else {
                          await _db.crearPromocion(data);
                        }
                        Navigator.pop(ctx);
                        _cargarPromociones();
                      } catch (e) {
                        setDialogState(() => guardando = false);
                        debugPrint('Error guardando promoción: $e');
                      }
                    },
              icon: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                guardando ? 'GUARDANDO...' : 'GUARDAR',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
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
                  fontWeight: FontWeight.w800,
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
                              color: Colors.black.withValues(alpha: 0.05),
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
                              gradient: AppColors.gradientPrimary,
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
                            value:
                                promo['activo'] == 1 || promo['activo'] == true,
                            onChanged: (val) async {
                              await _db.actualizarPromocion(
                                promo['id'].toString(),
                                {'activo': val ? 1 : 0},
                              );
                              _cargarPromociones();
                            },
                            activeThumbColor: AppColors.primary,
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: AppColors.danger.withValues(alpha: 0.7),
                                size: 18),
                            onPressed: () async {
                              await _db
                                  .eliminarPromocion(promo['id'].toString());
                              _cargarPromociones();
                            },
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogo(),
                  icon: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 24),
                  label: const Text('AGREGAR PROMOCIÓN',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
// PANTALLA: COMPRAS
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
  final _db = DatabaseService();
  List<Map<String, dynamic>> _compras = [];
  List<Map<String, dynamic>> _proveedores = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      _compras = await LocalDatabase().getAll('compras', orderBy: 'fecha DESC');
      _proveedores = await _db.getProveedores();
    } catch (e) {
      debugPrint('Error cargando compras: $e');
      _compras = [];
      _proveedores = [];
    }
    setState(() => _cargando = false);
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
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
                  fontWeight: FontWeight.w800,
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
                              color: Colors.black.withValues(alpha: 0.05),
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
                              gradient: AppColors.gradientSuccess,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// PANTALLA: USUARIOS Y ROLES
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
  final _db = DatabaseService();
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
      _usuarios = await _db.getUsuarios();
    } catch (e) {
      debugPrint('Error cargando usuarios: $e');
      _usuarios = [];
    }
    setState(() => _cargando = false);
  }

  void _mostrarDialogo({Map<String, dynamic>? usuario}) {
    final isDark = widget.modoOscuro;
    final nombreCtrl = TextEditingController(text: usuario?['nombre'] ?? '');
    final emailCtrl = TextEditingController(text: usuario?['email'] ?? '');
    final passwordCtrl = TextEditingController();
    String rol = usuario?['rol'] ?? 'vendedor';
    bool guardando = false;

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
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2)),
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
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2)),
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
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.divider(isDark), width: 1),
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
            ElevatedButton.icon(
              onPressed: guardando
                  ? null
                  : () async {
                      if (nombreCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                        return;
                      }
                      if (usuario == null && passwordCtrl.text.isEmpty) return;
                      setDialogState(() => guardando = true);
                      try {
                        final data = {
                          'nombre': nombreCtrl.text,
                          'email': emailCtrl.text,
                          'rol': rol,
                          'activo': 1,
                        };
                        if (passwordCtrl.text.isNotEmpty) {
                          data['password_hash'] = passwordCtrl.text;
                        }
                        if (usuario != null) {
                          await _db.actualizarUsuario(
                              usuario['id'].toString(), data);
                        } else {
                          await _db.crearUsuario(data);
                        }
                        Navigator.pop(ctx);
                        await _cargarUsuarios();
                      } catch (e) {
                        setDialogState(() => guardando = false);
                        debugPrint('Error guardando usuario: $e');
                      }
                    },
              icon: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                guardando ? 'GUARDANDO...' : 'GUARDAR',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
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
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${_usuarios.length}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
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
                                fontSize: 16)),
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
                      final nombre = usuario['nombre'] ?? '';
                      final email = usuario['email'] ?? '';
                      final rol = usuario['rol'] ?? 'vendedor';
                      final rolColor = rol == 'admin'
                          ? AppColors.danger
                          : rol == 'vendedor'
                              ? AppColors.primary
                              : AppColors.warning;
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
                              color: Colors.black.withValues(alpha: 0.05),
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
                            child: Center(
                                child: Text(inicial,
                                    style: TextStyle(
                                        color: rolColor,
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
                                Text(email,
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
                              rol.toUpperCase(),
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
                              await _db
                                  .eliminarUsuario(usuario['id'].toString());
                              await _cargarUsuarios();
                            },
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogo(),
                  icon: const Icon(Icons.person_add_rounded,
                      color: Colors.white, size: 24),
                  label: const Text('AGREGAR USUARIO',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
// PANTALLA: ESTADÍSTICAS
// ============================================
class EstadisticasScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const EstadisticasScreen(
      {super.key, required this.onAbrirSidebar, this.modoOscuro = false});
  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final _db = DatabaseService();
  List<Map<String, dynamic>> _ventasHoy = [];
  List<Map<String, dynamic>> _productosMasVendidos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      _ventasHoy = await _db.getVentasHoy();
      _productosMasVendidos = await _db.getProductosMasVendidos();
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
      _ventasHoy = [];
      _productosMasVendidos = [];
    }
    setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    double totalVentas = 0;
    for (var v in _ventasHoy) {
      totalVentas += (v['total'] as num? ?? 0).toDouble();
    }
    double gananciaTotal = 0;
    for (var v in _ventasHoy) {
      gananciaTotal += (v['ganancia_total'] as num? ?? 0).toDouble();
    }

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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.menu_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text('ESTADÍSTICAS',
              style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
        ]),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _cargarDatos,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPrimary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(children: [
                            const Text('Total Ventas Hoy',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 10)),
                            const SizedBox(height: 4),
                            Text('\$${totalVentas.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientSuccess,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(children: [
                            const Text('Ganancia',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 10)),
                            const SizedBox(height: 4),
                            Text('\$${gananciaTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    if (_productosMasVendidos.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PRODUCTOS MÁS VENDIDOS',
                                style: TextStyle(
                                    color: AppColors.text(isDark),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1)),
                            const SizedBox(height: 12),
                            ..._productosMasVendidos.take(10).map((p) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p['nombre'] ?? '',
                                        style: TextStyle(
                                            color: AppColors.text(isDark),
                                            fontSize: 12),
                                      ),
                                    ),
                                    Text(
                                      '${p['cantidad']} vendidos',
                                      style: TextStyle(
                                          color: AppColors.subtext(isDark),
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (_ventasHoy.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('VENTAS DE HOY',
                                style: TextStyle(
                                    color: AppColors.text(isDark),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1)),
                            const SizedBox(height: 12),
                            ..._ventasHoy.take(10).map((v) {
                              final fecha = v['fecha'] != null
                                  ? DateTime.parse(v['fecha'].toString())
                                  : DateTime.now();
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        v['numero_factura'] ??
                                            'Venta #${v['id']}',
                                        style: TextStyle(
                                            color: AppColors.text(isDark),
                                            fontSize: 12),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(fecha),
                                      style: TextStyle(
                                          color: AppColors.subtext(isDark),
                                          fontSize: 11),
                                    ),
                                    const SizedBox(width: 8),
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
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
