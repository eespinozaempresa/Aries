class DetalleVenta {
  final String id;
  final String ventaId;
  final String codigoEmpresa;
  final String codigoArticulo;
  final double cantidad;
  final double precioUnitario;
  final double descuentoPct;
  final double importe;

  const DetalleVenta({
    required this.id,
    required this.ventaId,
    required this.codigoEmpresa,
    required this.codigoArticulo,
    required this.cantidad,
    required this.precioUnitario,
    required this.descuentoPct,
    required this.importe,
  });
}
