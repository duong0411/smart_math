import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/auth/domain/entities/user.dart';

abstract interface class AuthRepository {
  Future<Result<User>> register({
    required String email,
    required String password,
    UserRole role = UserRole.student,
  });

  Future<Result<User>> login({
    required String email,
    required String password,
  });

  Future<Result<void>> logout();

  Future<Result<User?>> getCurrentUser();
}
