import 'package:flutter/material.dart';

import '../../../core/localization/fr_labels.dart';
import '../../../core/theme/rank_colors.dart';
import '../../../domain/entities/muscle_group.dart';
import '../../../domain/entities/progress.dart';
import '../../../domain/services/muscle_rank.dart';

typedef _Region = ({MuscleGroup group, Rect rect});

// Fractional coordinates (0..1) over the painted area, front view.
const _frontRegions = <_Region>[
  (group: MuscleGroup.shoulders, rect: Rect.fromLTRB(0.08, 0.14, 0.30, 0.24)),
  (group: MuscleGroup.shoulders, rect: Rect.fromLTRB(0.70, 0.14, 0.92, 0.24)),
  (group: MuscleGroup.chest, rect: Rect.fromLTRB(0.30, 0.16, 0.70, 0.30)),
  (group: MuscleGroup.biceps, rect: Rect.fromLTRB(0.06, 0.24, 0.24, 0.40)),
  (group: MuscleGroup.biceps, rect: Rect.fromLTRB(0.76, 0.24, 0.94, 0.40)),
  (group: MuscleGroup.core, rect: Rect.fromLTRB(0.32, 0.30, 0.68, 0.46)),
  (group: MuscleGroup.forearms, rect: Rect.fromLTRB(0.04, 0.40, 0.22, 0.55)),
  (group: MuscleGroup.forearms, rect: Rect.fromLTRB(0.78, 0.40, 0.96, 0.55)),
  (group: MuscleGroup.quads, rect: Rect.fromLTRB(0.30, 0.48, 0.48, 0.74)),
  (group: MuscleGroup.quads, rect: Rect.fromLTRB(0.52, 0.48, 0.70, 0.74)),
  (group: MuscleGroup.calves, rect: Rect.fromLTRB(0.30, 0.76, 0.47, 0.96)),
  (group: MuscleGroup.calves, rect: Rect.fromLTRB(0.53, 0.76, 0.70, 0.96)),
];

// Fractional coordinates, back view.
const _backRegions = <_Region>[
  (group: MuscleGroup.shoulders, rect: Rect.fromLTRB(0.08, 0.14, 0.30, 0.24)),
  (group: MuscleGroup.shoulders, rect: Rect.fromLTRB(0.70, 0.14, 0.92, 0.24)),
  (group: MuscleGroup.back, rect: Rect.fromLTRB(0.30, 0.16, 0.70, 0.36)),
  (group: MuscleGroup.triceps, rect: Rect.fromLTRB(0.06, 0.24, 0.24, 0.40)),
  (group: MuscleGroup.triceps, rect: Rect.fromLTRB(0.76, 0.24, 0.94, 0.40)),
  (group: MuscleGroup.forearms, rect: Rect.fromLTRB(0.04, 0.40, 0.22, 0.55)),
  (group: MuscleGroup.forearms, rect: Rect.fromLTRB(0.78, 0.40, 0.96, 0.55)),
  (group: MuscleGroup.glutes, rect: Rect.fromLTRB(0.32, 0.46, 0.68, 0.58)),
  (group: MuscleGroup.hamstrings, rect: Rect.fromLTRB(0.30, 0.58, 0.48, 0.76)),
  (group: MuscleGroup.hamstrings, rect: Rect.fromLTRB(0.52, 0.58, 0.70, 0.76)),
  (group: MuscleGroup.calves, rect: Rect.fromLTRB(0.30, 0.76, 0.47, 0.96)),
  (group: MuscleGroup.calves, rect: Rect.fromLTRB(0.53, 0.76, 0.70, 0.96)),
];

/// Interactive front/back body diagram: each muscle group region is tinted
/// by its [MuscleGroupScore], and tapping a region surfaces the exact score.
class BodySilhouette extends StatefulWidget {
  final Map<MuscleGroup, MuscleGroupScore> scores;
  const BodySilhouette({super.key, required this.scores});

  @override
  State<BodySilhouette> createState() => _BodySilhouetteState();
}

class _BodySilhouetteState extends State<BodySilhouette> {
  bool _showBack = false;
  MuscleGroup? _selected;

