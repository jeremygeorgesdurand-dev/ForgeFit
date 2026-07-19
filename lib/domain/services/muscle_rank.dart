/// Game-style tiers over the 0..100 [MuscleGroupScore], purely a
/// presentation layer over the same rule-based score — no new heuristic.
enum MuscleRank { iron, bronze, silver, gold, platinum, diamond }

extension MuscleRankThresholds on MuscleRank {
  /// Minimum score (inclusive) required to reach this rank.
  double get minScore => switch (this) {
        MuscleRank.iron => 0,
        MuscleRank.bronze => 15,
        MuscleRank.silver => 35,
        MuscleRank.gold => 55,
        MuscleRank.platinum => 75,
        MuscleRank.diamond => 90,
      };

  MuscleRank? get next {
    const order = MuscleRank.values;
    final i = order.indexOf(this);
    return i + 1 < order.length ? order[i + 1] : null;
  }
}

MuscleRank rankForScore(double score) {
  for (final rank in MuscleRank.values.reversed) {
    if (score >= rank.minScore) return rank;
  }
  return MuscleRank.iron;
}

/// Simple average across every muscle group that has a score yet — groups
/// never trained don't drag it down. Null when nothing has been scored.
double? overallMuscleScore(Iterable<double> scores) {
  final list = scores.toList();
  if (list.isEmpty) return null;
  return list.reduce((a, b) => a + b) / list.length;
}
