import '../entities/progress.dart';
import '../entities/workout_session.dart';
import 'personal_record_detector.dart';

/// Computes the derived per-exercise performance index used to drive
/// next-session weight/rep suggestions and muscle-group scoring.
class PerformanceIndexCalculator {
  static ExercisePerformanceIndex compute({
    required String userId,
    required String exerciseId,
    required List<WorkoutSession> sessions,
  }) {
    final now = DateTime.now();
    final fourWeeksAgo = now.subtract(const Duration(days: 28));
    final eightWeeksAgo = now.subtract(const Duration(days: 56));

    double best1RM = 0;
    double recentVolume = 0;
    double priorVolume = 0;
    DateTime? lastPerformedAt;

    for (final session in sessions) {
      for (final se in session.exercises) {
        if (se.exerciseId != exerciseId) continue;
        lastPerformedAt = lastPerformedAt == null || session.startedAt.isAfter(lastPerformedAt)
            ? session.startedAt
            : lastPerformedAt;

        for (final set in se.sets) {
          if (set.isWarmup) continue;
          final est1RM = PersonalRecordDetector.estimated1RM(set.weightKg, set.actualReps);
          if (est1RM > best1RM) best1RM = est1RM;
        }

        if (session.startedAt.isAfter(fourWeeksAgo)) {
          recentVolume += se.totalVolume;
        } else if (session.startedAt.isAfter(eightWeeksAgo)) {
          priorVolume += se.totalVolume;
        }
      }
    }

    int trend = 0;
    if (recentVolume > priorVolume * 1.05) {
      trend = 1;
    } else if (recentVolume < priorVolume * 0.95) {
      trend = -1;
    }

    return ExercisePerformanceIndex(
      userId: userId,
      exerciseId: exerciseId,
      best1RM: best1RM,
      avgVolumeLast4Weeks: recentVolume,
      trend: trend,
      lastPerformedAt: lastPerformedAt,
    );
  }
}
