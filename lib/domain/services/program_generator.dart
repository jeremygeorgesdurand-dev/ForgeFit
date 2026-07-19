import '../entities/ai_program.dart';
import '../entities/exercise.dart';
import '../entities/muscle_group.dart';
import '../entities/user_profile.dart';
import '../entities/workout_template.dart';

class _SetScheme {
  final int sets;
  final int repMin;
  final int repMax;
  final int restSec;
  const _SetScheme(this.sets, this.repMin, this.repMax, this.restSec);
}

/// Local, rule-based program generation — PARTIE 6. No LLM involved: split,
/// sets/reps and exercise selection are all deterministic given goal,
/// level, weekly frequency and available equipment. A server LLM call is
/// only ever meant to layer naming/wording/substitution on top of this —
/// never to decide the numbers.
class ProgramGenerator {
  static AIProgram generate({
    required TrainingGoal goal,
    required TrainingLevel level,
    required int weeklyFrequency,
    required Set<String> availableEquipment,
    required List<Exercise> allExercises,
  }) {
    final scheme = _schemeFor(goal);
    final split = _splitFor(weeklyFrequency);
    final pool = _filterByEquipment(allExercises, availableEquipment);

    final days = <ProgramDay>[];
    for (var i = 0; i < split.length; i++) {
      final dayType = split[i];
      final targets = _targetsFor(dayType);
      final dayExercises = <WorkoutTemplateExercise>[];

      for (var order = 0; order < targets.length; order++) {
        final candidate = _pickExercise(pool, targets[order], excludeIds: {
          for (final e in dayExercises) e.exerciseId,
        });
        if (candidate == null) continue;
        dayExercises.add(
          WorkoutTemplateExercise(
            exerciseId: candidate.id,
            order: order,
            targetSets: scheme.sets,
            targetRepRange: RepRange(scheme.repMin, scheme.repMax),
            targetRestSec: scheme.restSec,
          ),
        );
      }

      days.add(ProgramDay(name: dayType, exercises: dayExercises));
    }

    return AIProgram(
      name: 'Programme ${goal.name} — $weeklyFrequency×/semaine',
      goal: goal,
      level: level,
      days: days,
    );
  }

  static _SetScheme _schemeFor(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.strength:
        return const _SetScheme(5, 3, 6, 180);
      case TrainingGoal.hypertrophy:
        return const _SetScheme(4, 8, 12, 90);
      case TrainingGoal.endurance:
        return const _SetScheme(3, 15, 20, 45);
      case TrainingGoal.fatLoss:
        return const _SetScheme(3, 12, 15, 60);
      case TrainingGoal.generalFitness:
        return const _SetScheme(3, 10, 12, 75);
    }
  }

  /// Deterministic split table (PARTIE 6): ≤3×/week → full body every day;
  /// 4×/week → upper/lower alternation; ≥5×/week → push/pull/legs rotation.
  static List<String> _splitFor(int weeklyFrequency) {
    final freq = weeklyFrequency.clamp(1, 6);
    if (freq <= 3) {
      return List.generate(freq, (_) => 'Full Body');
    }
    if (freq == 4) {
      return ['Haut du corps', 'Bas du corps', 'Haut du corps', 'Bas du corps'];
    }
    const pushPullLegs = ['Push', 'Pull', 'Legs'];
    return List.generate(freq, (i) => pushPullLegs[i % 3]);
  }

  static List<MuscleGroup> _targetsFor(String dayType) {
    switch (dayType) {
      case 'Full Body':
        return [
          MuscleGroup.chest,
          MuscleGroup.back,
          MuscleGroup.quads,
          MuscleGroup.shoulders,
          MuscleGroup.hamstrings,
          MuscleGroup.core,
        ];
      case 'Haut du corps':
        return [
          MuscleGroup.chest,
          MuscleGroup.back,
          MuscleGroup.shoulders,
          MuscleGroup.biceps,
          MuscleGroup.triceps,
        ];
      case 'Bas du corps':
        return [
          MuscleGroup.quads,
          MuscleGroup.hamstrings,
          MuscleGroup.glutes,
          MuscleGroup.calves,
          MuscleGroup.core,
        ];
      case 'Push':
        return [MuscleGroup.chest, MuscleGroup.shoulders, MuscleGroup.triceps];
      case 'Pull':
        return [MuscleGroup.back, MuscleGroup.biceps, MuscleGroup.forearms];
      case 'Legs':
        return [MuscleGroup.quads, MuscleGroup.hamstrings, MuscleGroup.glutes, MuscleGroup.calves];
      default:
        return const [];
    }
  }

  /// Strict equipment rule: body weight is always available; everything
  /// else must be in the user's declared equipment set.
  static List<Exercise> _filterByEquipment(List<Exercise> all, Set<String> available) {
    return all
        .where((e) => e.equipment == 'body weight' || available.contains(e.equipment))
        .toList();
  }

  static Exercise? _pickExercise(
    List<Exercise> pool,
    MuscleGroup target, {
    required Set<String> excludeIds,
  }) {
    for (final e in pool) {
      if (e.primaryMuscle == target && !excludeIds.contains(e.id)) return e;
    }
    return null;
  }
}
