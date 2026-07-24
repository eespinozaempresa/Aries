import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../models/usuario_model.dart';
import '../../domain/entities/empresa_opcion.dart';

abstract class AuthRemoteDataSource {
  Future<({String preAuthToken, List<EmpresaOpcion> empresas, String usuarioCodigo, String usuarioNombre})> login({
    required String usuario,
    required String clave,
    required int captchaA,
    required int captchaB,
    required int captchaAnswer,
  });

  Future<({String accessToken, String refreshToken, UsuarioModel usuario})> seleccionarEmpresa({
    required String preAuthToken,
    required String codigoEmpresa,
  });

  Future<({String accessToken, String refreshToken, UsuarioModel usuario})> cambiarEmpresa({
    required String codigoEmpresa,
  });

  Future<List<EmpresaOpcion>> misEmpresas();

  Future<void> logout(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;
  const AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<({String preAuthToken, List<EmpresaOpcion> empresas, String usuarioCodigo, String usuarioNombre})>
      login({
    required String usuario,
    required String clave,
    required int captchaA,
    required int captchaB,
    required int captchaAnswer,
  }) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'usuario': usuario.toUpperCase(),
        'clave': clave,
        'captchaA': captchaA,
        'captchaB': captchaB,
        'captchaAnswer': captchaAnswer,
      });
      final usuarioJson = res.data['usuario'] as Map<String, dynamic>;
      return (
        preAuthToken: res.data['preAuthToken'] as String,
        empresas: (res.data['empresas'] as List)
            .map((e) => EmpresaOpcion.fromJson(e as Map<String, dynamic>))
            .toList(),
        usuarioCodigo: usuarioJson['codigo'] as String,
        usuarioNombre: usuarioJson['nombre'] as String,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<({String accessToken, String refreshToken, UsuarioModel usuario})> seleccionarEmpresa({
    required String preAuthToken,
    required String codigoEmpresa,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/seleccionar-empresa',
        data: {'codigoEmpresa': codigoEmpresa.toUpperCase()},
        options: Options(headers: {'Authorization': 'Bearer $preAuthToken'}),
      );
      return (
        accessToken: res.data['accessToken'] as String,
        refreshToken: res.data['refreshToken'] as String,
        usuario: UsuarioModel.fromJson(res.data['usuario'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<({String accessToken, String refreshToken, UsuarioModel usuario})> cambiarEmpresa({
    required String codigoEmpresa,
  }) async {
    try {
      final res = await _dio.post('/auth/cambiar-empresa', data: {
        'codigoEmpresa': codigoEmpresa.toUpperCase(),
      });
      return (
        accessToken: res.data['accessToken'] as String,
        refreshToken: res.data['refreshToken'] as String,
        usuario: UsuarioModel.fromJson(res.data['usuario'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<EmpresaOpcion>> misEmpresas() async {
    try {
      final res = await _dio.get('/auth/mis-empresas');
      return (res.data as List)
          .map((e) => EmpresaOpcion.fromJson(e as Map<String, dynamic>))
          .toList();
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
