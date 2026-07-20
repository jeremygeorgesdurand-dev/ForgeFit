import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/data/datasources/local/app_database.dart';
import 'package:forgefit/data/repositories/drift_workout_repository.dart';
import 'package:forgefit/domain/entities/workout_session.dart';

void main() {
  late AppDatabase db;
  late DriftWorkoutRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftWorkoutRepository(db);
  });

  tearDown(() => db.close());

  test('deleteSession removes the session and every set logged under it', () async {
    const userId = 'u1';
    var session = await repo.startSession(userId: userId);
    session = await repo.appendSet(
      sessionId: session.id,
      exerciseId: 'bench-press',
      set: SetLog(
        id: 's1',
        setIndex: 0,
        targetReps: 8,
        actualReps: 8,
        weightKg: 60,
        completedAt: DateTime(2026, 1, 1),
        restTakenSec: 0,
      ),
    );
    await repo.completeSession(session.id);

    expect(await repo.getHistory(userId), hasLength(1));

    await repo.deleteSession(session.id);

    expect(await repo.getHistory(userId), isEmpty);
  });

  test('a deleted session can be restored via importSession (undo)', () async {
    const userId = 'u1';
    var session = await repo.startSession(userId: userId);
    session = await repo.appendSet(
      sessionId: session.id,
      exerciseId: 'squat',
      set: SetLog(
        id: 's1',
        setIndex: 0,
        targetReps: 5,
        actualReps: 5,
        weightKg: 100,
        completedAt: DateTime(2026, 1, 1),
        restTakenSec: 0,
      ),
    );
    session = await repo.completeSession(session.id);

    await repo.deleteSession(session.id);
    expect(await repo.getHistory(userId), isEmpty);

    await repo.importSession(session);
    final restored = await repo.getHistory(userId);
    expect(restored, hasLength(1));
    expect(restored.single.exercises.single.sets.single.weightKg, 100);
  });
}
