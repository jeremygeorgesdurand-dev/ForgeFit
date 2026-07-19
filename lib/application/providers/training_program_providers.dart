import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/training_program.dart';
import 'repository_providers.dart';
import 'user_providers.dart';

final trainingProgramsProvider = FutureProvider<List<TrainingProgram>>((ref) async {
  return ref.watch(trainingProgramRepositoryProvider).getPrograms(localUserId);
});
