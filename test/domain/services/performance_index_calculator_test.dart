import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/domain/entities/workout_session.dart';
import 'package:forgefit/domain/services/performance_index_calculator.dart';

WorkoutSession _sessionAt(DateTime startedAt, double weightKg, int reps) {
  return WorkoutSession(
    id: 'session-${startedAt.toIso8601String()}',
    userId: 'u1',
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(hours: 1)),
    status: SessionStatus.completed,
    exercises: [
      WorkoutSessionExercise(
        exerciseId: 'bench',
        order: 0,
        sets: [
          SetLog(
            id: 'set-${startedAt.toIso8601String()}',
            setIndex: 0,
            targetReps: reps,
            actualReps: reps,
            weightKg: weightKg,
            completedAt: startedAt,
            restTakenSec: 90,
          ),
        ],
      ),
    ],
  );
}

void main() {
  final now = DateTime.now();

  test('best1RM reflects the highest estimated 1RM across all sessions', () {
    final sessions = [
      _sessionAt(now.subtract(const Duration(days: 10)), 60, 8),
      _sessionAt(now.subtract(const Duration(days: 3)), 70, 8),
    ];

    final index = PerformanceIndexCalculator.compute(
      userId: 'u1',
      exerciseId: 'bench',
      sessions: sessions,
    );

    expect(index.best1RM, greaterThan(70));
    expect(index.lastPerformedAt, sessions.last.startedAt);
  });

  test('trend is up when recent 4-week volume clearly exceeds the prior 4 weeks', () {
    final sessions = [
      _sessionAt(now.subtract(const Duration(days: 40)), 40, 8), // prior window
      _sessionAt(now.subtract(const Duration(days: 5)), 80, 8), // recent window
    ];

    final index = PerformanceIndexCalculator.compute(
      userId: 'u1',
      exerciseId: 'bench',
      sessions: sessions,
    );

    expect(index.trend, 1);
  });

  test('trend is flat when there is no session history for the exercise', () {
    final index = PerformanceIndexCalculator.compute(
      userId: 'u1',
      exerciseId: 'bench',
      sessions: const [],
    );

    expect(index.trend, 0);
    expect(index.best1RM, 0);
    expect(index.lastPerformedAt, isNull);
  });
}
