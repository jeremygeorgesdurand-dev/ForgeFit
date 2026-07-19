import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/domain/entities/muscle_group.dart';
import 'package:forgefit/domain/entities/progress.dart';
import 'package:forgefit/domain/entities/workout_session.dart';
import 'package:forgefit/domain/services/achievement_calculator.dart';

WorkoutSession _completedSession(DateTime date, {double volume = 0}) {
  return WorkoutSession(
    id: 's-${date.toIso8601String()}',
    userId: 'u',
    startedAt: date,
    endedAt: date.add(const Duration(minutes: 45)),
    status: SessionStatus.completed,
    exercises: volume == 0
        ? const []
        : [
            WorkoutSessionExercise(
              exerciseId: 'bench',
              order: 0,
              sets: [
                SetLog(
                  id: 'set-${date.toIso8601String()}',
                  setIndex: 0,
                  targetReps: 10,
                  actualReps: 10,
                  weightKg: volume / 10,
                  completedAt: date,
                  restTakenSec: 90,
                ),
              ],
            ),
          ],
  );
}

void main() {
  test('no history unlocks nothing', () {
    final achievements = AchievementCalculator.compute(
      sessions: [],
      records: [],
      muscleScores: [],
    );
    expect(achievements.every((a) => !a.unlocked), isTrue);
  });

  test('a single completed session unlocks "Premier pas" but not "Régulier"', () {
    final achievements = AchievementCalculator.compute(
      sessions: [_completedSession(DateTime(2026, 1, 1))],
      records: [],
      muscleScores: [],
    );
    final byId = {for (final a in achievements) a.id: a};
    expect(byId['sessions_1']!.unlocked, isTrue);
    expect(byId['sessions_10']!.unlocked, isFalse);
    expect(byId['sessions_10']!.progress, closeTo(0.1, 0.001));
  });

  test('cumulative volume across sessions unlocks the volume milestone', () {
    final achievements = AchievementCalculator.compute(
      sessions: [
        _completedSession(DateTime(2026, 1, 1), volume: 6000),
        _completedSession(DateTime(2026, 1, 8), volume: 5000),
      ],
      records: [],
      muscleScores: [],
    );
    final byId = {for (final a in achievements) a.id: a};
    expect(byId['volume_10t']!.unlocked, isTrue);
    expect(byId['volume_100t']!.unlocked, isFalse);
  });

  test('reaching gold on a muscle group unlocks rank_gold but not rank_diamond', () {
    final achievements = AchievementCalculator.compute(
      sessions: [],
      records: [],
      muscleScores: [
        MuscleGroupScore(
          userId: 'u',
          muscleGroup: MuscleGroup.chest,
          score: 60,
          confidence: 1,
          lastComputedAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    final byId = {for (final a in achievements) a.id: a};
    expect(byId['rank_gold']!.unlocked, isTrue);
    expect(byId['rank_diamond']!.unlocked, isFalse);
  });

  test('rank_balanced requires every trained group to be at least bronze', () {
    final mixed = AchievementCalculator.compute(
      sessions: [],
      records: [],
      muscleScores: [
        MuscleGroupScore(
          userId: 'u',
          muscleGroup: MuscleGroup.chest,
          score: 60,
          confidence: 1,
          lastComputedAt: DateTime(2026, 1, 1),
        ),
        MuscleGroupScore(
          userId: 'u',
          muscleGroup: MuscleGroup.back,
          score: 5,
          confidence: 1,
          lastComputedAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    expect({for (final a in mixed) a.id: a}['rank_balanced']!.unlocked, isFalse);

    final balanced = AchievementCalculator.compute(
      sessions: [],
      records: [],
      muscleScores: [
        MuscleGroupScore(
          userId: 'u',
          muscleGroup: MuscleGroup.chest,
          score: 60,
          confidence: 1,
          lastComputedAt: DateTime(2026, 1, 1),
        ),
        MuscleGroupScore(
          userId: 'u',
          muscleGroup: MuscleGroup.back,
          score: 20,
          confidence: 1,
          lastComputedAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    expect({for (final a in balanced) a.id: a}['rank_balanced']!.unlocked, isTrue);
  });

  test('achievement ids are unique', () {
    final achievements = AchievementCalculator.compute(sessions: [], records: [], muscleScores: []);
    final ids = achievements.map((a) => a.id).toSet();
    expect(ids.length, achievements.length);
  });
}
