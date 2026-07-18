import 'package:dartz/dartz.dart';
import '../../../../core/network/api_exception.dart';
import '../entities/tipo_cambio.dart';

abstract class TipoCambioRepository {
  Future<Either<ApiException, TipoCambio?>> getHoy();
  Future<Either<ApiException, TipoCambio>> registrar(double tipoCambio);
  Future<Either<ApiException, Map<String, dynamic>>> list({int page = 1, int limit = 20});
  Future<Either<ApiException, TipoCambio>> update(String id, double tipoCambio);
  Future<Either<ApiException, void>> delete(String id);
}
