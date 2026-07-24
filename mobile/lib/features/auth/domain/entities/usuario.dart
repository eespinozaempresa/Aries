import 'package:equatable/equatable.dart';

class Usuario extends Equatable {
  final String id;
  final String codigo;
  final String nombre;
  final String nivel;
  final String empresa;
  final List<String> menus;
  final bool multiEmpresa;

  const Usuario({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.nivel,
    required this.empresa,
    this.menus = const [],
    this.multiEmpresa = false,
  });

  @override
  List<Object> get props => [id, empresa];
}
