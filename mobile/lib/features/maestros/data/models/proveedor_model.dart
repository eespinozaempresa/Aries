import '../../domain/entities/proveedor.dart';

class ProveedorModel extends Proveedor {
  const ProveedorModel({
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

  factory ProveedorModel.fromJson(Map<String, dynamic> j) => ProveedorModel(
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
