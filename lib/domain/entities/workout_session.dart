enum SessionStatus { inProgress, completed, aborted }

class SetLog {
  final String id;
  final int setIndex;
  final int targetReps;
  final int actualReps;
  final double weightKg;
  final double? rpe;
  final double? rir;
  final bool isWarmup;
  final DateTime completedAt;
  final int restTakenSec;

  const SetLog({
    required this.id,
    required this.setIndex,
    required this.targetReps,
    required this.actualReps,
    required this.weightKg,
    this.rpe,
    this.rir,
    this.isWarmup = false,
    required this.completedAt,
    required this.restTakenSec,
  });

  double get volume => isWarmup ? 0 : weightKg * actualReps;
}

class WorkoutSessionExercise {
  final String exerciseId;
  final int order;
  final List<SetLog> sets;

  const WorkoutSessionExercise({
    required this.exerciseId,
    required this.order,
    this.sets = const [],
  });

  double get totalVolume => sets.fold(0, (sum, s) => sum + s.volume);
}

class WorkoutSession {
  final String id;
  final String userId;
  final String? templateId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final SessionStatus status;
  final List<WorkoutSessionExercise> exercises;
  final String? notes;

  const WorkoutSession({
    required this.id,
    required this.userId,
    this.templateId,
    required this.startedAt,
    this.endedAt,
    this.status = SessionStatus.inProgress,
    this.exercises = const [],
    this.notes,
  });

  double get totalVolumeKg =>
      exercises.fold(0, (sum, e) => sum + e.totalVolume);

  int? get durationSec => endedAt?.difference(startedAt).inSeconds;
}
