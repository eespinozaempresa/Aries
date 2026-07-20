import '../../domain/entities/venta.dart';
import '../../domain/entities/detalle_venta.dart';

class VentaModel {
  static Venta fromJson(Map<String, dynamic> j) => Venta(
    id: j['id'] as String,
    codigoEmpresa: j['codigoEmpresa'] as String,
    codigoDocumento: j['codigoDocumento'] as String,
    abreviaturaDocumento: j['abreviaturaDocumento'] as String?,
    serie: j['serie'] as String? ?? '0001',
    numeroDocumento: j['numeroDocumento'] as String,
    fecha: j['fecha'] as String,
    observacion: j['observacion'] as String?,
    codigoAlmacen: j['codigoAlmacen'] as String,
    codigoCliente: j['codigoCliente'] as String,
    codigoUsuario: j['codigoUsuario'] as String,
    subtotal: (j['subtotal'] as num).toDouble(),
    igv: (j['igv'] as num).toDouble(),
    total: (j['total'] as num).toDouble(),
    subtotalUsd: (j['subtotalUsd'] as num?)?.toDouble() ?? 0,
    igvUsd: (j['igvUsd'] as num?)?.toDouble() ?? 0,
    totalUsd: (j['totalUsd'] as num?)?.toDouble() ?? 0,
    moneda: j['moneda'] as String? ?? 'PEN',
    tipoCambio: (j['tipoCambio'] as num?)?.toDouble() ?? 1,
    tipoVenta: TipoVenta.values.byName(j['tipoVenta'] as String),
    plazoDias: (j['plazoDias'] as num?)?.toInt() ?? 0,
    fechaVencimiento: j['fechaVencimiento'] as String?,
    anulado: j['anulado'] as bool,
    createdAt: j['createdAt'] as String?,
    detalles: (j['detalles'] as List<dynamic>? ?? [])
        .map((d) => DetalleVentaModel.fromJson(d as Map<String, dynamic>))
        .toList(),
    razonSocialCliente: j['razonSocialCliente'] as String?,
    descripcionAlmacen: j['descripcionAlmacen'] as String?,
  );
}

class DetalleVentaModel {
  static DetalleVenta fromJson(Map<String, dynamic> j) => DetalleVenta(
    id: j['id'] as String,
    ventaId: j['ventaId'] as String,
    codigoEmpresa: j['codigoEmpresa'] as String,
    codigoArticulo: j['codigoArticulo'] as String,
    descripcionArticulo: j['descripcionArticulo'] as String?,
    cantidad: (j['cantidad'] as num).toDouble(),
    precioUnitario: (j['precioUnitario'] as num).toDouble(),
    descuentoPct: (j['descuentoPct'] as num?)?.toDouble() ?? 0,
    importe: (j['importe'] as num).toDouble(),
    precioUnitarioUsd: (j['precioUnitarioUsd'] as num?)?.toDouble() ?? 0,
    importeUsd: (j['importeUsd'] as num?)?.toDouble() ?? 0,
  );
}
