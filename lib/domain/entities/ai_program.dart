import 'user_profile.dart';
import 'workout_template.dart';

/// One training day within a generated program — same shape as a
/// [WorkoutTemplateExercise] list so a day can be turned into a real
/// [WorkoutTemplate] with no conversion logic.
class ProgramDay {
  final String name;
  final List<WorkoutTemplateExercise> exercises;

  const ProgramDay({required this.name, required this.exercises});
}

/// A single generated weekly cycle — rule-based only (PARTIE 6), never
/// persisted as-is: the user turns individual [ProgramDay]s into
/// [WorkoutTemplate]s, which is what actually gets saved.
class AIProgram {
  final String name;
  final TrainingGoal goal;
  final TrainingLevel level;
  final List<ProgramDay> days;

  const AIProgram({
    required this.name,
    required this.goal,
    required this.level,
    required this.days,
  });
}
