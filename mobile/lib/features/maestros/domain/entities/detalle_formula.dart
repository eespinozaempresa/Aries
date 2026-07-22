class DetalleFormula {
  final String? id;
  final String? formulaId;
  final String codigoArticulo;
  final String? descripcionArticulo;
  final double cantidad;
  final int orden;

  const DetalleFormula({
    this.id,
    this.formulaId,
    required this.codigoArticulo,
    this.descripcionArticulo,
    required this.cantidad,
    this.orden = 0,
  });
}
