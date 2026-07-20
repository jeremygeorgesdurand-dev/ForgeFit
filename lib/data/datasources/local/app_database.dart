import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Local persistence for all user-owned, highly customizable data
/// (templates, sessions, sets, profile). Exercise reference data stays in
/// the bundled dataset asset — see `local_exercise_repository.dart`.
///
/// Connection is opened via `drift_flutter`, which picks the right backend
/// per platform behind a conditional import (native sqlite3 on
/// iOS/Android/macOS/Windows/Linux, sqlite3 wasm + IndexedDB on web) so
/// `dart:ffi` is never pulled into the web compile — a plain
/// `NativeDatabase` import breaks `flutter run -d chrome` outright, even on
/// screens that never touch the database, because Dart resolves the whole
/// import graph at compile time.
///
/// Web persistence needs two files under `web/`, both version-pinned to
/// what's actually resolved in `pubspec.lock` — a mismatch throws a cryptic
/// `WebAssembly.instantiate(): Import ... module is not an object or
/// function` at runtime instead of a clear version error:
/// - `sqlite3.wasm`: download the asset matching the resolved `sqlite3`
///   package version from
///   https://github.com/simolus3/sqlite3.dart/releases/tag/sqlite3-<version>
/// - `drift_worker.js`: compile it yourself from the resolved `drift`
///   package version (no prebuilt binary is published for every version):
///   `dart compile js --packages=.dart_tool/package_config.json -o web/drift_worker.js
///   "$(dirname "$(dart pub deps --json | ... )")"/web/drift_worker.dart`
///   — or simply locate `web/drift_worker.dart` inside the resolved
///   `drift` package under `~/.pub-cache/hosted/pub.dev/drift-<version>/`
///   and run `dart compile js --packages=.dart_tool/package_config.json
///   -o web/drift_worker.js <that path>` from the project root.
///
/// Schema versioning: bump [schemaVersion] and add a migration step in
/// [migration] for every structural change. Never edit a released
/// migration in place — the version number is the contract with installed
/// apps' on-device databases.
@DriftDatabase(
  tables: [
    WorkoutTemplates,
    WorkoutTemplateExercises,
    WorkoutSessions,
    WorkoutSessionExercises,
    SetLogs,
    UserProfiles,
    EquipmentProfiles,
    BodyMetrics,
    TrainingPrograms,
    TrainingProgramTemplates,
    FavoriteExercises,
    ScheduledSessions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(
          driftDatabase(
            name: 'forgefit',
            web: DriftWebOptions(
              sqlite3Wasm: Uri.parse('sqlite3.wasm'),
              driftWorker: Uri.parse('drift_worker.js'),
            ),
          ),
        );
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(bodyMetrics);
          }
          if (from < 3) {
            await m.createTable(trainingPrograms);
            await m.createTable(trainingProgramTemplates);
          }
          if (from < 4) {
            await m.createTable(favoriteExercises);
          }
          if (from < 5) {
            await m.addColumn(workoutTemplateExercises, workoutTemplateExercises.supersetGroup);
          }
          if (from < 6) {
            await m.addColumn(bodyMetrics, bodyMetrics.measurements);
          }
          if (from < 7) {
            await m.addColumn(workoutSessions, workoutSessions.notes);
          }
          if (from < 8) {
            await m.createTable(scheduledSessions);
          }
        },
      );

  /// Wipes every user-owned table — irreversible, only meant to be called
  /// from an explicit "reset all data" action behind its own confirmation.
  Future<void> resetAllData() async {
    await transaction(() async {
      await delete(setLogs).go();
      await delete(workoutSessionExercises).go();
      await delete(workoutSessions).go();
      await delete(workoutTemplateExercises).go();
      await delete(workoutTemplates).go();
      await delete(trainingProgramTemplates).go();
      await delete(trainingPrograms).go();
      await delete(favoriteExercises).go();
      await delete(bodyMetrics).go();
      await delete(equipmentProfiles).go();
      await delete(userProfiles).go();
    });
  }
}
