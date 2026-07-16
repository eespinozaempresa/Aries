import 'detalle_venta.dart';

enum TipoVenta { CONTADO, CREDITO }

class Venta {
  final String id;
  final String codigoEmpresa;
  final String codigoDocumento;
  final String serie;
  final String numeroDocumento;
  final String fecha;
  final String? observacion;
  final String codigoAlmacen;
  final String codigoCliente;
  final String codigoUsuario;
  final double subtotal;
  final double igv;
  final double total;
  final TipoVenta tipoVenta;
  final int plazoDias;
  final String? fechaVencimiento;
  final bool anulado;
  final String? createdAt;
  final List<DetalleVenta> detalles;

  const Venta({
    required this.id,
    required this.codigoEmpresa,
    required this.codigoDocumento,
    this.serie = '0001',
    required this.numeroDocumento,
    required this.fecha,
    this.observacion,
    required this.codigoAlmacen,
    required this.codigoCliente,
    required this.codigoUsuario,
    required this.subtotal,
    required this.igv,
    required this.total,
    required this.tipoVenta,
    required this.plazoDias,
    this.fechaVencimiento,
    required this.anulado,
    this.createdAt,
    this.detalles = const [],
  });
}
