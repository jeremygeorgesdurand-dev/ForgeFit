import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/live_session_controller.dart';
import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/scheduled_session_providers.dart';
import '../../../application/providers/workout_providers.dart';
import '../../../domain/entities/scheduled_session.dart';
import '../../../domain/entities/workout_template.dart';

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _dateLabel(DateTime date) {
  final today = _dayOnly(DateTime.now());
  final diff = date.difference(today).inDays;
  if (diff == 0) return "Aujourd'hui";
  if (diff == 1) return 'Demain';
  return 'le ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

/// Surfaces the nearest upcoming [ScheduledSession] right on the dashboard
/// — previously a planned session was only visible by opening the
/// calendar and spotting the marker.
class NextScheduledSessionCard extends ConsumerWidget {
  const NextScheduledSessionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledAsync = ref.watch(scheduledSessionsProvider);
    final templatesAsync = ref.watch(templatesProvider);
    final scheme = Theme.of(context).colorScheme;

    return scheduledAsync.when(
      data: (scheduled) {
        final templates = templatesAsync.valueOrNull;
        if (templates == null) return const SizedBox.shrink();
        final templatesById = {for (final t in templates) t.id: t};

        final today = _dayOnly(DateTime.now());
        final upcoming = scheduled.where((s) => !_dayOnly(s.date).isBefore(today)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        final next = upcoming.isEmpty ? null : upcoming.first;
        final template = next == null ? null : templatesById[next.templateId];
        if (next == null || template == null) return const SizedBox.shrink();

        return Card(
          color: scheme.secondary.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.event_available, color: scheme.secondary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prochaine séance : ${_dateLabel(next.date)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(template.name, style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _start(context, ref, next, template),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Démarrer'),
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

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    ScheduledSession scheduled,
    WorkoutTemplate template,
  ) async {
    await ref.read(liveSessionControllerProvider.notifier).start(template: template);
    await ref.read(scheduledSessionRepositoryProvider).deleteScheduled(scheduled.id);
    ref.invalidate(scheduledSessionsProvider);
    if (context.mounted) context.go('/live');
  }
}
