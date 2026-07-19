import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/user_providers.dart';
import '../../../application/providers/workout_providers.dart';
import '../../../domain/services/training_streak_calculator.dart';

/// Weekly training streak — consecutive weeks with at least one completed
/// session — plus progress against the profile's weekly frequency target.
/// Complements the ranks: a reason to show up even on an "off" muscle day.
class TrainingStreakCard extends ConsumerWidget {
  const TrainingStreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final profileAsync = ref.watch(currentUserProvider);
    final scheme = Theme.of(context).colorScheme;

    return historyAsync.when(
      data: (history) {
        final streak = weekStreak(history);
        final thisWeek = sessionsThisWeek(history);
        final target = profileAsync.valueOrNull?.weeklyFrequencyTarget ?? 3;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: streak > 0 ? const Color(0xFFFF8A3D) : scheme.onSurfaceVariant,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        streak == 0
                            ? 'Aucune série en cours'
                            : '$streak semaine${streak > 1 ? 's' : ''} d\'affilée',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cette semaine : $thisWeek/$target séances',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: target == 0 ? 0 : (thisWeek / target).clamp(0, 1),
                    strokeWidth: 4,
                    backgroundColor: scheme.surfaceContainerHighest,
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
