import 'package:dartz/dartz.dart';
import '../../../../core/network/api_exception.dart';
import '../entities/almacen.dart';

abstract class AlmacenRepository {
  Future<Either<ApiException, List<Almacen>>> findAll({String? q, bool? activo});
  Future<Either<ApiException, Almacen>> getById(String id);
  Future<Either<ApiException, Almacen>> save(Map<String, dynamic> data, {String? id});
}
