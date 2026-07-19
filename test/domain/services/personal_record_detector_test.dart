import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/domain/entities/progress.dart';
import 'package:forgefit/domain/entities/workout_session.dart';
import 'package:forgefit/domain/services/personal_record_detector.dart';

WorkoutSession _session({
  required String id,
  required DateTime startedAt,
  required List<WorkoutSessionExercise> exercises,
}) {
  return WorkoutSession(
    id: id,
    userId: 'u1',
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(hours: 1)),
    status: SessionStatus.completed,
    exercises: exercises,
  );
}

SetLog _set({
  required int weightKg,
  required int reps,
  int setIndex = 0,
  bool isWarmup = false,
}) {
  return SetLog(
    id: 's$weightKg-$reps-$setIndex',
    setIndex: setIndex,
    targetReps: reps,
    actualReps: reps,
    weightKg: weightKg.toDouble(),
    isWarmup: isWarmup,
    completedAt: DateTime(2026, 1, 1),
    restTakenSec: 90,
  );
}

void main() {
  group('estimated1RM', () {
    test('returns the weight itself for a single rep', () {
      expect(PersonalRecordDetector.estimated1RM(100, 1), 100);
    });

    test('applies the Epley formula above 1 rep', () {
      // 100 * (1 + 10/30) = 133.33...
      expect(PersonalRecordDetector.estimated1RM(100, 10), closeTo(133.33, 0.01));
    });
  });

  group('detectAll', () {
    test('flags the first-ever set on an exercise as a weight and 1RM record', () {
      final session = _session(
        id: 's1',
        startedAt: DateTime(2026, 1, 1),
        exercises: [
          WorkoutSessionExercise(exerciseId: 'bench', order: 0, sets: [_set(weightKg: 60, reps: 8)]),
        ],
      );

      final records = PersonalRecordDetector.detectAll('u1', [session]);

      expect(records.any((r) => r.type == RecordType.maxWeight && r.value == 60), isTrue);
      expect(records.any((r) => r.type == RecordType.estimated1RM), isTrue);
      expect(records.any((r) => r.type == RecordType.maxVolume), isTrue);
    });

    test('only flags a later session as a record when it actually beats the prior best', () {
      final earlier = _session(
        id: 's1',
        startedAt: DateTime(2026, 1, 1),
        exercises: [
          WorkoutSessionExercise(exerciseId: 'bench', order: 0, sets: [_set(weightKg: 60, reps: 8)]),
        ],
      );
      final same = _session(
        id: 's2',
        startedAt: DateTime(2026, 1, 8),
        exercises: [
          WorkoutSessionExercise(exerciseId: 'bench', order: 0, sets: [_set(weightKg: 60, reps: 8)]),
        ],
      );
      final heavier = _session(
        id: 's3',
        startedAt: DateTime(2026, 1, 15),
        exercises: [
          WorkoutSessionExercise(exerciseId: 'bench', order: 0, sets: [_set(weightKg: 65, reps: 8)]),
        ],
      );

      final records = PersonalRecordDetector.detectAll('u1', [earlier, same, heavier]);

      final weightRecords = records.where((r) => r.type == RecordType.maxWeight).toList();
      // Only the very first set (60kg) and the heavier one (65kg) should count —
      // the repeat of 60kg in session 2 must not produce a duplicate record.
      expect(weightRecords.length, 2);
      expect(weightRecords.last.value, 65);
      expect(weightRecords.last.sessionId, 's3');
    });

    test('ignores warmup sets entirely', () {
      final session = _session(
        id: 's1',
        startedAt: DateTime(2026, 1, 1),
        exercises: [
          WorkoutSessionExercise(
            exerciseId: 'squat',
            order: 0,
            sets: [
              _set(weightKg: 100, reps: 5, isWarmup: true),
              _set(weightKg: 80, reps: 5, setIndex: 1),
            ],
          ),
        ],
      );

      final records = PersonalRecordDetector.detectAll('u1', [session]);
      final weightRecords = records.where((r) => r.type == RecordType.maxWeight);

      expect(weightRecords.every((r) => r.value == 80), isTrue);
    });
  });
}
