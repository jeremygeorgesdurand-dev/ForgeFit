import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:forgefit/data/services/backup_codec.dart';
import 'package:forgefit/domain/entities/progress.dart';
import 'package:forgefit/domain/entities/training_program.dart';
import 'package:forgefit/domain/entities/user_profile.dart';
import 'package:forgefit/domain/entities/workout_session.dart';
import 'package:forgefit/domain/entities/workout_template.dart';

void main() {
  const userId = 'local-user';

  test('encode then decode round-trips a full profile', () {
    final profile = UserProfile(
      id: userId,
      displayName: 'Jeremy',
      heightCm: 180,
      weightKg: 78.5,
      level: TrainingLevel.intermediate,
      goals: const [TrainingGoal.hypertrophy, TrainingGoal.strength],
      preferredUnits: UnitSystem.imperial,
      weeklyFrequencyTarget: 4,
      createdAt: DateTime(2026, 1, 1),
    );

    final json = jsonDecode(jsonEncode(BackupCodec.encode(BackupData(profile: profile))))
        as Map<String, dynamic>;
    final decoded = BackupCodec.decode(json, userId: userId);

    expect(decoded.profile!.displayName, 'Jeremy');
    expect(decoded.profile!.heightCm, 180);
    expect(decoded.profile!.level, TrainingLevel.intermediate);
    expect(decoded.profile!.goals, [TrainingGoal.hypertrophy, TrainingGoal.strength]);
    expect(decoded.profile!.preferredUnits, UnitSystem.imperial);
    expect(decoded.profile!.weeklyFrequencyTarget, 4);
  });

  test('round-trips a template with superset grouping and optional fields', () {
    final template = WorkoutTemplate(
      id: 'tpl-1',
      userId: userId,
      name: 'Push',
      createdAt: DateTime(2026, 1, 1),
      exercises: const [
        WorkoutTemplateExercise(
          exerciseId: 'bench',
          order: 0,
          targetSets: 4,
          targetRepRange: RepRange(6, 10),
          targetRestSec: 120,
          targetWeightKg: 80,
          supersetGroup: 1,
          notes: 'Pause 1s en bas',
        ),
      ],
    );

    final json = jsonDecode(
      jsonEncode(BackupCodec.encode(BackupData(templates: [template]))),
    ) as Map<String, dynamic>;
    final decoded = BackupCodec.decode(json, userId: userId);

    expect(decoded.templates, hasLength(1));
    final restored = decoded.templates.first;
    expect(restored.id, 'tpl-1');
    expect(restored.exercises.first.targetWeightKg, 80);
    expect(restored.exercises.first.supersetGroup, 1);
    expect(restored.exercises.first.notes, 'Pause 1s en bas');
  });

  test('round-trips a completed session with sets, warmup flag, and notes', () {
    final session = WorkoutSession(
      id: 'session-1',
      userId: userId,
      startedAt: DateTime(2026, 1, 1, 10, 0),
      endedAt: DateTime(2026, 1, 1, 11, 0),
      status: SessionStatus.completed,
      notes: 'Bonne séance',
      exercises: [
        WorkoutSessionExercise(
          exerciseId: 'bench',
          order: 0,
          sets: [
            SetLog(
              id: 'set-1',
              setIndex: 0,
              targetReps: 8,
              actualReps: 8,
              weightKg: 60,
              rpe: 7,
              isWarmup: false,
              completedAt: DateTime(2026, 1, 1, 10, 5),
              restTakenSec: 90,
            ),
          ],
        ),
      ],
    );

    final json = jsonDecode(
      jsonEncode(BackupCodec.encode(BackupData(sessions: [session]))),
    ) as Map<String, dynamic>;
    final decoded = BackupCodec.decode(json, userId: userId);

    expect(decoded.sessions, hasLength(1));
    final restored = decoded.sessions.first;
    expect(restored.id, 'session-1');
    expect(restored.status, SessionStatus.completed);
    expect(restored.notes, 'Bonne séance');
    expect(restored.exercises.first.sets.first.weightKg, 60);
    expect(restored.exercises.first.sets.first.rpe, 7);
  });

  test('round-trips a saved program and body metric with custom measurements', () {
    final program = TrainingProgram(
      id: 'prog-1',
      userId: userId,
      name: 'Prise de masse',
      goal: TrainingGoal.hypertrophy,
      level: TrainingLevel.intermediate,
      createdAt: DateTime(2026, 1, 1),
      templateIds: const ['tpl-1', 'tpl-2'],
    );
    final metric = BodyMetric(
      userId: userId,
      date: DateTime(2026, 1, 1),
      weightKg: 78,
      measurements: const {'waist': 82, 'arm': 36.5},
    );

    final json = jsonDecode(
      jsonEncode(BackupCodec.encode(BackupData(trainingPrograms: [program], bodyMetrics: [metric]))),
    ) as Map<String, dynamic>;
    final decoded = BackupCodec.decode(json, userId: userId);

    expect(decoded.trainingPrograms.first.templateIds, ['tpl-1', 'tpl-2']);
    expect(decoded.bodyMetrics.first.measurements['waist'], 82);
    expect(decoded.bodyMetrics.first.measurements['arm'], 36.5);
  });
}
