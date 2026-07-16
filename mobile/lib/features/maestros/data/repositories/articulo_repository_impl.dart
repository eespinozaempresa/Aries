import 'package:dartz/dartz.dart';
import '../../domain/entities/articulo.dart';
import '../../domain/repositories/articulo_repository.dart';
import '../datasources/maestros_remote_datasource.dart';
import '../../../../core/network/api_exception.dart';

class ArticuloRepositoryImpl implements ArticuloRepository {
  final MaestrosRemoteDataSource _remote;
  const ArticuloRepositoryImpl(this._remote);

  @override
  Future<Either<ApiException, ArticuloPage>> search({
    String? q, bool? activo, int page = 1, int limit = 20,
  }) async {
    try {
      final r = await _remote.searchArticulos(q: q, activo: activo, page: page, limit: limit);
      return Right(ArticuloPage(data: r.data, total: r.total, page: r.page, lastPage: r.lastPage));
    } on ApiException catch (e) { return Left(e); }
  }

  @override
  Future<Either<ApiException, Articulo>> save(Map<String, dynamic> data, {String? id}) async {
    try {
      return Right(await _remote.saveArticulo(data, id: id));
    } on ApiException catch (e) { return Left(e); }
  }
}
