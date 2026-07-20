import '../../domain/entities/movimiento.dart';
import '../../domain/entities/detalle_movimiento.dart';
import '../../domain/entities/kardex_item.dart';
import '../../domain/entities/stock_item.dart';

class MovimientoModel {
  static Movimiento fromJson(Map<String, dynamic> j) => Movimiento(
        id: j['id'] as String,
        codigoEmpresa: j['codigoEmpresa'] as String,
        codigoDocumento: j['codigoDocumento'] as String,
        abreviaturaDocumento: j['abreviaturaDocumento'] as String?,
        serie: j['serie'] as String? ?? '0001',
        numeroDocumento: j['numeroDocumento'] as String,
        fecha: j['fecha'] as String,
        tipo: TipoMovimiento.values.byName(j['tipo'] as String),
        codigoAlmacenOrigen: j['codigoAlmacenOrigen'] as String,
        codigoAlmacenDest: j['codigoAlmacenDest'] as String?,
        descripcionAlmacenOrigen: j['descripcionAlmacenOrigen'] as String?,
        descripcionAlmacenDest: j['descripcionAlmacenDest'] as String?,
        observacion: j['observacion'] as String?,
        concepto: j['concepto'] as String?,
        codigoUsuario: j['codigoUsuario'] as String,
        total: (j['total'] as num).toDouble(),
        anulado: j['anulado'] as bool,
        createdAt: j['createdAt'] as String?,
        detalles: (j['detalles'] as List<dynamic>? ?? [])
            .map((d) => DetalleModel.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}

class DetalleModel {
  static DetalleMovimiento fromJson(Map<String, dynamic> j) => DetalleMovimiento(
        id: j['id'] as String,
        movimientoId: j['movimientoId'] as String,
        codigoEmpresa: j['codigoEmpresa'] as String,
        codigoArticulo: j['codigoArticulo'] as String,
        descripcionArticulo: j['descripcionArticulo'] as String?,
        cantidad: (j['cantidad'] as num).toDouble(),
        precioUnitario: (j['precioUnitario'] as num).toDouble(),
        importe: (j['importe'] as num).toDouble(),
      );
}

class KardexModel {
  static KardexItem fromJson(Map<String, dynamic> j) => KardexItem(
        id: j['id'] as int,
        codigoEmpresa: j['codigoEmpresa'] as String,
        codigoAlmacen: j['codigoAlmacen'] as String,
        codigoArticulo: j['codigoArticulo'] as String,
        descripcionAlmacen: j['descripcionAlmacen'] as String?,
        descripcionArticulo: j['descripcionArticulo'] as String?,
        fecha: j['fecha'] as String,
        codigoDocumento: j['codigoDocumento'] as String,
        abreviaturaDocumento: j['abreviaturaDocumento'] as String?,
        serie: j['serie'] as String? ?? '0001',
        numeroDocumento: j['numeroDocumento'] as String,
        tipo: j['tipo'] as String,
        cantEntrada: (j['cantEntrada'] as num).toDouble(),
        precioEntrada: (j['precioEntrada'] as num).toDouble(),
        importeEntrada: (j['importeEntrada'] as num).toDouble(),
        cantSalida: (j['cantSalida'] as num).toDouble(),
        precioSalida: (j['precioSalida'] as num).toDouble(),
        importeSalida: (j['importeSalida'] as num).toDouble(),
        stock: (j['stock'] as num).toDouble(),
        precioStock: (j['precioStock'] as num).toDouble(),
        importeStock: (j['importeStock'] as num).toDouble(),
      );
}

class StockModel {
  static StockItem fromJson(Map<String, dynamic> j) => StockItem(
        id: j['id'] as String,
        codigoEmpresa: j['codigoEmpresa'] as String,
        codigoAlmacen: j['codigoAlmacen'] as String,
        codigoArticulo: j['codigoArticulo'] as String,
        descripcionAlmacen: j['descripcionAlmacen'] as String?,
        descripcionArticulo: j['descripcionArticulo'] as String?,
        stockInicial: (j['stockInicial'] as num).toDouble(),
        stockCompras: (j['stockCompras'] as num).toDouble(),
        stockVentas: (j['stockVentas'] as num).toDouble(),
        stockEntradas: (j['stockEntradas'] as num).toDouble(),
        stockSalidas: (j['stockSalidas'] as num).toDouble(),
        stockTrasladosIn: (j['stockTrasladosIn'] as num).toDouble(),
        stockTrasladosOut: (j['stockTrasladosOut'] as num).toDouble(),
        costoPromedio: (j['costoPromedio'] as num).toDouble(),
        importeTotal: (j['importeTotal'] as num).toDouble(),
        fechaActualizacion: j['fechaActualizacion'] as String?,
        stockActual: (j['stockActual'] as num).toDouble(),
      );
}
