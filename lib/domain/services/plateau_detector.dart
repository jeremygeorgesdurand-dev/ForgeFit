import '../entities/workout_session.dart';
import 'personal_record_detector.dart';

class PlateauStatus {
  final bool isPlateaued;
  final int sessionsConsidered;
  const PlateauStatus({required this.isPlateaued, required this.sessionsConsidered});
}

/// Rule-based plateau signal: tracks the best estimated 1RM per session an
/// exercise was performed, and flags a plateau when the most recent
/// sessions show no meaningful (>2%) improvement over the span — a nudge
/// toward a deload week, never an automatic one.
class PlateauDetector {
  static PlateauStatus detect({
    required String exerciseId,
    required List<WorkoutSession> sessions,
    int lookback = 4,
    int minSessions = 4,
  }) {
    final chronological = [...sessions]..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    final best1RMsPerSession = <double>[];
    for (final session in chronological) {
      if (session.status != SessionStatus.completed) continue;
      double? best;
      for (final se in session.exercises) {
        if (se.exerciseId != exerciseId) continue;
        for (final set in se.sets) {
          if (set.isWarmup) continue;
          final est1RM = PersonalRecordDetector.estimated1RM(set.weightKg, set.actualReps);
          if (best == null || est1RM > best) best = est1RM;
        }
      }
      if (best != null) best1RMsPerSession.add(best);
    }

    if (best1RMsPerSession.length < minSessions) {
      return PlateauStatus(isPlateaued: false, sessionsConsidered: best1RMsPerSession.length);
    }

    final recent = best1RMsPerSession.sublist(best1RMsPerSession.length - lookback);
    final earliest = recent.first;
    final maxRecent = recent.reduce((a, b) => a > b ? a : b);
    final improved = maxRecent > earliest * 1.02;

    return PlateauStatus(isPlateaued: !improved, sessionsConsidered: recent.length);
  }
}
