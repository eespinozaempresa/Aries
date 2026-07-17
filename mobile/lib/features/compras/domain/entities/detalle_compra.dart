class DetalleCompra {
  final String id;
  final String compraId;
  final String codigoEmpresa;
  final String codigoArticulo;
  final String? descripcionArticulo;
  final double cantidad;
  final double precioUnitario;
  final double importe;
  final String? fechaVencimiento;
  final double precioUnitarioUsd;
  final double importeUsd;

  const DetalleCompra({
    required this.id,
    required this.compraId,
    required this.codigoEmpresa,
    required this.codigoArticulo,
    this.descripcionArticulo,
    required this.cantidad,
    required this.precioUnitario,
    required this.importe,
    this.fechaVencimiento,
    required this.precioUnitarioUsd,
    required this.importeUsd,
  });
}
