import 'package:flutter/material.dart';

import '../../../domain/entities/achievement.dart';

IconData achievementIcon(AchievementCategory category) {
  switch (category) {
    case AchievementCategory.sessions:
      return Icons.fitness_center;
    case AchievementCategory.volume:
      return Icons.scale;
    case AchievementCategory.streak:
      return Icons.local_fire_department;
    case AchievementCategory.records:
      return Icons.emoji_events;
    case AchievementCategory.rank:
      return Icons.military_tech;
  }
}
