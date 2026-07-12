import 'package:eduself_study_app/core/config/app_config.dart';
import 'package:eduself_study_app/core/routing/app_router.dart';
import 'package:eduself_study_app/core/theme/app_theme.dart';
import 'package:eduself_study_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  runApp(const ProviderScope(child: EduSelfApp()));
}

class EduSelfApp extends ConsumerWidget {
  const EduSelfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      scaffoldMessengerKey: AppToast.scaffoldMessengerKey,
      routerConfig: router,
    );
  }
}
