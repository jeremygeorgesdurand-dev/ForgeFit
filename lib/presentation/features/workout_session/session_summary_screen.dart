import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/achievement_providers.dart';
import '../../../application/providers/user_providers.dart';
import '../../../application/providers/workout_providers.dart';
import '../../../core/units/weight_units.dart';
import '../../../domain/entities/workout_session.dart';
import '../achievements/achievement_icon.dart';

/// End-of-session recap: totals plus a comparison against the last similar
/// session (PARTIE 4/6 — "comparaison avec la dernière séance similaire").
class SessionSummaryScreen extends ConsumerWidget {
  final WorkoutSession session;
  const SessionSummaryScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(lastSimilarSessionProvider(session));
    final duration = session.durationSec;
    final unit = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Récapitulatif')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Volume',
                  value: session.totalVolumeKg.displayWeight(unit, decimals: 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Durée',
                  value: duration == null ? '—' : '${(duration / 60).round()} min',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(label: 'Exercices', value: '${session.exercises.length}')),
            ],
          ),
          const SizedBox(height: 24),
          Text('Comparaison avec la dernière séance similaire', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          comparisonAsync.when(
            data: (previous) {
              if (previous == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Pas de séance similaire récente à comparer.'),
                  ),
                );
              }
              final delta = session.totalVolumeKg - previous.totalVolumeKg;
              final improved = delta >= 0;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        improved ? Icons.trending_up : Icons.trending_down,
                        color: improved ? Colors.greenAccent : Colors.redAccent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${improved ? '+' : ''}${delta.displayWeight(unit, decimals: 0)} de volume '
                          'par rapport à la séance du ${previous.startedAt.day}/${previous.startedAt.month}',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Erreur: $err'),
          ),
          _NewAchievementsBanner(session: session),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Retour au dashboard'),
          ),
        ],
      ),
    );
  }
}

class _NewAchievementsBanner extends ConsumerWidget {
  final WorkoutSession session;
  const _NewAchievementsBanner({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newlyUnlockedAsync = ref.watch(newlyUnlockedAchievementsProvider(session));
    final scheme = Theme.of(context).colorScheme;

    return newlyUnlockedAsync.when(
      data: (achievements) {
        if (achievements.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Card(
            color: scheme.primary.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.workspace_premium, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        achievements.length > 1 ? 'Nouveaux succès débloqués !' : 'Nouveau succès débloqué !',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final achievement in achievements)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(achievementIcon(achievement.category), size: 18, color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              achievement.titleFr,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
