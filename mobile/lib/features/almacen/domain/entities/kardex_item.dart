class KardexItem {
  final int id;
  final String codigoEmpresa;
  final String codigoAlmacen;
  final String codigoArticulo;
  final String? descripcionAlmacen;
  final String? descripcionArticulo;
  final String fecha;
  final String codigoDocumento;
  final String? abreviaturaDocumento;
  final String serie;
  final String numeroDocumento;
  final String tipo;
  final double cantEntrada;
  final double precioEntrada;
  final double importeEntrada;
  final double cantSalida;
  final double precioSalida;
  final double importeSalida;
  final double stock;
  final double precioStock;
  final double importeStock;

  const KardexItem({
    required this.id,
    required this.codigoEmpresa,
    required this.codigoAlmacen,
    required this.codigoArticulo,
    this.descripcionAlmacen,
    this.descripcionArticulo,
    required this.fecha,
    required this.codigoDocumento,
    this.abreviaturaDocumento,
    this.serie = '0001',
    required this.numeroDocumento,
    required this.tipo,
    required this.cantEntrada,
    required this.precioEntrada,
    required this.importeEntrada,
    required this.cantSalida,
    required this.precioSalida,
    required this.importeSalida,
    required this.stock,
    required this.precioStock,
    required this.importeStock,
  });
}
