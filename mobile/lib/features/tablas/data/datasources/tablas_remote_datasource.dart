import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';

class TablasRemoteDataSource {
  final Dio _dio;
  TablasRemoteDataSource(this._dio);

  Future<List<Map<String, dynamic>>> list(String path, {String? q, bool? activo, String? tipo}) async {
    try {
      final params = <String, dynamic>{};
      if (q != null && q.isNotEmpty) params['q'] = q;
      if (activo != null) params['activo'] = activo.toString();
      if (tipo != null) params['tipo'] = tipo;
      final res = await _dio.get('/tablas/$path', queryParameters: params);
      final data = res.data;
      return List<Map<String, dynamic>>.from(
        data is List ? data : (data['data'] as List),
      );
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<Map<String, dynamic>> save(String path, Map<String, dynamic> body, {String? id}) async {
    try {
      final res = id != null
          ? await _dio.put('/tablas/$path/$id', data: body)
          : await _dio.post('/tablas/$path', data: body);
      final data = res.data;
      return data is Map<String, dynamic> && data.containsKey('data')
          ? data['data'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<Map<String, dynamic>> toggle(String path, String id) async {
    try {
      final res = await _dio.patch('/tablas/$path/$id/toggle');
      final data = res.data;
      return data is Map<String, dynamic> && data.containsKey('data')
          ? data['data'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }
}
