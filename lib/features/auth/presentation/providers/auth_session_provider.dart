import 'package:eduself_study_app/features/auth/domain/entities/user.dart';
import 'package:eduself_study_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthSessionNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final result = await ref.read(authRepositoryProvider).getCurrentUser();
    return result.when(
      success: (user) => user,
      failure: (_) => null,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authRepositoryProvider).getCurrentUser();
      return result.when(
        success: (user) => user,
        failure: (_) => null,
      );
    });
  }

  void setUser(User user) {
    state = AsyncData(user);
  }

  void clear() {
    state = const AsyncData(null);
  }
}

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, User?>(AuthSessionNotifier.new);
