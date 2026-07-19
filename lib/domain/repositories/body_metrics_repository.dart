import '../entities/progress.dart';

/// User-entered body measurements over time (weight, body fat %). Source of
/// truth, unlike [ProgressRepository]'s derived data — nothing recomputes
/// this from elsewhere.
abstract class BodyMetricsRepository {
  Future<List<BodyMetric>> getHistory(String userId, {int limit = 200});
  Future<void> logMetric(BodyMetric metric);
  Future<void> deleteMetric(String userId, DateTime date);
}
