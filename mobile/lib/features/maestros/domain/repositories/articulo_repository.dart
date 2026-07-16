import 'package:dartz/dartz.dart';
import '../../../../core/network/api_exception.dart';
import '../entities/articulo.dart';

class ArticuloPage {
  final List<Articulo> data;
  final int total;
  final int page;
  final int lastPage;
  const ArticuloPage({required this.data, required this.total, required this.page, required this.lastPage});
}

abstract class ArticuloRepository {
  Future<Either<ApiException, ArticuloPage>> search({String? q, bool? activo, int page = 1, int limit = 20});
  Future<Either<ApiException, Articulo>> save(Map<String, dynamic> data, {String? id});
}
