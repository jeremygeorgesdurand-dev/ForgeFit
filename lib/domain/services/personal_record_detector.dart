import '../entities/progress.dart';
import '../entities/workout_session.dart';

/// Epley-based estimated 1RM and best-of heuristics for PR detection.
/// See PARTIE 6 of the design doc for rationale.
class PersonalRecordDetector {
  static double estimated1RM(double weightKg, int reps) {
    if (reps <= 1) return weightKg;
    return weightKg * (1 + reps / 30);
  }

  static List<PersonalRecord> detectAll(
    String userId,
    List<WorkoutSession> completedSessionsChronological,
  ) {
    final sessions = [...completedSessionsChronological]
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    final bestWeightByExercise = <String, double>{};
    final best1RMByExercise = <String, double>{};
    final bestVolumeByExercise = <String, double>{};
    final records = <PersonalRecord>[];

    for (final session in sessions) {
      for (final sessionExercise in session.exercises) {
        double sessionVolume = 0;
        for (final set in sessionExercise.sets) {
          if (set.isWarmup) continue;
          sessionVolume += set.volume;

          final est1RM = estimated1RM(set.weightKg, set.actualReps);
          final bestWeight = bestWeightByExercise[sessionExercise.exerciseId] ?? 0;
          final best1RM = best1RMByExercise[sessionExercise.exerciseId] ?? 0;

          if (set.weightKg > bestWeight) {
            bestWeightByExercise[sessionExercise.exerciseId] = set.weightKg;
            records.add(PersonalRecord(
              userId: userId,
              exerciseId: sessionExercise.exerciseId,
              type: RecordType.maxWeight,
              value: set.weightKg,
              achievedAt: set.completedAt,
              sessionId: session.id,
            ));
          }
          if (est1RM > best1RM) {
            best1RMByExercise[sessionExercise.exerciseId] = est1RM;
            records.add(PersonalRecord(
              userId: userId,
              exerciseId: sessionExercise.exerciseId,
              type: RecordType.estimated1RM,
              value: est1RM,
              achievedAt: set.completedAt,
              sessionId: session.id,
            ));
          }
        }

        final bestVolume = bestVolumeByExercise[sessionExercise.exerciseId] ?? 0;
        if (sessionVolume > bestVolume) {
          bestVolumeByExercise[sessionExercise.exerciseId] = sessionVolume;
          records.add(PersonalRecord(
            userId: userId,
            exerciseId: sessionExercise.exerciseId,
            type: RecordType.maxVolume,
            value: sessionVolume,
            achievedAt: session.endedAt ?? session.startedAt,
            sessionId: session.id,
          ));
        }
      }
    }
    return records;
  }
}
