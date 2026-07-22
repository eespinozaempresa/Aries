import 'package:dartz/dartz.dart';
import '../../domain/entities/formula.dart';
import '../../domain/repositories/formula_repository.dart';
import '../datasources/maestros_remote_datasource.dart';
import '../../../../core/network/api_exception.dart';

class FormulaRepositoryImpl implements FormulaRepository {
  final MaestrosRemoteDataSource _remote;
  const FormulaRepositoryImpl(this._remote);

  @override
  Future<Either<ApiException, List<Formula>>> findAll({String? q, bool? activo}) async {
    try {
      return Right(await _remote.findAllFormulas(q: q, activo: activo));
    } on ApiException catch (e) { return Left(e); }
  }

  @override
  Future<Either<ApiException, Formula>> getById(String id) async {
    try {
      return Right(await _remote.getFormula(id));
    } on ApiException catch (e) { return Left(e); }
  }

  @override
  Future<Either<ApiException, Formula>> save(Map<String, dynamic> data, {String? id}) async {
    try {
      return Right(await _remote.saveFormula(data, id: id));
    } on ApiException catch (e) { return Left(e); }
  }

  @override
  Future<Either<ApiException, Formula>> toggleActivo(String id) async {
    try {
      return Right(await _remote.toggleFormula(id));
    } on ApiException catch (e) { return Left(e); }
  }
}
