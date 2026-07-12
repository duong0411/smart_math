import 'package:eduself_study_app/core/config/app_config.dart';
import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/core/settings/app_settings_store.dart';
import 'package:eduself_study_app/features/auth/domain/entities/user.dart';
import 'package:eduself_study_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required ApiClient api,
    required AppSettingsStore settings,
  })  : _api = api,
        _settings = settings;

  final ApiClient _api;
  final AppSettingsStore _settings;

  @override
  Future<Result<User>> register({
    required String email,
    required String password,
    UserRole role = UserRole.student,
  }) async {
    final result = await _api.post(
      '/auth/register',
      auth: false,
      body: {
        'email': email,
        'password': password,
        'role': role.name,
      },
    );
    return switch (result) {
      Success(:final value) => _persistAuthResult(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    final result = await _api.post(
      '/auth/login',
      auth: false,
      body: {
        'email': email,
        'password': password,
      },
    );
    return switch (result) {
      Success(:final value) => _persistAuthResult(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> logout() async {
    final refresh = await _settings.readApiRefreshToken();
    if (refresh != null && refresh.trim().isNotEmpty) {
      await _api.post(
        '/auth/logout',
        auth: false,
        body: {'refreshToken': refresh.trim()},
      );
    }
    await _settings.clearApiTokens();
    return const Success(null);
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    final access = await _settings.readApiAccessToken();
    final fallback = AppConfig.fallbackApiAccessToken;
    if ((access == null || access.trim().isEmpty) &&
        (fallback == null || fallback.isEmpty)) {
      return const Success(null);
    }

    final result = await _api.get('/auth/me');
    switch (result) {
      case Success(:final value):
        final data = value['data'];
        if (data is! Map<String, dynamic>) {
          return const Success(null);
        }
        return Success(User.fromJson(data));
      case FailureResult(:final failure):
        if (failure is UnauthorizedFailure) {
          await _settings.clearApiTokens();
          return const Success(null);
        }
        return FailureResult(failure);
    }
  }

  Future<Result<User>> _persistAuthResult(Map<String, dynamic> envelope) async {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid auth response.'));
    }
    final userJson = data['user'];
    final tokens = data['tokens'];
    if (userJson is! Map<String, dynamic> || tokens is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid auth response.'));
    }

    final access = (tokens['accessToken'] as String?)?.trim();
    final refresh = (tokens['refreshToken'] as String?)?.trim();
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      return const FailureResult(ApiFailure('Auth tokens missing.'));
    }

    await _settings.writeApiAccessToken(access);
    await _settings.writeApiRefreshToken(refresh);
    return Success(User.fromJson(userJson));
  }
}
