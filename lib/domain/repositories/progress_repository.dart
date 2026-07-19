import '../entities/progress.dart';

/// Derived/computed data (PRs, per-exercise index, per-muscle-group score,
/// period snapshots). Implementations recompute these from WorkoutRepository
/// history — they are never the source of truth and can always be rebuilt.
abstract class ProgressRepository {
  Future<List<PersonalRecord>> getRecords(String userId, {String? exerciseId});
  Future<ExercisePerformanceIndex?> getPerformanceIndex(
    String userId,
    String exerciseId,
  );
  Future<List<MuscleGroupScore>> getMuscleGroupScores(String userId);
  Future<ProgressSnapshot> getSnapshot({
    required String userId,
    required DateTime periodStart,
    required DateTime periodEnd,
  });
  Future<void> recomputeAll(String userId);
}
