part of '../main.dart';

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


