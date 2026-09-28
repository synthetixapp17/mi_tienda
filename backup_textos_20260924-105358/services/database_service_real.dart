part of '../main.dart';

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

