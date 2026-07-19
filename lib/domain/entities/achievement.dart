enum AchievementCategory { sessions, volume, streak, records, rank }

/// Rule-based, always recomputed from existing history/records/scores —
/// never persisted, never LLM-decided. Unlocking is a pure function of the
/// same numbers already shown elsewhere in the app.
class Achievement {
  final String id;
  final AchievementCategory category;
  final String titleFr;
  final String descriptionFr;
  final bool unlocked;
  final double progress; // 0..1
  final double current;
  final double target;

  const Achievement({
    required this.id,
    required this.category,
    required this.titleFr,
    required this.descriptionFr,
    required this.unlocked,
    required this.progress,
    required this.current,
    required this.target,
  });
}
