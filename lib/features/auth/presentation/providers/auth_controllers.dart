import 'dart:async';

import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/auth/domain/entities/user.dart';
import 'package:eduself_study_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:eduself_study_app/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:eduself_study_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginController extends AutoDisposeAsyncNotifier<User?> {
  @override
  FutureOr<User?> build() => null;

  Future<Result<User>> submit({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(loginWithEmailProvider)(
      email: email,
      password: password,
    );
    switch (result) {
      case Success(:final value):
        // Sync in-memory bearer before any parent/teacher hub API calls.
        await _syncAccessTokenMemory();
        state = AsyncData(value);
        ref.read(authSessionProvider.notifier).setUser(value);
      case FailureResult(:final failure):
        state = AsyncError(failure, StackTrace.current);
    }
    return result;
  }

  Future<void> _syncAccessTokenMemory() async {
    ref.invalidate(apiAccessTokenProvider);
    final token = await ref.read(apiAccessTokenProvider.future);
    if (token != null && token.trim().isNotEmpty) {
      ref.read(apiAccessTokenProvider.notifier).setMemory(token);
    }
  }
}

final loginControllerProvider =
    AutoDisposeAsyncNotifierProvider<LoginController, User?>(
  LoginController.new,
);

class RegisterController extends AutoDisposeAsyncNotifier<User?> {
  @override
  FutureOr<User?> build() => null;

  Future<Result<User>> submit({
    required String email,
    required String password,
    required String confirmPassword,
    required UserRole role,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(registerWithEmailProvider)(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      role: role,
    );
    switch (result) {
      case Success(:final value):
        await _syncAccessTokenMemory();
        state = AsyncData(value);
        ref.read(authSessionProvider.notifier).setUser(value);
      case FailureResult(:final failure):
        state = AsyncError(failure, StackTrace.current);
    }
    return result;
  }

  Future<void> _syncAccessTokenMemory() async {
    ref.invalidate(apiAccessTokenProvider);
    final token = await ref.read(apiAccessTokenProvider.future);
    if (token != null && token.trim().isNotEmpty) {
      ref.read(apiAccessTokenProvider.notifier).setMemory(token);
    }
  }
}

final registerControllerProvider =
    AutoDisposeAsyncNotifierProvider<RegisterController, User?>(
  RegisterController.new,
);
