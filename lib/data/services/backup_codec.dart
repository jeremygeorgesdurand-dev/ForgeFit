import '../../domain/entities/progress.dart';
import '../../domain/entities/training_program.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_template.dart';

/// Full-fidelity snapshot of everything a local user owns — the same data
/// [BackupCodec.encode] serializes and [BackupCodec.decode] restores.
/// Ids are preserved end to end so re-importing the same backup twice is
/// idempotent rather than duplicating rows.
class BackupData {
  final UserProfile? profile;
  final EquipmentProfile? equipmentProfile;
  final List<WorkoutTemplate> templates;
  final List<WorkoutSession> sessions;
  final List<TrainingProgram> trainingPrograms;
  final List<BodyMetric> bodyMetrics;
  final List<String> favoriteExerciseIds;

  const BackupData({
    this.profile,
    this.equipmentProfile,
    this.templates = const [],
    this.sessions = const [],
    this.trainingPrograms = const [],
    this.bodyMetrics = const [],
    this.favoriteExerciseIds = const [],
  });
}

class BackupCodec {
  static const formatVersion = 1;

  static Map<String, dynamic> encode(BackupData data) {
    final profile = data.profile;
    final equipment = data.equipmentProfile;

    return {
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile == null
          ? null
          : {
              'id': profile.id,
              'displayName': profile.displayName,
              'heightCm': profile.heightCm,
              'weightKg': profile.weightKg,
              'birthDate': profile.birthDate?.toIso8601String(),
              'level': profile.level.name,
              'goals': profile.goals.map((g) => g.name).toList(),
              'preferredUnits': profile.preferredUnits.name,
              'weeklyFrequencyTarget': profile.weeklyFrequencyTarget,
              'createdAt': profile.createdAt.toIso8601String(),
            },
      'equipmentProfile': equipment == null
          ? null
          : {
              'availableEquipment': equipment.availableEquipment.toList(),
              'isHomeGym': equipment.isHomeGym,
            },
      'templates': data.templates.map(_encodeTemplate).toList(),
      'sessions': data.sessions.map(_encodeSession).toList(),
      'trainingPrograms': data.trainingPrograms.map(_encodeProgram).toList(),
      'bodyMetrics': data.bodyMetrics.map(_encodeBodyMetric).toList(),
      'favoriteExerciseIds': data.favoriteExerciseIds,
    };
  }

  static Map<String, dynamic> _encodeTemplate(WorkoutTemplate t) => {
        'id': t.id,
        'name': t.name,
        'createdAt': t.createdAt.toIso8601String(),
        'lastUsedAt': t.lastUsedAt?.toIso8601String(),
        'exercises': t.exercises
            .map((e) => {
                  'exerciseId': e.exerciseId,
                  'order': e.order,
                  'targetSets': e.targetSets,
                  'targetRepMin': e.targetRepRange.min,
                  'targetRepMax': e.targetRepRange.max,
                  'targetRestSec': e.targetRestSec,
                  'targetWeightKg': e.targetWeightKg,
                  'targetRpe': e.targetRpe,
                  'notes': e.notes,
                  'supersetGroup': e.supersetGroup,
                })
            .toList(),
      };

  static Map<String, dynamic> _encodeSession(WorkoutSession s) => {
        'id': s.id,
        'templateId': s.templateId,
        'startedAt': s.startedAt.toIso8601String(),
        'endedAt': s.endedAt?.toIso8601String(),
        'status': s.status.name,
        'notes': s.notes,
        'exercises': s.exercises
            .map((e) => {
                  'exerciseId': e.exerciseId,
                  'order': e.order,
                  'sets': e.sets
                      .map((set) => {
                            'id': set.id,
                            'setIndex': set.setIndex,
                            'targetReps': set.targetReps,
                            'actualReps': set.actualReps,
                            'weightKg': set.weightKg,
                            'rpe': set.rpe,
                            'rir': set.rir,
                            'isWarmup': set.isWarmup,
                            'completedAt': set.completedAt.toIso8601String(),
                            'restTakenSec': set.restTakenSec,
                          })
                      .toList(),
                })
            .toList(),
      };

  static Map<String, dynamic> _encodeProgram(TrainingProgram p) => {
        'id': p.id,
        'name': p.name,
        'goal': p.goal.name,
        'level': p.level.name,
        'createdAt': p.createdAt.toIso8601String(),
        'templateIds': p.templateIds,
      };

  static Map<String, dynamic> _encodeBodyMetric(BodyMetric m) => {
        'date': m.date.toIso8601String(),
        'weightKg': m.weightKg,
        'bodyFatPct': m.bodyFatPct,
        'measurements': m.measurements,
      };

