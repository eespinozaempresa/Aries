import 'package:dartz/dartz.dart';
import '../../../../core/network/api_exception.dart';
import '../entities/proveedor.dart';

class ProveedorPage {
  final List<Proveedor> data;
  final int total;
  final int page;
  final int lastPage;
  const ProveedorPage({required this.data, required this.total, required this.page, required this.lastPage});
}

abstract class ProveedorRepository {
  Future<Either<ApiException, ProveedorPage>> search({String? q, bool? activo, int page = 1, int limit = 20});
  Future<Either<ApiException, Proveedor>> getById(String id);
  Future<Either<ApiException, Proveedor>> save(Map<String, dynamic> data, {String? id});
}
