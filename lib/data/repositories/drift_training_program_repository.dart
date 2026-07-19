import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/entities/training_program.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/training_program_repository.dart';
import '../datasources/local/app_database.dart';

class DriftTrainingProgramRepository implements TrainingProgramRepository {
  final AppDatabase _db;
  static final _rng = Random();

  DriftTrainingProgramRepository(this._db);

  String _generateId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_rng.nextInt(99999)}';

  @override
  Future<List<TrainingProgram>> getPrograms(String userId) async {
    final programRows = await (_db.select(_db.trainingPrograms)
          ..where((p) => p.userId.equals(userId))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .get();

    final programs = <TrainingProgram>[];
    for (final row in programRows) {
      final links = await (_db.select(_db.trainingProgramTemplates)
            ..where((t) => t.programId.equals(row.id))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();
      programs.add(TrainingProgram(
        id: row.id,
        userId: row.userId,
        name: row.name,
        goal: TrainingGoal.values.firstWhere(
          (g) => g.name == row.goal,
          orElse: () => TrainingGoal.generalFitness,
        ),
        level: TrainingLevel.values.firstWhere(
          (l) => l.name == row.level,
          orElse: () => TrainingLevel.beginner,
        ),
        createdAt: row.createdAt,
        templateIds: links.map((l) => l.templateId).toList(),
      ));
    }
    return programs;
  }

  @override
  Future<TrainingProgram> saveProgram(TrainingProgram program) async {
    final id = program.id.isEmpty ? _generateId() : program.id;

    await _db.transaction(() async {
      await _db.into(_db.trainingPrograms).insertOnConflictUpdate(
            TrainingProgramsCompanion.insert(
              id: id,
              userId: program.userId,
              name: program.name,
              goal: program.goal.name,
              level: program.level.name,
              createdAt: program.createdAt,
            ),
          );
      await (_db.delete(_db.trainingProgramTemplates)
            ..where((t) => t.programId.equals(id)))
          .go();
      for (var i = 0; i < program.templateIds.length; i++) {
        await _db.into(_db.trainingProgramTemplates).insert(
              TrainingProgramTemplatesCompanion.insert(
                programId: id,
                templateId: program.templateIds[i],
                sortOrder: i,
              ),
            );
      }
    });

    return TrainingProgram(
      id: id,
      userId: program.userId,
      name: program.name,
      goal: program.goal,
      level: program.level,
      createdAt: program.createdAt,
      templateIds: program.templateIds,
    );
  }

  @override
  Future<void> deleteProgram(String programId) async {
    await (_db.delete(_db.trainingPrograms)..where((p) => p.id.equals(programId))).go();
  }
}
