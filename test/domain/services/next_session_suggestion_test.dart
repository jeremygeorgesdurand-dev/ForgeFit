import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/domain/entities/workout_session.dart';
import 'package:forgefit/domain/entities/workout_template.dart';
import 'package:forgefit/domain/services/next_session_suggestion.dart';

SetLog _set({required int targetReps, required int actualReps, double? rpe}) {
  return SetLog(
    id: 'set-$actualReps-$rpe',
    setIndex: 0,
    targetReps: targetReps,
    actualReps: actualReps,
    weightKg: 60,
    rpe: rpe,
    completedAt: DateTime(2026, 1, 1),
    restTakenSec: 90,
  );
}

void main() {
  const targetRepRange = RepRange(8, 12);

  test('suggests a maintain when there are no working sets', () {
    const exercise = WorkoutSessionExercise(exerciseId: 'bench', order: 0, sets: []);

    final suggestion = NextSessionSuggestionService.suggest(
      lastExercise: exercise,
      targetRepRange: targetRepRange,
      lastWeightKg: 60,
    );

    expect(suggestion.action, SuggestionAction.maintain);
  });

  test('suggests increasing load when every set hit the top of the range with low RPE', () {
    final exercise = WorkoutSessionExercise(
      exerciseId: 'bench',
      order: 0,
      sets: [
        _set(targetReps: 12, actualReps: 12, rpe: 7),
        _set(targetReps: 12, actualReps: 12, rpe: 8),
      ],
    );

    final suggestion = NextSessionSuggestionService.suggest(
      lastExercise: exercise,
      targetRepRange: targetRepRange,
      lastWeightKg: 60,
    );

    expect(suggestion.action, SuggestionAction.increaseLoad);
    expect(suggestion.suggestedWeightKg, 62.5);
  });

  test('uses a percentage increment for machine exercises instead of a flat +2.5kg', () {
    final exercise = WorkoutSessionExercise(
      exerciseId: 'leg-press',
      order: 0,
      sets: [_set(targetReps: 12, actualReps: 12, rpe: 7)],
    );

    final suggestion = NextSessionSuggestionService.suggest(
      lastExercise: exercise,
      targetRepRange: targetRepRange,
      lastWeightKg: 100,
      isMachine: true,
    );

    expect(suggestion.action, SuggestionAction.increaseLoad);
    expect(suggestion.suggestedWeightKg, 105);
  });

  test('suggests decreasing load by 10% when a set fell short of its target reps', () {
    final exercise = WorkoutSessionExercise(
      exerciseId: 'bench',
      order: 0,
      sets: [_set(targetReps: 10, actualReps: 7)],
    );

    final suggestion = NextSessionSuggestionService.suggest(
      lastExercise: exercise,
      targetRepRange: targetRepRange,
      lastWeightKg: 60,
    );

    expect(suggestion.action, SuggestionAction.decreaseLoad);
    expect(suggestion.suggestedWeightKg, 54);
  });

  test('maintains load when performance was solid but not at the top of the range', () {
    final exercise = WorkoutSessionExercise(
      exerciseId: 'bench',
      order: 0,
      sets: [_set(targetReps: 10, actualReps: 10, rpe: 8)],
    );

    final suggestion = NextSessionSuggestionService.suggest(
      lastExercise: exercise,
      targetRepRange: targetRepRange,
      lastWeightKg: 60,
    );

    expect(suggestion.action, SuggestionAction.maintain);
    expect(suggestion.suggestedWeightKg, 60);
  });
}
