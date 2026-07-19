import '../entities/workout_session.dart';
import '../entities/workout_template.dart';

enum SuggestionAction { increaseLoad, maintain, decreaseLoad }

class LoadSuggestion {
  final SuggestionAction action;
  final double suggestedWeightKg;
  final String rationale;

  const LoadSuggestion(this.action, this.suggestedWeightKg, this.rationale);
}

/// Pure local heuristic — no LLM involved. See PARTIE 6: "suggestion
/// intelligente de charge/reps à la séance suivante".
class NextSessionSuggestionService {
  static LoadSuggestion suggest({
    required WorkoutSessionExercise lastExercise,
    required RepRange targetRepRange,
    required double lastWeightKg,
    bool isMachine = false,
  }) {
    final workingSets = lastExercise.sets.where((s) => !s.isWarmup).toList();
    if (workingSets.isEmpty) {
      return LoadSuggestion(
        SuggestionAction.maintain,
        lastWeightKg,
        'Pas de données de la dernière séance.',
      );
    }

    final anyFailed = workingSets.any((s) => s.actualReps < s.targetReps);
    if (anyFailed) {
      return LoadSuggestion(
        SuggestionAction.decreaseLoad,
        lastWeightKg * 0.9,
        'Échec de série détecté — réduction de charge de 10%.',
      );
    }

    final allAtTopOfRange = workingSets.every(
      (s) => s.actualReps >= targetRepRange.max && (s.rpe == null || s.rpe! <= 8),
    );
    if (allAtTopOfRange) {
      final increment = isMachine ? lastWeightKg * 1.05 : lastWeightKg + 2.5;
      return LoadSuggestion(
        SuggestionAction.increaseLoad,
        increment,
        'Haut de la plage de reps atteint avec RPE ≤ 8 sur toutes les séries.',
      );
    }

    return LoadSuggestion(
      SuggestionAction.maintain,
      lastWeightKg,
      'Performance stable — maintien de la charge.',
    );
  }
}
