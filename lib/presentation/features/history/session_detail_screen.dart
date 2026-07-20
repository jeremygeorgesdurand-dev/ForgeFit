import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/achievement_providers.dart';
import '../../../application/providers/exercise_providers.dart';
import '../../../application/providers/progress_providers.dart';
import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/user_providers.dart';
import '../../../application/providers/workout_providers.dart';
import '../../../core/units/weight_units.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/workout_session.dart';
import '../../widgets/confirm_dialog.dart';

/// Full breakdown of a past session: every exercise and every set logged —
/// the detail view the plain "date + volume" history list was missing.
class SessionDetailScreen extends ConsumerWidget {
  final WorkoutSession session;
  const SessionDetailScreen({super.key, required this.session});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Supprimer cette séance ?',
      message: 'Toutes les séries enregistrées pour cette séance seront définitivement supprimées.',
      confirmLabel: 'Supprimer',
    );
    if (!confirmed) return;

    await ref.read(workoutRepositoryProvider).deleteSession(session.id);
    ref.invalidate(historyProvider);
    ref.invalidate(personalRecordsProvider);
    ref.invalidate(muscleGroupScoresProvider);
    ref.invalidate(achievementsProvider);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = session.durationSec;
    final unit = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Séance du ${_formatDate(session.startedAt)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer la séance',
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Volume',
                  value: session.totalVolumeKg.displayWeight(unit, decimals: 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(
                  label: 'Durée',
                  value: duration == null ? '—' : '${(duration / 60).round()} min',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(label: 'Exercices', value: '${session.exercises.length}'),
              ),
            ],
          ),
          if (session.notes != null && session.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notes, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text('Notes', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(session.notes!),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          for (final exercise in session.exercises)
            _SessionExerciseCard(exercise: exercise, unit: unit),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        'à ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SessionExerciseCard extends ConsumerWidget {
  final WorkoutSessionExercise exercise;
  final UnitSystem unit;
  const _SessionExerciseCard({required this.exercise, required this.unit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseByIdProvider(exercise.exerciseId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            exerciseAsync.when(
              data: (e) => Text(
                e?.name ?? exercise.exerciseId,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              loading: () => const Text('…'),
              error: (_, __) => Text(exercise.exerciseId),
            ),
            const SizedBox(height: 8),
            for (final set in exercise.sets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        'S${set.setIndex + 1}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (set.isWarmup)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          'échauf.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    Text('${set.weightKg.displayWeight(unit)} × ${set.actualReps} reps'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
