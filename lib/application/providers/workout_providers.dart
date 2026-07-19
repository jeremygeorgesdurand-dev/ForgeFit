import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_template.dart';
import 'repository_providers.dart';
import 'user_providers.dart';

final templatesProvider = FutureProvider<List<WorkoutTemplate>>((ref) async {
  return ref.watch(workoutRepositoryProvider).getTemplates(localUserId);
});

final historyProvider = FutureProvider<List<WorkoutSession>>((ref) async {
  return ref.watch(workoutRepositoryProvider).getHistory(localUserId);
});

final lastSimilarSessionProvider =
    FutureProvider.family<WorkoutSession?, WorkoutSession>((ref, current) async {
  return ref
      .watch(workoutRepositoryProvider)
      .findLastSimilarSession(userId: localUserId, current: current);
});

/// Most recent completed occurrence of a given exercise — drives the
/// "dernière fois vs aujourd'hui" comparison shown live during a set
/// (PARTIE 4/7), not just in the end-of-session recap.
final lastPerformanceForExerciseProvider =
    FutureProvider.family<WorkoutSessionExercise?, String>((ref, exerciseId) async {
  final history = await ref.watch(workoutRepositoryProvider).getHistory(localUserId, limit: 200);
  for (final session in history) {
    if (session.status != SessionStatus.completed) continue;
    for (final se in session.exercises) {
      if (se.exerciseId == exerciseId && se.sets.isNotEmpty) return se;
    }
  }
  return null;
});
