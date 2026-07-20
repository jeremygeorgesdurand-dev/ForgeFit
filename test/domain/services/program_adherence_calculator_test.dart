import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/domain/entities/training_program.dart';
import 'package:forgefit/domain/entities/user_profile.dart';
import 'package:forgefit/domain/entities/workout_session.dart';
import 'package:forgefit/domain/services/program_adherence_calculator.dart';

void main() {
  final program = TrainingProgram(
    id: 'p1',
    userId: 'u1',
    name: 'Push Pull Legs',
    goal: TrainingGoal.hypertrophy,
    level: TrainingLevel.intermediate,
    createdAt: DateTime(2026, 1, 1),
    templateIds: const ['day-a', 'day-b'],
  );

  WorkoutSession session({
    required String? templateId,
    required DateTime startedAt,
    SessionStatus status = SessionStatus.completed,
  }) {
    return WorkoutSession(
      id: 'session-${startedAt.toIso8601String()}',
      userId: 'u1',
      templateId: templateId,
      startedAt: startedAt,
      status: status,
    );
  }

  test('is null (no rating yet) before a full week has elapsed', () {
    final adherence = ProgramAdherenceCalculator.compute(
      program: program,
      history: const [],
      weeklyFrequencyTarget: 3,
      now: DateTime(2026, 1, 3),
    );

    expect(adherence.expectedSessions, 0);
    expect(adherence.adherenceRatio, isNull);
  });

  test('counts only completed sessions on the program\'s own templates, on/after createdAt', () {
    final history = [
      session(templateId: 'day-a', startedAt: DateTime(2026, 1, 2)),
      session(templateId: 'day-b', startedAt: DateTime(2026, 1, 4)),
      // Wrong template — not part of this program.
      session(templateId: 'other-template', startedAt: DateTime(2026, 1, 5)),
      // In progress — doesn't count yet.
      session(
        templateId: 'day-a',
        startedAt: DateTime(2026, 1, 6),
        status: SessionStatus.inProgress,
      ),
      // Before the program existed — a leftover session from an old template
      // id that happens to collide, shouldn't count.
      session(templateId: 'day-a', startedAt: DateTime(2025, 12, 20)),
    ];

    // 2 weeks elapsed at 3x/week target -> 6 expected sessions.
    final adherence = ProgramAdherenceCalculator.compute(
      program: program,
      history: history,
      weeklyFrequencyTarget: 3,
      now: DateTime(2026, 1, 15),
    );

    expect(adherence.expectedSessions, 6);
    expect(adherence.completedSessions, 2);
    expect(adherence.adherenceRatio, closeTo(2 / 6, 0.0001));
    expect(adherence.lastSessionAt, DateTime(2026, 1, 4));
  });

  test('adherenceRatio can exceed 1.0 when the user trains more than the target', () {
    final history = [
      for (var i = 0; i < 10; i++)
        session(templateId: 'day-a', startedAt: DateTime(2026, 1, 1 + i)),
    ];

    final adherence = ProgramAdherenceCalculator.compute(
      program: program,
      history: history,
      weeklyFrequencyTarget: 2,
      now: DateTime(2026, 1, 8),
    );

    expect(adherence.expectedSessions, 2);
    expect(adherence.completedSessions, 10);
    expect(adherence.adherenceRatio, 5.0);
  });
}
