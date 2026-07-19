import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/user_providers.dart';
import '../../../application/providers/workout_providers.dart';
import '../../../core/units/weight_units.dart';
import '../../../domain/entities/workout_session.dart';

class _WeekVolume {
  final DateTime weekStart;
  final double volumeKg;
  const _WeekVolume(this.weekStart, this.volumeKg);
}

DateTime _mondayOf(DateTime d) {
  final date = DateTime(d.year, d.month, d.day);
  return date.subtract(Duration(days: date.weekday - 1));
}

List<_WeekVolume> _weeklyVolumes(List<WorkoutSession> sessions, {required int weeksBack}) {
  final thisMonday = _mondayOf(DateTime.now());
  final volumesByWeek = <DateTime, double>{};
  for (final s in sessions) {
    if (s.status != SessionStatus.completed) continue;
    final week = _mondayOf(s.startedAt.toLocal());
    volumesByWeek[week] = (volumesByWeek[week] ?? 0) + s.totalVolumeKg;
  }
  return [
    for (var i = weeksBack - 1; i >= 0; i--)
      _WeekVolume(
        thisMonday.subtract(Duration(days: 7 * i)),
        volumesByWeek[thisMonday.subtract(Duration(days: 7 * i))] ?? 0,
      ),
  ];
}

/// Last 8 weeks of total training volume, one bar per week — the trend
/// view that was missing next to the single-number totals shown in the
/// session summary and history detail.
class TrainingVolumeChart extends ConsumerWidget {
  const TrainingVolumeChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final unit = ref.watch(unitSystemProvider);
    final scheme = Theme.of(context).colorScheme;

    return historyAsync.when(
      data: (history) {
        final weeks = _weeklyVolumes(history, weeksBack: 8);
        if (weeks.every((w) => w.volumeKg == 0)) return const SizedBox.shrink();
        final thisWeekVolume = weeks.last.volumeKg;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Volume hebdomadaire', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      'Cette semaine : ${thisWeekVolume.displayWeight(unit, decimals: 0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _VolumeBarsPainter(
                      weeks: weeks,
                      barColor: scheme.primary,
                      mutedColor: scheme.surfaceContainerHighest,
                    ),
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

class _VolumeBarsPainter extends CustomPainter {
  final List<_WeekVolume> weeks;
  final Color barColor;
  final Color mutedColor;

  _VolumeBarsPainter({required this.weeks, required this.barColor, required this.mutedColor});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVolume = weeks.fold<double>(0, (max, w) => w.volumeKg > max ? w.volumeKg : max);
    if (maxVolume <= 0) return;

    final slot = size.width / weeks.length;
    final barWidth = slot * 0.55;

    for (var i = 0; i < weeks.length; i++) {
      final week = weeks[i];
      final isCurrent = i == weeks.length - 1;
      final barHeight = (week.volumeKg / maxVolume) * size.height * 0.92;
      final left = slot * i + (slot - barWidth) / 2;
      final rect = Rect.fromLTWH(
        left,
        size.height - barHeight,
        barWidth,
        barHeight < 2 && week.volumeKg > 0 ? 2 : barHeight,
      );
      final paint = Paint()..color = isCurrent ? barColor : barColor.withValues(alpha: 0.35);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VolumeBarsPainter oldDelegate) {
    return oldDelegate.weeks != weeks;
  }
}