  void _handleTapUp(TapUpDetails details, Size size, List<_Region> regions) {
    final dx = details.localPosition.dx / size.width;
    final dy = details.localPosition.dy / size.height;
    for (final region in regions.reversed) {
      if (region.rect.contains(Offset(dx, dy))) {
        setState(() => _selected = region.group);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final regions = _showBack ? _backRegions : _frontRegions;
    final selectedScore = _selected == null ? null : widget.scores[_selected];
    final overall = overallMuscleScore(widget.scores.values.map((s) => s.score));
    final overallRank = overall == null ? null : rankForScore(overall);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Silhouette musculaire', style: Theme.of(context).textTheme.titleMedium),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, label: Text('Face')),
                    ButtonSegment(value: true, label: Text('Dos')),
                  ],
                  selected: {_showBack},
                  onSelectionChanged: (s) => setState(() {
                    _showBack = s.first;
                    _selected = null;
                  }),
                ),
              ],
            ),
            if (overallRank != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      'Rang global',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.military_tech, size: 16, color: rankColor(overallRank)),
                    const SizedBox(width: 4),
                    Text(
                      overallRank.labelFr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: rankColor(overallRank),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 0.62,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onTapUp: (details) => _handleTapUp(details, size, regions),
                    child: CustomPaint(
                      size: size,
                      painter: _SilhouettePainter(
                        regions: regions,
                        scores: widget.scores,
                        selected: _selected,
                        scheme: scheme,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (selectedScore != null)
              _SelectedLegend(score: selectedScore)
            else if (_selected != null)
              Text(
                '${_selected!.labelFr} — pas encore de données',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              )
            else
              Text(
                'Touche une zone pour voir le détail',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectedLegend extends StatelessWidget {
  final MuscleGroupScore score;
  const _SelectedLegend({required this.score});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rank = rankForScore(score.score);
    final color = rankColor(rank);
    final next = rank.next;
    final pointsToNext = next == null ? null : (next.minScore - score.score).clamp(0, 100);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(score.muscleGroup.labelFr, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: 10),
            Icon(Icons.military_tech, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              rank.labelFr,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              '· ${score.score.toStringAsFixed(0)}/100',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (score.confidence < 1) ...[
              const SizedBox(width: 6),
              Icon(Icons.info_outline, size: 14, color: scheme.onSurfaceVariant),
            ],
          ],
        ),
        if (pointsToNext != null) ...[
          const SizedBox(height: 4),
          Text(
            '${pointsToNext.toStringAsFixed(0)} pts avant ${next!.labelFr}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Rang maximum atteint',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
      ],
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  final List<_Region> regions;
  final Map<MuscleGroup, MuscleGroupScore> scores;
  final MuscleGroup? selected;
  final ColorScheme scheme;

  _SilhouettePainter({
    required this.regions,
    required this.scores,
    required this.selected,
    required this.scheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Neutral body outline (head, torso, limbs) as reference context.
    final outlinePaint = Paint()
      ..color = scheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final bodyFill = Paint()..color = scheme.surfaceContainerHighest;

    // Head.
    final headCenter = Offset(w * 0.5, h * 0.08);
    canvas.drawOval(Rect.fromCenter(center: headCenter, width: w * 0.16, height: h * 0.11), bodyFill);
    canvas.drawOval(Rect.fromCenter(center: headCenter, width: w * 0.16, height: h * 0.11), outlinePaint);

    // Torso silhouette (rounded).
    final torso = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.22, h * 0.13, w * 0.78, h * 0.50),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(torso, bodyFill);

    // Legs silhouette.
    final legs = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.28, h * 0.46, w * 0.72, h * 0.98),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(legs, bodyFill);

    // Arms silhouette.
    final armL = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.02, h * 0.14, w * 0.24, h * 0.58),
      Radius.circular(w * 0.05),
    );
    final armR = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.76, h * 0.14, w * 0.98, h * 0.58),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(armL, bodyFill);
    canvas.drawRRect(armR, bodyFill);
    canvas.drawRRect(torso, outlinePaint);
    canvas.drawRRect(legs, outlinePaint);
    canvas.drawRRect(armL, outlinePaint);
    canvas.drawRRect(armR, outlinePaint);

    // Colored, tappable muscle regions on top.
    for (final region in regions) {
      final rect = Rect.fromLTRB(
        region.rect.left * w,
        region.rect.top * h,
        region.rect.right * w,
        region.rect.bottom * h,
      );
      final score = scores[region.group];
      final confidence = score?.confidence ?? 0;
      final baseColor = score == null
          ? scheme.surfaceContainerHighest
          : rankColor(rankForScore(score.score));
      final alpha = score == null ? 0.5 : (0.45 + 0.55 * confidence);

      final regionPaint = Paint()..color = baseColor.withValues(alpha: alpha);
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide * 0.3));
      canvas.drawRRect(rrect, regionPaint);

      if (region.group == selected) {
        final selectedPaint = Paint()
          ..color = scheme.secondary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawRRect(rrect, selectedPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter oldDelegate) {
    return oldDelegate.scores != scores ||
        oldDelegate.selected != selected ||
        oldDelegate.regions != regions;
  }
}
