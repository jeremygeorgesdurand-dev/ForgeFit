import 'package:drift/drift.dart';

import '../../domain/entities/progress.dart';
import '../../domain/repositories/body_metrics_repository.dart';
import '../datasources/local/app_database.dart';

class DriftBodyMetricsRepository implements BodyMetricsRepository {
  final AppDatabase _db;

  DriftBodyMetricsRepository(this._db);

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Future<List<BodyMetric>> getHistory(String userId, {int limit = 200}) async {
    final rows = await (_db.select(_db.bodyMetrics)
          ..where((m) => m.userId.equals(userId))
          ..orderBy([(m) => OrderingTerm.desc(m.date)])
          ..limit(limit))
        .get();
    return rows
        .map((r) => BodyMetric(
              userId: r.userId,
              date: r.date,
              weightKg: r.weightKg,
              bodyFatPct: r.bodyFatPct,
            ))
        .toList();
  }

  @override
  Future<void> logMetric(BodyMetric metric) async {
    // One entry per calendar day: replace whatever was logged for that day.
    final day = _dayOnly(metric.date);
    final nextDay = day.add(const Duration(days: 1));
    await (_db.delete(_db.bodyMetrics)
          ..where((m) =>
              m.userId.equals(metric.userId) &
              m.date.isBiggerOrEqualValue(day) &
              m.date.isSmallerThanValue(nextDay)))
        .go();
    await _db.into(_db.bodyMetrics).insert(
          BodyMetricsCompanion.insert(
            userId: metric.userId,
            date: day,
            weightKg: Value(metric.weightKg),
            bodyFatPct: Value(metric.bodyFatPct),
          ),
        );
  }

  @override
  Future<void> deleteMetric(String userId, DateTime date) async {
    final day = _dayOnly(date);
    final nextDay = day.add(const Duration(days: 1));
    await (_db.delete(_db.bodyMetrics)
          ..where((m) =>
              m.userId.equals(userId) &
              m.date.isBiggerOrEqualValue(day) &
              m.date.isSmallerThanValue(nextDay)))
        .go();
  }
}
