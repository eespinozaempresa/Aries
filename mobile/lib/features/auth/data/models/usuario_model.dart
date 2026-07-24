import '../../domain/entities/usuario.dart';

class UsuarioModel extends Usuario {
  const UsuarioModel({
    required super.id,
    required super.codigo,
    required super.nombre,
    required super.nivel,
    required super.empresa,
    super.menus = const [],
    super.multiEmpresa = false,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) => UsuarioModel(
        id: json['id'] as String,
        codigo: json['codigo'] as String,
        nombre: json['nombre'] as String,
        nivel: json['nivel'] as String,
        empresa: json['empresa'] as String,
        menus: (json['menus'] as List<dynamic>?)?.cast<String>() ?? const [],
        multiEmpresa: json['multiEmpresa'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'nombre': nombre,
        'nivel': nivel,
        'empresa': empresa,
        'menus': menus,
        'multiEmpresa': multiEmpresa,
      };
}
