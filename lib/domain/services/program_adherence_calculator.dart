import '../entities/training_program.dart';
import '../entities/workout_session.dart';

/// How closely completed sessions have tracked the program's intended
/// weekly frequency since it was saved.
class ProgramAdherence {
  final int expectedSessions;
  final int completedSessions;
  final DateTime? lastSessionAt;

  const ProgramAdherence({
    required this.expectedSessions,
    required this.completedSessions,
    this.lastSessionAt,
  });

  /// Null before any session is expected yet (program saved less than a
  /// week ago at the target frequency) — there's nothing meaningful to
  /// rate yet, so the UI should show a neutral "just started" state.
  double? get adherenceRatio =>
      expectedSessions == 0 ? null : completedSessions / expectedSessions;
}

class ProgramAdherenceCalculator {
  ProgramAdherenceCalculator._();

  /// [history] should be the user's full session history (any templates) —
  /// this filters down to sessions started on/after [program.createdAt]
  /// against one of the program's own template ids.
  static ProgramAdherence compute({
    required TrainingProgram program,
    required List<WorkoutSession> history,
    required int weeklyFrequencyTarget,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final templateIds = program.templateIds.toSet();

    final matched = history.where(
      (s) =>
          s.status == SessionStatus.completed &&
          s.templateId != null &&
          templateIds.contains(s.templateId) &&
          !s.startedAt.isBefore(program.createdAt),
    );

    DateTime? lastSessionAt;
    for (final s in matched) {
      if (lastSessionAt == null || s.startedAt.isAfter(lastSessionAt)) {
        lastSessionAt = s.startedAt;
      }
    }

    final daysElapsed = currentTime.difference(program.createdAt).inDays;
    final weeksElapsed = daysElapsed / 7;
    final expectedSessions = (weeklyFrequencyTarget * weeksElapsed).floor().clamp(0, 1 << 30);

    return ProgramAdherence(
      expectedSessions: expectedSessions,
      completedSessions: matched.length,
      lastSessionAt: lastSessionAt,
    );
  }
}
