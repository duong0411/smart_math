import 'package:eduself_study_app/features/assessments/presentation/pages/assessment_attempt_page.dart';
import 'package:eduself_study_app/features/assessments/presentation/pages/assessment_detail_page.dart';
import 'package:eduself_study_app/features/assessments/presentation/pages/assessment_editor_page.dart';
import 'package:eduself_study_app/features/assessments/presentation/pages/assessment_result_page.dart';
import 'package:eduself_study_app/features/assessments/presentation/pages/assessments_page.dart';
import 'package:eduself_study_app/features/assessments/presentation/pages/grade_attempt_page.dart';
import 'package:eduself_study_app/features/assessments/presentation/pages/teacher_assessments_page.dart';
import 'package:eduself_study_app/features/auth/presentation/pages/home_page.dart';
import 'package:eduself_study_app/features/auth/presentation/pages/login_page.dart';
import 'package:eduself_study_app/features/auth/presentation/pages/register_page.dart';
import 'package:eduself_study_app/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:eduself_study_app/features/classrooms/presentation/pages/assignment_progress_page.dart';
import 'package:eduself_study_app/features/classrooms/presentation/pages/classroom_detail_page.dart';
import 'package:eduself_study_app/features/classrooms/presentation/pages/classrooms_page.dart';
import 'package:eduself_study_app/features/curriculum/presentation/pages/curriculum_page.dart';
import 'package:eduself_study_app/features/exam_matrices/presentation/pages/exam_matrices_page.dart';
import 'package:eduself_study_app/features/exam_matrices/presentation/pages/exam_matrix_detail_page.dart';
import 'package:eduself_study_app/features/exam_matrices/presentation/pages/matrix_coverage_page.dart';
import 'package:eduself_study_app/features/homework_capture/presentation/pages/homework_capture_page.dart';
import 'package:eduself_study_app/features/ipa/presentation/pages/ipa_page.dart';
import 'package:eduself_study_app/features/library/presentation/pages/library_page.dart';
import 'package:eduself_study_app/features/library/presentation/pages/library_reader_page.dart';
import 'package:eduself_study_app/features/parents/presentation/pages/child_detail_page.dart';
import 'package:eduself_study_app/features/parents/presentation/pages/weekly_report_detail_page.dart';
import 'package:eduself_study_app/features/progress/presentation/pages/progress_page.dart';
import 'package:eduself_study_app/features/settings/presentation/pages/about_page.dart';
import 'package:eduself_study_app/features/settings/presentation/pages/settings_page.dart';
import 'package:eduself_study_app/features/student/presentation/pages/profile_page.dart';
import 'package:eduself_study_app/features/study_tools/presentation/pages/flashcard_study_page.dart';
import 'package:eduself_study_app/features/study_tools/presentation/pages/mindmap_viewer_page.dart';
import 'package:eduself_study_app/features/study_tools/presentation/pages/study_tools_page.dart';
import 'package:eduself_study_app/features/tutoring/presentation/pages/tutoring_chat_page.dart';
import 'package:eduself_study_app/features/tutoring/presentation/pages/tutoring_sessions_page.dart';
import 'package:eduself_study_app/shared/navigation/app_destinations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authSessionProvider, (_, next) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    // No shared GlobalKey — recreating GoRouter must not reuse a disposed key.
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(authSessionProvider);
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (session.isLoading) return null;

      final user = session.valueOrNull;
      final signedIn = user != null;

      if (!signedIn && !loggingIn) return '/login';
      if (signedIn && loggingIn) return '/home';

      final loc = state.matchedLocation;
      if (signedIn) {
        if (loc == '/teachers' || loc == '/parents') {
          return '/home';
        }
        if (!AppDestinations.isAllowedRoute(user.role, loc)) {
          return '/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/tutoring',
        builder: (context, state) => const TutoringSessionsPage(),
      ),
      GoRoute(
        path: '/tutoring/:sessionId',
        builder: (context, state) {
          final sessionId = int.parse(state.pathParameters['sessionId']!);
          return TutoringChatPage(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/curriculum',
        builder: (context, state) => const CurriculumPage(),
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryPage(),
      ),
      GoRoute(
        path: '/library/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return LibraryReaderPage(documentId: id);
        },
      ),
      GoRoute(
        path: '/study-tools',
        builder: (context, state) => const StudyToolsPage(),
      ),
      GoRoute(
        path: '/study-tools/decks/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return FlashcardStudyPage(deckId: id);
        },
      ),
      GoRoute(
        path: '/study-tools/mindmaps/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return MindmapViewerPage(mindmapId: id);
        },
      ),
      GoRoute(
        path: '/ipa',
        builder: (context, state) => const IpaPage(),
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressPage(),
      ),
      GoRoute(
        path: '/assessments',
        builder: (context, state) => const AssessmentsPage(),
      ),
      GoRoute(
        path: '/classrooms',
        builder: (context, state) => const ClassroomsPage(),
      ),
      GoRoute(
        path: '/classrooms/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ClassroomDetailPage(classroomId: id);
        },
      ),
      GoRoute(
        path: '/classrooms/:id/assignments/:assignmentId/progress',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final assignmentId =
              int.parse(state.pathParameters['assignmentId']!);
          return AssignmentProgressPage(
            classroomId: id,
            assignmentId: assignmentId,
          );
        },
      ),
      GoRoute(
        path: '/assessments/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AssessmentDetailPage(assessmentId: id);
        },
      ),
      GoRoute(
        path: '/assessments/:id/attempt',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AssessmentAttemptPage(assessmentId: id);
        },
      ),
      GoRoute(
        path: '/assessments/attempts/:attemptId/result',
        builder: (context, state) {
          final attemptId = int.parse(state.pathParameters['attemptId']!);
          return AssessmentResultPage(attemptId: attemptId);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/homework-capture',
        builder: (context, state) => const HomeworkCapturePage(),
      ),
      GoRoute(
        path: '/parents',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/parents/children/:studentId',
        builder: (context, state) {
          final studentId = int.parse(state.pathParameters['studentId']!);
          return ChildDetailPage(studentId: studentId);
        },
      ),
      GoRoute(
        path: '/parents/reports/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return WeeklyReportDetailPage(reportId: id);
        },
      ),
      GoRoute(
        path: '/teachers',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/teachers/assessments',
        builder: (context, state) => const TeacherAssessmentsPage(),
      ),
      GoRoute(
        path: '/teachers/assessments/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AssessmentEditorPage(assessmentId: id);
        },
      ),
      GoRoute(
        path: '/teachers/grading',
        builder: (context, state) => const TeacherGradingPage(),
      ),
      GoRoute(
        path: '/teachers/grading/attempts/:attemptId',
        builder: (context, state) {
          final attemptId = int.parse(state.pathParameters['attemptId']!);
          return GradeAttemptPage(attemptId: attemptId);
        },
      ),
      GoRoute(
        path: '/exam-matrices',
        builder: (context, state) => const ExamMatricesPage(),
      ),
      GoRoute(
        path: '/exam-matrices/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ExamMatrixDetailPage(matrixId: id);
        },
      ),
      GoRoute(
        path: '/exam-matrices/:id/coverage',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return MatrixCoveragePage(matrixId: id);
        },
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
