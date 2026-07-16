import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/network/api_exception.dart';

class LogoutUseCase {
  final AuthRepository _repo;
  const LogoutUseCase(this._repo);

  Future<Either<ApiException, void>> call(String refreshToken) =>
      _repo.logout(refreshToken);
}
