import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

final class LoginRequested extends AuthEvent {
  final String usuario;
  final String clave;
  final int captchaA;
  final int captchaB;
  final int captchaAnswer;

  const LoginRequested({
    required this.usuario,
    required this.clave,
    required this.captchaA,
    required this.captchaB,
    required this.captchaAnswer,
  });

  @override
  List<Object> get props => [usuario, clave, captchaA, captchaB, captchaAnswer];
}

final class LogoutRequested extends AuthEvent {
  final String refreshToken;
  const LogoutRequested(this.refreshToken);
  @override
  List<Object> get props => [refreshToken];
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}
