import 'muscle_group.dart';

enum MediaSource { localDataset, remoteLicensed }

class ExerciseMedia {
  final String? imagePath;
  final String? gifPath;
  final MediaSource source;

  /// Mandatory copyright notice for media from the research dataset
  /// (© Gym visual — see assets/data/DATASET_LICENSE_NOTE.md). Must stay
  /// visible wherever this media is displayed.
  final String? attribution;

  const ExerciseMedia({
    this.imagePath,
    this.gifPath,
    this.source = MediaSource.localDataset,
    this.attribution,
  });
}

/// Read-only exercise reference entity. Never mutated by user actions —
/// user customization lives in [WorkoutTemplateExercise], not here.
class Exercise {
  final String id;
  final String name;
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;
  final String equipment;
  final String category;

  /// Localized instruction steps (French preferred, English fallback —
  /// the dataset ships 10 languages, see RawExerciseRow.instructionSteps).
  final List<String> instructions;
  final ExerciseMedia media;

  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.equipment,
    required this.category,
    this.instructions = const [],
    this.media = const ExerciseMedia(),
  });
}
