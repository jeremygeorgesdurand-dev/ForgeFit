import '../entities/exercise.dart';
import '../entities/muscle_group.dart';

class ExerciseFilter {
  final MuscleGroup? muscleGroup;
  final String? equipment;
  final String? category;
  final String? searchQuery;

  const ExerciseFilter({
    this.muscleGroup,
    this.equipment,
    this.category,
    this.searchQuery,
  });
}

/// Abstraction over the exercise reference data source.
///
/// This is the seam that lets the exercises-dataset GitHub repo (research/
/// local mode) be swapped for a licensed provider/backend later without
/// touching any feature code — nothing above this interface knows the
/// dataset's raw JSON schema.
abstract class ExerciseRepository {
  Future<List<Exercise>> getAll();
  Future<List<Exercise>> search(ExerciseFilter filter);
  Future<Exercise?> getById(String id);
  Future<List<String>> listEquipmentOptions();
  Future<List<String>> listCategoryOptions();
}
