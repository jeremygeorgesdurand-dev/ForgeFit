import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/domain/entities/exercise.dart';
import 'package:forgefit/domain/entities/muscle_group.dart';
import 'package:forgefit/domain/entities/user_profile.dart';
import 'package:forgefit/domain/services/program_generator.dart';

Exercise _exercise(String id, MuscleGroup muscle, String equipment) {
  return Exercise(
    id: id,
    name: id,
    primaryMuscle: muscle,
    equipment: equipment,
    category: muscle.name,
  );
}

final _pool = [
  _exercise('bench-press', MuscleGroup.chest, 'barbell'),
  _exercise('row', MuscleGroup.back, 'barbell'),
  _exercise('squat', MuscleGroup.quads, 'barbell'),
  _exercise('shoulder-press', MuscleGroup.shoulders, 'dumbbell'),
  _exercise('rdl', MuscleGroup.hamstrings, 'dumbbell'),
  _exercise('plank', MuscleGroup.core, 'body weight'),
  _exercise('curl', MuscleGroup.biceps, 'dumbbell'),
  _exercise('pushdown', MuscleGroup.triceps, 'cable'),
  _exercise('wrist-curl', MuscleGroup.forearms, 'dumbbell'),
  _exercise('hip-thrust', MuscleGroup.glutes, 'barbell'),
  _exercise('calf-raise', MuscleGroup.calves, 'body weight'),
];

void main() {
  test('3x/week or fewer produces a full body day for every session', () {
    final program = ProgramGenerator.generate(
      goal: TrainingGoal.hypertrophy,
      level: TrainingLevel.beginner,
      weeklyFrequency: 3,
      availableEquipment: {'barbell', 'dumbbell', 'cable'},
      allExercises: _pool,
    );

    expect(program.days, hasLength(3));
    expect(program.days.every((d) => d.name == 'Full Body'), isTrue);
  });

  test('4x/week alternates upper and lower body days', () {
    final program = ProgramGenerator.generate(
      goal: TrainingGoal.hypertrophy,
      level: TrainingLevel.beginner,
      weeklyFrequency: 4,
      availableEquipment: {'barbell', 'dumbbell', 'cable'},
      allExercises: _pool,
    );

    expect(program.days.map((d) => d.name).toList(), [
      'Haut du corps',
      'Bas du corps',
      'Haut du corps',
      'Bas du corps',
    ]);
  });

  test('5x/week or more rotates push/pull/legs', () {
    final program = ProgramGenerator.generate(
      goal: TrainingGoal.hypertrophy,
      level: TrainingLevel.beginner,
      weeklyFrequency: 5,
      availableEquipment: {'barbell', 'dumbbell', 'cable'},
      allExercises: _pool,
    );

    expect(program.days.map((d) => d.name).toList(), ['Push', 'Pull', 'Legs', 'Push', 'Pull']);
  });

  test('strength goal produces low-rep, high-rest sets', () {
    final program = ProgramGenerator.generate(
      goal: TrainingGoal.strength,
      level: TrainingLevel.advanced,
      weeklyFrequency: 3,
      availableEquipment: {'barbell', 'dumbbell', 'cable'},
      allExercises: _pool,
    );

    final firstExercise = program.days.first.exercises.first;
    expect(firstExercise.targetSets, 5);
    expect(firstExercise.targetRepRange.min, 3);
    expect(firstExercise.targetRepRange.max, 6);
    expect(firstExercise.targetRestSec, 180);
  });

  test('excludes exercises whose equipment was not declared as available', () {
    final program = ProgramGenerator.generate(
      goal: TrainingGoal.hypertrophy,
      level: TrainingLevel.beginner,
      weeklyFrequency: 3,
      availableEquipment: const {}, // only body weight allowed
      allExercises: _pool,
    );

    final allSelectedIds = program.days.expand((d) => d.exercises).map((e) => e.exerciseId);
    expect(allSelectedIds, everyElement(anyOf('plank', 'calf-raise')));
  });
}
