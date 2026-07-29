import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';

class CajaRemoteDataSource {
  final Dio _dio;
  CajaRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> list({String? codigoCaja, String? estado, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (codigoCaja != null) params['codigoCaja'] = codigoCaja;
      if (estado != null) params['estado'] = estado;
      final r = await _dio.get('/caja', queryParameters: params);
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> findById(String id) async {
    try {
      final r = await _dio.get('/caja/$id');
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> reporte(String id) async {
    try {
      final r = await _dio.get('/caja/$id/reporte');
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> abrir({required String codigoCaja, required double montoApertura}) async {
    try {
      final r = await _dio.post('/caja/abrir', data: {'codigoCaja': codigoCaja, 'montoApertura': montoApertura});
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> cerrar({required String id, required double montosCierre}) async {
    try {
      final r = await _dio.post('/caja/$id/cerrar', data: {'montosCierre': montosCierre});
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> registrarMovimiento({
    required String sesionCajaId,
    required String tipo,
    required String concepto,
    required double monto,
    required String fecha,
    String? referencia,
    String? tipoPago,
    String? numeroOperacion,
    String? codigoBanco,
  }) async {
    try {
      final r = await _dio.post('/caja/movimientos', data: {
        'sesionCajaId': sesionCajaId,
        'tipo': tipo,
        'concepto': concepto,
        'monto': monto,
        'fecha': fecha,
        if (referencia != null) 'referencia': referencia,
        if (tipoPago != null) 'tipoPago': tipoPago,
        if (numeroOperacion != null) 'numeroOperacion': numeroOperacion,
        if (codigoBanco != null) 'codigoBanco': codigoBanco,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> eliminarMovimiento(String id) async {
    try {
      final r = await _dio.delete('/caja/movimientos/$id');
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> actualizarMovimiento(
    String id, {
    String? tipo,
    String? concepto,
    String? referencia,
    String? tipoPago,
    String? numeroOperacion,
    String? codigoBanco,
    double? monto,
    String? fecha,
  }) async {
    try {
      final r = await _dio.patch('/caja/movimientos/$id', data: {
        if (tipo != null) 'tipo': tipo,
        if (concepto != null) 'concepto': concepto,
        if (referencia != null) 'referencia': referencia,
        if (tipoPago != null) 'tipoPago': tipoPago,
        if (numeroOperacion != null) 'numeroOperacion': numeroOperacion,
        if (codigoBanco != null) 'codigoBanco': codigoBanco,
        if (monto != null) 'monto': monto,
        if (fecha != null) 'fecha': fecha,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
