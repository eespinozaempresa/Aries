import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/compra.dart';
import '../models/compra_model.dart';

class ComprasRemoteDataSource {
  final Dio _dio;
  ComprasRemoteDataSource(this._dio);

  Future<Compra> registrar(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/compras', data: body);
      return CompraModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<Map<String, dynamic>> list(Map<String, dynamic> params) async {
    try {
      final res = await _dio.get('/compras', queryParameters: params);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<Compra> findById(String id) async {
    try {
      final res = await _dio.get('/compras/$id');
      return CompraModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<Compra> anular(String id) async {
    try {
      final res = await _dio.patch('/compras/$id/anular');
      return CompraModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }
}
