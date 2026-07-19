import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/workout_providers.dart';
import '../../../domain/entities/workout_session.dart';

const _weekdayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const _monthLabels = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Month grid of completed sessions — a calendar view of training history,
/// complementary to the flat chronological list on the Historique screen.
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

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: historyAsync.when(
          data: (history) {
            final byDay = <DateTime, List<WorkoutSession>>{};
            for (final s in history) {
              if (s.status != SessionStatus.completed) continue;
              byDay.putIfAbsent(_dayOnly(s.startedAt.toLocal()), () => []).add(s);
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
                    final isToday = _dayOnly(DateTime.now()) == date;

                    return Padding(
                      padding: const EdgeInsets.all(2),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: sessions == null ? null : () => _showDaySessions(sessions),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sessions != null
                                ? scheme.primary.withValues(alpha: sessions.length > 1 ? 0.9 : 0.55)
                                : Colors.transparent,
                            border: isToday ? Border.all(color: scheme.secondary, width: 1.5) : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: sessions != null ? scheme.onPrimary : scheme.onSurface,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
