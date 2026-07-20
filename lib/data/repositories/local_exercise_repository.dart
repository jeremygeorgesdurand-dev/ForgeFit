import '../../core/localization/fr_labels.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../datasources/local/exercises_dataset_loader.dart';

/// `ExerciseRepository` backed directly by the bundled exercises-dataset
/// JSON. Educational/non-commercial data source — see ADR in
/// `assets/data/DATASET_LICENSE_NOTE.md`. Swappable for a licensed/remote
/// implementation without changing any feature code.
class LocalExerciseRepository implements ExerciseRepository {
  final ExercisesDatasetLoader _loader;
  List<Exercise>? _normalizedCache;

  LocalExerciseRepository(this._loader);

  /// Language preference order for instruction steps: French first (native
  /// UI language), English as fallback since it's always present.
  static const _languagePriority = ['fr', 'en'];

  List<String> _stepsFor(RawExerciseRow row) {
    for (final lang in _languagePriority) {
      final steps = row.instructionSteps[lang];
      if (steps != null && steps.isNotEmpty) return steps;
    }
    return row.instructionSteps.values.firstWhere(
      (s) => s.isNotEmpty,
      orElse: () => const [],
    );
  }

  Future<List<Exercise>> _normalized() async {
    final cached = _normalizedCache;
    if (cached != null) return cached;

    final rows = await _loader.load();
    final exercises = rows
        .map(
          (row) => Exercise(
            id: row.id,
            name: row.name,
            primaryMuscle: MuscleGroup.fromRaw(row.target.isNotEmpty ? row.target : row.bodyPart),
            secondaryMuscles:
                row.secondaryMuscles.map(MuscleGroup.fromRaw).toList(),
            equipment: row.equipment,
            category: row.category,
            instructions: _stepsFor(row),
            media: ExerciseMedia(
              imagePath: 'assets/${row.image}',
              gifPath: 'assets/${row.gifUrl}',
              attribution: row.attribution,
            ),
          ),
        )
        .toList(growable: false);

    _normalizedCache = exercises;
    return exercises;
  }

  @override
  Future<List<Exercise>> getAll() => _normalized();

  @override
  Future<Exercise?> getById(String id) async {
    final all = await _normalized();
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<List<Exercise>> search(ExerciseFilter filter) async {
    final all = await _normalized();
    return all.where((e) {
      if (filter.muscleGroup != null &&
          e.primaryMuscle != filter.muscleGroup &&
          !e.secondaryMuscles.contains(filter.muscleGroup)) {
        return false;
      }
      if (filter.equipment != null &&
          e.equipment.toLowerCase() != filter.equipment!.toLowerCase()) {
        return false;
      }
      if (filter.category != null &&
          e.category.toLowerCase() != filter.category!.toLowerCase()) {
        return false;
      }
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final q = filter.searchQuery!.toLowerCase();
        // The dataset only has English exercise names, so also match the
        // French muscle/equipment labels shown in the UI — lets someone
        // type "pectoraux" or "haltère" and still find something, even
        // without knowing the English exercise name.
        final haystack = [
          e.name,
          e.primaryMuscle.labelFr,
          equipmentLabelFr(e.equipment),
          for (final m in e.secondaryMuscles) m.labelFr,
        ].join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<String>> listEquipmentOptions() async {
    final all = await _normalized();
    return all.map((e) => e.equipment).where((e) => e.isNotEmpty).toSet().toList()..sort();
  }

  @override
  Future<List<String>> listCategoryOptions() async {
    final all = await _normalized();
    return all.map((e) => e.category).where((e) => e.isNotEmpty).toSet().toList()..sort();
  }
}
