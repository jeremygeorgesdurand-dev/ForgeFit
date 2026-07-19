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

  /// Exercises sharing the same non-null group are a superset: performed
  /// back-to-back with a short rest between their own sets instead of the
  /// full [targetRestSec] — the round-ending rest happens after the last
  /// member, driven manually by moving to the next exercise.
  final int? supersetGroup;

  const WorkoutTemplateExercise({
    required this.exerciseId,
    required this.order,
    required this.targetSets,
    required this.targetRepRange,
    required this.targetRestSec,
    this.targetWeightKg,
    this.targetRpe,
    this.notes,
    this.supersetGroup,
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
