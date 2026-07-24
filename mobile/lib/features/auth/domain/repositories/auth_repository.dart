import 'package:dartz/dartz.dart';
import '../entities/usuario.dart';
import '../entities/empresa_opcion.dart';
import '../../../../core/network/api_exception.dart';

abstract class AuthRepository {
  Future<Either<ApiException, ({String preAuthToken, List<EmpresaOpcion> empresas, String usuarioCodigo, String usuarioNombre})>> login({
    required String usuario,
    required String clave,
    required int captchaA,
    required int captchaB,
    required int captchaAnswer,
  });

  Future<Either<ApiException, Usuario>> seleccionarEmpresa({
    required String preAuthToken,
    required String codigoEmpresa,
  });

  Future<Either<ApiException, Usuario>> cambiarEmpresa({
    required String codigoEmpresa,
  });

  Future<Either<ApiException, List<EmpresaOpcion>>> misEmpresas();

  Future<Either<ApiException, void>> logout(String refreshToken);

  Future<Usuario?> getCachedUsuario();
  Future<bool> isLoggedIn();
}
