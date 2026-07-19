import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/exercise_providers.dart';
import '../../../application/providers/progress_providers.dart';
import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/user_providers.dart';
import '../../../core/localization/fr_labels.dart';
import '../../../domain/entities/exercise.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final String exerciseId;
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseByIdProvider(exerciseId));
    final favoriteIds = ref.watch(favoriteExerciseIdsProvider).valueOrNull ?? const <String>{};
    final isFavorite = favoriteIds.contains(exerciseId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail exercice'),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Theme.of(context).colorScheme.secondary : null,
            ),
            onPressed: () async {
              await ref.read(favoritesRepositoryProvider).toggleFavorite(localUserId, exerciseId);
              ref.invalidate(favoriteExerciseIdsProvider);
            },
          ),
        ],
      ),
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
              _PlateauBanner(exerciseId: exercise.id),
              const SizedBox(height: 16),
              Text('Instructions', style: Theme.of(context).textTheme.titleMedium),
              for (final step in exercise.instructions) Text('• $step'),
              const SizedBox(height: 24),
              _SimilarExercisesSection(exerciseId: exercise.id),
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

class _PlateauBanner extends ConsumerWidget {
  final String exerciseId;
  const _PlateauBanner({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(plateauStatusProvider(exerciseId));

    return statusAsync.when(
      data: (status) {
        if (!status.isPlateaued) return const SizedBox.shrink();
        return Card(
          color: Colors.orange.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.trending_flat, color: Colors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stagnation détectée',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ta charge estimée n\'a pas progressé sur les ${status.sessionsConsidered} '
                        'dernières séances. Envisage une semaine de décharge (-20% de charge ou de volume) '
                        'avant de repousser tes limites.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SimilarExercisesSection extends ConsumerWidget {
  final String exerciseId;
  const _SimilarExercisesSection({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarAsync = ref.watch(similarExercisesProvider(exerciseId));

    return similarAsync.when(
      data: (similar) {
        if (similar.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exercices similaires', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Même groupe musculaire — utile si le matériel manque en salle.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: similar.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _SimilarExerciseCard(exercise: similar[index]),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SimilarExerciseCard extends StatelessWidget {
  final Exercise exercise;
  const _SimilarExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 110,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/library/${exercise.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              exercise.media.imagePath != null
                  ? Image.asset(
                      exercise.media.imagePath!,
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        height: 80,
                        color: scheme.primary.withValues(alpha: 0.15),
                        child: Icon(Icons.fitness_center, color: scheme.primary),
                      ),
                    )
                  : Container(
                      height: 80,
                      color: scheme.primary.withValues(alpha: 0.15),
                      child: Icon(Icons.fitness_center, color: scheme.primary),
                    ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
