import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/auth/domain/entities/user.dart';
import 'package:eduself_study_app/features/auth/domain/repositories/auth_repository.dart';

class LoginWithEmail {
  const LoginWithEmail(this._repository);

  final AuthRepository _repository;

  Future<Result<User>> call({
    required String email,
    required String password,
  }) {
    final normalized = email.trim();
    if (normalized.isEmpty || password.isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure('Email and password are required.'),
        ),
      );
    }
    return _repository.login(
      email: normalized.toLowerCase(),
      password: password,
    );
  }
}
