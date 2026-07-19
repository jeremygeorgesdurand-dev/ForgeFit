import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../domain/services/muscle_group_score_calculator.dart';
import '../../domain/services/performance_index_calculator.dart';
import '../../domain/services/personal_record_detector.dart';

/// Derived-data repository. Recomputes everything from workout history via
/// the domain services — never stores anything that isn't rebuildable.
class InMemoryProgressRepository implements ProgressRepository {
  final WorkoutRepository _workoutRepository;
  final ExerciseRepository _exerciseRepository;

  List<PersonalRecord> _records = [];
  Map<String, ExercisePerformanceIndex> _performanceIndex = {};
  List<MuscleGroupScore> _muscleScores = [];

  InMemoryProgressRepository(this._workoutRepository, this._exerciseRepository);

  @override
  Future<void> recomputeAll(String userId) async {
    final sessions = await _workoutRepository.getHistory(userId, limit: 1000);
    final completed =
        sessions.where((s) => s.status == SessionStatus.completed).toList();

    _records = PersonalRecordDetector.detectAll(userId, completed);

    final exerciseIds = <String>{
      for (final s in completed)
        for (final e in s.exercises) e.exerciseId,
    };
    _performanceIndex = {
      for (final id in exerciseIds)
        id: PerformanceIndexCalculator.compute(
          userId: userId,
          exerciseId: id,
          sessions: completed,
        ),
    };

    final exercises = await _exerciseRepository.getAll();
    final muscleByExercise = {
      for (final e in exercises) e.id: e.primaryMuscle,
    };
    final secondaryByExercise = {
      for (final e in exercises) e.id: e.secondaryMuscles,
    };

    _muscleScores = MuscleGroupScoreCalculator.compute(
      userId: userId,
      sessions: completed,
      primaryMuscleOf: (id) => muscleByExercise[id] ?? MuscleGroup.unknown,
      secondaryMusclesOf: (id) => secondaryByExercise[id] ?? const [],
    );
  }

  @override
  Future<List<PersonalRecord>> getRecords(String userId, {String? exerciseId}) async {
    return _records.where((r) => exerciseId == null || r.exerciseId == exerciseId).toList();
  }

  @override
  Future<ExercisePerformanceIndex?> getPerformanceIndex(
    String userId,
    String exerciseId,
  ) async => _performanceIndex[exerciseId];

  @override
  Future<List<MuscleGroupScore>> getMuscleGroupScores(String userId) async => _muscleScores;

  @override
  Future<ProgressSnapshot> getSnapshot({
    required String userId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final sessions = await _workoutRepository.getHistory(userId, limit: 1000);
    final inPeriod = sessions.where(
      (s) =>
          s.status == SessionStatus.completed &&
          s.startedAt.isAfter(periodStart) &&
          s.startedAt.isBefore(periodEnd),
    );
    final totalVolume = inPeriod.fold<double>(0, (sum, s) => sum + s.totalVolumeKg);
    final durations = inPeriod
        .map((s) => s.durationSec)
        .whereType<int>()
        .toList();
    final avgSeconds = durations.isEmpty
        ? 0
        : durations.reduce((a, b) => a + b) ~/ durations.length;

    return ProgressSnapshot(
      userId: userId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalVolumeKg: totalVolume,
      sessionsCount: inPeriod.length,
      avgDuration: Duration(seconds: avgSeconds),
    );
  }
}
