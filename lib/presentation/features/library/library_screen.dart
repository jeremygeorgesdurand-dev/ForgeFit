import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/exercise_providers.dart';
import '../../../core/localization/fr_labels.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/repositories/exercise_repository.dart';
import 'exercise_filter_sheet.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(filteredExercisesProvider);
    final filter = ref.watch(exerciseFilterProvider);
    final hasActiveFilter = filter.muscleGroup != null || filter.equipment != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque'),
        actions: [
          IconButton(
            icon: Icon(
              hasActiveFilter ? Icons.filter_alt : Icons.filter_list,
              color: hasActiveFilter ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => const ExerciseFilterSheet(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher un exercice…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (query) {
                ref.read(exerciseFilterProvider.notifier).state = ExerciseFilter(
                  muscleGroup: filter.muscleGroup,
                  equipment: filter.equipment,
                  category: filter.category,
                  searchQuery: query,
                );
              },
            ),
          ),
        ),
      ),
      body: exercisesAsync.when(
        data: (exercises) => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: exercises.length,
          itemBuilder: (context, index) => _ExerciseCard(exercise: exercises[index]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/library/${exercise.id}'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: exercise.media.imagePath != null
                    ? Image.asset(
                        exercise.media.imagePath!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => _placeholder(context),
                      )
                    : _placeholder(context),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _tag(context, exercise.primaryMuscle.labelFr, primary: true),
                        _tag(context, equipmentLabelFr(exercise.equipment), primary: false),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
      child: Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary),
    );
  }

  Widget _tag(BuildContext context, String label, {required bool primary}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primary ? scheme.primary.withValues(alpha: 0.18) : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: primary ? scheme.primary : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
