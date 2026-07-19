import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/services/muscle_rank.dart';

extension MuscleRankFrLabel on MuscleRank {
  String get labelFr {
    switch (this) {
      case MuscleRank.iron:
        return 'Fer';
      case MuscleRank.bronze:
        return 'Bronze';
      case MuscleRank.silver:
        return 'Argent';
      case MuscleRank.gold:
        return 'Or';
      case MuscleRank.platinum:
        return 'Platine';
      case MuscleRank.diamond:
        return 'Diamant';
    }
  }
}

extension RecordTypeFrLabel on RecordType {
  String get labelFr {
    switch (this) {
      case RecordType.estimated1RM:
        return '1RM estimée';
      case RecordType.maxWeight:
        return 'Charge max';
      case RecordType.maxVolume:
        return 'Volume max (séance)';
      case RecordType.maxReps:
        return 'Reps max';
    }
  }
}

/// French display labels for the app's UI. The dataset itself (equipment
/// strings, enum identifiers) stays in English internally — this is purely
/// a presentation-layer concern, kept in one place so every screen renders
/// the same wording.
extension MuscleGroupFrLabel on MuscleGroup {
  String get labelFr {
    switch (this) {
      case MuscleGroup.chest:
        return 'Pectoraux';
      case MuscleGroup.back:
        return 'Dos';
      case MuscleGroup.shoulders:
        return 'Épaules';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.forearms:
        return 'Avant-bras';
      case MuscleGroup.core:
        return 'Abdominaux';
      case MuscleGroup.quads:
        return 'Quadriceps';
      case MuscleGroup.hamstrings:
        return 'Ischio-jambiers';
      case MuscleGroup.glutes:
        return 'Fessiers';
      case MuscleGroup.calves:
        return 'Mollets';
      case MuscleGroup.fullBody:
        return 'Cardio / corps entier';
      case MuscleGroup.unknown:
        return 'Autre';
    }
  }
}

extension TrainingLevelFrLabel on TrainingLevel {
  String get labelFr {
    switch (this) {
      case TrainingLevel.beginner:
        return 'Débutant';
      case TrainingLevel.intermediate:
        return 'Intermédiaire';
      case TrainingLevel.advanced:
        return 'Avancé';
    }
  }
}

extension TrainingGoalFrLabel on TrainingGoal {
  String get labelFr {
    switch (this) {
      case TrainingGoal.strength:
        return 'Force';
      case TrainingGoal.hypertrophy:
        return 'Hypertrophie';
      case TrainingGoal.endurance:
        return 'Endurance';
      case TrainingGoal.fatLoss:
        return 'Perte de gras';
      case TrainingGoal.generalFitness:
        return 'Forme générale';
    }
  }
}

/// Raw `equipment` values as they appear in the exercises dataset →
/// French label. Falls back to a capitalized version of the raw value for
/// anything not explicitly mapped, so new dataset values never show up
/// blank.
const _equipmentLabelsFr = <String, String>{
  'assisted': 'Assisté',
  'band': 'Élastique',
  'barbell': 'Barre',
  'body weight': 'Poids du corps',
  'bosu ball': 'Bosu',
  'cable': 'Poulie',
  'dumbbell': 'Haltère',
  'elliptical machine': 'Vélo elliptique',
  'ez barbell': 'Barre EZ',
  'hammer': 'Marteau',
  'kettlebell': 'Kettlebell',
  'leverage machine': 'Machine guidée',
  'medicine ball': 'Medicine ball',
  'olympic barbell': 'Barre olympique',
  'resistance band': 'Bande de résistance',
  'roller': 'Rouleau',
  'rope': 'Corde',
  'skierg machine': 'SkiErg',
  'sled machine': 'Traîneau',
  'smith machine': 'Machine Smith',
  'stability ball': 'Swiss ball',
  'stationary bike': 'Vélo d\'appartement',
  'stepmill machine': 'Stepmill',
  'tire': 'Pneu',
  'trap bar': 'Barre hexagonale',
  'upper body ergometer': 'Ergomètre bras',
  'weighted': 'Lesté',
  'wheel roller': 'Roue abdominale',
};

String equipmentLabelFr(String raw) {
  final label = _equipmentLabelsFr[raw.trim().toLowerCase()];
  if (label != null) return label;
  if (raw.isEmpty) return raw;
  return raw[0].toUpperCase() + raw.substring(1);
}
