import 'package:flutter/material.dart';

import '../../domain/services/muscle_rank.dart';

/// Fixed tier colors, independent of light/dark theme — a rank badge should
/// read the same regardless of the surrounding surface.
Color rankColor(MuscleRank rank) {
  switch (rank) {
    case MuscleRank.iron:
      return const Color(0xFF8A8F98);
    case MuscleRank.bronze:
      return const Color(0xFFB2703C);
    case MuscleRank.silver:
      return const Color(0xFFAEB8C4);
    case MuscleRank.gold:
      return const Color(0xFFE8B93A);
    case MuscleRank.platinum:
      return const Color(0xFF4FD1C5);
    case MuscleRank.diamond:
      return const Color(0xFF6C8CFF);
  }
}
