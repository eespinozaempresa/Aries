import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../models/tipo_cambio_model.dart';

abstract class TipoCambioRemoteDataSource {
  Future<TipoCambioModel?> getHoy();
  Future<TipoCambioModel?> preview(String codigoEmpresa, {String? bearerOverride});
  Future<TipoCambioModel?> getByFecha(String fecha);
  Future<TipoCambioModel> registrar(double tipoCambio);
  Future<Map<String, dynamic>> list({int page = 1, int limit = 20});
  Future<TipoCambioModel> update(String id, double tipoCambio);
  Future<void> delete(String id);
}

class TipoCambioRemoteDataSourceImpl implements TipoCambioRemoteDataSource {
  final Dio _dio;
  const TipoCambioRemoteDataSourceImpl(this._dio);

  @override
  Future<TipoCambioModel?> getHoy() async {
    try {
      final res = await _dio.get('/tipo-cambio/hoy');
      final data = res.data['data'];
      if (data == null) return null;
      return TipoCambioModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<TipoCambioModel?> preview(String codigoEmpresa, {String? bearerOverride}) async {
    try {
      final res = await _dio.get(
        '/tipo-cambio/preview/$codigoEmpresa',
        options: bearerOverride != null
            ? Options(headers: {'Authorization': 'Bearer $bearerOverride'})
            : null,
      );
      final data = res.data['data'];
      if (data == null) return null;
      return TipoCambioModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<TipoCambioModel> registrar(double tipoCambio) async {
    try {
      final res = await _dio.post('/tipo-cambio', data: {'tipoCambio': tipoCambio});
      return TipoCambioModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<TipoCambioModel?> getByFecha(String fecha) async {
    try {
      final res = await _dio.get('/tipo-cambio/fecha/$fecha');
      final data = res.data['data'];
      if (data == null) return null;
      return TipoCambioModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> list({int page = 1, int limit = 20}) async {
    try {
      final res = await _dio.get('/tipo-cambio', queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<TipoCambioModel> update(String id, double tipoCambio) async {
    try {
      final res = await _dio.patch('/tipo-cambio/$id', data: {'tipoCambio': tipoCambio});
      return TipoCambioModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/tipo-cambio/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
