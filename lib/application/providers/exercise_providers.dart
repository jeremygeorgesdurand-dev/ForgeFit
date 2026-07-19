import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import 'repository_providers.dart';

final allExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  return ref.watch(exerciseRepositoryProvider).getAll();
});

final exerciseFilterProvider = StateProvider<ExerciseFilter>((ref) {
  return const ExerciseFilter();
});

final filteredExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final filter = ref.watch(exerciseFilterProvider);
  return ref.watch(exerciseRepositoryProvider).search(filter);
});

final exerciseByIdProvider = FutureProvider.family<Exercise?, String>((ref, id) async {
  return ref.watch(exerciseRepositoryProvider).getById(id);
});

final equipmentOptionsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(exerciseRepositoryProvider).listEquipmentOptions();
});
