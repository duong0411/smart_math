import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/auth/domain/repositories/auth_repository.dart';

class Logout {
  const Logout(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.logout();
}
