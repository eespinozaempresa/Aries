import 'package:dartz/dartz.dart';
import '../entities/usuario.dart';
import '../../../../core/network/api_exception.dart';

abstract class AuthRepository {
  Future<Either<ApiException, ({String accessToken, String refreshToken, Usuario usuario})>> login({
    required String empresa,
    required String usuario,
    required String clave,
    required int captchaA,
    required int captchaB,
    required int captchaAnswer,
  });

  Future<Either<ApiException, void>> logout(String refreshToken);

  Future<Usuario?> getCachedUsuario();
  Future<bool> isLoggedIn();
}
