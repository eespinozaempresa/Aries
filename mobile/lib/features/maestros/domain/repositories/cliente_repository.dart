import 'package:dartz/dartz.dart';
import '../../../../core/network/api_exception.dart';
import '../entities/cliente.dart';

class ClientePage {
  final List<Cliente> data;
  final int total;
  final int page;
  final int lastPage;
  const ClientePage({required this.data, required this.total, required this.page, required this.lastPage});
}

abstract class ClienteRepository {
  Future<Either<ApiException, ClientePage>> search({String? q, bool? activo, int page = 1, int limit = 20});
  Future<Either<ApiException, Cliente>> save(Map<String, dynamic> data, {String? id});
}
