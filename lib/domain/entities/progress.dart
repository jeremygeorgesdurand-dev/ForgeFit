import 'muscle_group.dart';

enum RecordType { estimated1RM, maxWeight, maxVolume, maxReps }

class PersonalRecord {
  final String userId;
  final String exerciseId;
  final RecordType type;
  final double value;
  final DateTime achievedAt;
  final String sessionId;

  const PersonalRecord({
    required this.userId,
    required this.exerciseId,
    required this.type,
    required this.value,
    required this.achievedAt,
    required this.sessionId,
  });
}

class BodyMetric {
  final String userId;
  final DateTime date;
  final double? weightKg;
  final double? bodyFatPct;
  final Map<String, double> measurements;

  const BodyMetric({
    required this.userId,
    required this.date,
    this.weightKg,
    this.bodyFatPct,
    this.measurements = const {},
  });
}

/// Derived/precomputed — always regenerable from SetLog history.
/// Never the source of truth.
class ExercisePerformanceIndex {
  final String userId;
  final String exerciseId;
  final double best1RM;
  final double avgVolumeLast4Weeks;
  final int trend; // -1 down, 0 flat, 1 up
  final DateTime? lastPerformedAt;

  const ExercisePerformanceIndex({
    required this.userId,
    required this.exerciseId,
    required this.best1RM,
    required this.avgVolumeLast4Weeks,
    required this.trend,
    this.lastPerformedAt,
  });
}

/// Derived — 0..100 score per muscle group with a confidence flag.
class MuscleGroupScore {
  final String userId;
  final MuscleGroup muscleGroup;
  final double score;
  final double confidence; // 0..1
  final DateTime lastComputedAt;

  const MuscleGroupScore({
    required this.userId,
    required this.muscleGroup,
    required this.score,
    required this.confidence,
    required this.lastComputedAt,
  });
}

class ProgressSnapshot {
  final String userId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalVolumeKg;
  final int sessionsCount;
  final Duration avgDuration;

  const ProgressSnapshot({
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalVolumeKg,
    required this.sessionsCount,
    required this.avgDuration,
  });
}
