/// Rule-based warm-up ramp toward a working weight — no LLM, just a
/// standard percentage progression lifters already use. Purely a
/// suggestion; nothing here is logged automatically.
class WarmupSet {
  final double weightKg;
  final int reps;
  const WarmupSet({required this.weightKg, required this.reps});
}

class WarmupCalculator {
  static const _steps = [
    (pct: 0.4, reps: 8),
    (pct: 0.6, reps: 5),
    (pct: 0.8, reps: 3),
  ];

  /// Empty when [workingWeightKg] is too light for a warm-up ramp to be
  /// meaningful (bodyweight work, empty bar, light isolation exercises).
  static List<WarmupSet> suggest(double workingWeightKg, {double minWorkingWeightKg = 25}) {
    if (workingWeightKg < minWorkingWeightKg) return [];

    final result = <WarmupSet>[];
    for (final step in _steps) {
      final weight = _roundToNearest(workingWeightKg * step.pct, 2.5);
      if (weight <= 0 || weight >= workingWeightKg) continue;
      if (result.isNotEmpty && weight <= result.last.weightKg) continue;
      result.add(WarmupSet(weightKg: weight, reps: step.reps));
    }
    return result;
  }

  static double _roundToNearest(double value, double increment) {
    return (value / increment).round() * increment;
  }
}
