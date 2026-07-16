import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  static const String _envUrl = String.fromEnvironment('API_URL');

  // kIsWeb → localhost; Android emulator → 10.0.2.2; --dart-define=API_URL overrides both
  static String get baseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    return kIsWeb
        ? 'http://localhost:3000/api/v1'
        : 'http://10.0.2.2:3000/api/v1';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage keys
  static const String kAccessToken = 'access_token';
  static const String kRefreshToken = 'refresh_token';
  static const String kUsuario = 'usuario_json';
}
