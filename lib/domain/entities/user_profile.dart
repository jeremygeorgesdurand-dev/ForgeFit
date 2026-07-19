enum TrainingLevel { beginner, intermediate, advanced }

enum TrainingGoal { strength, hypertrophy, endurance, fatLoss, generalFitness }

enum UnitSystem { metric, imperial }

class EquipmentProfile {
  final String userId;
  final Set<String> availableEquipment;
  final bool isHomeGym;

  const EquipmentProfile({
    required this.userId,
    this.availableEquipment = const {},
    this.isHomeGym = false,
  });
}

class UserProfile {
  final String id;
  final String displayName;
  final double? heightCm;
  final double? weightKg;
  final DateTime? birthDate;
  final TrainingLevel level;
  final List<TrainingGoal> goals;
  final UnitSystem preferredUnits;
  final int weeklyFrequencyTarget;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    this.heightCm,
    this.weightKg,
    this.birthDate,
    this.level = TrainingLevel.beginner,
    this.goals = const [],
    this.preferredUnits = UnitSystem.metric,
    this.weeklyFrequencyTarget = 3,
    required this.createdAt,
  });
}
