import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Raw row as it exists in the bundled exercises-dataset JSON
/// (github.com/hasaneyldrm/exercises-dataset, data/exercises.json —
/// schema confirmed against data/exercises.schema.json).
///
/// This class intentionally mirrors the dataset's own field names verbatim
/// (snake_case, per-language maps). It is the ONLY place in the codebase
/// allowed to know that schema — every other layer consumes the normalized
/// `Exercise` domain entity instead.
class RawExerciseRow {
  final String id;
  final String name;
  final String category;
  final String bodyPart;
  final String equipment;

  /// Full instructions per ISO 639-1 language code (en, es, it, tr, ru, zh,
  /// hi, pl, ko, fr).
  final Map<String, String> instructions;

  /// Same instructions split into ordered steps, per language.
  final Map<String, List<String>> instructionSteps;

  final String muscleGroup;
  final List<String> secondaryMuscles;
  final String target;
  final String image;
  final String gifUrl;
  final String mediaId;
  final String attribution;

  RawExerciseRow({
    required this.id,
    required this.name,
    required this.category,
    required this.bodyPart,
    required this.equipment,
    required this.instructions,
    required this.instructionSteps,
    required this.muscleGroup,
    this.secondaryMuscles = const [],
    required this.target,
    required this.image,
    required this.gifUrl,
    required this.mediaId,
    required this.attribution,
  });

  factory RawExerciseRow.fromJson(Map<String, dynamic> json) {
    final rawInstructions = (json['instructions'] as Map?)?.cast<String, dynamic>() ?? {};
    final rawSteps = (json['instruction_steps'] as Map?)?.cast<String, dynamic>() ?? {};

    return RawExerciseRow(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      bodyPart: json['body_part'] as String? ?? '',
      equipment: json['equipment'] as String? ?? '',
      instructions: rawInstructions.map((k, v) => MapEntry(k, v as String? ?? '')),
      instructionSteps: rawSteps.map(
        (k, v) => MapEntry(k, (v as List?)?.map((e) => e.toString()).toList() ?? const []),
      ),
      muscleGroup: json['muscle_group'] as String? ?? '',
      secondaryMuscles: (json['secondary_muscles'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      target: json['target'] as String? ?? '',
      image: json['image'] as String? ?? '',
      gifUrl: json['gif_url'] as String? ?? '',
      mediaId: json['media_id'] as String? ?? '',
      attribution: json['attribution'] as String? ?? '',
    );
  }
}

/// Loads the bundled dataset JSON asset once and caches the parsed rows.
///
/// This is the "prototype/local/research" data source. A future production
/// provider (licensed media, remote catalog) implements the same
/// contract-shape but is wired in at the repository level
/// (see [ExerciseRepository]) — this loader is never referenced outside
/// `data/repositories/local_exercise_repository.dart`.
class ExercisesDatasetLoader {
  static const _assetPath = 'assets/data/exercises.json';

  List<RawExerciseRow>? _cache;

  Future<List<RawExerciseRow>> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    final rows = decoded
        .cast<Map<String, dynamic>>()
        .map(RawExerciseRow.fromJson)
        .toList(growable: false);

    _cache = rows;
    return rows;
  }
}
