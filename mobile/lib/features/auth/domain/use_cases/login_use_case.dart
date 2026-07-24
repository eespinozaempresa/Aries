import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../entities/empresa_opcion.dart';
import '../../../../core/network/api_exception.dart';

class LoginUseCase {
  final AuthRepository _repo;
  const LoginUseCase(this._repo);

  Future<Either<ApiException, ({String preAuthToken, List<EmpresaOpcion> empresas, String usuarioCodigo, String usuarioNombre})>> call({
    required String usuario,
    required String clave,
    required int captchaA,
    required int captchaB,
    required int captchaAnswer,
  }) {
    return _repo.login(
      usuario: usuario,
      clave: clave,
      captchaA: captchaA,
      captchaB: captchaB,
      captchaAnswer: captchaAnswer,
    );
  }
}
