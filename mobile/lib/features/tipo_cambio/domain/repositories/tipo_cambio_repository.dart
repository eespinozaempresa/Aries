import 'package:dartz/dartz.dart';
import '../../../../core/network/api_exception.dart';
import '../entities/tipo_cambio.dart';

abstract class TipoCambioRepository {
  Future<Either<ApiException, TipoCambio?>> getHoy();
  Future<Either<ApiException, TipoCambio>> registrar(double tipoCambio);
}
