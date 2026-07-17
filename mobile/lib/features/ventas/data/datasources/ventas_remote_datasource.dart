import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/venta.dart';
import '../models/venta_model.dart';

class VentasRemoteDataSource {
  final Dio _dio;
  VentasRemoteDataSource(this._dio);

  Future<Venta> registrar(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/ventas', data: body);
      return VentaModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<Map<String, dynamic>> list(Map<String, dynamic> params) async {
    try {
      final res = await _dio.get('/ventas', queryParameters: params);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<Venta> findById(String id) async {
    try {
      final res = await _dio.get('/ventas/$id');
      return VentaModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<Venta> anular(String id) async {
    try {
      final res = await _dio.patch('/ventas/$id/anular');
      return VentaModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<List<dynamic>> reporteUtilidad({String? almacen, String? desde, String? hasta}) async {
    try {
      final params = <String, dynamic>{
        if (almacen != null) 'almacen': almacen,
        if (desde != null) 'desde': desde,
        if (hasta != null) 'hasta': hasta,
      };
      final res = await _dio.get('/ventas/reporte/utilidad', queryParameters: params);
      final data = res.data;
      return data is List ? data : (data['data'] as List);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<Map<String, dynamic>> getParametros() async {
    try {
      final res = await _dio.get('/utilitarios/parametros');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<List<Map<String, dynamic>>> getDocumentos() async {
    try {
      final res = await _dio.get('/tablas/documentos');
      final data = res.data;
      return List<Map<String, dynamic>>.from(
          data is List ? data : (data['data'] as List));
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }
}
