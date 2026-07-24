import 'package:equatable/equatable.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/entities/empresa_opcion.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  final Usuario usuario;
  const AuthAuthenticated(this.usuario);
  @override
  List<Object> get props => [usuario];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthEmpresaSelectionRequired extends AuthState {
  final String preAuthToken;
  final List<EmpresaOpcion> empresas;
  final String usuarioCodigo;
  final String usuarioNombre;

  const AuthEmpresaSelectionRequired({
    required this.preAuthToken,
    required this.empresas,
    required this.usuarioCodigo,
    required this.usuarioNombre,
  });

  @override
  List<Object> get props => [preAuthToken, empresas, usuarioCodigo, usuarioNombre];
}

final class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object> get props => [message];
}
