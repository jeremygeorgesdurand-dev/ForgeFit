import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/progress.dart';
import 'repository_providers.dart';
import 'user_providers.dart';

final muscleGroupScoresProvider = FutureProvider<List<MuscleGroupScore>>((ref) async {
  final repo = ref.watch(progressRepositoryProvider);
  await repo.recomputeAll(localUserId);
  return repo.getMuscleGroupScores(localUserId);
});

final personalRecordsProvider = FutureProvider<List<PersonalRecord>>((ref) async {
  final repo = ref.watch(progressRepositoryProvider);
  await repo.recomputeAll(localUserId);
  return repo.getRecords(localUserId);
});