  static BackupData decode(Map<String, dynamic> json, {required String userId}) {
    final profileJson = json['profile'] as Map<String, dynamic>?;
    final equipmentJson = json['equipmentProfile'] as Map<String, dynamic>?;

    return BackupData(
      profile: profileJson == null
          ? null
          : UserProfile(
              id: userId,
              displayName: profileJson['displayName'] as String? ?? 'Athlète',
              heightCm: (profileJson['heightCm'] as num?)?.toDouble(),
              weightKg: (profileJson['weightKg'] as num?)?.toDouble(),
              birthDate: profileJson['birthDate'] == null
                  ? null
                  : DateTime.parse(profileJson['birthDate'] as String),
              level: TrainingLevel.values.firstWhere(
                (l) => l.name == profileJson['level'],
                orElse: () => TrainingLevel.beginner,
              ),
              goals: (profileJson['goals'] as List<dynamic>? ?? [])
                  .map((g) => TrainingGoal.values.firstWhere((v) => v.name == g))
                  .toList(),
              preferredUnits: UnitSystem.values.firstWhere(
                (u) => u.name == profileJson['preferredUnits'],
                orElse: () => UnitSystem.metric,
              ),
              weeklyFrequencyTarget: profileJson['weeklyFrequencyTarget'] as int? ?? 3,
              createdAt: profileJson['createdAt'] == null
                  ? DateTime.now()
                  : DateTime.parse(profileJson['createdAt'] as String),
            ),
      equipmentProfile: equipmentJson == null
          ? null
          : EquipmentProfile(
              userId: userId,
              availableEquipment:
                  (equipmentJson['availableEquipment'] as List<dynamic>? ?? []).cast<String>().toSet(),
              isHomeGym: equipmentJson['isHomeGym'] as bool? ?? false,
            ),
      templates: (json['templates'] as List<dynamic>? ?? [])
          .map((t) => _decodeTemplate(t as Map<String, dynamic>, userId))
          .toList(),
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .map((s) => _decodeSession(s as Map<String, dynamic>, userId))
          .toList(),
      trainingPrograms: (json['trainingPrograms'] as List<dynamic>? ?? [])
          .map((p) => _decodeProgram(p as Map<String, dynamic>, userId))
          .toList(),
      bodyMetrics: (json['bodyMetrics'] as List<dynamic>? ?? [])
          .map((m) => _decodeBodyMetric(m as Map<String, dynamic>, userId))
          .toList(),
      favoriteExerciseIds:
          (json['favoriteExerciseIds'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  static WorkoutTemplate _decodeTemplate(Map<String, dynamic> json, String userId) {
    return WorkoutTemplate(
      id: json['id'] as String? ?? '',
      userId: userId,
      name: json['name'] as String? ?? 'Séance',
      createdAt: json['createdAt'] == null ? DateTime.now() : DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] == null ? null : DateTime.parse(json['lastUsedAt'] as String),
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => _decodeTemplateExercise(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static WorkoutTemplateExercise _decodeTemplateExercise(Map<String, dynamic> json) {
    return WorkoutTemplateExercise(
      exerciseId: json['exerciseId'] as String,
      order: json['order'] as int? ?? 0,
      targetSets: json['targetSets'] as int? ?? 3,
      targetRepRange: RepRange(
        json['targetRepMin'] as int? ?? 8,
        json['targetRepMax'] as int? ?? 12,
      ),
      targetRestSec: json['targetRestSec'] as int? ?? 90,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      targetRpe: (json['targetRpe'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      supersetGroup: json['supersetGroup'] as int?,
    );
  }

  static WorkoutSession _decodeSession(Map<String, dynamic> json, String userId) {
    return WorkoutSession(
      id: json['id'] as String,
      userId: userId,
      templateId: json['templateId'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null ? null : DateTime.parse(json['endedAt'] as String),
      status: SessionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SessionStatus.completed,
      ),
      notes: json['notes'] as String?,
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => _decodeSessionExercise(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static WorkoutSessionExercise _decodeSessionExercise(Map<String, dynamic> json) {
    return WorkoutSessionExercise(
      exerciseId: json['exerciseId'] as String,
      order: json['order'] as int? ?? 0,
      sets: (json['sets'] as List<dynamic>? ?? [])
          .map((s) => _decodeSetLog(s as Map<String, dynamic>))
          .toList(),
    );
  }

  static SetLog _decodeSetLog(Map<String, dynamic> json) {
    return SetLog(
      id: json['id'] as String,
      setIndex: json['setIndex'] as int? ?? 0,
      targetReps: json['targetReps'] as int? ?? 0,
      actualReps: json['actualReps'] as int? ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      rpe: (json['rpe'] as num?)?.toDouble(),
      rir: (json['rir'] as num?)?.toDouble(),
      isWarmup: json['isWarmup'] as bool? ?? false,
      completedAt: DateTime.parse(json['completedAt'] as String),
      restTakenSec: json['restTakenSec'] as int? ?? 0,
    );
  }

  static TrainingProgram _decodeProgram(Map<String, dynamic> json, String userId) {
    return TrainingProgram(
      id: json['id'] as String? ?? '',
      userId: userId,
      name: json['name'] as String? ?? 'Programme',
      goal: TrainingGoal.values.firstWhere(
        (g) => g.name == json['goal'],
        orElse: () => TrainingGoal.generalFitness,
      ),
      level: TrainingLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => TrainingLevel.beginner,
      ),
      createdAt: json['createdAt'] == null ? DateTime.now() : DateTime.parse(json['createdAt'] as String),
      templateIds: (json['templateIds'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  static BodyMetric _decodeBodyMetric(Map<String, dynamic> json, String userId) {
    return BodyMetric(
      userId: userId,
      date: DateTime.parse(json['date'] as String),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      bodyFatPct: (json['bodyFatPct'] as num?)?.toDouble(),
      measurements: (json['measurements'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }
}
