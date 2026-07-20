import '../entities/scheduled_session.dart';

abstract class ScheduledSessionRepository {
  Future<List<ScheduledSession>> getScheduled(String userId);
  Future<ScheduledSession> scheduleSession(ScheduledSession session);
  Future<void> deleteScheduled(String id);
}
