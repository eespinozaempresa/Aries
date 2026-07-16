import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/movimiento.dart';
import '../models/movimiento_model.dart';

class AlmacenRemoteDataSource {
  final Dio _dio;
  AlmacenRemoteDataSource(this._dio);

  Future<String> registrar(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/almacen/movimientos', data: body);
      return (res.data['id'] ?? res.data['data']?['id']) as String;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Movimiento> findById(String id) async {
    try {
      final res = await _dio.get('/almacen/movimientos/$id');
      final data = res.data is Map && res.data['data'] != null ? res.data['data'] : res.data;
      return MovimientoModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> list(Map<String, dynamic> params) async {
    try {
      final res = await _dio.get('/almacen/movimientos', queryParameters: params);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Movimiento> anular(String id) async {
    try {
      final res = await _dio.patch('/almacen/movimientos/$id/anular');
      final data = res.data is Map && res.data['data'] != null ? res.data['data'] : res.data;
      return MovimientoModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<dynamic>> getKardex(Map<String, dynamic> params) async {
    try {
      final res = await _dio.get('/almacen/kardex', queryParameters: params);
      final data = res.data;
      return data is List ? data : (data['data'] as List);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> recalcularKardex() async {
    try {
      final res = await _dio.post('/almacen/kardex/recalcular');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<dynamic>> getStock(Map<String, dynamic> params) async {
    try {
      final res = await _dio.get('/almacen/stock', queryParameters: params);
      final data = res.data;
      return data is List ? data : (data['data'] as List);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
