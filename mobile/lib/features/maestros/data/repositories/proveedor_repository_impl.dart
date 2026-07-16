import 'package:dartz/dartz.dart';
import '../../domain/entities/proveedor.dart';
import '../../domain/repositories/proveedor_repository.dart';
import '../datasources/maestros_remote_datasource.dart';
import '../../../../core/network/api_exception.dart';

class ProveedorRepositoryImpl implements ProveedorRepository {
  final MaestrosRemoteDataSource _remote;
  const ProveedorRepositoryImpl(this._remote);

  @override
  Future<Either<ApiException, ProveedorPage>> search({
    String? q, bool? activo, int page = 1, int limit = 20,
  }) async {
    try {
      final r = await _remote.searchProveedores(q: q, activo: activo, page: page, limit: limit);
      return Right(ProveedorPage(data: r.data, total: r.total, page: r.page, lastPage: r.lastPage));
    } on ApiException catch (e) { return Left(e); }
  }

  @override
  Future<Either<ApiException, Proveedor>> save(Map<String, dynamic> data, {String? id}) async {
    try {
      return Right(await _remote.saveProveedor(data, id: id));
    } on ApiException catch (e) { return Left(e); }
  }
}
