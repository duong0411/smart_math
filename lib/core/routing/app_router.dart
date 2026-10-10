import 'package:eduself_study_app/features/math_ai/presentation/pages/math_home_page.dart';
import 'package:eduself_study_app/features/math_ai/presentation/pages/math_monitor_page.dart';
import 'package:eduself_study_app/features/math_ai/presentation/pages/math_practice_page.dart';
import 'package:eduself_study_app/features/math_ai/presentation/pages/math_settings_page.dart';
import 'package:eduself_study_app/features/math_ai/presentation/pages/math_tutor_chat_page.dart';
import 'package:eduself_study_app/features/math_ai/presentation/pages/math_tutor_sessions_page.dart';
import 'package:eduself_study_app/features/math_games/presentation/pages/boss_battle_game_page.dart';
import 'package:eduself_study_app/features/math_games/presentation/pages/math_games_hub_page.dart';
import 'package:eduself_study_app/features/math_games/presentation/pages/rocket_rush_game_page.dart';
import 'package:eduself_study_app/features/math_games/presentation/pages/treasure_trail_game_page.dart';
import 'package:eduself_study_app/shared/utils/supported_grades.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

int _gradeFromQuery(GoRouterState state) {
  final raw = state.uri.queryParameters['grade'];
  return SupportedGrades.normalize(int.tryParse(raw ?? ''));
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const MathHomePage(),
      ),
      GoRoute(
        path: '/tutor',
        builder: (context, state) => const MathTutorSessionsPage(),
      ),
      GoRoute(
        path: '/tutor/:sessionId',
        builder: (context, state) {
          final id = state.pathParameters['sessionId']!;
          return MathTutorChatPage(sessionId: id);
        },
      ),
      GoRoute(
        path: '/practice',
        builder: (context, state) => const MathPracticePage(),
      ),
      GoRoute(
        path: '/monitor',
        builder: (context, state) => const MathMonitorPage(),
      ),
      GoRoute(
        path: '/games',
        builder: (context, state) => const MathGamesHubPage(),
      ),
      GoRoute(
        path: '/games/treasure',
        builder: (context, state) => TreasureTrailGamePage(
          gradeLevel: _gradeFromQuery(state),
        ),
      ),
      GoRoute(
        path: '/games/boss',
        builder: (context, state) => BossBattleGamePage(
          gradeLevel: _gradeFromQuery(state),
        ),
      ),
      GoRoute(
        path: '/games/rocket',
        builder: (context, state) => RocketRushGamePage(
          gradeLevel: _gradeFromQuery(state),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const MathSettingsPage(),
      ),
    ],
  );
});
