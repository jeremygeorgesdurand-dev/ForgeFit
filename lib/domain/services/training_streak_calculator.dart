import '../entities/workout_session.dart';

DateTime _mondayOf(DateTime d) {
  final date = DateTime(d.year, d.month, d.day);
  return date.subtract(Duration(days: date.weekday - 1));
}

/// Consecutive weeks (ISO, Monday-start) with at least one completed
/// session, counted backward from the current week. The current week
/// doesn't break the streak just because no session has happened yet.
int weekStreak(List<WorkoutSession> sessions, {DateTime? now}) {
  final weeksWithSessions = <DateTime>{
    for (final s in sessions)
      if (s.status == SessionStatus.completed) _mondayOf(s.startedAt.toLocal()),
  };
  if (weeksWithSessions.isEmpty) return 0;

  var cursor = _mondayOf(now ?? DateTime.now());
  if (!weeksWithSessions.contains(cursor)) {
    cursor = cursor.subtract(const Duration(days: 7));
  }
  var streak = 0;
  while (weeksWithSessions.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 7));
  }
  return streak;
}

int sessionsThisWeek(List<WorkoutSession> sessions, {DateTime? now}) {
  final monday = _mondayOf(now ?? DateTime.now());
  return sessions
      .where((s) =>
          s.status == SessionStatus.completed && !_mondayOf(s.startedAt.toLocal()).isBefore(monday))
      .length;
}
