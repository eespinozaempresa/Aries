class Cliente {
  final String id;
  final String codigoEmpresa;
  final String codigo;
  final String razonSocial;
  final String? direccion;
  final String? rucDni;
  final String? telefono;
  final String? celular;
  final String? email;
  final bool activo;
  final String? idTipoLista;

  const Cliente({
    required this.id,
    required this.codigoEmpresa,
    required this.codigo,
    required this.razonSocial,
    this.direccion,
    this.rucDni,
    this.telefono,
    this.celular,
    this.email,
    required this.activo,
    this.idTipoLista,
  });
}
