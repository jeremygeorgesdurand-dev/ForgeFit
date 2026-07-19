import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/exercise_providers.dart';
import '../../../core/localization/fr_labels.dart';
import '../../../domain/entities/muscle_group.dart';
import '../../../domain/repositories/exercise_repository.dart';

/// Multi-criteria filter (muscle group / equipment) — PARTIE 4
/// "filtrer et trier les exercices par groupe musculaire, équipement".
class ExerciseFilterSheet extends ConsumerWidget {
  const ExerciseFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(exerciseFilterProvider);
    final equipmentAsync = ref.watch(equipmentOptionsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtrer les exercices', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Text('Groupe musculaire', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final group in MuscleGroup.values.where((g) => g != MuscleGroup.unknown))
                ChoiceChip(
                  label: Text(group.labelFr),
                  selected: current.muscleGroup == group,
                  onSelected: (selected) {
                    ref.read(exerciseFilterProvider.notifier).state = ExerciseFilter(
                      muscleGroup: selected ? group : null,
                      equipment: current.equipment,
                      category: current.category,
                      searchQuery: current.searchQuery,
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Équipement', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          equipmentAsync.when(
            data: (options) {
              final sorted = [...options]
                ..sort((a, b) => equipmentLabelFr(a).compareTo(equipmentLabelFr(b)));
              return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final equipment in sorted)
                  ChoiceChip(
                    label: Text(equipmentLabelFr(equipment)),
                    selected: current.equipment == equipment,
                    onSelected: (selected) {
                      ref.read(exerciseFilterProvider.notifier).state = ExerciseFilter(
                        muscleGroup: current.muscleGroup,
                        equipment: selected ? equipment : null,
                        category: current.category,
                        searchQuery: current.searchQuery,
                      );
                    },
                  ),
              ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('Erreur: $err'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(exerciseFilterProvider.notifier).state = const ExerciseFilter();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
