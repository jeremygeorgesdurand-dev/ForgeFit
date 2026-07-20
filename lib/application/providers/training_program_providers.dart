import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/training_program.dart';
import '../../domain/services/program_adherence_calculator.dart';
import 'repository_providers.dart';
import 'user_providers.dart';
import 'workout_providers.dart';

final trainingProgramsProvider = FutureProvider<List<TrainingProgram>>((ref) async {
  return ref.watch(trainingProgramRepositoryProvider).getPrograms(localUserId);
});

/// How closely the user has stuck to [program]'s intended weekly frequency
/// since saving it, based on completed sessions logged against its own
/// template ids.
final programAdherenceProvider =
    FutureProvider.family<ProgramAdherence, TrainingProgram>((ref, program) async {
  final history = await ref.watch(historyProvider.future);
  final profile = await ref.watch(currentUserProvider.future);
  return ProgramAdherenceCalculator.compute(
    program: program,
    history: history,
    weeklyFrequencyTarget: profile?.weeklyFrequencyTarget ?? 3,
  );
});
