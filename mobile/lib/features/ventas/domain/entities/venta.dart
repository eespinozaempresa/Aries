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
  final double subtotalUsd;
  final double igvUsd;
  final double totalUsd;
  final String moneda;
  final double tipoCambio;
  final TipoVenta tipoVenta;
  final int plazoDias;
  final String? fechaVencimiento;
  final bool anulado;
  final String? createdAt;
  final List<DetalleVenta> detalles;
  final String? razonSocialCliente;
  final String? descripcionAlmacen;

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
    this.subtotalUsd = 0,
    this.igvUsd = 0,
    this.totalUsd = 0,
    this.moneda = 'PEN',
    this.tipoCambio = 1,
    required this.tipoVenta,
    required this.plazoDias,
    this.fechaVencimiento,
    required this.anulado,
    this.createdAt,
    this.detalles = const [],
    this.razonSocialCliente,
    this.descripcionAlmacen,
  });
}
