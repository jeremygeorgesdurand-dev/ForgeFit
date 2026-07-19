import 'dart:math';

import '../entities/muscle_group.dart';
import '../entities/progress.dart';
import '../entities/workout_session.dart';

/// Estimates a 0..100 "level" per muscle group from real training history:
/// weighted contribution of exercises targeting that group (primary x1.0,
/// secondary x0.4), exponentially decayed by recency (21-day half-life).
/// Confidence is low when fewer than 3 sessions touched the group in 60
/// days — surfaced in the UI as "estimation faible".
class MuscleGroupScoreCalculator {
  static const _halfLifeDays = 21.0;
  static const _minSessionsForConfidence = 3;
  static const _lookbackDays = 60;

  static List<MuscleGroupScore> compute({
    required String userId,
    required List<WorkoutSession> sessions,
    required MuscleGroup Function(String exerciseId) primaryMuscleOf,
    required List<MuscleGroup> Function(String exerciseId) secondaryMusclesOf,
  }) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: _lookbackDays));

    final weightedVolume = <MuscleGroup, double>{};
    final sessionCount = <MuscleGroup, Set<String>>{};

    for (final session in sessions) {
      if (session.startedAt.isBefore(cutoff)) continue;
      final ageDays = now.difference(session.startedAt).inHours / 24.0;
      final decay = pow(0.5, ageDays / _halfLifeDays).toDouble();

      for (final se in session.exercises) {
        final primary = primaryMuscleOf(se.exerciseId);
        final secondaries = secondaryMusclesOf(se.exerciseId);
        final volume = se.totalVolume;

        weightedVolume[primary] = (weightedVolume[primary] ?? 0) + volume * decay * 1.0;
        (sessionCount[primary] ??= {}).add(session.id);

        for (final s in secondaries) {
          weightedVolume[s] = (weightedVolume[s] ?? 0) + volume * decay * 0.4;
          (sessionCount[s] ??= {}).add(session.id);
        }
      }
    }

    if (weightedVolume.isEmpty) return [];

    final maxVolume = weightedVolume.values.reduce(max);
    final scores = <MuscleGroupScore>[];

    for (final group in weightedVolume.keys) {
      final normalized = maxVolume == 0 ? 0.0 : (weightedVolume[group]! / maxVolume) * 100;
      final sessions = sessionCount[group]?.length ?? 0;
      final confidence = min(1.0, sessions / _minSessionsForConfidence);

      scores.add(MuscleGroupScore(
        userId: userId,
        muscleGroup: group,
        score: normalized,
        confidence: confidence,
        lastComputedAt: now,
      ));
    }
    return scores;
  }
}
