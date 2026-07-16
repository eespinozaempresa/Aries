import '../../domain/entities/cliente.dart';

class ClienteModel extends Cliente {
  const ClienteModel({
    required super.id,
    required super.codigoEmpresa,
    required super.codigo,
    required super.razonSocial,
    super.direccion,
    super.rucDni,
    super.telefono,
    super.celular,
    super.email,
    required super.activo,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> j) => ClienteModel(
        id: j['id'] as String,
        codigoEmpresa: j['codigoEmpresa'] as String,
        codigo: j['codigo'] as String,
        razonSocial: j['razonSocial'] as String,
        direccion: j['direccion'] as String?,
        rucDni: j['rucDni'] as String?,
        telefono: j['telefono'] as String?,
        celular: j['celular'] as String?,
        email: j['email'] as String?,
        activo: j['activo'] as bool? ?? true,
      );
}
