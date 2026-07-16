import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../models/articulo_model.dart';
import '../models/cliente_model.dart';
import '../models/proveedor_model.dart';
import '../models/almacen_model.dart';

class PageResult<T> {
  final List<T> data;
  final int total;
  final int page;
  final int lastPage;
  const PageResult({required this.data, required this.total, required this.page, required this.lastPage});
}

abstract class MaestrosRemoteDataSource {
  Future<PageResult<ArticuloModel>> searchArticulos({String? q, bool? activo, int page = 1, int limit = 20});
  Future<ArticuloModel> saveArticulo(Map<String, dynamic> data, {String? id});

  Future<PageResult<ClienteModel>> searchClientes({String? q, bool? activo, int page = 1, int limit = 20});
  Future<ClienteModel> saveCliente(Map<String, dynamic> data, {String? id});

  Future<PageResult<ProveedorModel>> searchProveedores({String? q, bool? activo, int page = 1, int limit = 20});
  Future<ProveedorModel> saveProveedor(Map<String, dynamic> data, {String? id});

  Future<List<AlmacenModel>> findAllAlmacenes({String? q, bool? activo});
  Future<AlmacenModel> saveAlmacen(Map<String, dynamic> data, {String? id});
}

class MaestrosRemoteDataSourceImpl implements MaestrosRemoteDataSource {
  final Dio _dio;
  const MaestrosRemoteDataSourceImpl(this._dio);

  // ── Artículos ──────────────────────────────────────────────────────────────

  @override
  Future<PageResult<ArticuloModel>> searchArticulos({
    String? q, bool? activo, int page = 1, int limit = 20,
  }) async {
    try {
      final res = await _dio.get('/maestros/articulos', queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (activo != null) 'activo': activo,
        'page': page,
        'limit': limit,
      });
      return _parsePage(res.data, ArticuloModel.fromJson);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  @override
  Future<ArticuloModel> saveArticulo(Map<String, dynamic> data, {String? id}) async {
    try {
      final res = id != null
          ? await _dio.put('/maestros/articulos/$id', data: data)
          : await _dio.post('/maestros/articulos', data: data);
      return ArticuloModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  // ── Clientes ───────────────────────────────────────────────────────────────

  @override
  Future<PageResult<ClienteModel>> searchClientes({
    String? q, bool? activo, int page = 1, int limit = 20,
  }) async {
    try {
      final res = await _dio.get('/maestros/clientes', queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (activo != null) 'activo': activo,
        'page': page,
        'limit': limit,
      });
      return _parsePage(res.data, ClienteModel.fromJson);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  @override
  Future<ClienteModel> saveCliente(Map<String, dynamic> data, {String? id}) async {
    try {
      final res = id != null
          ? await _dio.put('/maestros/clientes/$id', data: data)
          : await _dio.post('/maestros/clientes', data: data);
      return ClienteModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  // ── Proveedores ────────────────────────────────────────────────────────────

  @override
  Future<PageResult<ProveedorModel>> searchProveedores({
    String? q, bool? activo, int page = 1, int limit = 20,
  }) async {
    try {
      final res = await _dio.get('/maestros/proveedores', queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (activo != null) 'activo': activo,
        'page': page,
        'limit': limit,
      });
      return _parsePage(res.data, ProveedorModel.fromJson);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  @override
  Future<ProveedorModel> saveProveedor(Map<String, dynamic> data, {String? id}) async {
    try {
      final res = id != null
          ? await _dio.put('/maestros/proveedores/$id', data: data)
          : await _dio.post('/maestros/proveedores', data: data);
      return ProveedorModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  // ── Almacenes ──────────────────────────────────────────────────────────────

  @override
  Future<List<AlmacenModel>> findAllAlmacenes({String? q, bool? activo}) async {
    try {
      final res = await _dio.get('/maestros/almacenes', queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (activo != null) 'activo': activo,
      });
      return (res.data['data'] as List)
          .map((e) => AlmacenModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  @override
  Future<AlmacenModel> saveAlmacen(Map<String, dynamic> data, {String? id}) async {
    try {
      final res = id != null
          ? await _dio.put('/maestros/almacenes/$id', data: data)
          : await _dio.post('/maestros/almacenes', data: data);
      return AlmacenModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  PageResult<T> _parsePage<T>(dynamic body, T Function(Map<String, dynamic>) fromJson) {
    final list = body['data'] as List;
    return PageResult(
      data: list.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      total: body['total'] as int? ?? 0,
      page: body['page'] as int? ?? 1,
      lastPage: body['lastPage'] as int? ?? 1,
    );
  }
}
