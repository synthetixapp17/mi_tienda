// ============================================
// SINTHETIX PRO - V19 POS PROFESIONAL + DRAWER PREMIUM
// Rediseño visual del POS, drawer flotante y checkout profesional
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
import 'package:audioplayers/audioplayers.dart';

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
      isDark ? const Color(0xFF0D1117) : const Color(0xFFF8F7FC);
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
      isDark ? Colors.black : const Color(0xFF6D3DF5).withValues(alpha: 0.05);

  // Paleta profesional
  static const Color primary = Color(0xFF6D3DF5);
  static const Color primaryDark = Color(0xFF5B2AE6);
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
    colors: [Color(0xFF6D3DF5), Color(0xFF1D4ED8)],
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
  static const Color backgroundLight = Color(0xFFF8F7FC);
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
  static final SoundService _instance=SoundService._();
  factory SoundService()=>_instance;
  SoundService._();
  final AudioPlayer _player=AudioPlayer();
  Future<void> playBeep() async {
    try { await _player.stop(); await _player.play(AssetSource('bit.mp3'),volume:.85); }
    catch(e){ debugPrint('Error sonido assets/bit.mp3: $e'); try{await SystemSound.play(SystemSoundType.click);}catch(_){}}
    try{HapticFeedback.selectionClick();}catch(_){}
  }
  Future<void> playSuccess()=>playBeep();
  void dispose(){_player.dispose();}
}

// ============================================
// BASE DE DATOS LOCAL// ============================================
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
      prod['codigo_barras'] = codigo.isEmpty
          ? await BarcodeService().generarCodigoEAN13()
          : codigo;
      prod['nombre'] = prod['nombre']?.toString().trim() ?? '';
      prod['precio'] = (prod['precio'] as num?)?.toDouble() ??
          double.tryParse(prod['precio']?.toString() ?? '') ?? 0.0;
      prod['costo'] = (prod['costo'] as num?)?.toDouble() ??
          double.tryParse(prod['costo']?.toString() ?? '') ?? 0.0;
      prod['stock'] = (prod['stock'] as num?)?.toInt() ??
          int.tryParse(prod['stock']?.toString() ?? '') ?? 0;
      prod['stock_minimo'] = (prod['stock_minimo'] as num?)?.toInt() ??
          int.tryParse(prod['stock_minimo']?.toString() ?? '') ?? 5;
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

class _ScannerRapidoState extends State<ScannerRapido> {
  MobileScannerController? _controller;
  bool _linternaEncendida = false;
  bool _procesando = false;
  String? _ultimoCodigo;
  DateTime? _ultimoEscaneo;
  final Duration _tiempoDebounce = const Duration(milliseconds: 220);

  @override
  void initState() {
    super.initState();
    _inicializarCamara();
  }

  Future<void> _inicializarCamara() async {
    try {
      _controller = MobileScannerController(
        formats: [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.code128,
          BarcodeFormat.qrCode,
          BarcodeFormat.code39,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
        ],
        detectionSpeed: DetectionSpeed.unrestricted,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
    }
  }

  void _toggleLinterna() {
    if (_controller == null) return;
    setState(() => _linternaEncendida = !_linternaEncendida);
    _controller!.toggleTorch();
  }

  void _cambiarCamara() {
    if (_controller == null) return;
    _controller!.switchCamera();
  }

  Future<void> _procesarCodigo(String codigo) async {
    if (_procesando) return;

    if (_ultimoCodigo == codigo && _ultimoEscaneo != null) {
      final diferencia = DateTime.now().difference(_ultimoEscaneo!);
      if (diferencia < _tiempoDebounce) return;
    }

    setState(() {
      _procesando = true;
      _ultimoCodigo = codigo;
      _ultimoEscaneo = DateTime.now();
    });

    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);

    widget.onCodigoDetectado(codigo);

    
    if (mounted) {
      setState(() => _procesando = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _procesando
              ? AppColors.success
              : AppColors.primary.withValues(alpha: 0.3),
          width: _procesando ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            if (_controller != null)
              MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isEmpty) return;
                  final rawValue = barcodes.first.rawValue;
                  if (rawValue != null && rawValue.isNotEmpty) {
                    _procesarCodigo(rawValue);
                  }
                },
              ),
            Center(
              child: Container(
                width: 220,
                height: 110,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _procesando ? AppColors.success : AppColors.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            if (_procesando)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 48),
                ),
              ),
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: [
                  _buildControlCamara(
                    icon: _linternaEncendida
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color:
                        _linternaEncendida ? AppColors.warning : Colors.white,
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
                    icon: Icons.close,
                    color: Colors.white,
                    onTap: widget.onCerrar,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Apunte la cámara al código de barras',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
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

  void _abrirSidebar() {
    final navContext = navigatorKey.currentState?.overlay?.context;
    if (navContext == null) return;
    showGeneralDialog(
      context: navContext,
      barrierDismissible: true,
      barrierLabel: 'Cerrar menú',
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerLeft,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
              child: SidebarMenu(
                modoOscuro: _modoOscuro,
                onToggleModoOscuro: _toggleModoOscuro,
                onNavigate: _navegar,
                currentRoute: _rutaActual(),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(-1.08, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
        return SlideTransition(position: slide, child: child);
      },
    );
  }

  Widget _buildGlobalMenuButton() {
    final dark = _modoOscuro;
    final bg = dark ? const Color(0xFF20262D) : Colors.white;
    final fg = dark ? Colors.white : const Color(0xFF25292E);
    return Material(
      color: bg,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _abrirSidebar,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: .08)
                  : const Color(0xFFE2DED7),
            ),
          ),
          child: Icon(Icons.apps_rounded, color: fg, size: 21),
        ),
      ),
    );
  }

  void _toggleModoOscuro() {
    setState(() => _modoOscuro = !_modoOscuro);
  }

  String _rutaActual() {
    const rutas = [
      'pos','dashboard','configuracion','categorias','metodos_pago','vendedores','clientes','reportes','impresora','configurar_ticket','variantes','codigos_barras','backup','caja','perfil','inventario','tienda','proveedores','promociones','compras','roles','estadisticas'
    ];
    return (_currentIndex >= 0 && _currentIndex < rutas.length) ? rutas[_currentIndex] : '';
  }

  void _navegar(String ruta) {
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
      navigatorKey.currentState?.maybePop();
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
          backgroundColor: AppColors.background(_modoOscuro),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final sidebarVisible = constraints.maxWidth >= 480;
              final expandedSidebar = constraints.maxWidth >= 1000;
              final content = IndexedStack(
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
                  ConfiguracionScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  CategoriasScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  MetodosPagoScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  VendedoresScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  ClientesScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  ReportesScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  ImpresoraScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  ConfigurarTicketScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  ConfiguracionVariantesScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  CodigosBarrasScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  BackupScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  CajaScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  PerfilScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  InventarioScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  UniversalFlyCartStore(onAbrirSidebar: _abrirSidebar),
                  ProveedoresScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  PromocionesScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  ComprasScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  RolesScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                  EstadisticasScreen(onAbrirSidebar: _abrirSidebar, modoOscuro: _modoOscuro),
                ],
              );

return Stack(
                fit: StackFit.expand,
                children: [
                  content,
                  if (_currentIndex != 0)
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 12,
                      right: 14,
                      child: _buildGlobalMenuButton(),
                    ),
                ],
              );
            },
          ),
          bottomNavigationBar: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 480 || _currentIndex > 1) {
                return const SizedBox.shrink();
              }
              return CurvedNavigationBar(
                backgroundColor: Colors.transparent,
                color: _modoOscuro
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFE5E7EB),
                buttonBackgroundColor: _modoOscuro
                    ? const Color(0xFF374151)
                    : const Color(0xFFD1D5DB),
                height: 65,
                animationDuration: const Duration(milliseconds: 280),
                animationCurve: Curves.easeInOut,
                index: _currentIndex,
                items: [
                  CurvedNavigationBarItem(
                    child: Icon(
                      Icons.point_of_sale_outlined,
                      size: 25,
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
                    ),
                  ),
                  CurvedNavigationBarItem(
                    child: Icon(
                      Icons.dashboard_outlined,
                      size: 25,
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
                    ),
                  ),
                ],
                onTap: (index) => setState(() => _currentIndex = index),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================
// MENÚ GLOBAL - PANEL FLOTANTE ELEVADO
// ============================================
class SidebarMenu extends StatefulWidget {
  final bool modoOscuro;
  final VoidCallback onToggleModoOscuro;
  final Function(String) onNavigate;
  final bool embedded;
  final bool compactMode;
  final String currentRoute;

  const SidebarMenu({
    super.key,
    required this.modoOscuro,
    required this.onToggleModoOscuro,
    required this.onNavigate,
    this.embedded = false,
    this.compactMode = false,
    this.currentRoute = '',
  });

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  String _hovered = '';

