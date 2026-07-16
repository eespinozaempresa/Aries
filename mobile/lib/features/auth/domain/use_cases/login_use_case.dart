import 'package:dartz/dartz.dart';
import '../entities/usuario.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/network/api_exception.dart';

class LoginUseCase {
  final AuthRepository _repo;
  const LoginUseCase(this._repo);

  Future<Either<ApiException, Usuario>> call({
    required String empresa,
    required String usuario,
    required String clave,
    required int captchaA,
    required int captchaB,
    required int captchaAnswer,
  }) async {
    final result = await _repo.login(
      empresa: empresa,
      usuario: usuario,
      clave: clave,
      captchaA: captchaA,
      captchaB: captchaB,
      captchaAnswer: captchaAnswer,
    );
    return result.fold(Left.new, (data) => Right(data.usuario));
  }
}
