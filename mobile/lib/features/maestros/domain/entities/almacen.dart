class Almacen {
  final String id;
  final String codigoEmpresa;
  final String codigo;
  final String descripcion;
  final String? abreviatura;
  final String? ubicacion;
  final String tipo;
  final bool activo;

  const Almacen({
    required this.id,
    required this.codigoEmpresa,
    required this.codigo,
    required this.descripcion,
    this.abreviatura,
    this.ubicacion,
    required this.tipo,
    required this.activo,
  });
}
