import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/domain/entities/muscle_group.dart';
import 'package:forgefit/domain/entities/workout_session.dart';
import 'package:forgefit/domain/services/muscle_group_score_calculator.dart';

WorkoutSession _sessionAt(String id, DateTime startedAt, {double weightKg = 60, int reps = 8}) {
  return WorkoutSession(
    id: id,
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
            id: 'set-$id',
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

  MuscleGroup primaryOf(String id) => MuscleGroup.chest;
  List<MuscleGroup> secondaryOf(String id) => const [MuscleGroup.triceps];

  test('primary muscle scores higher than a secondary-only muscle for the same volume', () {
    final sessions = [
      _sessionAt('s1', now.subtract(const Duration(days: 1))),
      _sessionAt('s2', now.subtract(const Duration(days: 3))),
      _sessionAt('s3', now.subtract(const Duration(days: 5))),
    ];

    final scores = MuscleGroupScoreCalculator.compute(
      userId: 'u1',
      sessions: sessions,
      primaryMuscleOf: primaryOf,
      secondaryMusclesOf: secondaryOf,
    );

    final chest = scores.firstWhere((s) => s.muscleGroup == MuscleGroup.chest);
    final triceps = scores.firstWhere((s) => s.muscleGroup == MuscleGroup.triceps);

    expect(chest.score, greaterThan(triceps.score));
  });

  test('confidence is below 1 with fewer than 3 sessions touching the group', () {
    final sessions = [_sessionAt('s1', now.subtract(const Duration(days: 1)))];

    final scores = MuscleGroupScoreCalculator.compute(
      userId: 'u1',
      sessions: sessions,
      primaryMuscleOf: primaryOf,
      secondaryMusclesOf: secondaryOf,
    );

    final chest = scores.firstWhere((s) => s.muscleGroup == MuscleGroup.chest);
    expect(chest.confidence, lessThan(1));
  });

  test('sessions older than the 60-day lookback are excluded', () {
    final sessions = [_sessionAt('old', now.subtract(const Duration(days: 90)))];

    final scores = MuscleGroupScoreCalculator.compute(
      userId: 'u1',
      sessions: sessions,
      primaryMuscleOf: primaryOf,
      secondaryMusclesOf: secondaryOf,
    );

    expect(scores, isEmpty);
  });
}
