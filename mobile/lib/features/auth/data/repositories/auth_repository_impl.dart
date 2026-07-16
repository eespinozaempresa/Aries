import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/usuario_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final FlutterSecureStorage _storage;

  const AuthRepositoryImpl(this._remote, this._storage);

  @override
  Future<Either<ApiException, ({String accessToken, String refreshToken, Usuario usuario})>>
      login({
    required String empresa,
    required String usuario,
    required String clave,
    required int captchaA,
    required int captchaB,
    required int captchaAnswer,
  }) async {
    try {
      final data = await _remote.login(
        empresa: empresa,
        usuario: usuario,
        clave: clave,
        captchaA: captchaA,
        captchaB: captchaB,
        captchaAnswer: captchaAnswer,
      );
      await _persistSession(data.accessToken, data.refreshToken, data.usuario);
      return Right((
        accessToken: data.accessToken,
        refreshToken: data.refreshToken,
        usuario: data.usuario,
      ));
    } on ApiException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<ApiException, void>> logout(String refreshToken) async {
    try {
      await _remote.logout(refreshToken);
    } catch (_) {
      // Fire-and-forget: clear local even if request fails
    }
    await _storage.deleteAll();
    return const Right(null);
  }

  @override
  Future<Usuario?> getCachedUsuario() async {
    final json = await _storage.read(key: ApiConstants.kUsuario);
    if (json == null) return null;
    return UsuarioModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: ApiConstants.kAccessToken);
    return token != null;
  }

  Future<void> _persistSession(
    String accessToken,
    String refreshToken,
    UsuarioModel usuario,
  ) async {
    await _storage.write(key: ApiConstants.kAccessToken, value: accessToken);
    await _storage.write(key: ApiConstants.kRefreshToken, value: refreshToken);
    await _storage.write(
      key: ApiConstants.kUsuario,
      value: jsonEncode(usuario.toJson()),
    );
  }
}
