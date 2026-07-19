import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/domain/entities/workout_session.dart';
import 'package:forgefit/domain/services/plateau_detector.dart';

WorkoutSession _sessionWithBench(DateTime date, double weight, int reps) {
  return WorkoutSession(
    id: 's-${date.toIso8601String()}',
    userId: 'u',
    startedAt: date,
    endedAt: date.add(const Duration(minutes: 45)),
    status: SessionStatus.completed,
    exercises: [
      WorkoutSessionExercise(
        exerciseId: 'bench',
        order: 0,
        sets: [
          SetLog(
            id: 'set-${date.toIso8601String()}',
            setIndex: 0,
            targetReps: reps,
            actualReps: reps,
            weightKg: weight,
            completedAt: date,
            restTakenSec: 90,
          ),
        ],
      ),
    ],
  );
}

void main() {
  test('not enough sessions yet -> no plateau flagged', () {
    final sessions = [
      _sessionWithBench(DateTime(2026, 1, 1), 60, 8),
      _sessionWithBench(DateTime(2026, 1, 8), 62, 8),
    ];
    final status = PlateauDetector.detect(exerciseId: 'bench', sessions: sessions);
    expect(status.isPlateaued, isFalse);
  });

  test('flat estimated 1RM across recent sessions is flagged as a plateau', () {
    final sessions = [
      _sessionWithBench(DateTime(2026, 1, 1), 60, 8),
      _sessionWithBench(DateTime(2026, 1, 8), 60, 8),
      _sessionWithBench(DateTime(2026, 1, 15), 60, 8),
      _sessionWithBench(DateTime(2026, 1, 22), 60, 8),
    ];
    final status = PlateauDetector.detect(exerciseId: 'bench', sessions: sessions);
    expect(status.isPlateaued, isTrue);
    expect(status.sessionsConsidered, 4);
  });

  test('clear progression across recent sessions is not a plateau', () {
    final sessions = [
      _sessionWithBench(DateTime(2026, 1, 1), 60, 8),
      _sessionWithBench(DateTime(2026, 1, 8), 65, 8),
      _sessionWithBench(DateTime(2026, 1, 15), 70, 8),
      _sessionWithBench(DateTime(2026, 1, 22), 75, 8),
    ];
    final status = PlateauDetector.detect(exerciseId: 'bench', sessions: sessions);
    expect(status.isPlateaued, isFalse);
  });

  test('warmup sets are ignored when computing the best estimated 1RM', () {
    final warmupOnlySession = WorkoutSession(
      id: 's-warmup',
      userId: 'u',
      startedAt: DateTime(2026, 1, 29),
      status: SessionStatus.completed,
      exercises: [
        WorkoutSessionExercise(
          exerciseId: 'bench',
          order: 0,
          sets: [
            SetLog(
              id: 'warmup-set',
              setIndex: 0,
              targetReps: 5,
              actualReps: 5,
              weightKg: 100,
              isWarmup: true,
              completedAt: DateTime(2026, 1, 29),
              restTakenSec: 60,
            ),
          ],
        ),
      ],
    );

    final sessions = [
      _sessionWithBench(DateTime(2026, 1, 1), 60, 8),
      _sessionWithBench(DateTime(2026, 1, 8), 60, 8),
      _sessionWithBench(DateTime(2026, 1, 15), 60, 8),
      warmupOnlySession,
    ];
    final status = PlateauDetector.detect(exerciseId: 'bench', sessions: sessions);
    // The 4th session only has a warmup set logged for "bench", so it
    // shouldn't count toward sessionsConsidered.
    expect(status.sessionsConsidered, 3);
  });
}
