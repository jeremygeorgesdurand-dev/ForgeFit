import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/exercise_providers.dart';
import '../../../core/localization/fr_labels.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final String exerciseId;
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseByIdProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Détail exercice')),
      body: exerciseAsync.when(
        data: (exercise) {
          if (exercise == null) return const Center(child: Text('Introuvable'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (exercise.media.gifPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    exercise.media.gifPath!,
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) =>
                        const SizedBox(height: 220, child: Icon(Icons.image_not_supported)),
                  ),
                ),
              const SizedBox(height: 8),
              Text(exercise.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Chip(label: Text('Muscle principal: ${exercise.primaryMuscle.labelFr}')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: exercise.secondaryMuscles
                    .map((m) => Chip(label: Text(m.labelFr)))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text('Équipement: ${equipmentLabelFr(exercise.equipment)}'),
              const SizedBox(height: 16),
              Text('Instructions', style: Theme.of(context).textTheme.titleMedium),
              for (final step in exercise.instructions) Text('• $step'),
              if (exercise.media.attribution != null) ...[
                const SizedBox(height: 24),
                Text(
                  exercise.media.attribution!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
