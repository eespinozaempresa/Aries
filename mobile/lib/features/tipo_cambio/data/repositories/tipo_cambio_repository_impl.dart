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
      final result = await _remote.registrar(tipoCambio);
      return Right(result);
    } on ApiException catch (e) {
      return Left(e);
    }
  }
}
