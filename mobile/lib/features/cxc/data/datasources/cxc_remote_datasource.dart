import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';

class CxCRemoteDataSource {
  final Dio _dio;
  CxCRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> list({
    String? codigoCliente,
    bool? pendiente,
    String? desde,
    String? hasta,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (codigoCliente != null) params['codigoCliente'] = codigoCliente;
      if (pendiente != null) params['pendiente'] = pendiente;
      if (desde != null) params['desde'] = desde;
      if (hasta != null) params['hasta'] = hasta;
      final r = await _dio.get('/cxc', queryParameters: params);
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> findById(String id) async {
    try {
      final r = await _dio.get('/cxc/$id');
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<dynamic>> getCobros(String cxcId) async {
    try {
      final r = await _dio.get('/cxc/$cxcId/cobros');
      return r.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> registrarCobro({
    required String cuentaCobrarId,
    required String numeroRecibo,
    required String fecha,
    required String tipoPago,
    String? numeroOperacion,
    String? codigoBanco,
    required double monto,
  }) async {
    try {
      final r = await _dio.post('/cxc/cobros', data: {
        'cuentaCobrarId': cuentaCobrarId,
        'numeroRecibo': numeroRecibo,
        'fecha': fecha,
        'tipoPago': tipoPago,
        if (numeroOperacion != null) 'numeroOperacion': numeroOperacion,
        if (codigoBanco != null) 'codigoBanco': codigoBanco,
        'monto': monto,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> eliminarCobro(String id) async {
    try {
      final r = await _dio.delete('/cxc/cobros/$id');
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<dynamic>> renovar({
    required String id,
    required List<Map<String, dynamic>> cuotas,
  }) async {
    try {
      final r = await _dio.post('/cxc/$id/renovar', data: {'cuotas': cuotas});
      return r.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
