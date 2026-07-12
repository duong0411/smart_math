import 'package:eduself_study_app/core/network/network_providers.dart';
import 'package:eduself_study_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:eduself_study_app/features/auth/domain/usecases/login_with_email.dart';
import 'package:eduself_study_app/features/auth/domain/usecases/logout.dart';
import 'package:eduself_study_app/features/auth/domain/usecases/register_with_email.dart';
import 'package:eduself_study_app/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:eduself_study_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    api: ref.watch(apiClientProvider),
    settings: ref.watch(appSettingsStoreProvider),
  );
});

final registerWithEmailProvider = Provider<RegisterWithEmail>((ref) {
  return RegisterWithEmail(ref.watch(authRepositoryProvider));
});

final loginWithEmailProvider = Provider<LoginWithEmail>((ref) {
  return LoginWithEmail(ref.watch(authRepositoryProvider));
});

final logoutProvider = Provider<Logout>((ref) {
  return Logout(ref.watch(authRepositoryProvider));
});
