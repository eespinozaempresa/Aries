import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';

class CxPRemoteDataSource {
  final Dio _dio;
  CxPRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> list({
    String? codigoProveedor,
    bool? pendiente,
    String? desde,
    String? hasta,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (codigoProveedor != null) params['codigoProveedor'] = codigoProveedor;
      if (pendiente != null) params['pendiente'] = pendiente;
      if (desde != null) params['desde'] = desde;
      if (hasta != null) params['hasta'] = hasta;
      final r = await _dio.get('/cxp', queryParameters: params);
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> findById(String id) async {
    try {
      final r = await _dio.get('/cxp/$id');
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<dynamic>> getPagos(String cxpId) async {
    try {
      final r = await _dio.get('/cxp/$cxpId/pagos');
      return r.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> registrarPago({
    required String cuentaPagarId,
    required String numeroVoucher,
    required String fecha,
    required String tipoPago,
    String? numeroOperacion,
    String? codigoBanco,
    required double monto,
  }) async {
    try {
      final r = await _dio.post('/cxp/pagos', data: {
        'cuentaPagarId': cuentaPagarId,
        'numeroVoucher': numeroVoucher,
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

  Future<List<dynamic>> renovar({
    required String id,
    required List<Map<String, dynamic>> cuotas,
  }) async {
    try {
      final r = await _dio.post('/cxp/$id/renovar', data: {'cuotas': cuotas});
      return r.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
