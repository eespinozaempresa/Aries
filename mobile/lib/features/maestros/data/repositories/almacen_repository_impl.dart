import 'package:dartz/dartz.dart';
import '../../domain/entities/almacen.dart';
import '../../domain/repositories/almacen_repository.dart';
import '../datasources/maestros_remote_datasource.dart';
import '../../../../core/network/api_exception.dart';

class AlmacenRepositoryImpl implements AlmacenRepository {
  final MaestrosRemoteDataSource _remote;
  const AlmacenRepositoryImpl(this._remote);

  @override
  Future<Either<ApiException, List<Almacen>>> findAll({String? q, bool? activo}) async {
    try {
      return Right(await _remote.findAllAlmacenes(q: q, activo: activo));
    } on ApiException catch (e) { return Left(e); }
  }

  @override
  Future<Either<ApiException, Almacen>> save(Map<String, dynamic> data, {String? id}) async {
    try {
      return Right(await _remote.saveAlmacen(data, id: id));
    } on ApiException catch (e) { return Left(e); }
  }
}
