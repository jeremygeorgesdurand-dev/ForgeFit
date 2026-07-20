import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/achievement_providers.dart';
import '../../../application/providers/progress_providers.dart';
import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/user_providers.dart';
import '../../../application/providers/workout_providers.dart';
import '../../../core/units/weight_units.dart';
import '../../../domain/entities/workout_session.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  Future<void> _delete(WorkoutSession session) async {
    await ref.read(workoutRepositoryProvider).deleteSession(session.id);
    ref.invalidate(historyProvider);
    ref.invalidate(personalRecordsProvider);
    ref.invalidate(muscleGroupScoresProvider);
    ref.invalidate(achievementsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Séance supprimée'),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () async {
            await ref.read(workoutRepositoryProvider).importSession(session);
            ref.invalidate(historyProvider);
            ref.invalidate(personalRecordsProvider);
            ref.invalidate(muscleGroupScoresProvider);
            ref.invalidate(achievementsProvider);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);
    final unit = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: historyAsync.when(
        data: (sessions) => sessions.isEmpty
            ? const Center(child: Text('Aucune séance terminée pour le moment.'))
            : ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final s = sessions[index];
                  final d = s.startedAt.toLocal();
                  return Dismissible(
                    key: ValueKey(s.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: const Icon(Icons.delete_outline),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Supprimer cette séance ?'),
                              content: const Text(
                                'Toutes les séries enregistrées pour cette séance seront '
                                'définitivement supprimées.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                    },
                    onDismissed: (_) => _delete(s),
                    child: ListTile(
                      title: Text(
                        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
                      ),
                      subtitle: Text(
                        '${s.exercises.length} exercices · Volume: ${s.totalVolumeKg.displayWeight(unit, decimals: 0)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/history/detail', extra: s),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