  @override
  Widget build(BuildContext context) {
    final dark = widget.modoOscuro;
    final width = MediaQuery.sizeOf(context).width < 500 ? 326.0 : 366.0;
    final bg = dark ? const Color(0xFF0E1018) : const Color(0xFFFBFAFE);
    final panel = dark ? const Color(0xFF151827) : Colors.white;
    final text = dark ? Colors.white : const Color(0xFF20212A);
    final muted = dark ? const Color(0xFF9EA3B4) : const Color(0xFF747887);
    final border = dark ? Colors.white.withValues(alpha: .07) : const Color(0xFFE9E7F0);
    const violet = Color(0xFF6D3DF5);
    const violet2 = Color(0xFF8B5CF6);

    return Material(
      color: bg,
      elevation: 28,
      shadowColor: Colors.black.withValues(alpha: .34),
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 16, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: dark
                      ? const [Color(0xFF1B1740), Color(0xFF25145A)]
                      : const [Color(0xFFF1ECFF), Color(0xFFEAE2FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [violet, violet2],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: violet.withValues(alpha: .28),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 25),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SINTHETIX PRO', style: TextStyle(color: text, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -.3)),
                            const SizedBox(height: 2),
                            Text('Punto de Venta Offline', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Material(
                        color: dark ? Colors.white.withValues(alpha: .07) : Colors.white.withValues(alpha: .8),
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(13),
                          child: const SizedBox(width: 42, height: 42, child: Icon(Icons.close_rounded, size: 20)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dark ? Colors.black.withValues(alpha: .16) : Colors.white.withValues(alpha: .76),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: dark ? Colors.white.withValues(alpha: .08) : const Color(0xFFEDE8FA), shape: BoxShape.circle),
                          child: Icon(Icons.person_rounded, color: dark ? Colors.white : violet, size: 21),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Administrador', style: TextStyle(color: text, fontWeight: FontWeight.w800, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text('Sesión activa · Local', style: TextStyle(color: muted, fontSize: 9)),
                            ],
                          ),
                        ),
                        Icon(Icons.verified_rounded, color: violet, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('PRINCIPAL', muted),
                    _menuItem('pos', Icons.point_of_sale_rounded, 'Punto de venta', 'Vender y cobrar', text, muted, border, violet, dark),
                    _menuItem('dashboard', Icons.grid_view_rounded, 'Inicio', 'Resumen del negocio', text, muted, border, violet, dark),
                    const SizedBox(height: 12),
                    _sectionLabel('OPERACIÓN', muted),
                    _menuItem('inventario', Icons.inventory_2_outlined, 'Inventario', 'Productos y existencias', text, muted, border, violet, dark),
                    _menuItem('categorias', Icons.sell_outlined, 'Categorías', 'Organiza tu catálogo', text, muted, border, violet, dark),
                    _menuItem('clientes', Icons.groups_rounded, 'Clientes', 'Agenda y compradores', text, muted, border, violet, dark),
                    _menuItem('proveedores', Icons.local_shipping_outlined, 'Proveedores', 'Compras y abastecimiento', text, muted, border, violet, dark),
                    _menuItem('compras', Icons.shopping_cart_checkout_rounded, 'Compras', 'Entradas de mercancía', text, muted, border, violet, dark),
                    const SizedBox(height: 12),
                    _sectionLabel('CONTROL', muted),
                    _menuItem('caja', Icons.account_balance_wallet_outlined, 'Caja', 'Movimientos y cierre', text, muted, border, violet, dark),
                    _menuItem('reportes', Icons.bar_chart_rounded, 'Reportes', 'Ventas y rendimiento', text, muted, border, violet, dark),
                    _menuItem('estadisticas', Icons.insights_rounded, 'Estadísticas', 'Indicadores del negocio', text, muted, border, violet, dark),
                    const SizedBox(height: 12),
                    _sectionLabel('SISTEMA', muted),
                    _menuItem('configuracion', Icons.settings_outlined, 'Configuración', 'Preferencias del sistema', text, muted, border, violet, dark),
                    _menuItem('perfil', Icons.manage_accounts_outlined, 'Perfil', 'Cuenta y datos', text, muted, border, violet, dark),
                    _menuItem('backup', Icons.cloud_sync_outlined, 'Copias de seguridad', 'Respaldo local', text, muted, border, violet, dark),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withValues(alpha: .045) : const Color(0xFFF7F5FB),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Icon(dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: violet, size: 19),
                          const SizedBox(width: 10),
                          Expanded(child: Text(dark ? 'Modo oscuro' : 'Modo claro', style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w700))),
                          Switch.adaptive(value: dark, onChanged: (_) => widget.onToggleModoOscuro()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: border))),
              child: Row(
                children: [
                  Icon(Icons.offline_bolt_rounded, color: violet, size: 17),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Funcionamiento local · SINTHETIX PRO', style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w600))),
                  Text('7.0', style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 0, 10, 7),
    child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
  );

  Widget _menuItem(String route, IconData icon, String title, String subtitle, Color text, Color muted, Color border, Color accent, bool dark) {
    final selected = widget.currentRoute == route;
    final hover = _hovered == route;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = route),
        onExit: (_) => setState(() => _hovered = ''),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(colors: [Color(0xFF6D3DF5), Color(0xFF8B5CF6)], begin: Alignment.centerLeft, end: Alignment.centerRight)
                : null,
            color: selected ? null : (hover ? (dark ? Colors.white.withValues(alpha: .055) : const Color(0xFFF6F3FB)) : Colors.transparent),
            borderRadius: BorderRadius.circular(15),
            border: selected ? Border.all(color: Colors.white.withValues(alpha: .12)) : Border.all(color: Colors.transparent),
          ),
          child: InkWell(
            onTap: () => widget.onNavigate(route),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: selected ? Colors.white.withValues(alpha: .14) : (dark ? Colors.white.withValues(alpha: .045) : const Color(0xFFF3F1F7)), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: selected ? Colors.white : text, size: 18)),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: selected ? Colors.white : text, fontSize: 12, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(color: selected ? Colors.white.withValues(alpha: .72) : muted, fontSize: 8.5, fontWeight: FontWeight.w500))])),
                  Icon(Icons.chevron_right_rounded, color: selected ? Colors.white.withValues(alpha: .8) : muted.withValues(alpha: .55), size: 17),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
  final ValueNotifier<int> _carritoVersion=ValueNotifier<int>(0);
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
  final Duration _tiempoDebounce = const Duration(milliseconds: 220);

  bool get _isTablet => MediaQuery.of(context).size.width >= 600;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 1024;

  void _vibrar() => HapticFeedback.heavyImpact();
  void _notificarCambioCarrito()=>_carritoVersion.value++;

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
        detectionSpeed: DetectionSpeed.unrestricted,
        facing: CameraFacing.back,
        autoZoom: true,
        detectionTimeoutMs: 80,
        cameraResolution: const Size(1920, 1080),
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
    _notificarCambioCarrito();
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
                _notificarCambioCarrito();
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
              _notificarCambioCarrito();
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
            final codigo = (prod['codigo_barras'] ?? '').toString().toLowerCase();
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
    _carritoVersion.dispose();
    _soundService.dispose();
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
            throw Exception('No se pudo guardar el detalle de la venta ${fac}.');
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
        _notificarCambioCarrito();
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

  Future<void> _procesarCodigoConDebounce(String codigo) async {
    if (_procesandoCodigo) return;

    if (_ultimoCodigoEscaneado == codigo && _ultimoEscaneo != null) {
      final diferencia = DateTime.now().difference(_ultimoEscaneo!);
      if (diferencia < _tiempoDebounce) return;
    }

    setState(() {
      _procesandoCodigo = true;
      _ultimoCodigoEscaneado = codigo;
      _ultimoEscaneo = DateTime.now();
    });

    HapticFeedback.heavyImpact();
    await _procesarCodigo(codigo);
    
    if (mounted) {
      setState(() => _procesandoCodigo = false);
    }
  }

  Future<void> _procesarCodigo(String codigo) async {
    Map<String, dynamic>? prod;
    try {
      prod = listaProductos.firstWhere(
        (p) => p['codigo_barras'] == codigo,
      );
    } catch (e) {
      prod = null;
    }

    prod ??= await _db.buscarPorCodigo(codigo);

    if (prod != null) {
      _agregar(prod);
      _snack('${prod['nombre']} agregado', AppColors.success);
            _sonidoExito();
    } else {
      _snack('Producto no encontrado: $codigo', AppColors.danger);
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.modoOscuro;
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 1024;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0A0D12) : const Color(0xFFF1F4F8),
      appBar: _buildModernAppBar(dark),
      body: SafeArea(
        child: desktop
            ? Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: _buildPosRail(dark),
                  ),
                  Expanded(child: _buildDesktopWorkspace(dark)),
                ],
              )
            : _buildMobileWorkspace(dark),
      ),
    );
  }

  AppBar _buildModernAppBar(bool dark) {
    final bg = dark ? const Color(0xFF0F131A) : Colors.white;
    final ink = dark ? Colors.white : const Color(0xFF17202A);
    final muted = dark ? const Color(0xFF8D98A8) : const Color(0xFF6B7280);

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 18,
      leadingWidth: 68,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12, top: 7, bottom: 7),
        child: Material(
          color: dark ? const Color(0xFF171D26) : const Color(0xFFF0F3F7),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onAbrirSidebar,
            child: const Icon(Icons.menu_rounded, size: 22, color: AppColors.primary),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6D3DF5), Color(0xFF9B7BFF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SINTHETIX PRO',
                style: TextStyle(
                  color: ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
              Text(
                'Terminal de ventas',
                style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _buildTopStatus(Icons.cloud_off_rounded, 'SIN CONEXIÓN', muted, dark),
        const SizedBox(width: 6),
        _buildTopStatus(Icons.inventory_2_outlined, '${listaProductos.length} productos', muted, dark),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildTopStatus(IconData icon, String label, Color muted, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF171D26) : const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: muted),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildPosRail(bool dark) {
    final surface = dark ? const Color(0xFF0F131A) : Colors.white;
    final muted = dark ? const Color(0xFF7D8795) : const Color(0xFF8A93A0);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(right: BorderSide(color: dark ? Colors.white10 : const Color(0xFFE1E6EC))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),
          _railButton(Icons.point_of_sale_rounded, 'Venta', true, dark, () {}),
          _railButton(Icons.receipt_long_outlined, 'Pedidos', false, dark, () {}),
          _railButton(Icons.inventory_2_outlined, 'Stock', false, dark, widget.onNavigateToDashboard),
          const Spacer(),
          Icon(Icons.lock_outline_rounded, color: muted, size: 19),
          const SizedBox(height: 6),
          Text('OFFLINE', style: TextStyle(color: muted, fontSize: 7, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _railButton(
    IconData icon,
    String label,
    bool active,
    bool dark,
    VoidCallback onTap,
  ) {
    final accent = const Color(0xFF6D3DF5);
    final muted = dark ? const Color(0xFF7D8795) : const Color(0xFF8A93A0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Material(
        color: active
            ? accent.withValues(alpha: .12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Column(
              children: [
                Icon(icon, size: 20, color: active ? accent : muted),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? accent : muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopWorkspace(bool dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 7, child: _buildProductWorkspace(dark)),
          const SizedBox(width: 16),
          SizedBox(width: 390, child: _buildOrderWorkspace(dark)),
        ],
      ),
    );
  }

  Widget _buildMobileWorkspace(bool dark) {
    return Column(
      children: [
        _buildMobileSearch(dark),
        if (_camara) _buildCamaraEscaneo(dark),
        Expanded(child: _buildProductWorkspace(dark, mobile: true)),
        _buildMobileCartBarModern(dark),
      ],
    );
  }

  Widget _buildProductWorkspace(bool dark, {bool mobile = false}) {
    final surface = dark ? const Color(0xFF10151C) : Colors.white;
    final border = dark ? Colors.white10 : const Color(0xFFE0E5EB);
    final ink = dark ? Colors.white : const Color(0xFF17202A);
    final muted = dark ? const Color(0xFF8792A2) : const Color(0xFF737D89);

    Widget productsPanel() {
      if (_cargando) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }

      if (listaProductos.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: muted),
              const SizedBox(height: 16),
              Text(
                'No hay productos disponibles',
                style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                'Agrega productos desde Inventario para comenzar.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: widget.onNavigateToDashboard,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Abrir inventario'),
              ),
            ],
          ),
        );
      }

      final baseItems = _mostrarTodos ? listaProductos : busqueda;
      final items = baseItems.where((prod) {
        final categoria = (prod['categoria'] ?? 'General').toString();
        final stock = (prod['stock'] as num?)?.toDouble() ?? 0;
        final precio = (prod['precio'] as num?)?.toDouble() ?? 0;
        return (_filtroCategoriaPOS == 'Todas' || categoria == _filtroCategoriaPOS) &&
            (!_soloDisponiblesPOS || stock > 0) &&
            (_precioMinPOS == null || precio >= _precioMinPOS!) &&
            (_precioMaxPOS == null || precio <= _precioMaxPOS!);
      }).toList();

      if (items.isEmpty) {
        return Center(
          child: Text(
            'No hay resultados para los filtros actuales.',
            style: TextStyle(color: muted, fontWeight: FontWeight.w700),
          ),
        );
      }

      return GridView.builder(
        padding: EdgeInsets.fromLTRB(mobile ? 12 : 16, 6, mobile ? 12 : 16, 18),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: mobile ? 2 : 4,
          crossAxisSpacing: mobile ? 10 : 12,
          mainAxisSpacing: mobile ? 10 : 12,
          childAspectRatio: mobile ? .74 : .80,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildModernProductCard(items[i], dark),
      );
    }

    final cats = <String>{
      'Todas',
      ...listaProductos.map((p) => (p['categoria'] ?? 'General').toString())
    }.toList();

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (!mobile)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Catálogo',
                      style: TextStyle(color: ink, fontSize: 19, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    '${listaProductos.length} artículos',
                    style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, mobile ? 10 : 12, 14, 8),
            child: Row(
              children: [
                Expanded(child: _buildSearchField(dark)),
                const SizedBox(width: 8),
                _squareAction(Icons.tune_rounded, _filtrosActivos, () => _mostrarFiltrosPOS(dark), dark),
                const SizedBox(width: 7),
                _squareAction(
                  Icons.qr_code_scanner_rounded,
                  _camara,
                  () => setState(() => _camara = !_camara),
                  dark,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, i) {
                final c = cats[i];
                final selected = _filtroCategoriaPOS == c;
                return ChoiceChip(
                  label: Text(
                    c,
                    style: TextStyle(
                      color: selected ? Colors.white : muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  selected: selected,
                  selectedColor: const Color(0xFF6D3DF5),
                  backgroundColor: dark ? const Color(0xFF171D26) : const Color(0xFFF4F6F9),
                  side: BorderSide(color: selected ? const Color(0xFF6D3DF5) : border),
                  onSelected: (_) => setState(() => _filtroCategoriaPOS = c),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                );
              },
            ),
          ),
          const SizedBox(height: 5),
          Expanded(child: productsPanel()),
        ],
      ),
    );
  }

  bool get _filtrosActivos =>
      _filtroCategoriaPOS != 'Todas' ||
      _soloDisponiblesPOS ||
      _precioMinPOS != null ||
      _precioMaxPOS != null;

  Widget _buildSearchField(bool dark) {
    final surface = dark ? const Color(0xFF171D26) : const Color(0xFFF5F7F9);
    final muted = dark ? const Color(0xFF7D8795) : const Color(0xFF8A93A0);
    final ink = dark ? Colors.white : const Color(0xFF17202A);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
      ),
      child: TextField(
        controller: _buscador,
        onChanged: _buscar,
        style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search_rounded, color: muted, size: 21),
          suffixIcon: _buscador.text.isEmpty
              ? Icon(Icons.keyboard_rounded, color: muted, size: 18)
              : IconButton(
                  onPressed: _limpiarBusqueda,
                  icon: Icon(Icons.close_rounded, color: muted, size: 18),
                ),
          hintText: 'Buscar producto, código o nombre...',
          hintStyle: TextStyle(color: muted, fontSize: 11),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildMobileSearch(bool dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          Expanded(child: _buildSearchField(dark)),
          const SizedBox(width: 8),
          _squareAction(Icons.qr_code_scanner_rounded, _camara, () => setState(() => _camara = !_camara), dark),
        ],
      ),
    );
  }

  Widget _squareAction(IconData icon, bool active, VoidCallback onTap, bool dark) {
    return Material(
      color: active
          ? const Color(0xFF6D3DF5).withValues(alpha: .13)
          : (dark ? const Color(0xFF171D26) : const Color(0xFFF5F7F9)),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: active ? const Color(0xFF6D3DF5) : (dark ? Colors.white70 : const Color(0xFF697382)),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildModernProductCard(Map<String, dynamic> prod, bool dark) {
    final stock = (prod['stock'] as num?)?.toInt() ?? 0;
    final min = (prod['stock_minimo'] as num?)?.toInt() ?? 5;
    final discount = (prod['descuento'] as num?)?.toDouble() ?? 0;
    final price = (prod['precio'] as num?)?.toDouble() ?? 0;
    final finalPrice = discount > 0 ? price * (1 - discount / 100) : price;
    final category = (prod['categoria'] ?? 'General').toString();
    final surface = dark ? const Color(0xFF151B23) : Colors.white;
    final border = dark ? Colors.white10 : const Color(0xFFE1E6EC);
    final ink = dark ? Colors.white : const Color(0xFF17202A);
    final muted = dark ? const Color(0xFF818C9B) : const Color(0xFF77818E);
    final status = stock <= 0
        ? const Color(0xFFE25C5C)
        : stock <= min
            ? const Color(0xFFD49A3A)
            : const Color(0xFF3CA66B);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: stock <= 0 ? null : () => _agregar(prod),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: dark ? const Color(0xFF1B222C) : const Color(0xFFF5F7F9),
                      child: ImagenProducto(
                        imagenBase64: prod['imagen_base64']?.toString(),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 9,
                      left: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xCC0F131A) : const Color(0xDDFFFFFF),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: dark ? Colors.white : const Color(0xFF4D5662),
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 9,
                      right: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(color: status, borderRadius: BorderRadius.circular(7)),
                        child: Text(
                          stock <= 0 ? 'AGOTADO' : '$stock',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    if (discount > 0)
                      Positioned(
                        left: 9,
                        bottom: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE55353),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            '-${discount.toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    if (stock > 0)
                      Positioned(
                        right: 9,
                        bottom: 9,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6D3DF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prod['nombre']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _precio(finalPrice),
                            style: const TextStyle(
                              color: Color(0xFF6D3DF5),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          prod['unidad_medida']?.toString() ?? 'pieza',
                          style: TextStyle(color: muted, fontSize: 8, fontWeight: FontWeight.w700),
                        ),
                      ],
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

  Widget _buildOrderWorkspace(bool dark) {
    final surface = dark ? const Color(0xFF10151C) : Colors.white;
    final border = dark ? Colors.white10 : const Color(0xFFE0E5EB);
    final ink = dark ? Colors.white : const Color(0xFF17202A);
    final muted = dark ? const Color(0xFF818C9B) : const Color(0xFF737D89);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ValueListenableBuilder<int>(
        valueListenable: _carritoVersion,
        builder: (_, __, ___) {
          final units = carrito.fold<int>(
            0,
            (sum, item) => sum + ((item['cantidad'] as num?)?.toInt() ?? 0),
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Venta actual',
                            style: TextStyle(color: ink, fontSize: 19, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            carrito.isEmpty
                                ? 'Agrega productos al pedido'
                                : '$units unidades · ${carrito.length} líneas',
                            style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (carrito.isNotEmpty)
                      IconButton(
                        tooltip: 'Vaciar venta',
                        onPressed: () {
                          setState(() => carrito.clear());
                          _notificarCambioCarrito();
                        },
                        icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFE25C5C)),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: border),
              Expanded(
                child: carrito.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6D3DF5).withValues(alpha: .09),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF6D3DF5), size: 32),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'La venta está vacía',
                              style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Selecciona productos del catálogo',
                              style: TextStyle(color: muted, fontSize: 10),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: carrito.length,
                        itemBuilder: (_, i) => _buildModernCartItem(carrito[i], i, dark),
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 15, 18, 18),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF151B23) : const Color(0xFFF7F9FB),
                  border: Border(top: BorderSide(color: border)),
                ),
                child: Column(
                  children: [
                    _summaryRow('Subtotal', _precio(total), muted, ink),
                    const SizedBox(height: 7),
                    _summaryRow('Descuentos', _precio(0), muted, ink),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('TOTAL', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                        const Spacer(),
                        Text(
                          _precio(total),
                          style: const TextStyle(color: Color(0xFF6D3DF5), fontSize: 27, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: carrito.isEmpty ? null : _cobrar,
                        icon: const Icon(Icons.payments_rounded, size: 20),
                        label: Text(
                          carrito.isEmpty ? 'AGREGA PRODUCTOS' : 'CONTINUAR AL PAGO',
                          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .2),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6D3DF5),
                          disabledBackgroundColor: dark ? const Color(0xFF252C36) : const Color(0xFFDCE1E7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color muted, Color ink) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value, style: TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildModernCartItem(Map<String, dynamic> item, int index, bool dark) {
    final q = (item['cantidad'] as num?)?.toInt() ?? 1;
    final unit = (item['precio'] as num?)?.toDouble() ?? 0;
    final amount = unit * q;
    final ink = dark ? Colors.white : const Color(0xFF17202A);
    final muted = dark ? const Color(0xFF818C9B) : const Color(0xFF737D89);
    final surface = dark ? const Color(0xFF171D26) : const Color(0xFFF7F9FB);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 58,
              height: 62,
              color: dark ? const Color(0xFF202731) : const Color(0xFFEFF2F5),
              child: ImagenProducto(
                imagenBase64: item['imagen_base64']?.toString(),
                width: 58,
                height: 62,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nombre']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(_precio(unit), style: TextStyle(color: muted, fontSize: 9)),
                const SizedBox(height: 4),
                Text(
                  _precio(amount),
                  style: const TextStyle(color: Color(0xFF6D3DF5), fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF222A35) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: dark ? Colors.white10 : const Color(0xFFE0E5EB)),
            ),
            child: Row(
              children: [
                _cartQtyButton(Icons.remove_rounded, () {
                  setState(() {
                    if (q > 1) {
                      item['cantidad'] = q - 1;
                    } else {
                      carrito.removeAt(index);
                    }
                  });
                  _notificarCambioCarrito();
                }, dark),
                SizedBox(
                  width: 28,
                  child: Center(
                    child: Text('$q', style: TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
                ),
                _cartQtyButton(Icons.add_rounded, () {
                  setState(() => item['cantidad'] = q + 1);
                  _notificarCambioCarrito();
                }, dark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartQtyButton(IconData icon, VoidCallback onTap, bool dark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: 30,
          height: 34,
          child: Icon(icon, size: 16, color: const Color(0xFF6D3DF5)),
        ),
      ),
    );
  }

  Widget _buildMobileCartBarModern(bool dark) {
    if (carrito.isEmpty) return const SizedBox(height: 8);

    final surface = dark ? const Color(0xFF10151C) : Colors.white;
    final muted = dark ? const Color(0xFF818C9B) : const Color(0xFF737D89);

    return ValueListenableBuilder<int>(
      valueListenable: _carritoVersion,
      builder: (_, __, ___) {
        final units = carrito.fold<int>(
          0,
          (sum, item) => sum + ((item['cantidad'] as num?)?.toInt() ?? 0),
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 5, 12, 10),
          child: Material(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            elevation: 4,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => Container(
                    height: MediaQuery.sizeOf(context).height * .88,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: _buildOrderWorkspace(dark),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6D3DF5).withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shopping_cart_rounded, color: Color(0xFF6D3DF5), size: 21),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$units unidades · revisar venta',
                            style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            _precio(total),
                            style: TextStyle(
                              color: dark ? Colors.white : const Color(0xFF17202A),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFF6D3DF5), size: 21),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCamaraEscaneo(bool isDark) {
    return Container(
      height: _isDesktop ? 300 : 250,
      margin: EdgeInsets.fromLTRB(_isDesktop ? 18 : 12, 8, _isDesktop ? 18 : 12, 8),
      child: ScannerRapido(
        isDark: isDark,
        onCodigoDetectado: _procesarCodigoConDebounce,
        onCerrar: () => setState(() => _camara = false),
      ),
    );
  }

  void _mostrarFiltrosPOS(bool isDark) {
    double min = _precioMinPOS ?? 0;
    double max = _precioMaxPOS ?? 100000;
    bool soloDisponibles = _soloDisponiblesPOS;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, ds) {
            final rango = RangeValues(
              min.clamp(0, 100000).toDouble(),
              max.clamp(0, 100000).toDouble(),
            );

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF151B23) : Colors.white,
              title: Text(
                'Filtros',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF17202A),
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Rango de precio',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF818C9B) : const Color(0xFF737D89),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    RangeSlider(
                      values: rango,
                      min: 0,
                      max: 100000,
                      divisions: 100,
                      labels: RangeLabels(_precio(min), _precio(max)),
                      onChanged: (v) => ds(() {
                        min = v.start;
                        max = v.end;
                      }),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Solo productos disponibles',
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF17202A)),
                        ),
                        value: soloDisponibles,
                        onChanged: (v) => ds(() => soloDisponibles = v),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _precioMinPOS = min <= 0 ? null : min;
                      _precioMaxPOS = max >= 100000 ? null : max;
                      _soloDisponiblesPOS = soloDisponibles;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
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
  const PantallaCobro({super.key, required this.carrito, required this.total, required this.formatearPrecio, required this.onVentaCompletada, required this.modoOscuro});
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
  bool _clienteEncontrado = false;

  bool get _isTablet => MediaQuery.of(context).size.width >= 600;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 1000;
  static const violet = Color(0xFF6D3DF5);
  static const violet2 = Color(0xFF8B5CF6);

  @override
  void initState() { super.initState(); _cargarDatos(); }
  @override
  void dispose() { _montoCtrl.dispose(); _nombreCtrl.dispose(); _telefonoCtrl.dispose(); _cedulaCtrl.dispose(); _direccionCtrl.dispose(); super.dispose(); }

  Future<void> _cargarDatos() async {
    try {
      final metodos = await _db.getMetodosPago();
      if (metodos.isNotEmpty) { _metodosPago = metodos; _metodo = (metodos.first['nombre'] ?? 'Efectivo').toString(); }
    } catch (e) { debugPrint('Error cargando métodos de pago: $e'); }
    if (mounted) setState(() => _cargandoMetodos = false);
  }

  Future<void> _buscarClientePorCedula() async {
    final cedula = _cedulaCtrl.text.trim();
    if (cedula.isEmpty) { _mostrarSnackbar('Escribe la identificación del cliente', Colors.orange); return; }
    setState(() => _buscandoCliente = true);
    try {
      final cliente = await _db.buscarClientePorCedula(cedula);
      if (cliente != null) {
        setState(() { _clienteEncontrado = true; _nombreCtrl.text = cliente['nombre']?.toString() ?? ''; _telefonoCtrl.text = cliente['telefono']?.toString() ?? ''; _direccionCtrl.text = cliente['direccion']?.toString() ?? ''; });
        _mostrarSnackbar('Cliente encontrado', Colors.green);
      } else {
        setState(() => _clienteEncontrado = false);
        _mostrarSnackbar('Cliente nuevo: se registrará al confirmar', violet);
      }
    } catch (e) { _mostrarSnackbar('No se pudo buscar el cliente', Colors.red); }
    if (mounted) setState(() => _buscandoCliente = false);
  }

  double _totalEnMoneda() => widget.total * (tasasCambio[_moneda] ?? 1.0);
  double _vuelto() => (double.tryParse(_montoCtrl.text) ?? 0) - _totalEnMoneda();

  Future<void> _confirmarVenta() async {
    if (_metodo.toLowerCase() == 'efectivo' && _vuelto() < 0) { _mostrarSnackbar('El efectivo recibido es insuficiente', Colors.red); return; }
    if (_cedulaCtrl.text.trim().isNotEmpty) {
      try {
        final existente = await _db.buscarClientePorCedula(_cedulaCtrl.text.trim());
        if (existente == null && _nombreCtrl.text.trim().isNotEmpty) {
          await _db.crearCliente({'nombre': _nombreCtrl.text.trim(), 'telefono': _telefonoCtrl.text.trim(), 'identificacion': _cedulaCtrl.text.trim(), 'direccion': _direccionCtrl.text.trim(), 'tipo': 'Regular'});
        }
      } catch (e) { debugPrint('Error registrando cliente: $e'); }
    }
    widget.onVentaCompletada(_metodo, _montoCtrl.text, _nombreCtrl.text.trim(), _telefonoCtrl.text.trim(), _cedulaCtrl.text.trim());
  }

  void _mostrarSnackbar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))));
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.modoOscuro;
    final bg = dark ? const Color(0xFF0E1018) : const Color(0xFFF7F6FA);
    final card = dark ? const Color(0xFF171A27) : Colors.white;
    final soft = dark ? const Color(0xFF202438) : const Color(0xFFF4F1FA);
    final text = dark ? Colors.white : const Color(0xFF20212A);
    final muted = dark ? const Color(0xFF9CA3B8) : const Color(0xFF747887);
    final border = dark ? Colors.white.withValues(alpha: .07) : const Color(0xFFE7E4EF);
    final h = (MediaQuery.sizeOf(context).height * (_isDesktop ? .90 : .96)).clamp(520.0, MediaQuery.sizeOf(context).height);

    return Container(
      height: h,
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 46, height: 4, decoration: BoxDecoration(color: dark ? Colors.white24 : const Color(0xFFD5D1DC), borderRadius: BorderRadius.circular(8))),
        Padding(padding: const EdgeInsets.fromLTRB(22, 14, 14, 14), child: Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(gradient: const LinearGradient(colors: [violet, violet2]), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.credit_score_rounded, color: Colors.white, size: 23)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Finalizar venta', style: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4)), const SizedBox(height: 3), Text('${widget.carrito.length} productos · ${widget.formatearPrecio(widget.total)}', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w600))])),
          Material(color: dark ? Colors.white.withValues(alpha: .06) : const Color(0xFFF0EEF5), borderRadius: BorderRadius.circular(13), child: InkWell(onTap: () => Navigator.of(context).pop(), borderRadius: BorderRadius.circular(13), child: const SizedBox(width: 44, height: 44, child: Icon(Icons.close_rounded, size: 20)))),
        ])),
        Divider(height: 1, color: border),
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 980;
          final form = SingleChildScrollView(padding: EdgeInsets.fromLTRB(desktop ? 24 : 18, 18, desktop ? 12 : 18, 22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionHeader('Cliente', 'Identifica al comprador o usa Público general', Icons.person_outline_rounded, text, muted),
            const SizedBox(height: 10),
            _buildClienteCard(dark, card, soft, text, muted, border),
            const SizedBox(height: 18),
            _sectionHeader('Pago', 'Elige cómo se registra esta venta', Icons.payments_outlined, text, muted),
            const SizedBox(height: 10),
            _buildCurrencyAndPayment(dark, card, soft, text, muted, border),
            const SizedBox(height: 18),
            if (_metodo.toLowerCase() == 'efectivo') _buildCashCard(dark, card, soft, text, muted, border),
          ]));
          final summary = _buildSummaryCard(dark, card, soft, text, muted, border);
          if (!desktop) return form;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 7, child: form), Expanded(flex: 4, child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12, 18, 24, 22), child: summary))]);
        })),
        Container(padding: const EdgeInsets.fromLTRB(18, 12, 18, 16), decoration: BoxDecoration(color: card, border: Border(top: BorderSide(color: border))), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('TOTAL A COBRAR', style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.1)), const SizedBox(height: 3), Text('${simbolosMoneda[_moneda] ?? '\$'} ${_totalEnMoneda().toStringAsFixed(2)}', style: TextStyle(color: text, fontSize: 22, fontWeight: FontWeight.w900))])),
          SizedBox(height: 54, child: DecoratedBox(decoration: BoxDecoration(gradient: const LinearGradient(colors: [violet, violet2]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: violet.withValues(alpha: .25), blurRadius: 16, offset: const Offset(0, 7))]), child: ElevatedButton.icon(onPressed: _confirmarVenta, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), icon: const Icon(Icons.check_rounded, color: Colors.white, size: 19), label: const Text('Confirmar venta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))))),
        ])),
      ]),
    );
  }

  Widget _sectionHeader(String title, String subtitle, IconData icon, Color text, Color muted) => Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: violet.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: violet, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(color: muted, fontSize: 9.5, fontWeight: FontWeight.w500))]))]);

  Widget _buildClienteCard(bool dark, Color card, Color soft, Color text, Color muted, Color border) {
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), border: Border.all(color: border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .12 : .035), blurRadius: 18, offset: const Offset(0, 8))]), child: Column(children: [
      Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(gradient: const LinearGradient(colors: [violet, violet2]), borderRadius: BorderRadius.circular(14)), child: Icon(_clienteEncontrado ? Icons.person_rounded : Icons.groups_rounded, color: Colors.white, size: 22)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_clienteEncontrado ? 'Cliente identificado' : 'Público general', style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(_clienteEncontrado ? _nombreCtrl.text : 'Venta sin datos de cliente', style: TextStyle(color: muted, fontSize: 9.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)])), TextButton(onPressed: () { setState(() { _clienteEncontrado = false; _cedulaCtrl.clear(); _nombreCtrl.clear(); _telefonoCtrl.clear(); _direccionCtrl.clear(); }); }, child: Text('Limpiar', style: TextStyle(color: violet, fontWeight: FontWeight.w800, fontSize: 10)))]),
      const SizedBox(height: 13),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _field(_cedulaCtrl, 'Identificación', Icons.badge_outlined, dark, text, muted, border, onSubmitted: (_) => _buscarClientePorCedula())), const SizedBox(width: 8), SizedBox(width: 50, height: 50, child: Material(color: violet, borderRadius: BorderRadius.circular(14), child: InkWell(onTap: _buscandoCliente ? null : _buscarClientePorCedula, borderRadius: BorderRadius.circular(14), child: Center(child: _buscandoCliente ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.search_rounded, color: Colors.white, size: 21))))) ]),
      const SizedBox(height: 9),
      _field(_nombreCtrl, 'Nombre completo', Icons.person_outline_rounded, dark, text, muted, border),
      const SizedBox(height: 9),
      Row(children: [Expanded(child: _field(_telefonoCtrl, 'Teléfono', Icons.phone_outlined, dark, text, muted, border, keyboardType: TextInputType.phone)), const SizedBox(width: 9), Expanded(child: _field(_direccionCtrl, 'Dirección', Icons.location_on_outlined, dark, text, muted, border))]),
    ]));
  }

  Widget _field(TextEditingController controller, String label, IconData icon, bool dark, Color text, Color muted, Color border, {TextInputType? keyboardType, Function(String)? onSubmitted}) => TextField(controller: controller, onSubmitted: onSubmitted, keyboardType: keyboardType, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w600), decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: muted, fontSize: 11), prefixIcon: Icon(icon, color: violet, size: 18), filled: true, fillColor: dark ? const Color(0xFF202438) : const Color(0xFFF8F7FB), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: violet, width: 1.5))));

  Widget _buildCurrencyAndPayment(bool dark, Color card, Color soft, Color text, Color muted, Color border) {
    final methods = _metodosPago.isEmpty
        ? ['Efectivo', 'Tarjeta', 'Transferencia']
        : _metodosPago
            .map((e) => (e['nombre'] ?? '').toString())
            .where((e) => e.isNotEmpty)
            .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Moneda', style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 7),
          Row(
            children: ['USD', 'COP', 'VES'].map((m) {
              final sel = _moneda == m;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _moneda = m),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: sel ? violet : soft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sel ? violet : border),
                      ),
                      child: Center(
                        child: Text(
                          m,
                          style: TextStyle(color: sel ? Colors.white : text, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 15),
          Text('Forma de pago', style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: methods.map((m) {
              final sel = _metodo == m;
              return InkWell(
                onTap: () => setState(() => _metodo = m),
                borderRadius: BorderRadius.circular(13),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: _isDesktop ? 150 : 138,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? violet.withValues(alpha: .10) : soft,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: sel ? violet : border, width: sel ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Icon(_getIconoMetodo(m), color: sel ? violet : muted, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: sel ? violet : text, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCashCard(bool dark, Color card, Color soft, Color text, Color muted, Color border) {
    final vuelto = _vuelto();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Efectivo recibido', style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 7),
          TextField(
            controller: _montoCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: text, fontSize: 24, fontWeight: FontWeight.w900),
            decoration: InputDecoration(
              prefixText: '${simbolosMoneda[_moneda] ?? '\$'} ',
              prefixStyle: const TextStyle(color: violet, fontWeight: FontWeight.w900, fontSize: 20),
              hintText: '0.00',
              hintStyle: TextStyle(color: muted),
              filled: true,
              fillColor: soft,
              prefixIcon: const Icon(Icons.payments_outlined, color: violet),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: violet, width: 1.5)),
            ),
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: vuelto >= 0 ? Colors.green.withValues(alpha: .08) : Colors.red.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(vuelto >= 0 ? Icons.check_circle_outline : Icons.warning_amber_rounded, color: vuelto >= 0 ? Colors.green : Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Vuelto', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700))),
                Text('${simbolosMoneda[_moneda] ?? '\$'} ${vuelto.toStringAsFixed(2)}', style: TextStyle(color: vuelto >= 0 ? Colors.green : Colors.red, fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool dark, Color card, Color soft, Color text, Color muted, Color border) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(22), border: Border.all(color: border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .12 : .04), blurRadius: 22, offset: const Offset(0, 10))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: violet.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.receipt_long_rounded, color: violet, size: 19)), const SizedBox(width: 10), Expanded(child: Text('Resumen del pedido', style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w900)))]), const SizedBox(height: 14),
      ...widget.carrito.map((item) { final q=(item['cantidad'] as num?)?.toInt()??1; final p=(item['precio'] as num?)?.toDouble()??0; return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(10)), clipBehavior: Clip.antiAlias, child: ImagenProducto(imagenBase64: item['imagen_base64']?.toString(), width: 36, height: 36, fit: BoxFit.cover)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['nombre']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text('$q × ${widget.formatearPrecio(p)}', style: TextStyle(color: muted, fontSize: 9))])), Text(widget.formatearPrecio(p*q), style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.w900))])); }),
      Divider(color: border), const SizedBox(height: 8), Row(children: [Text('Total', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w800)), const Spacer(), Text('${simbolosMoneda[_moneda] ?? '\$'} ${_totalEnMoneda().toStringAsFixed(2)}', style: TextStyle(color: text, fontSize: 23, fontWeight: FontWeight.w900))]), const SizedBox(height: 8), Container(width: double.infinity, padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: violet.withValues(alpha: .07), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.lock_outline_rounded, color: violet, size: 16), const SizedBox(width: 7), Expanded(child: Text('Venta local y segura', style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w700)))])),
    ]));
  }

  IconData _getIconoMetodo(String nombre) {
    switch (nombre.toLowerCase()) { case 'efectivo': return Icons.payments_outlined; case 'tarjeta': return Icons.credit_card_outlined; case 'transferencia': return Icons.swap_horiz_rounded; case 'pago movil': return Icons.phone_android_rounded; default: return Icons.payment_rounded; }
  }
}

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
    final total = ventasHoy.fold<double>(0, (sum, v) =>
        sum + ((v['total'] as num?)?.toDouble() ?? 0));
    _ticketPromedio = cantidad == 0 ? 0 : total / cantidad;

    final utilidad = ventasHoy.fold<double>(0, (sum, v) =>
        sum + ((v['ganancia_total'] as num?)?.toDouble() ?? 0));
    _margenPorcentaje = total <= 0 ? 0 : (utilidad / total) * 100;

    final metodos = <String, double>{};
    for (final v in ventasHoy) {
      final metodo = (v['metodo_pago']?.toString().trim().isNotEmpty ?? false)
          ? v['metodo_pago'].toString()
          : 'Otros';
      metodos[metodo] = (metodos[metodo] ?? 0) +
          ((v['total'] as num?)?.toDouble() ?? 0);
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
        padding: EdgeInsets.fromLTRB(tablet ? 26 : 14, 10, tablet ? 26 : 14, 34),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: .10),
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
                                    Text('ONLINE · LOCAL', style: TextStyle(
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
                                Text('VENTAS HOY', style: TextStyle(
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
                                Text('$cantidadVentasHoy operaciones', style: TextStyle(
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
                          _quickAction('Nueva venta', Icons.point_of_sale_rounded, AppColors.primary, widget.onNavigateToPOS),
                          _quickAction('Inventario', Icons.inventory_2_rounded, AppColors.info, widget.onAbrirSidebar),
                          _quickAction('Clientes', Icons.groups_rounded, AppColors.secondary, widget.onAbrirSidebar),
                          _quickAction('Caja', Icons.account_balance_wallet_rounded, AppColors.success, widget.onAbrirSidebar),
                        ];
                        if (!twoColumns) {
                          return Column(children: items.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(width: double.infinity, child: e))).toList());
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
                    _executiveMetric('Ventas', '\$${totalVentasHoy.toStringAsFixed(2)}', '$cantidadVentasHoy transacciones', Icons.trending_up_rounded, AppColors.primary, isDark),
                    _executiveMetric('Ganancia', '\$${gananciaTotalVentas.toStringAsFixed(2)}', 'Margen ${_margenPorcentaje.toStringAsFixed(1)}%', Icons.savings_rounded, AppColors.success, isDark),
                    _executiveMetric('Este mes', '\$${totalVentasMes.toStringAsFixed(2)}', 'Acumulado mensual', Icons.calendar_today_rounded, AppColors.secondary, isDark),
                    _executiveMetric('Ticket medio', '\$${_ticketPromedio.toStringAsFixed(2)}', 'Por operación', Icons.receipt_long_rounded, AppColors.info, isDark),
                  ];
                  return Wrap(spacing: gap, runSpacing: gap, children: cards.map((x) => SizedBox(width: w, child: x)).toList());
                }),
                const SizedBox(height: 14),

                // Zona analítica principal.
                if (desktop)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 7, child: _panel(isDark, title: 'Rendimiento de ventas', subtitle: 'Ingresos distribuidos durante el día', icon: Icons.multiline_chart_rounded, child: SizedBox(height: 290, child: _graficoVentasHora(isDark, ventasHora, maxHora)))),
                    const SizedBox(width: 12),
                    Expanded(flex: 4, child: _inventarioPanel(isDark)),
                  ])
                else ...[
                  _panel(isDark, title: 'Rendimiento de ventas', subtitle: 'Ingresos distribuidos durante el día', icon: Icons.multiline_chart_rounded, child: SizedBox(height: 255, child: _graficoVentasHora(isDark, ventasHora, maxHora))),
                  const SizedBox(height: 12),
                  _inventarioPanel(isDark),
                ],
                const SizedBox(height: 14),

                // Segunda fila: ventas + pagos.
                if (desktop)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _topProductosPanel(isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _metodosPagoPanel(isDark, metodosOrdenados)),
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
                      _statusItem('Productos', '${productos.length}', Icons.inventory_2_outlined, AppColors.primary, isDark),
                      _statusItem('Unidades', '$_totalStock', Icons.layers_outlined, AppColors.info, isDark),
                      _statusItem('Stock bajo', '$_productosStockBajo', Icons.warning_amber_rounded, AppColors.warning, isDark),
                      _statusItem('Agotados', '$_productosAgotados', Icons.remove_shopping_cart_outlined, AppColors.danger, isDark),
                      _statusItem('Costo', '\$${_valorInventarioCosto.toStringAsFixed(2)}', Icons.price_check_outlined, AppColors.secondary, isDark),
                      _statusItem('Valor venta', '\$${_valorInventarioVenta.toStringAsFixed(2)}', Icons.sell_outlined, AppColors.success, isDark),
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

  Widget _quickAction(String label, IconData icon, Color accent, VoidCallback onTap) {
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
            Container(width: 38, height: 38, decoration: BoxDecoration(color: accent.withValues(alpha: .11), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 19, color: accent)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent))),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: accent.withValues(alpha: .65)),
          ]),
        ),
      ),
    );
  }

  Widget _executiveMetric(String title, String value, String subtitle, IconData icon, Color accent, bool isDark) {
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
          decoration: BoxDecoration(color: accent.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.toUpperCase(), style: TextStyle(color: AppColors.subtext(isDark), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const Spacer(),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.text(isDark), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -.7)),
          const SizedBox(height: 3),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.subtext(isDark), fontSize: 10)),
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

  Widget _panel(bool isDark, {
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

  Widget _graficoVentasHora(bool isDark, Map<int, double> ventasHora, double maxHora) {
    final spots = List.generate(24, (hora) =>
        FlSpot(hora.toDouble(), ventasHora[hora] ?? 0));

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
                style: TextStyle(
                    color: AppColors.subtext(isDark), fontSize: 9),
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
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
    final disponibles = productos.where((p) => ((p['stock'] as num?)?.toInt() ?? 0) > 0).length;
    final categoriasActivas = _categorias.length;
    final unidades = _totalStock;
    final maxStock = productos.isEmpty ? 1 : productos.map((p) => ((p['stock'] as num?)?.toInt() ?? 0)).fold<int>(0, (a, b) => a > b ? a : b);

    return _panel(
      isDark,
      title: 'Catálogo e inventario',
      subtitle: 'Cantidad y estado de tus productos',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _dashboardCount('Productos', '$totalProductos', Icons.inventory_2_rounded, AppColors.primary, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _dashboardCount('Disponibles', '$disponibles', Icons.check_circle_rounded, AppColors.success, isDark)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _dashboardCount('Categorías', '$categoriasActivas', Icons.category_rounded, AppColors.info, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _dashboardCount('Unidades', '$unidades', Icons.all_inbox_rounded, AppColors.secondary, isDark)),
          ]),
          const SizedBox(height: 14),
          _inventoryProgress('Nivel de unidades disponibles', unidades, maxStock, AppColors.info, isDark),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _miniStatus('Stock bajo', '$_productosStockBajo', AppColors.warning, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _miniStatus('Agotados', '$_productosAgotados', AppColors.danger, isDark)),
          ]),
        ],
      ),
    );
  }

  Widget _dashboardCount(String label, String value, IconData icon, Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: .14)),
      ),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: accent.withValues(alpha: .11), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: accent, size: 18)),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: AppColors.text(isDark), fontSize: 17, fontWeight: FontWeight.w900)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.subtext(isDark), fontSize: 9, fontWeight: FontWeight.w600)),
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
          Expanded(child: Text(label, style: TextStyle(color: AppColors.subtext(isDark), fontSize: 11))),
          Text('\$${value.toStringAsFixed(2)}', style: TextStyle(color: AppColors.text(isDark), fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _inventoryProgress(String label, int value, int max, Color color, bool isDark) {
    final progress = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(label, style: TextStyle(color: AppColors.subtext(isDark), fontSize: 11))),
          Text('$value', style: TextStyle(color: AppColors.text(isDark), fontSize: 12, fontWeight: FontWeight.w800)),
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
        Expanded(child: Text(label, style: TextStyle(color: AppColors.subtext(isDark), fontSize: 10))),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
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
              children: productosMasVendidos.take(7).toList().asMap().entries.map((entry) {
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
                      child: Text('${index + 1}', style: TextStyle(color: index < 3 ? AppColors.primary : AppColors.subtext(isDark), fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p['nombre']?.toString() ?? 'Producto', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.text(isDark), fontSize: 12, fontWeight: FontWeight.w600))),
                    Text('$cantidad', style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 4),
                    Text('vendidos', style: TextStyle(color: AppColors.subtext(isDark), fontSize: 9)),
                  ]),
                );
              }).toList(),
            ),
    );
  }

  Widget _metodosPagoPanel(bool isDark, List<MapEntry<String, double>> metodos) {
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
                            sections: metodos.take(5).toList().asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final porcentaje = total <= 0 ? 0.0 : item.value / total * 100;
                              final colores = [AppColors.primary, AppColors.success, AppColors.secondary, AppColors.warning, AppColors.info];
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
                          children: metodos.take(5).toList().asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final porcentaje = total <= 0 ? 0.0 : item.value / total * 100;
                            final colores = [AppColors.primary, AppColors.success, AppColors.secondary, AppColors.warning, AppColors.info];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(children: [
                                Container(width: 7, height: 7, decoration: BoxDecoration(color: colores[index % colores.length], shape: BoxShape.circle)),
                                const SizedBox(width: 7),
                                Expanded(child: Text(item.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.subtext(isDark), fontSize: 10))),
                                Text('${porcentaje.toStringAsFixed(0)}%', style: TextStyle(color: AppColors.text(isDark), fontSize: 10, fontWeight: FontWeight.w800)),
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
                  Expanded(child: Text('Total procesado', style: TextStyle(color: AppColors.subtext(isDark), fontSize: 10))),
                  Text('\$${total.toStringAsFixed(2)}', style: TextStyle(color: AppColors.text(isDark), fontSize: 14, fontWeight: FontWeight.w800)),
                ]),
              ],
            ),
    );
  }

  Widget _statusItem(String label, String value, IconData icon, Color color, bool isDark) {
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
          Text(label, style: TextStyle(color: AppColors.subtext(isDark), fontSize: 9)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: AppColors.text(isDark), fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }

  Widget _emptyDashboard(String message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Center(
        child: Text(message, style: TextStyle(color: AppColors.subtext(isDark), fontSize: 11)),
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
                      onCodigoDetectado: (codigo) async {
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
const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DASHBOARD', style: TextStyle(color: AppColors.text(isDark), fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                Text('${productos.length} productos · ${cantidadVentasHoy} ventas hoy', style: TextStyle(color: AppColors.subtext(isDark), fontSize: 10)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: AppColors.primary, size: 21),
            onPressed: widget.onToggleModoOscuro,
          ),
          PopupMenuButton<String>(
            tooltip: 'Acciones',
            icon: Icon(Icons.more_horiz_rounded, color: AppColors.subtext(isDark)),
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
              PopupMenuItem(value: 'refresh', child: Row(children: [Icon(Icons.refresh_rounded, color: AppColors.primary, size: 18), const SizedBox(width: 10), const Text('Actualizar') ])),
              PopupMenuItem(value: 'caja', child: Row(children: [Icon(ca ? Icons.lock_open_rounded : Icons.lock_rounded, color: ca ? AppColors.success : AppColors.warning, size: 18), const SizedBox(width: 10), Text(ca ? 'Cerrar caja' : 'Abrir caja') ])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'pos', child: Row(children: [Icon(Icons.point_of_sale_rounded, color: AppColors.primary, size: 18), SizedBox(width: 10), Text('Ir al POS') ])),
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
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
    '0001101','0011001','0010011','0111101','0100011','0110001','0101111','0111011','0110111','0001011'
  ];
  static const _leftB = [
    '0100111','0110011','0011011','0100001','0011101','0111001','0000101','0010001','0001001','0010111'
  ];
  static const _right = [
    '1110010','1100110','1101100','1000010','1011100','1001110','1010000','1000100','1001000','1110100'
  ];
  static const _parity = ['AAAAAA','AABABB','AABBAB','AABBBA','ABAABB','ABBAAB','ABBBAA','ABABAB','ABABBA','ABBABA'];

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
        canvas.drawRect(Rect.fromLTWH(i * module, 0, module + .35, barHeight), barPaint);
      }
    }
    final tp = TextPainter(
      text: TextSpan(text: code, style: const TextStyle(fontSize: 12, letterSpacing: 1.1)),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, barHeight + 4));
  }

  @override
  bool shouldRepaint(covariant _EAN13Painter oldDelegate) => oldDelegate.value != value;
}

