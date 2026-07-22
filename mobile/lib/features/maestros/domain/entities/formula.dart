import 'detalle_formula.dart';

class Formula {
  final String id;
  final String codigoEmpresa;
  final String codigoArticulo;
  final String? descripcionArticulo;
  final String? observacion;
  final bool activo;
  final List<DetalleFormula> detalle;

  const Formula({
    required this.id,
    required this.codigoEmpresa,
    required this.codigoArticulo,
    this.descripcionArticulo,
    this.observacion,
    required this.activo,
    this.detalle = const [],
  });
}
