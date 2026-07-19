import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import 'repository_providers.dart';
import 'user_providers.dart';

final allExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  return ref.watch(exerciseRepositoryProvider).getAll();
});

final exerciseFilterProvider = StateProvider<ExerciseFilter>((ref) {
  return const ExerciseFilter();
});

final favoritesOnlyProvider = StateProvider<bool>((ref) => false);

final favoriteExerciseIdsProvider = FutureProvider<Set<String>>((ref) async {
  return ref.watch(favoritesRepositoryProvider).getFavoriteExerciseIds(localUserId);
});

final filteredExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final filter = ref.watch(exerciseFilterProvider);
  final results = await ref.watch(exerciseRepositoryProvider).search(filter);
  if (!ref.watch(favoritesOnlyProvider)) return results;
  final favoriteIds = await ref.watch(favoriteExerciseIdsProvider.future);
  return results.where((e) => favoriteIds.contains(e.id)).toList();
});

final exerciseByIdProvider = FutureProvider.family<Exercise?, String>((ref, id) async {
  return ref.watch(exerciseRepositoryProvider).getById(id);
});

final equipmentOptionsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(exerciseRepositoryProvider).listEquipmentOptions();
});

/// Rule-based substitution candidates: same primary muscle, same equipment
/// first (closest match), then other equipment (useful when the gym is
/// missing something) — no LLM, just a same/different-equipment sort.
final similarExercisesProvider = FutureProvider.family<List<Exercise>, String>((ref, exerciseId) async {
  final target = await ref.watch(exerciseByIdProvider(exerciseId).future);
  if (target == null) return [];

  final all = await ref.watch(allExercisesProvider.future);
  final candidates = all
      .where((e) => e.id != target.id && e.primaryMuscle == target.primaryMuscle)
      .toList();
  candidates.sort((a, b) {
    final aSame = a.equipment == target.equipment ? 0 : 1;
    final bSame = b.equipment == target.equipment ? 0 : 1;
    if (aSame != bSame) return aSame.compareTo(bSame);
    return a.name.compareTo(b.name);
  });
  return candidates.take(8).toList();
});
