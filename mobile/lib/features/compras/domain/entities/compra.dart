import 'detalle_compra.dart';

enum FormaPago { CONTADO, CREDITO }

class Compra {
  final String id;
  final String codigoEmpresa;
  final String codigoDocumento;
  final String serie;
  final String numeroDocumento;
  final String fecha;
  final FormaPago formaPago;
  final int plazoDias;
  final String? fechaVencimiento;
  final String? observacion;
  final String codigoAlmacen;
  final String codigoProveedor;
  final String codigoUsuario;
  final double subtotal;
  final double igv;
  final double total;
  final double subtotalUsd;
  final double igvUsd;
  final double totalUsd;
  final String moneda;
  final double tipoCambio;
  final bool anulado;
  final String? createdAt;
  final List<DetalleCompra> detalles;

  const Compra({
    required this.id,
    required this.codigoEmpresa,
    required this.codigoDocumento,
    this.serie = '0001',
    required this.numeroDocumento,
    required this.fecha,
    required this.formaPago,
    required this.plazoDias,
    this.fechaVencimiento,
    this.observacion,
    required this.codigoAlmacen,
    required this.codigoProveedor,
    required this.codigoUsuario,
    required this.subtotal,
    required this.igv,
    required this.total,
    required this.subtotalUsd,
    required this.igvUsd,
    required this.totalUsd,
    required this.moneda,
    required this.tipoCambio,
    required this.anulado,
    this.createdAt,
    this.detalles = const [],
  });
}
