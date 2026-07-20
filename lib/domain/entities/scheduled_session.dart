/// A template planned for a future date — distinct from [WorkoutSession],
/// which only exists once a session has actually started.
class ScheduledSession {
  final String id;
  final String userId;
  final String templateId;
  final DateTime date;

  const ScheduledSession({
    required this.id,
    required this.userId,
    required this.templateId,
    required this.date,
  });
}
