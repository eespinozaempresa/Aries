import 'detalle_movimiento.dart';

enum TipoMovimiento { INGRESO, SALIDA, TRASLADO }

class Movimiento {
  final String id;
  final String codigoEmpresa;
  final String codigoDocumento;
  final String? abreviaturaDocumento;
  final String serie;
  final String numeroDocumento;
  final String fecha;
  final TipoMovimiento tipo;
  final String codigoAlmacenOrigen;
  final String? codigoAlmacenDest;
  final String? descripcionAlmacenOrigen;
  final String? descripcionAlmacenDest;
  final String? observacion;
  final String? concepto;
  final String codigoUsuario;
  final double total;
  final bool anulado;
  final String? createdAt;
  final List<DetalleMovimiento> detalles;

  const Movimiento({
    required this.id,
    required this.codigoEmpresa,
    required this.codigoDocumento,
    this.abreviaturaDocumento,
    this.serie = '0001',
    required this.numeroDocumento,
    required this.fecha,
    required this.tipo,
    required this.codigoAlmacenOrigen,
    this.codigoAlmacenDest,
    this.descripcionAlmacenOrigen,
    this.descripcionAlmacenDest,
    this.observacion,
    this.concepto,
    required this.codigoUsuario,
    required this.total,
    required this.anulado,
    this.createdAt,
    this.detalles = const [],
  });

  double get stockActual => 0;
}
