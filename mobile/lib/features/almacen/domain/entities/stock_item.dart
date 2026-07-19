class StockItem {
  final String id;
  final String codigoEmpresa;
  final String codigoAlmacen;
  final String codigoArticulo;
  final String? descripcionAlmacen;
  final String? descripcionArticulo;
  final double stockInicial;
  final double stockCompras;
  final double stockVentas;
  final double stockEntradas;
  final double stockSalidas;
  final double stockTrasladosIn;
  final double stockTrasladosOut;
  final double costoPromedio;
  final double importeTotal;
  final String? fechaActualizacion;
  final double stockActual;

  const StockItem({
    required this.id,
    required this.codigoEmpresa,
    required this.codigoAlmacen,
    required this.codigoArticulo,
    this.descripcionAlmacen,
    this.descripcionArticulo,
    required this.stockInicial,
    required this.stockCompras,
    required this.stockVentas,
    required this.stockEntradas,
    required this.stockSalidas,
    required this.stockTrasladosIn,
    required this.stockTrasladosOut,
    required this.costoPromedio,
    required this.importeTotal,
    this.fechaActualizacion,
    required this.stockActual,
  });
}
