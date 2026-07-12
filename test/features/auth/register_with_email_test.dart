import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/auth/domain/entities/user.dart';
import 'package:eduself_study_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:eduself_study_app/features/auth/domain/usecases/register_with_email.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepo implements AuthRepository {
  UserRole? lastRole;

  @override
  Future<Result<User>> register({
    required String email,
    required String password,
    UserRole role = UserRole.student,
  }) async {
    lastRole = role;
    return Success(
      User(
        id: 1,
        email: email,
        role: role,
        createdAtUtc: DateTime.utc(2026, 1, 1),
      ),
    );
  }

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<User?>> getCurrentUser() => throw UnimplementedError();

  @override
  Future<Result<void>> logout() => throw UnimplementedError();
}

void main() {
  test('RegisterWithEmail passes parent role to repository', () async {
    final repo = _FakeAuthRepo();
    final useCase = RegisterWithEmail(repo);
    final result = await useCase(
      email: 'p@example.com',
      password: 'password1',
      confirmPassword: 'password1',
      role: UserRole.parent,
    );
    expect(result.isSuccess, isTrue);
    expect(repo.lastRole, UserRole.parent);
  });
}
