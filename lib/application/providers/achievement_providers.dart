import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/achievement.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/services/achievement_calculator.dart';
import '../../domain/services/muscle_group_score_calculator.dart';
import '../../domain/services/personal_record_detector.dart';
import 'progress_providers.dart';
import 'repository_providers.dart';
import 'user_providers.dart';

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final sessions = await ref.watch(workoutRepositoryProvider).getHistory(localUserId, limit: 5000);
  final records = await ref.watch(personalRecordsProvider.future);
  final muscleScores = await ref.watch(muscleGroupScoresProvider.future);

  return AchievementCalculator.compute(
    sessions: sessions,
    records: records,
    muscleScores: muscleScores,
  );
});

/// Achievements that just flipped from locked to unlocked because of
/// [session] specifically — computed by diffing achievement state with and
/// without that session in the history, the same "before vs after" idea
/// [LiveSessionController] already uses to detect personal records live.
final newlyUnlockedAchievementsProvider =
    FutureProvider.family<List<Achievement>, WorkoutSession>((ref, session) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);

  final allSessions = await workoutRepo.getHistory(localUserId, limit: 5000);
  final completedAll = allSessions.where((s) => s.status == SessionStatus.completed).toList();
  final completedBefore = completedAll.where((s) => s.id != session.id).toList();

  final exercises = await exerciseRepo.getAll();
  final primaryOf = {for (final e in exercises) e.id: e.primaryMuscle};
  final secondaryOf = {for (final e in exercises) e.id: e.secondaryMuscles};

  List<Achievement> computeFor(List<WorkoutSession> sessions) {
    final records = PersonalRecordDetector.detectAll(localUserId, sessions);
    final scores = MuscleGroupScoreCalculator.compute(
      userId: localUserId,
      sessions: sessions,
      primaryMuscleOf: (id) => primaryOf[id] ?? MuscleGroup.unknown,
      secondaryMusclesOf: (id) => secondaryOf[id] ?? const [],
    );
    return AchievementCalculator.compute(sessions: sessions, records: records, muscleScores: scores);
  }

  final beforeUnlocked =
      computeFor(completedBefore).where((a) => a.unlocked).map((a) => a.id).toSet();
  return computeFor(completedAll).where((a) => a.unlocked && !beforeUnlocked.contains(a.id)).toList();
});
