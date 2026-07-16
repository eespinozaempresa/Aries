import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../models/usuario_model.dart';

abstract class AuthRemoteDataSource {
  Future<({String accessToken, String refreshToken, UsuarioModel usuario})> login({
    required String empresa,
    required String usuario,
    required String clave,
    required int captchaA,
    required int captchaB,
    required int captchaAnswer,
  });

  Future<void> logout(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;
  const AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<({String accessToken, String refreshToken, UsuarioModel usuario})>
      login({
    required String empresa,
    required String usuario,
    required String clave,
    required int captchaA,
    required int captchaB,
    required int captchaAnswer,
  }) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'empresa': empresa.toUpperCase(),
        'usuario': usuario.toUpperCase(),
        'clave': clave,
        'captchaA': captchaA,
        'captchaB': captchaB,
        'captchaAnswer': captchaAnswer,
      });
      return (
        accessToken: res.data['accessToken'] as String,
        refreshToken: res.data['refreshToken'] as String,
        usuario: UsuarioModel.fromJson(
          res.data['usuario'] as Map<String, dynamic>,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
