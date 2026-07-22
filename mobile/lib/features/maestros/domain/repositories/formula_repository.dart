import 'package:dartz/dartz.dart';
import '../../../../core/network/api_exception.dart';
import '../entities/formula.dart';

abstract class FormulaRepository {
  Future<Either<ApiException, List<Formula>>> findAll({String? q, bool? activo});
  Future<Either<ApiException, Formula>> getById(String id);
  Future<Either<ApiException, Formula>> save(Map<String, dynamic> data, {String? id});
  Future<Either<ApiException, Formula>> toggleActivo(String id);
}
