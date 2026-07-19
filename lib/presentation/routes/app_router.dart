import 'package:go_router/go_router.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_template.dart';
import '../features/achievements/achievements_screen.dart';
import '../features/body_metrics/body_metrics_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/exercise_detail/exercise_detail_screen.dart';
import '../features/history/history_screen.dart';
import '../features/history/session_detail_screen.dart';
import '../features/library/exercise_picker_screen.dart';
import '../features/library/library_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_edit_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/programs/programs_screen.dart';
import '../features/records/records_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/workout_builder/template_editor_screen.dart';
import '../features/workout_builder/workout_builder_screen.dart';
import '../features/workout_session/session_summary_screen.dart';
import '../features/workout_session/workout_session_screen.dart';
import 'app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(path: '/programs', builder: (context, state) => const ProgramsScreen()),
    GoRoute(path: '/records', builder: (context, state) => const RecordsScreen()),
    GoRoute(path: '/achievements', builder: (context, state) => const AchievementsScreen()),
    GoRoute(
      path: '/exercise-picker',
      builder: (context, state) => const ExercisePickerScreen(),
    ),
    GoRoute(
      path: '/live/summary',
      builder: (context, state) => SessionSummaryScreen(
        session: state.extra as WorkoutSession,
      ),
    ),
    ShellRoute(
      builder: (context, state, child) {
        final index = _tabIndexFor(state.uri.path);
        return AppShell(
          currentIndex: index,
          onTabSelected: (i) => context.go(_tabPaths[i]),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => ExerciseDetailScreen(
                exerciseId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/builder',
          builder: (context, state) => const WorkoutBuilderScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const TemplateEditorScreen(),
            ),
            GoRoute(
              path: ':id/edit',
              builder: (context, state) => TemplateEditorScreen(
                template: state.extra as WorkoutTemplate?,
              ),
            ),
          ],
        ),
        GoRoute(path: '/live', builder: (context, state) => const WorkoutSessionScreen()),
        GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => ProfileEditScreen(
                profile: state.extra as UserProfile,
              ),
            ),
            GoRoute(
              path: 'body-metrics',
              builder: (context, state) => const BodyMetricsScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
          routes: [
            GoRoute(
              path: 'detail',
              builder: (context, state) => SessionDetailScreen(
                session: state.extra as WorkoutSession,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

const _tabPaths = ['/library', '/builder', '/live', '/dashboard', '/profile'];

int _tabIndexFor(String path) {
  for (var i = 0; i < _tabPaths.length; i++) {
    if (path.startsWith(_tabPaths[i])) return i;
  }
  return 0;
}
