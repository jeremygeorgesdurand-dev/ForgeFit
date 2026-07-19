import 'package:drift/drift.dart';

/// User-owned, highly customizable workout data (PARTIE 5). Exercise
/// reference data is NOT stored here — it stays in the bundled dataset
/// asset and is looked up by id at read time.
@DataClassName('WorkoutTemplateRow')
class WorkoutTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkoutTemplateExerciseRow')
class WorkoutTemplateExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get templateId =>
      text().references(WorkoutTemplates, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text()();
  IntColumn get sortOrder => integer()();
  IntColumn get targetSets => integer()();
  IntColumn get targetRepMin => integer()();
  IntColumn get targetRepMax => integer()();
  IntColumn get targetRestSec => integer()();
  RealColumn get targetWeightKg => real().nullable()();
  RealColumn get targetRpe => real().nullable()();
  TextColumn get notes => text().nullable()();
}

@DataClassName('WorkoutSessionRow')
class WorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get templateId => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  // Stored as text: inProgress | completed | aborted (see SessionStatus).
  TextColumn get status => text().withDefault(const Constant('inProgress'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkoutSessionExerciseRow')
class WorkoutSessionExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId =>
      text().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text()();
  IntColumn get sortOrder => integer()();
}

@DataClassName('SetLogRow')
class SetLogs extends Table {
  TextColumn get id => text()();
  IntColumn get sessionExerciseId => integer()
      .references(WorkoutSessionExercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get setIndex => integer()();
  IntColumn get targetReps => integer()();
  IntColumn get actualReps => integer()();
  RealColumn get weightKg => real()();
  RealColumn get rpe => real().nullable()();
  RealColumn get rir => real().nullable()();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get restTakenSec => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  DateTimeColumn get birthDate => dateTime().nullable()();
  TextColumn get level => text().withDefault(const Constant('beginner'))();
  // Comma-separated TrainingGoal names.
  TextColumn get goals => text().withDefault(const Constant(''))();
  TextColumn get preferredUnits => text().withDefault(const Constant('metric'))();
  IntColumn get weeklyFrequencyTarget => integer().withDefault(const Constant(3))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EquipmentProfileRow')
class EquipmentProfiles extends Table {
  TextColumn get userId => text()();
  // Comma-separated equipment strings.
  TextColumn get availableEquipment => text().withDefault(const Constant(''))();
  BoolColumn get isHomeGym => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {userId};
}

@DataClassName('BodyMetricRow')
class BodyMetrics extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get bodyFatPct => real().nullable()();
}

@DataClassName('TrainingProgramRow')
class TrainingPrograms extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get goal => text()();
  TextColumn get level => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TrainingProgramTemplateRow')
class TrainingProgramTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get programId =>
      text().references(TrainingPrograms, #id, onDelete: KeyAction.cascade)();
  // Not a FK to WorkoutTemplates: a program's days stay linked even if a
  // template is later deleted independently — the row is just orphaned.
  TextColumn get templateId => text()();
  IntColumn get sortOrder => integer()();
}
