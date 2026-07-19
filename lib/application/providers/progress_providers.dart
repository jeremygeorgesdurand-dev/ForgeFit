import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/progress.dart';
import '../../domain/services/plateau_detector.dart';
import 'repository_providers.dart';
import 'user_providers.dart';

/// Whether an exercise's best estimated 1RM has stalled across its last
/// few sessions — a nudge toward a deload week (PARTIE 6 heuristics,
/// nothing LLM-decided).
final plateauStatusProvider = FutureProvider.family<PlateauStatus, String>((ref, exerciseId) async {
  final history = await ref.watch(workoutRepositoryProvider).getHistory(localUserId, limit: 200);
  return PlateauDetector.detect(exerciseId: exerciseId, sessions: history);
});

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
