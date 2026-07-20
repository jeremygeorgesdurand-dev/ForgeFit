import '../entities/workout_template.dart';
import '../entities/workout_session.dart';

/// User-owned, highly customizable workout data. Backed locally by Drift
/// (offline-first) with best-effort sync to the backend in later phases.
abstract class WorkoutRepository {
  // Templates
  Future<List<WorkoutTemplate>> getTemplates(String userId);
  Future<WorkoutTemplate> saveTemplate(WorkoutTemplate template);
  Future<void> deleteTemplate(String templateId);

  // Sessions
  Future<WorkoutSession> startSession({
    required String userId,
    String? templateId,
  });
  Future<WorkoutSession> appendSet({
    required String sessionId,
    required String exerciseId,
    required SetLog set,
  });
  /// Corrects an already-logged set in place (fixing a typo'd weight/reps),
  /// matched by [SetLog.id].
  Future<WorkoutSession> updateSet({
    required String sessionId,
    required SetLog set,
  });
  Future<WorkoutSession> deleteSet({
    required String sessionId,
    required String setId,
  });
  Future<WorkoutSession> completeSession(String sessionId);
  Future<WorkoutSession> updateSessionNotes({
    required String sessionId,
    required String? notes,
  });
  /// Restores a full session tree (used by the data-import flow) —
  /// upserts the session, its exercises, and every set, honoring the ids
  /// already present on [session] so re-importing the same export twice
  /// is idempotent rather than duplicating rows.
  Future<void> importSession(WorkoutSession session);
  Future<List<WorkoutSession>> getHistory(String userId, {int limit = 50});
  Future<WorkoutSession?> findLastSimilarSession({
    required String userId,
    required WorkoutSession current,
  });
}
