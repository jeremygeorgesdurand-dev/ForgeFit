import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/entities/scheduled_session.dart';
import '../../domain/repositories/scheduled_session_repository.dart';
import '../datasources/local/app_database.dart';

class DriftScheduledSessionRepository implements ScheduledSessionRepository {
  final AppDatabase _db;
  static final _rng = Random();

  DriftScheduledSessionRepository(this._db);

  String _generateId() => '${DateTime.now().microsecondsSinceEpoch}-${_rng.nextInt(99999)}';

  @override
  Future<List<ScheduledSession>> getScheduled(String userId) async {
    final rows = await (_db.select(_db.scheduledSessions)
          ..where((s) => s.userId.equals(userId))
          ..orderBy([(s) => OrderingTerm.asc(s.date)]))
        .get();
    return rows
        .map((r) => ScheduledSession(
              id: r.id,
              userId: r.userId,
              templateId: r.templateId,
              date: r.date,
            ))
        .toList();
  }

  @override
  Future<ScheduledSession> scheduleSession(ScheduledSession session) async {
    final id = session.id.isEmpty ? _generateId() : session.id;
    await _db.into(_db.scheduledSessions).insertOnConflictUpdate(
          ScheduledSessionsCompanion.insert(
            id: id,
            userId: session.userId,
            templateId: session.templateId,
            date: session.date,
          ),
        );
    return ScheduledSession(
      id: id,
      userId: session.userId,
      templateId: session.templateId,
      date: session.date,
    );
  }

  @override
  Future<void> deleteScheduled(String id) async {
    await (_db.delete(_db.scheduledSessions)..where((s) => s.id.equals(id))).go();
  }
}