// ============================================
// PANTALLA: CÓDIGOS DE BARRAS
// ============================================
class CodigosBarrasScreen extends StatefulWidget {
  final VoidCallback onAbrirSidebar;
  final bool modoOscuro;
  const CodigosBarrasScreen({
    super.key,
    required this.onAbrirSidebar,
    this.modoOscuro = false,
  });

  @override
  State<CodigosBarrasScreen> createState() => _CodigosBarrasScreenState();
}

class _CodigosBarrasScreenState extends State<CodigosBarrasScreen> {
  final _db = DatabaseService();
  final _barcodeService = BarcodeService();

  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _productosFiltrados = [];
  bool _cargando = true;
  bool _imprimiendo = false;
  String _busqueda = '';
  String _filtro = 'Todos';
  int _cantidadEtiquetas = 1;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (mounted) setState(() => _cargando = true);
    try {
      _productos = await _db.getProductos();
      _aplicarFiltros();
    } catch (e) {
      debugPrint('Error cargando productos: $e');
      _productos = [];
      _productosFiltrados = [];
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _aplicarFiltros() {
    final q = _busqueda.trim().toLowerCase();
    _productosFiltrados = _productos.where((p) {
      final nombre = (p['nombre'] ?? '').toString().toLowerCase();
      final codigo = (p['codigo_barras'] ?? '').toString().toLowerCase();
      final tieneCodigo = codigo.trim().isNotEmpty;
      final coincide = q.isEmpty || nombre.contains(q) || codigo.contains(q);
      final estado = _filtro == 'Todos' ||
          (_filtro == 'Con código' && tieneCodigo) ||
          (_filtro == 'Sin código' && !tieneCodigo);
      return coincide && estado;
    }).toList();
  }

  Future<void> _generarCodigo(String productoId) async {
    try {
      final nuevoCodigo = await _barcodeService.generarCodigoEAN13();
      await _db.actualizarProducto(productoId, {'codigo_barras': nuevoCodigo});
      await _cargarDatos();
      _mostrarSnackbar('Código generado correctamente', AppColors.success);
    } catch (e) {
      _mostrarSnackbar('No se pudo generar el código: $e', AppColors.danger);
    }
  }

  Future<void> _generarCodigosMasivos() async {
    final faltantes = _productos.where((p) {
      final c = (p['codigo_barras'] ?? '').toString().trim();
      return c.isEmpty;
    }).toList();

    if (faltantes.isEmpty) {
      _mostrarSnackbar('Todos los productos ya tienen código', AppColors.warning);
      return;
    }

    try {
      for (final prod in faltantes) {
        final nuevoCodigo = await _barcodeService.generarCodigoEAN13();
        await _db.actualizarProducto(prod['id'].toString(), {
          'codigo_barras': nuevoCodigo,
        });
      }
      await _cargarDatos();
      _mostrarSnackbar(
        '${faltantes.length} códigos generados',
        AppColors.success,
      );
    } catch (e) {
      _mostrarSnackbar('Error generando códigos: $e', AppColors.danger);
    }
  }

  List<Map<String, dynamic>> _conCodigo(List<Map<String, dynamic>> source) {
    return source.where((p) {
      return (p['codigo_barras'] ?? '').toString().trim().isNotEmpty;
    }).toList();
  }

  Future<Uint8List> _crearPdfEtiquetas(
    List<Map<String, dynamic>> productos,
    int copias,
  ) async {
    final doc = pw.Document();
    final items = <Map<String, dynamic>>[];

    for (final p in productos) {
      for (var i = 0; i < copias; i++) {
        items.add(p);
      }
    }

    for (final p in items) {
      final nombre = (p['nombre'] ?? 'Producto').toString();
      final codigo = (p['codigo_barras'] ?? '').toString().trim();
      final precio = (p['precio_venta'] ?? p['precio'] ?? 0).toString();

      doc.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(
            80 * PdfPageFormat.mm,
            45 * PdfPageFormat.mm,
            marginAll: 4 * PdfPageFormat.mm,
          ),
          build: (context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    nombre,
                    maxLines: 2,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: codigo,
                    width: 68 * PdfPageFormat.mm,
                    height: 20 * PdfPageFormat.mm,
                    drawText: true,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '\$$precio',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return doc.save();
  }

  Future<void> _imprimirProductos(
    List<Map<String, dynamic>> productos, {
    int copias = 1,
  }) async {
    final validos = _conCodigo(productos);
    if (validos.isEmpty) {
      _mostrarSnackbar(
        'No hay productos con código de barras para imprimir',
        AppColors.warning,
      );
      return;
    }

    if (_imprimiendo) return;
    setState(() => _imprimiendo = true);

    try {
      final bytes = await _crearPdfEtiquetas(validos, copias);
      await Printing.layoutPdf(
        name: 'Etiquetas SINTHETIX PRO',
        onLayout: (_) async => bytes,
      );
      _mostrarSnackbar(
        '${validos.length * copias} etiquetas enviadas a impresión',
        AppColors.success,
      );
    } catch (e) {
      _mostrarSnackbar('Error de impresión: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _imprimiendo = false);
    }
  }

  void _imprimirUno(Map<String, dynamic> producto) {
    _imprimirProductos([producto], copias: _cantidadEtiquetas);
  }

  Future<void> _seleccionarCantidad() async {
    int cantidad = _cantidadEtiquetas;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Cantidad de etiquetas'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  if (cantidad > 1) setDialogState(() => cantidad--);
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$cantidad',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                onPressed: () {
                  if (cantidad < 100) setDialogState(() => cantidad++);
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, cantidad),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => _cantidadEtiquetas = result);
    }
  }

  void _mostrarSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    final conCodigo = _conCodigo(_productosFiltrados);
    final sinCodigo = _productosFiltrados.length - conCodigo.length;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            
            Expanded(
              child: Text(
                'Etiquetas y códigos',
                style: TextStyle(
                  color: AppColors.text(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_offer_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Impresión de etiquetas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_productos.length} productos · $conCodigo con código · $sinCodigo pendientes',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _accion(
                        isDark,
                        Icons.auto_awesome_rounded,
                        'Generar faltantes',
                        _generarCodigosMasivos,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _accion(
                        isDark,
                        Icons.print_rounded,
                        _imprimiendo ? 'Imprimiendo...' : 'Imprimir todos',
                        () => _imprimirProductos(_productosFiltrados),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider(isDark)),
                  ),
                  child: TextField(
                    onChanged: (v) {
                      setState(() {
                        _busqueda = v;
                        _aplicarFiltros();
                      });
                    },
                    style: TextStyle(color: AppColors.text(isDark)),
                    decoration: InputDecoration(
                      hintText: 'Buscar producto o código...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: AppColors.background(isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: ['Todos', 'Con código', 'Sin código']
                      .map(
                        (f) => ChoiceChip(
                          label: Text(f),
                          selected: _filtro == f,
                          onSelected: (_) {
                            setState(() {
                              _filtro = f;
                              _aplicarFiltros();
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider(isDark)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sticky_note_2_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Etiquetas por producto',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _seleccionarCantidad,
                        icon: const Icon(Icons.copy_rounded, size: 17),
                        label: Text('$_cantidadEtiquetas'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (_cargando)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_productosFiltrados.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No hay productos para mostrar',
                        style: TextStyle(color: AppColors.subtext(isDark)),
                      ),
                    ),
                  )
                else
                  ..._productosFiltrados.map(
                    (prod) => _productoTile(prod, isDark),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _accion(
    bool isDark,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
    );
  }

  Widget _productoTile(Map<String, dynamic> prod, bool isDark) {
    final codigo = (prod['codigo_barras'] ?? '').toString().trim();
    final tieneCodigo = codigo.isNotEmpty;
    final nombre = (prod['nombre'] ?? 'Producto').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider(isDark)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tieneCodigo
                  ? AppColors.success.withValues(alpha: .10)
                  : AppColors.warning.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              tieneCodigo
                  ? Icons.qr_code_2_rounded
                  : Icons.qr_code_scanner_rounded,
              color: tieneCodigo ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                    color: AppColors.text(isDark),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tieneCodigo ? codigo : 'Sin código de barras',
                  style: TextStyle(
                    color: tieneCodigo
                        ? AppColors.subtext(isDark)
                        : AppColors.warning,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!tieneCodigo)
            IconButton(
              tooltip: 'Generar código',
              onPressed: () => _generarCodigo(prod['id'].toString()),
              icon: const Icon(Icons.add_circle_outline),
            ),
          if (tieneCodigo)
            IconButton(
              tooltip: 'Imprimir etiqueta',
              onPressed: () => _imprimirUno(prod),
              icon: const Icon(Icons.print_outlined),
            ),
        ],
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
  const ImpresoraScreen({
    super.key,
    required this.onAbrirSidebar,
    this.modoOscuro = false,
  });

  @override
  State<ImpresoraScreen> createState() => _ImpresoraScreenState();
}

class _ImpresoraScreenState extends State<ImpresoraScreen> {
  List<Printer> _impresoras = [];
  Printer? _seleccionada;
  PrintingInfo? _info;
  bool _cargando = true;
  bool _imprimiendo = false;

  int _copias = 1;
  String _tamanoPapel = '80mm';
  bool _mostrarLogo = true;
  bool _mostrarQR = false;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
    _cargarImpresoras();
  }

  Future<void> _cargarConfiguracion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
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

  Future<void> _cargarImpresoras() async {
    if (mounted) setState(() => _cargando = true);
    try {
      final info = await Printing.info();
      List<Printer> lista = [];
      if (info.canListPrinters) {
        lista = await Printing.listPrinters();
      }

      Printer? seleccionada;
      if (lista.isNotEmpty) {
        seleccionada = lista.firstWhere(
          (p) => p.isDefault == true && p.isAvailable != false,
          orElse: () => lista.first,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('impresora_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        for (final p in lista) {
          if (p.url == savedUrl) {
            seleccionada = p;
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _info = info;
        _impresoras = lista;
        _seleccionada = seleccionada;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('Error listando impresoras: $e');
      if (mounted) {
        setState(() => _cargando = false);
        _mostrarMensaje('No se pudieron consultar las impresoras: $e', false);
      }
    }
  }

  Future<void> _seleccionarImpresora(Printer printer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('impresora_url', printer.url);
      await prefs.setString('impresora_nombre', printer.name);
    } catch (_) {}

    if (mounted) {
      setState(() => _seleccionada = printer);
      _mostrarMensaje('Impresora seleccionada: ${printer.name}', true);
    }
  }

  Future<void> _abrirSelectorNativo() async {
    try {
      final printer = await Printing.pickPrinter(
        context: context,
        title: 'Seleccionar impresora',
      );
      if (printer != null) {
        await _seleccionarImpresora(printer);
        await _cargarImpresoras();
      }
    } catch (e) {
      _mostrarMensaje('El sistema no pudo abrir el selector: $e', false);
    }
  }

  Future<Uint8List> _pdfPrueba(PdfPageFormat format) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (_) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'SINTHETIX PRO',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('PRUEBA DE IMPRESIÓN'),
              pw.SizedBox(height: 12),
              pw.Text(DateTime.now().toString()),
              pw.SizedBox(height: 12),
              pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: 'SINTHETIX-TEST',
                width: 55 * PdfPageFormat.mm,
                height: 18 * PdfPageFormat.mm,
              ),
            ],
          ),
        ),
      ),
    );
    return doc.save();
  }

  Future<void> _probarImpresion() async {
    if (_imprimiendo) return;
    setState(() => _imprimiendo = true);

    try {
      final format = _tamanoPapel == '58mm'
          ? PdfPageFormat(58 * PdfPageFormat.mm, 120 * PdfPageFormat.mm)
          : PdfPageFormat(80 * PdfPageFormat.mm, 120 * PdfPageFormat.mm);

      final bytes = await _pdfPrueba(format);

      if (_seleccionada != null && (_info?.directPrint ?? false)) {
        await Printing.directPrintPdf(
          printer: _seleccionada!,
          name: 'Prueba SINTHETIX PRO',
          onLayout: (_) async => bytes,
          format: format,
          usePrinterSettings: true,
        );
      } else {
        await Printing.layoutPdf(
          name: 'Prueba SINTHETIX PRO',
          onLayout: (_) async => bytes,
          format: format,
          usePrinterSettings: true,
        );
      }

      _mostrarMensaje('Trabajo de prueba enviado', true);
    } catch (e) {
      _mostrarMensaje('Error al imprimir: $e', false);
    } finally {
      if (mounted) setState(() => _imprimiendo = false);
    }
  }

  Future<void> _guardarConfiguracion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('impresora_copias', _copias);
      await prefs.setString('impresora_tamano', _tamanoPapel);
      await prefs.setBool('impresora_logo', _mostrarLogo);
      await prefs.setBool('impresora_qr', _mostrarQR);
      _mostrarMensaje('Configuración guardada', true);
    } catch (e) {
      _mostrarMensaje('No se pudo guardar: $e', false);
    }
  }

  void _mostrarMensaje(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.modoOscuro;
    final card = AppColors.card(isDark);
    final text = AppColors.text(isDark);
    final sub = AppColors.subtext(isDark);

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            
            Expanded(
              child: Text(
                'Impresoras',
                style: TextStyle(
                  color: text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Actualizar impresoras',
              onPressed: _cargarImpresoras,
              icon: Icon(Icons.refresh_rounded, color: sub),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;

            final statusCard = _statusCard(card, text, sub);
            final selectedCard = _selectedCard(card, text, sub);
            final availableCard = _availableCard(card, text, sub);
            final optionsCard = _optionsCard(card, text, sub);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.print_rounded,
                          color: Colors.white,
                          size: 31,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Centro de impresión',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Administra impresoras y prueba tus tickets',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                statusCard,
                const SizedBox(height: 12),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: selectedCard),
                      const SizedBox(width: 12),
                      Expanded(child: availableCard),
                    ],
                  )
                else ...[
                  selectedCard,
                  const SizedBox(height: 12),
                  availableCard,
                ],
                const SizedBox(height: 12),
                optionsCard,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statusCard(Color card, Color text, Color sub) {
    final canList = _info?.canListPrinters ?? false;
    final direct = _info?.directPrint ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider(widget.modoOscuro)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.print_outlined,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _seleccionada == null
                      ? 'Sin impresora seleccionada'
                      : _seleccionada!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  canList
                      ? 'Lista de impresoras disponible'
                      : 'El sistema usa el selector de impresión',
                  style: TextStyle(color: sub, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: (direct ? AppColors.success : AppColors.primary)
                  .withValues(alpha: .10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              direct ? 'DIRECTA' : 'SISTEMA',
              style: TextStyle(
                color: direct ? AppColors.success : AppColors.primary,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedCard(Color card, Color text, Color sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider(widget.modoOscuro)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impresora seleccionada',
            style: TextStyle(
              color: text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.background(widget.modoOscuro),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.print_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _seleccionada?.name ?? 'Ninguna seleccionada',
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _abrirSelectorNativo,
                  icon: const Icon(Icons.manage_search_rounded, size: 18),
                  label: const Text('Elegir impresora'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _imprimiendo ? null : _probarImpresion,
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: Text(
                    _imprimiendo ? 'Imprimiendo...' : 'Probar',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _availableCard(Color card, Color text, Color sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider(widget.modoOscuro)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Impresoras disponibles',
                  style: TextStyle(
                    color: text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${_impresoras.length}',
                style: TextStyle(color: sub, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_impresoras.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background(widget.modoOscuro),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: sub),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No hay impresoras enumerables en esta plataforma. Usa "Elegir impresora" para abrir el selector del sistema.',
                      style: TextStyle(color: sub, fontSize: 11),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._impresoras.map(
              (printer) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _seleccionarImpresora(printer),
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _seleccionada?.url == printer.url
                            ? AppColors.primary.withValues(alpha: .08)
                            : AppColors.background(widget.modoOscuro),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: _seleccionada?.url == printer.url
                              ? AppColors.primary
                              : AppColors.divider(widget.modoOscuro),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.print_outlined,
                            color: AppColors.primary,
                            size: 21,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  printer.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: text,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  [
                                    if ((printer.model ?? '').isNotEmpty)
                                      printer.model!,
                                    if ((printer.location ?? '').isNotEmpty)
                                      printer.location!,
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: sub,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _seleccionada?.url == printer.url
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: _seleccionada?.url == printer.url
                                ? AppColors.success
                                : sub,
                            size: 21,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _optionsCard(Color card, Color text, Color sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider(widget.modoOscuro)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opciones de impresión',
            style: TextStyle(
              color: text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  value: _tamanoPapel,
                  decoration: const InputDecoration(
                    labelText: 'Papel',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: '58mm',
                      child: Text('58 mm térmico'),
                    ),
                    DropdownMenuItem(
                      value: '80mm',
                      child: Text('80 mm térmico'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _tamanoPapel = v);
                  },
                ),
              ),
              SizedBox(
                width: 190,
                child: Row(
                  children: [
                    Text('Copias', style: TextStyle(color: sub)),
                    IconButton(
                      onPressed: _copias > 1
                          ? () => setState(() => _copias--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_copias',
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      onPressed: _copias < 10
                          ? () => setState(() => _copias++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Mostrar logo en tickets',
              style: TextStyle(color: text),
            ),
            value: _mostrarLogo,
            onChanged: (v) => setState(() => _mostrarLogo = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Mostrar código QR',
              style: TextStyle(color: text),
            ),
            value: _mostrarQR,
            onChanged: (v) => setState(() => _mostrarQR = v),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _guardarConfiguracion,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Guardar configuración'),
            ),
          ),
        ],
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
