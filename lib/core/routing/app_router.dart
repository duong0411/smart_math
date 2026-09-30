import 'package:eduself_study_app/features/math_ai/presentation/pages/math_home_page.dart';
import 'package:eduself_study_app/features/math_ai/presentation/pages/math_monitor_page.dart';
import 'package:eduself_study_app/features/math_ai/presentation/pages/math_practice_page.dart';
import 'package:eduself_study_app/features/math_ai/presentation/pages/math_settings_page.dart';
import 'package:eduself_study_app/features/math_ai/presentation/pages/math_tutor_chat_page.dart';
import 'package:eduself_study_app/features/math_ai/presentation/pages/math_tutor_sessions_page.dart';
import 'package:eduself_study_app/features/math_games/presentation/pages/bubble_pop_game_page.dart';
import 'package:eduself_study_app/features/math_games/presentation/pages/match_pairs_game_page.dart';
import 'package:eduself_study_app/features/math_games/presentation/pages/math_games_hub_page.dart';
import 'package:eduself_study_app/features/math_games/presentation/pages/speed_calc_game_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        path: '/games/speed',
        builder: (context, state) => const SpeedCalcGamePage(),
      ),
      GoRoute(
        path: '/games/bubbles',
        builder: (context, state) => const BubblePopGamePage(),
      ),
      GoRoute(
        path: '/games/match',
        builder: (context, state) => const MatchPairsGamePage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const MathSettingsPage(),
      ),
    ],
  );
});
