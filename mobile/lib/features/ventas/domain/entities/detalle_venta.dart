class DetalleVenta {
  final String id;
  final String ventaId;
  final String codigoEmpresa;
  final String codigoArticulo;
  final String? descripcionArticulo;
  final double cantidad;
  final double precioUnitario;
  final double descuentoPct;
  final double importe;
  final double precioUnitarioUsd;
  final double importeUsd;

  const DetalleVenta({
    required this.id,
    required this.ventaId,
    required this.codigoEmpresa,
    required this.codigoArticulo,
    this.descripcionArticulo,
    required this.cantidad,
    required this.precioUnitario,
    required this.descuentoPct,
    required this.importe,
    this.precioUnitarioUsd = 0,
    this.importeUsd = 0,
  });
}
