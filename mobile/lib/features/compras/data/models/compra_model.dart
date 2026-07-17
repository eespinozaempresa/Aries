import '../../domain/entities/compra.dart';
import '../../domain/entities/detalle_compra.dart';

class CompraModel {
  static Compra fromJson(Map<String, dynamic> j) => Compra(
    id: j['id'] as String,
    codigoEmpresa: j['codigoEmpresa'] as String,
    codigoDocumento: j['codigoDocumento'] as String,
    serie: j['serie'] as String? ?? '0001',
    numeroDocumento: j['numeroDocumento'] as String,
    fecha: j['fecha'] as String,
    formaPago: FormaPago.values.byName(j['formaPago'] as String),
    plazoDias: (j['plazoDias'] as num?)?.toInt() ?? 0,
    fechaVencimiento: j['fechaVencimiento'] as String?,
    observacion: j['observacion'] as String?,
    codigoAlmacen: j['codigoAlmacen'] as String,
    codigoProveedor: j['codigoProveedor'] as String,
    codigoUsuario: j['codigoUsuario'] as String,
    subtotal: (j['subtotal'] as num).toDouble(),
    igv: (j['igv'] as num).toDouble(),
    total: (j['total'] as num).toDouble(),
    subtotalUsd: (j['subtotalUsd'] as num?)?.toDouble() ?? 0,
    igvUsd: (j['igvUsd'] as num?)?.toDouble() ?? 0,
    totalUsd: (j['totalUsd'] as num?)?.toDouble() ?? 0,
    moneda: j['moneda'] as String? ?? 'PEN',
    tipoCambio: (j['tipoCambio'] as num?)?.toDouble() ?? 1,
    anulado: j['anulado'] as bool,
    createdAt: j['createdAt'] as String?,
    detalles: (j['detalles'] as List<dynamic>? ?? [])
        .map((d) => DetalleCompraModel.fromJson(d as Map<String, dynamic>))
        .toList(),
  );
}

class DetalleCompraModel {
  static DetalleCompra fromJson(Map<String, dynamic> j) => DetalleCompra(
    id: j['id'] as String,
    compraId: j['compraId'] as String,
    codigoEmpresa: j['codigoEmpresa'] as String,
    codigoArticulo: j['codigoArticulo'] as String,
    descripcionArticulo: j['descripcionArticulo'] as String?,
    cantidad: (j['cantidad'] as num).toDouble(),
    precioUnitario: (j['precioUnitario'] as num).toDouble(),
    importe: (j['importe'] as num).toDouble(),
    fechaVencimiento: j['fechaVencimiento'] as String?,
    precioUnitarioUsd: (j['precioUnitarioUsd'] as num?)?.toDouble() ?? 0,
    importeUsd: (j['importeUsd'] as num?)?.toDouble() ?? 0,
  );
}
