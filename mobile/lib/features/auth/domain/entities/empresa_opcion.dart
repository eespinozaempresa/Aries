import 'package:equatable/equatable.dart';

class EmpresaOpcion extends Equatable {
  final String codigo;
  final String nombre;

  const EmpresaOpcion({required this.codigo, required this.nombre});

  factory EmpresaOpcion.fromJson(Map<String, dynamic> json) => EmpresaOpcion(
        codigo: json['codigo'] as String,
        nombre: json['nombre'] as String,
      );

  @override
  List<Object> get props => [codigo];
}
