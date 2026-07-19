import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/body_metrics_providers.dart';
import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/user_providers.dart';
import '../../../core/units/weight_units.dart';
import '../../../domain/entities/progress.dart';

/// Body weight / body fat % tracking over time — logs into [BodyMetric],
/// a real source-of-truth table (unlike the derived progress data).
class BodyMetricsScreen extends ConsumerStatefulWidget {
  const BodyMetricsScreen({super.key});

  @override
  ConsumerState<BodyMetricsScreen> createState() => _BodyMetricsScreenState();
}

class _BodyMetricsScreenState extends ConsumerState<BodyMetricsScreen> {
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final bodyFat = double.tryParse(_bodyFatController.text.replaceAll(',', '.'));
    if (weight == null && bodyFat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renseigne au moins un poids ou un taux de masse grasse.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(bodyMetricsRepositoryProvider).logMetric(
            BodyMetric(
              userId: localUserId,
              date: _selectedDate,
              weightKg: weight,
              bodyFatPct: bodyFat,
            ),
          );
      ref.invalidate(bodyMetricsHistoryProvider);
      _weightController.clear();
      _bodyFatController.clear();
      setState(() => _selectedDate = DateTime.now());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(BodyMetric metric) async {
    await ref.read(bodyMetricsRepositoryProvider).deleteMetric(metric.userId, metric.date);
    ref.invalidate(bodyMetricsHistoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(bodyMetricsHistoryProvider);
    final unit = ref.watch(unitSystemProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Suivi du poids')),
      body: historyAsync.when(
        data: (history) {
          // Chronological order for the chart (oldest first).
          final chronological = history.reversed.toList();
          final latest = history.isEmpty ? null : history.first;
          final previous = history.length > 1 ? history[1] : null;
          final delta = (latest?.weightKg != null && previous?.weightKg != null)
              ? latest!.weightKg! - previous!.weightKg!
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (latest?.weightKg != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dernier poids', style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              latest!.weightKg!.displayWeight(unit),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (delta != null)
                          Row(
                            children: [
                              Icon(
                                delta <= 0 ? Icons.trending_down : Icons.trending_up,
                                color: delta <= 0 ? Colors.greenAccent : Colors.orangeAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${delta > 0 ? '+' : ''}${delta.displayWeight(unit)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              if (chronological.where((m) => m.weightKg != null).length >= 2) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _WeightChartPainter(
                          points: chronological.where((m) => m.weightKg != null).toList(),
                          lineColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('Ajouter une mesure', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Poids (kg)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _bodyFatController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Masse grasse (%)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      '${_selectedDate.day.toString().padLeft(2, '0')}/'
                      '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Enregistrer'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Aucune mesure enregistrée pour le moment.'),
                )
              else ...[
                Text('Historique', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final metric in history)
                  Dismissible(
                    key: ValueKey(metric.date.toIso8601String()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: const Icon(Icons.delete_outline),
                    ),
                    onDismissed: (_) => _delete(metric),
                    child: ListTile(
                      title: Text(
                        [
                          if (metric.weightKg != null) metric.weightKg!.displayWeight(unit),
                          if (metric.bodyFatPct != null) '${metric.bodyFatPct!.toStringAsFixed(1)} % MG',
                        ].join(' · '),
                      ),
                      subtitle: Text(
                        '${metric.date.day.toString().padLeft(2, '0')}/'
                        '${metric.date.month.toString().padLeft(2, '0')}/${metric.date.year}',
                      ),
                    ),
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

class _WeightChartPainter extends CustomPainter {
  final List<BodyMetric> points;
  final Color lineColor;
  _WeightChartPainter({required this.points, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final weights = points.map((p) => p.weightKg!).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final range = (maxW - minW).abs() < 0.5 ? 1.0 : maxW - minW;

    final dx = points.length > 1 ? size.width / (points.length - 1) : 0.0;
    final path = Path();
    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final normalized = (weights[i] - minW) / range;
      final y = size.height - normalized * size.height * 0.85 - size.height * 0.05;
      final x = dx * i;
      offsets.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    final fillPath = Path.from(path)
      ..lineTo(offsets.last.dx, size.height)
      ..lineTo(offsets.first.dx, size.height)
      ..close();
    final fillPaint = Paint()..color = lineColor.withValues(alpha: 0.12);
    canvas.drawPath(fillPath, fillPaint);

    final dotPaint = Paint()..color = lineColor;
    for (final o in offsets) {
      canvas.drawCircle(o, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}
