import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/live_session_controller.dart';
import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/scheduled_session_providers.dart';
import '../../../application/providers/user_providers.dart';
import '../../../application/providers/workout_providers.dart';
import '../../../domain/entities/scheduled_session.dart';
import '../../../domain/entities/workout_session.dart';
import '../../../domain/entities/workout_template.dart';

const _weekdayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const _monthLabels = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Month grid combining past completed sessions and future planned ones —
/// a calendar view of training history and upcoming plans, complementary
/// to the flat chronological list on the Historique screen.
class TrainingCalendar extends ConsumerStatefulWidget {
  const TrainingCalendar({super.key});

  @override
  ConsumerState<TrainingCalendar> createState() => _TrainingCalendarState();
}

class _TrainingCalendarState extends ConsumerState<TrainingCalendar> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _showDaySessions(List<WorkoutSession> sessions) {
    if (sessions.length == 1) {
      context.push('/history/detail', extra: sessions.first);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in sessions)
              ListTile(
                title: Text('${s.exercises.length} exercices'),
                subtitle: Text('Volume : ${s.totalVolumeKg.toStringAsFixed(0)} kg'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/history/detail', extra: s);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startScheduled(ScheduledSession scheduled, WorkoutTemplate template) async {
    Navigator.of(context).pop();
    await ref.read(liveSessionControllerProvider.notifier).start(template: template);
    await ref.read(scheduledSessionRepositoryProvider).deleteScheduled(scheduled.id);
    ref.invalidate(scheduledSessionsProvider);
    if (mounted) context.go('/live');
  }

  Future<void> _removeScheduled(ScheduledSession scheduled) async {
    Navigator.of(context).pop();
    await ref.read(scheduledSessionRepositoryProvider).deleteScheduled(scheduled.id);
    ref.invalidate(scheduledSessionsProvider);
  }

  void _pickTemplateToSchedule(DateTime date, List<WorkoutTemplate> templates) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choisir une séance à programmer'),
            ),
            if (templates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Aucune séance créée pour le moment.'),
              ),
            for (final t in templates)
              ListTile(
                title: Text(t.name),
                subtitle: Text('${t.exercises.length} exercices'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(scheduledSessionRepositoryProvider).scheduleSession(
                        ScheduledSession(id: '', userId: localUserId, templateId: t.id, date: date),
                      );
                  ref.invalidate(scheduledSessionsProvider);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDayOptions(
    DateTime date,
    List<ScheduledSession> scheduledForDay,
    Map<String, WorkoutTemplate> templatesById,
    List<WorkoutTemplate> allTemplates,
  ) {
    final isPast = date.isBefore(_dayOnly(DateTime.now()));

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in scheduledForDay)
              if (templatesById[s.templateId] != null)
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: Text(templatesById[s.templateId]!.name),
                  subtitle: const Text('Programmée'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _startScheduled(s, templatesById[s.templateId]!),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _removeScheduled(s),
                      ),
                    ],
                  ),
                ),
            if (!isPast)
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Programmer une séance ce jour'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickTemplateToSchedule(date, allTemplates);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);
    final scheduledAsync = ref.watch(scheduledSessionsProvider);
    final templatesAsync = ref.watch(templatesProvider);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: historyAsync.when(
          data: (history) {
            final scheduled = scheduledAsync.valueOrNull ?? const <ScheduledSession>[];
            final templates = templatesAsync.valueOrNull ?? const <WorkoutTemplate>[];
            final templatesById = {for (final t in templates) t.id: t};

            final byDay = <DateTime, List<WorkoutSession>>{};
            for (final s in history) {
              if (s.status != SessionStatus.completed) continue;
              byDay.putIfAbsent(_dayOnly(s.startedAt.toLocal()), () => []).add(s);
            }
            final scheduledByDay = <DateTime, List<ScheduledSession>>{};
            for (final s in scheduled) {
              scheduledByDay.putIfAbsent(_dayOnly(s.date), () => []).add(s);
            }

            final firstOfMonth = DateTime(_month.year, _month.month);
            final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
            final leadingBlanks = (firstOfMonth.weekday - 1) % 7;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month - 1),
                      ),
                    ),
                    Text(
                      '${_monthLabels[_month.month - 1]} ${_month.year}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month + 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (final label in _weekdayLabels)
                      Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                  itemCount: leadingBlanks + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < leadingBlanks) return const SizedBox.shrink();
                    final day = index - leadingBlanks + 1;
                    final date = DateTime(_month.year, _month.month, day);
                    final sessions = byDay[date];
                    final scheduledForDay = scheduledByDay[date] ?? const <ScheduledSession>[];
                    final isToday = _dayOnly(DateTime.now()) == date;

                    return Padding(
                      padding: const EdgeInsets.all(2),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: sessions != null
                            ? () => _showDaySessions(sessions)
                            : () => _showDayOptions(date, scheduledForDay, templatesById, templates),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sessions != null
                                ? scheme.primary.withValues(alpha: sessions.length > 1 ? 0.9 : 0.55)
                                : Colors.transparent,
                            border: sessions == null && scheduledForDay.isNotEmpty
                                ? Border.all(color: scheme.secondary, width: 1.5)
                                : (isToday ? Border.all(color: scheme.secondary, width: 1.5) : null),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: sessions != null
                                  ? scheme.onPrimary
                                  : (scheduledForDay.isNotEmpty ? scheme.secondary : scheme.onSurface),
                              fontWeight: isToday || scheduledForDay.isNotEmpty
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(color: scheme.primary, label: 'Séance faite'),
                    const SizedBox(width: 16),
                    _LegendDot(color: Colors.transparent, borderColor: scheme.secondary, label: 'Programmée'),
                  ],
                ),
              ],
            );
          },
          loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
          error: (err, stack) => Text('Erreur: $err'),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final Color? borderColor;
  final String label;
  const _LegendDot({required this.color, this.borderColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: borderColor != null ? Border.all(color: borderColor!, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
