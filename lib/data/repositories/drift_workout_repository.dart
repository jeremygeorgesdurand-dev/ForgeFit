import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/local/app_database.dart';

class DriftWorkoutRepository implements WorkoutRepository {
  final AppDatabase _db;
  final _rng = Random();

  DriftWorkoutRepository(this._db);

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_rng.nextInt(99999)}';

  // ---- Templates ----

  @override
  Future<List<WorkoutTemplate>> getTemplates(String userId) async {
    final rows = await (_db.select(_db.workoutTemplates)
          ..where((t) => t.userId.equals(userId)))
        .get();
    return Future.wait(rows.map(_hydrateTemplate));
  }

  Future<WorkoutTemplate> _hydrateTemplate(WorkoutTemplateRow row) async {
    final exerciseRows = await (_db.select(_db.workoutTemplateExercises)
          ..where((e) => e.templateId.equals(row.id))
          ..orderBy([(e) => OrderingTerm.asc(e.sortOrder)]))
        .get();

    return WorkoutTemplate(
      id: row.id,
      userId: row.userId,
      name: row.name,
      createdAt: row.createdAt,
      lastUsedAt: row.lastUsedAt,
      exercises: exerciseRows
          .map(
            (e) => WorkoutTemplateExercise(
              exerciseId: e.exerciseId,
              order: e.sortOrder,
              targetSets: e.targetSets,
              targetRepRange: RepRange(e.targetRepMin, e.targetRepMax),
              targetRestSec: e.targetRestSec,
              targetWeightKg: e.targetWeightKg,
              targetRpe: e.targetRpe,
              notes: e.notes,
              supersetGroup: e.supersetGroup,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<WorkoutTemplate> saveTemplate(WorkoutTemplate template) async {
    final id = template.id.isEmpty ? _newId() : template.id;

    await _db.transaction(() async {
      await _db.into(_db.workoutTemplates).insertOnConflictUpdate(
            WorkoutTemplatesCompanion.insert(
              id: id,
              userId: template.userId,
              name: template.name,
              createdAt: template.createdAt,
              lastUsedAt: Value(template.lastUsedAt),
            ),
          );

      await (_db.delete(_db.workoutTemplateExercises)
            ..where((e) => e.templateId.equals(id)))
          .go();

      for (final ex in template.exercises) {
        await _db.into(_db.workoutTemplateExercises).insert(
              WorkoutTemplateExercisesCompanion.insert(
                templateId: id,
                exerciseId: ex.exerciseId,
                sortOrder: ex.order,
                targetSets: ex.targetSets,
                targetRepMin: ex.targetRepRange.min,
                targetRepMax: ex.targetRepRange.max,
                targetRestSec: ex.targetRestSec,
                targetWeightKg: Value(ex.targetWeightKg),
                targetRpe: Value(ex.targetRpe),
                notes: Value(ex.notes),
                supersetGroup: Value(ex.supersetGroup),
              ),
            );
      }
    });

    final saved = await (_db.select(_db.workoutTemplates)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    return _hydrateTemplate(saved);
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.workoutTemplateExercises)
            ..where((e) => e.templateId.equals(templateId)))
          .go();
      await (_db.delete(_db.workoutTemplates)
            ..where((t) => t.id.equals(templateId)))
          .go();
    });
  }

  // ---- Sessions ----

  @override
  Future<WorkoutSession> startSession({
    required String userId,
    String? templateId,
  }) async {
    final id = _newId();
    final startedAt = DateTime.now();
    await _db.into(_db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            id: id,
            userId: userId,
            templateId: Value(templateId),
            startedAt: startedAt,
            status: const Value('inProgress'),
          ),
        );
    return WorkoutSession(
      id: id,
      userId: userId,
      templateId: templateId,
      startedAt: startedAt,
    );
  }

  @override
  Future<WorkoutSession> appendSet({
    required String sessionId,
    required String exerciseId,
    required SetLog set,
  }) async {
    await _db.transaction(() async {
      var sessionExercise = await (_db.select(_db.workoutSessionExercises)
            ..where(
              (e) => e.sessionId.equals(sessionId) & e.exerciseId.equals(exerciseId),
            ))
          .getSingleOrNull();

      int sessionExerciseId;
      if (sessionExercise == null) {
        final currentCount = await (_db.select(_db.workoutSessionExercises)
              ..where((e) => e.sessionId.equals(sessionId)))
            .get();
        sessionExerciseId = await _db.into(_db.workoutSessionExercises).insert(
              WorkoutSessionExercisesCompanion.insert(
                sessionId: sessionId,
                exerciseId: exerciseId,
                sortOrder: currentCount.length,
              ),
            );
      } else {
        sessionExerciseId = sessionExercise.id;
      }

      final setId = set.id.isEmpty ? _newId() : set.id;
      await _db.into(_db.setLogs).insert(
            SetLogsCompanion.insert(
              id: setId,
              sessionExerciseId: sessionExerciseId,
              setIndex: set.setIndex,
              targetReps: set.targetReps,
              actualReps: set.actualReps,
              weightKg: set.weightKg,
              rpe: Value(set.rpe),
              rir: Value(set.rir),
              isWarmup: Value(set.isWarmup),
              completedAt: set.completedAt,
              restTakenSec: set.restTakenSec,
            ),
          );
    });

    return _hydrateSession(sessionId);
  }

  @override
  Future<WorkoutSession> updateSet({
    required String sessionId,
    required SetLog set,
  }) async {
    await (_db.update(_db.setLogs)..where((s) => s.id.equals(set.id))).write(
      SetLogsCompanion(
        setIndex: Value(set.setIndex),
        targetReps: Value(set.targetReps),
        actualReps: Value(set.actualReps),
        weightKg: Value(set.weightKg),
        rpe: Value(set.rpe),
        rir: Value(set.rir),
        isWarmup: Value(set.isWarmup),
        completedAt: Value(set.completedAt),
        restTakenSec: Value(set.restTakenSec),
      ),
    );
    return _hydrateSession(sessionId);
  }

  @override
  Future<WorkoutSession> deleteSet({
    required String sessionId,
    required String setId,
  }) async {
    await (_db.delete(_db.setLogs)..where((s) => s.id.equals(setId))).go();
    return _hydrateSession(sessionId);
  }

  @override
  Future<WorkoutSession> completeSession(String sessionId) async {
    await (_db.update(_db.workoutSessions)..where((s) => s.id.equals(sessionId)))
        .write(
      WorkoutSessionsCompanion(
        endedAt: Value(DateTime.now()),
        status: const Value('completed'),
      ),
    );
    return _hydrateSession(sessionId);
  }

  @override
  Future<WorkoutSession> updateSessionNotes({
    required String sessionId,
    required String? notes,
  }) async {
    await (_db.update(_db.workoutSessions)..where((s) => s.id.equals(sessionId))).write(
      WorkoutSessionsCompanion(notes: Value(notes)),
    );
    return _hydrateSession(sessionId);
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await _db.transaction(() async {
      final exerciseRows = await (_db.select(_db.workoutSessionExercises)
            ..where((e) => e.sessionId.equals(sessionId)))
          .get();
      for (final exRow in exerciseRows) {
        await (_db.delete(_db.setLogs)..where((s) => s.sessionExerciseId.equals(exRow.id)))
            .go();
      }
      await (_db.delete(_db.workoutSessionExercises)
            ..where((e) => e.sessionId.equals(sessionId)))
          .go();
      await (_db.delete(_db.workoutSessions)..where((s) => s.id.equals(sessionId))).go();
    });
  }

  @override
  Future<void> importSession(WorkoutSession session) async {
    await _db.transaction(() async {
      await _db.into(_db.workoutSessions).insertOnConflictUpdate(
            WorkoutSessionsCompanion.insert(
              id: session.id,
              userId: session.userId,
              templateId: Value(session.templateId),
              startedAt: session.startedAt,
              endedAt: Value(session.endedAt),
              status: Value(session.status.name),
              notes: Value(session.notes),
            ),
          );

      for (final ex in session.exercises) {
        var sessionExercise = await (_db.select(_db.workoutSessionExercises)
              ..where(
                (e) => e.sessionId.equals(session.id) & e.exerciseId.equals(ex.exerciseId),
              ))
            .getSingleOrNull();

        int sessionExerciseId;
        if (sessionExercise == null) {
          sessionExerciseId = await _db.into(_db.workoutSessionExercises).insert(
                WorkoutSessionExercisesCompanion.insert(
                  sessionId: session.id,
                  exerciseId: ex.exerciseId,
                  sortOrder: ex.order,
                ),
              );
        } else {
          sessionExerciseId = sessionExercise.id;
        }

        for (final set in ex.sets) {
          final setId = set.id.isEmpty ? _newId() : set.id;
          await _db.into(_db.setLogs).insertOnConflictUpdate(
                SetLogsCompanion.insert(
                  id: setId,
                  sessionExerciseId: sessionExerciseId,
                  setIndex: set.setIndex,
                  targetReps: set.targetReps,
                  actualReps: set.actualReps,
                  weightKg: set.weightKg,
                  rpe: Value(set.rpe),
                  rir: Value(set.rir),
                  isWarmup: Value(set.isWarmup),
                  completedAt: set.completedAt,
                  restTakenSec: set.restTakenSec,
                ),
              );
        }
      }
    });
  }

  Future<WorkoutSession> _hydrateSession(String sessionId) async {
    final row = await (_db.select(_db.workoutSessions)
          ..where((s) => s.id.equals(sessionId)))
        .getSingle();

    final exerciseRows = await (_db.select(_db.workoutSessionExercises)
          ..where((e) => e.sessionId.equals(sessionId))
          ..orderBy([(e) => OrderingTerm.asc(e.sortOrder)]))
        .get();

    final exercises = <WorkoutSessionExercise>[];
    for (final exRow in exerciseRows) {
      final setRows = await (_db.select(_db.setLogs)
            ..where((s) => s.sessionExerciseId.equals(exRow.id))
            ..orderBy([(s) => OrderingTerm.asc(s.setIndex)]))
          .get();

      exercises.add(
        WorkoutSessionExercise(
          exerciseId: exRow.exerciseId,
          order: exRow.sortOrder,
          sets: setRows
              .map(
                (s) => SetLog(
                  id: s.id,
                  setIndex: s.setIndex,
                  targetReps: s.targetReps,
                  actualReps: s.actualReps,
                  weightKg: s.weightKg,
                  rpe: s.rpe,
                  rir: s.rir,
                  isWarmup: s.isWarmup,
                  completedAt: s.completedAt,
                  restTakenSec: s.restTakenSec,
                ),
              )
              .toList(),
        ),
      );
    }

    return WorkoutSession(
      id: row.id,
      userId: row.userId,
      templateId: row.templateId,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      status: SessionStatus.values.firstWhere(
        (s) => s.name == row.status,
        orElse: () => SessionStatus.inProgress,
      ),
      exercises: exercises,
      notes: row.notes,
    );
  }

  @override
  Future<List<WorkoutSession>> getHistory(String userId, {int limit = 50}) async {
    final rows = await (_db.select(_db.workoutSessions)
          ..where((s) => s.userId.equals(userId))
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
          ..limit(limit))
        .get();
    return Future.wait(rows.map((r) => _hydrateSession(r.id)));
  }

  @override
  Future<WorkoutSession?> findLastSimilarSession({
    required String userId,
    required WorkoutSession current,
  }) async {
    final currentIds = current.exercises.map((e) => e.exerciseId).toSet();
    if (currentIds.isEmpty) return null;

    final completed = await getHistory(userId, limit: 200);

    WorkoutSession? best;
    double bestScore = 0;
    for (final s in completed) {
      if (s.id == current.id || s.status != SessionStatus.completed) continue;
      final ids = s.exercises.map((e) => e.exerciseId).toSet();
      if (ids.isEmpty) continue;
      final intersection = currentIds.intersection(ids).length;
      final union = currentIds.union(ids).length;
      final jaccard = intersection / union;
      if (jaccard >= 0.7 && jaccard > bestScore) {
        bestScore = jaccard;
        best = s;
      }
    }
    return best;
  }
}
