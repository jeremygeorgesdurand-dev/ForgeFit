import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/progress_providers.dart';
import '../../../core/localization/fr_labels.dart';
import '../../../core/theme/rank_colors.dart';
import '../../../domain/entities/progress.dart';
import '../../../domain/services/muscle_rank.dart';
import 'achievements_summary_card.dart';
import 'body_silhouette.dart';
import 'training_calendar.dart';
import 'training_streak_card.dart';

/// Overview: muscle-group silhouette, training calendar, and per-group
/// score detail (PARTIE 7).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoresAsync = ref.watch(muscleGroupScoresProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: scoresAsync.when(
        data: (scores) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const TrainingStreakCard(),
            const SizedBox(height: 16),
            const AchievementsSummaryCard(),
            const SizedBox(height: 16),
            BodySilhouette(
              scores: {for (final s in scores) s.muscleGroup: s},
            ),
            const SizedBox(height: 16),
            const TrainingCalendar(),
            const SizedBox(height: 24),
            Text('Niveau par groupe musculaire', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (scores.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Pas encore assez de données pour estimer un niveau. '
                    'Termine quelques séances pour voir apparaître ton profil musculaire.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            for (final score in scores) _MuscleScoreBar(score: score),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}

class _MuscleScoreBar extends StatelessWidget {
  final MuscleGroupScore score;
  const _MuscleScoreBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rank = rankForScore(score.score);
    final color = rankColor(rank);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  score.muscleGroup.labelFr,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Row(
                  children: [
                    if (score.confidence < 1)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(Icons.info_outline, size: 14, color: scheme.onSurfaceVariant),
                      ),
                    Icon(Icons.military_tech, size: 16, color: color),
                    const SizedBox(width: 4),
                    Text(
                      rank.labelFr,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${score.score.toStringAsFixed(0)}/100',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (score.score / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            if (score.confidence < 1) ...[
              const SizedBox(height: 4),
              Text(
                'Estimation faible — peu de séances récentes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
