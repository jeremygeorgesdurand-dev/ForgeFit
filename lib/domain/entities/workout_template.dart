class RepRange {
  final int min;
  final int max;
  const RepRange(this.min, this.max);
}

/// One exercise slot inside a user-built [WorkoutTemplate].
/// This is the highly-customizable layer — free of dataset constraints.
class WorkoutTemplateExercise {
  final String exerciseId;
  final int order;
  final int targetSets;
  final RepRange targetRepRange;
  final int targetRestSec;
  final double? targetWeightKg;
  final double? targetRpe;
  final String? notes;

  const WorkoutTemplateExercise({
    required this.exerciseId,
    required this.order,
    required this.targetSets,
    required this.targetRepRange,
    required this.targetRestSec,
    this.targetWeightKg,
    this.targetRpe,
    this.notes,
  });
}

class WorkoutTemplate {
  final String id;
  final String userId;
  final String name;
  final List<WorkoutTemplateExercise> exercises;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  const WorkoutTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.exercises,
    required this.createdAt,
    this.lastUsedAt,
  });
}
