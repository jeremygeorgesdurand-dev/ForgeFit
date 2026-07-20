import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../../core/localization/fr_labels.dart';
import '../../../core/theme/rank_colors.dart';
import '../../../domain/entities/muscle_group.dart';
import '../../../domain/entities/progress.dart';
import '../../../domain/services/muscle_rank.dart';
import 'muscle_svg_data.dart';

// Shared 0..35 (x) / 0..93 (y) coordinate space for both views — back-view
// paths come in at x+37 (their own viewBox is "37 0 35 93"), so they're
// shifted back by -37 once here instead of juggling two viewBoxes at
// paint/hit-test time.
const _viewWidth = 35.0;
const _viewHeight = 93.0;

class _MuscleRegion {
  final String svgId;
  final MuscleGroup? group;
  final Path path;
  const _MuscleRegion({required this.svgId, required this.group, required this.path});
}

List<_MuscleRegion> _buildRegions(Map<String, String> source, {required bool shiftBack}) {
  return [
    for (final entry in source.entries)
      _MuscleRegion(
        svgId: entry.key,
        group: muscleGroupForSvgId(entry.key),
        path: shiftBack
            ? parseSvgPathData(entry.value).shift(const Offset(-37, 0))
            : parseSvgPathData(entry.value),
      ),
  ];
}

// Parsed once per app run — parsing ~90 SVG paths on every repaint would be
// wasteful, and the source data never changes at runtime.
final _frontRegions = _buildRegions(frontMusclePaths, shiftBack: false);
final _backRegions = _buildRegions(backMusclePaths, shiftBack: true);

/// Interactive front/back anatomical body diagram: real muscle-shaped
/// regions (adapted from the open-source body-muscles project, Apache
/// License 2.0) tinted by [MuscleGroupScore], tap a region to see its
/// exact score.
class BodySilhouette extends StatefulWidget {
  final Map<MuscleGroup, MuscleGroupScore> scores;
  const BodySilhouette({super.key, required this.scores});

  @override
  State<BodySilhouette> createState() => _BodySilhouetteState();
}

class _BodySilhouetteState extends State<BodySilhouette> {
  bool _showBack = false;
  MuscleGroup? _selected;

  void _handleTapUp(TapUpDetails details, Size size, List<_MuscleRegion> regions) {
    final source = Offset(
      details.localPosition.dx / size.width * _viewWidth,
      details.localPosition.dy / size.height * _viewHeight,
    );
    for (final region in regions.reversed) {
      if (region.group == null) continue;
      if (region.path.contains(source)) {
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
              aspectRatio: _viewWidth / _viewHeight,
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
                'Touche un muscle pour voir le détail',
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
  final List<_MuscleRegion> regions;
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
    canvas.save();
    canvas.scale(size.width / _viewWidth, size.height / _viewHeight);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.12
      ..color = scheme.outlineVariant;

    for (final region in regions) {
      final score = region.group == null ? null : scores[region.group];
      final Color fillColor;
      if (region.group == null) {
        // Non-trainable anatomy (head, hands, feet, joints...) — always
        // neutral, never tinted by a score.
        fillColor = scheme.surfaceContainerHighest.withValues(alpha: 0.6);
      } else if (score == null) {
        fillColor = scheme.surfaceContainerHighest;
      } else {
        final rank = rankForScore(score.score);
        final alpha = 0.45 + 0.55 * score.confidence;
        fillColor = rankColor(rank).withValues(alpha: alpha);
      }

      canvas.drawPath(region.path, Paint()..color = fillColor);
      canvas.drawPath(region.path, strokePaint);

      if (region.group != null && region.group == selected) {
        canvas.drawPath(
          region.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.35
            ..color = scheme.secondary,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter oldDelegate) {
    return oldDelegate.scores != scores ||
        oldDelegate.selected != selected ||
        oldDelegate.regions != regions;
  }
}
