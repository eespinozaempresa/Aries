class DetalleMovimiento {
  final String id;
  final String movimientoId;
  final String codigoEmpresa;
  final String codigoArticulo;
  final String? descripcionArticulo;
  final double cantidad;
  final double precioUnitario;
  final double importe;

  const DetalleMovimiento({
    required this.id,
    required this.movimientoId,
    required this.codigoEmpresa,
    required this.codigoArticulo,
    this.descripcionArticulo,
    required this.cantidad,
    required this.precioUnitario,
    required this.importe,
  });
}
