import 'user_profile.dart';

/// A generated multi-day program persisted as a whole, unlike its
/// individual days which live as plain [WorkoutTemplate]s. This is what
/// lets "Mes programmes" show the original split instead of a flat list of
/// unrelated templates.
class TrainingProgram {
  final String id;
  final String userId;
  final String name;
  final TrainingGoal goal;
  final TrainingLevel level;
  final DateTime createdAt;
  final List<String> templateIds;

  const TrainingProgram({
    required this.id,
    required this.userId,
    required this.name,
    required this.goal,
    required this.level,
    required this.createdAt,
    required this.templateIds,
  });
}
