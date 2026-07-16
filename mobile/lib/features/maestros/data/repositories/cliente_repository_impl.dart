import 'package:dartz/dartz.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';
import '../datasources/maestros_remote_datasource.dart';
import '../../../../core/network/api_exception.dart';

class ClienteRepositoryImpl implements ClienteRepository {
  final MaestrosRemoteDataSource _remote;
  const ClienteRepositoryImpl(this._remote);

  @override
  Future<Either<ApiException, ClientePage>> search({
    String? q, bool? activo, int page = 1, int limit = 20,
  }) async {
    try {
      final r = await _remote.searchClientes(q: q, activo: activo, page: page, limit: limit);
      return Right(ClientePage(data: r.data, total: r.total, page: r.page, lastPage: r.lastPage));
    } on ApiException catch (e) { return Left(e); }
  }

  @override
  Future<Either<ApiException, Cliente>> save(Map<String, dynamic> data, {String? id}) async {
    try {
      return Right(await _remote.saveCliente(data, id: id));
    } on ApiException catch (e) { return Left(e); }
  }
}
