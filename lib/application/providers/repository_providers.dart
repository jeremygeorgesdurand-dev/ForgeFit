import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/exercises_dataset_loader.dart';
import '../../data/repositories/drift_body_metrics_repository.dart';
import '../../data/repositories/drift_training_program_repository.dart';
import '../../data/repositories/drift_user_repository.dart';
import '../../data/repositories/drift_workout_repository.dart';
import '../../data/repositories/in_memory_progress_repository.dart';
import '../../data/repositories/local_exercise_repository.dart';
import '../../domain/repositories/body_metrics_repository.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/repositories/training_program_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/workout_repository.dart';

/// Composition root: this is the only place that wires a concrete
/// implementation to a domain interface. Swapping the exercise data source
/// (e.g. from the research dataset to a licensed backend) means changing
/// only `exerciseRepositoryProvider`.
final exercisesDatasetLoaderProvider = Provider((ref) => ExercisesDatasetLoader());

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return LocalExerciseRepository(ref.watch(exercisesDatasetLoaderProvider));
});

/// Single app-wide SQLite connection (offline-first store for templates,
/// sessions, sets, profile). Disposed when the provider scope is torn down.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return DriftWorkoutRepository(ref.watch(appDatabaseProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return DriftUserRepository(ref.watch(appDatabaseProvider));
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return InMemoryProgressRepository(
    ref.watch(workoutRepositoryProvider),
    ref.watch(exerciseRepositoryProvider),
  );
});

final bodyMetricsRepositoryProvider = Provider<BodyMetricsRepository>((ref) {
  return DriftBodyMetricsRepository(ref.watch(appDatabaseProvider));
});

final trainingProgramRepositoryProvider = Provider<TrainingProgramRepository>((ref) {
  return DriftTrainingProgramRepository(ref.watch(appDatabaseProvider));
});
