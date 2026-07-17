class Articulo {
  final String id;
  final String codigoEmpresa;
  final String codigo;
  final String descripcion;
  final String? codigoLinea;
  final String? codigoMedida;
  final String? codigoMarca;
  final double precioCompraBase;
  final double precioCompra;
  final double utilidadPct;
  final double precioVentaBase;
  final double precioVenta;
  final double stockMinimo;
  final double stockMaximo;
  final String? codigoBarras;
  final bool activo;

  const Articulo({
    required this.id,
    required this.codigoEmpresa,
    required this.codigo,
    required this.descripcion,
    this.codigoLinea,
    this.codigoMedida,
    this.codigoMarca,
    required this.precioCompraBase,
    required this.precioCompra,
    required this.utilidadPct,
    required this.precioVentaBase,
    required this.precioVenta,
    required this.stockMinimo,
    required this.stockMaximo,
    this.codigoBarras,
    required this.activo,
  });
}
