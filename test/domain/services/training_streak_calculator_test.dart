import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/domain/entities/workout_session.dart';
import 'package:forgefit/domain/services/training_streak_calculator.dart';

WorkoutSession _sessionOn(DateTime date) {
  return WorkoutSession(
    id: 's-${date.toIso8601String()}',
    userId: 'u',
    startedAt: date,
    endedAt: date.add(const Duration(minutes: 45)),
    status: SessionStatus.completed,
  );
}

void main() {
  // A fixed Wednesday so "now" is unambiguous relative to week boundaries.
  final now = DateTime(2026, 7, 15);

  test('weekStreak is 0 with no completed sessions', () {
    expect(weekStreak([], now: now), 0);
  });

  test('weekStreak counts the current week even before it ends', () {
    final sessions = [_sessionOn(now)];
    expect(weekStreak(sessions, now: now), 1);
  });

  test('weekStreak counts consecutive prior weeks without breaking on an in-progress current week', () {
    final sessions = [
      _sessionOn(now.subtract(const Duration(days: 7))),
      _sessionOn(now.subtract(const Duration(days: 14))),
    ];
    expect(weekStreak(sessions, now: now), 2);
  });

  test('weekStreak stops at the first gap', () {
    final sessions = [
      _sessionOn(now),
      _sessionOn(now.subtract(const Duration(days: 7))),
      // gap at now-14
      _sessionOn(now.subtract(const Duration(days: 21))),
    ];
    expect(weekStreak(sessions, now: now), 2);
  });

  test('sessionsThisWeek only counts sessions from the current week onward', () {
    final sessions = [
      _sessionOn(now),
      _sessionOn(now.subtract(const Duration(days: 1))),
      _sessionOn(now.subtract(const Duration(days: 10))),
    ];
    expect(sessionsThisWeek(sessions, now: now), 2);
  });
}
