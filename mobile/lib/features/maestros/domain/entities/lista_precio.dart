class ListaPrecio {
  final String id;
  final String codigoEmpresa;
  final String idArticulo;
  final String idTipoLista;
  final String descripcionTipoLista;
  final double precioVentaBase;
  final double descuentoPct;
  final double descuentoMonto;
  final double precioVenta;
  final bool activo;

  const ListaPrecio({
    required this.id,
    required this.codigoEmpresa,
    required this.idArticulo,
    required this.idTipoLista,
    required this.descripcionTipoLista,
    required this.precioVentaBase,
    required this.descuentoPct,
    required this.descuentoMonto,
    required this.precioVenta,
    required this.activo,
  });

  factory ListaPrecio.fromJson(Map<String, dynamic> j) => ListaPrecio(
        id: j['id'] as String,
        codigoEmpresa: j['codigoEmpresa'] as String,
        idArticulo: j['idArticulo'] as String,
        idTipoLista: j['idTipoLista'] as String,
        descripcionTipoLista: j['descripcionTipoLista'] as String? ?? '',
        precioVentaBase: (j['precioVentaBase'] as num?)?.toDouble() ?? 0,
        descuentoPct: (j['descuentoPct'] as num?)?.toDouble() ?? 0,
        descuentoMonto: (j['descuentoMonto'] as num?)?.toDouble() ?? 0,
        precioVenta: (j['precioVenta'] as num?)?.toDouble() ?? 0,
        activo: j['activo'] as bool? ?? true,
      );
}
