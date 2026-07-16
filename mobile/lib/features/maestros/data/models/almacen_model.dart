import '../../domain/entities/almacen.dart';

class AlmacenModel extends Almacen {
  const AlmacenModel({
    required super.id,
    required super.codigoEmpresa,
    required super.codigo,
    required super.descripcion,
    super.abreviatura,
    super.ubicacion,
    required super.tipo,
    required super.activo,
  });

  factory AlmacenModel.fromJson(Map<String, dynamic> j) => AlmacenModel(
        id: j['id'] as String,
        codigoEmpresa: j['codigoEmpresa'] as String,
        codigo: j['codigo'] as String,
        descripcion: j['descripcion'] as String,
        abreviatura: j['abreviatura'] as String?,
        ubicacion: j['ubicacion'] as String?,
        tipo: j['tipo'] as String? ?? 'ALMACEN',
        activo: j['activo'] as bool? ?? true,
      );
}
