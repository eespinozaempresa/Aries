import 'package:dartz/dartz.dart';
import '../../domain/entities/tipo_cambio.dart';
import '../../domain/repositories/tipo_cambio_repository.dart';
import '../datasources/tipo_cambio_remote_datasource.dart';
import '../../../../core/network/api_exception.dart';

class TipoCambioRepositoryImpl implements TipoCambioRepository {
  final TipoCambioRemoteDataSource _remote;
  const TipoCambioRepositoryImpl(this._remote);

  @override
  Future<Either<ApiException, TipoCambio?>> getHoy() async {
    try {
      final result = await _remote.getHoy();
      return Right(result);
    } on ApiException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<ApiException, TipoCambio>> registrar(double tipoCambio) async {
    try {
      return Right(await _remote.registrar(tipoCambio));
    } on ApiException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<ApiException, Map<String, dynamic>>> list({int page = 1, int limit = 20}) async {
    try {
      return Right(await _remote.list(page: page, limit: limit));
    } on ApiException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<ApiException, TipoCambio>> update(String id, double tipoCambio) async {
    try {
      return Right(await _remote.update(id, tipoCambio));
    } on ApiException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<ApiException, void>> delete(String id) async {
    try {
      await _remote.delete(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(e);
    }
  }
}
