import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/auth/domain/entities/user.dart';
import 'package:eduself_study_app/features/auth/domain/repositories/auth_repository.dart';

class RegisterWithEmail {
  const RegisterWithEmail(this._repository);

  final AuthRepository _repository;

  Future<Result<User>> call({
    required String email,
    required String password,
    required String confirmPassword,
    required UserRole role,
  }) {
    final validation = _validate(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    if (validation != null) {
      return Future.value(FailureResult(validation));
    }
    return _repository.register(
      email: email.trim().toLowerCase(),
      password: password,
      role: role,
    );
  }

  ValidationFailure? _validate({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final normalized = email.trim();
    if (normalized.isEmpty || !_emailRegex.hasMatch(normalized)) {
      return const ValidationFailure('Enter a valid email address.');
    }
    if (password.length < 8) {
      return const ValidationFailure('Password must be at least 8 characters.');
    }
    if (password != confirmPassword) {
      return const ValidationFailure('Passwords do not match.');
    }
    return null;
  }

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
