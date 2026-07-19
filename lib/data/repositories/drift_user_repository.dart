import 'package:drift/drift.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/app_database.dart';

/// Single-user local repository. `getCurrentProfile` returns the sole row
/// (if any) — multi-user support arrives with Supabase Auth in a later
/// phase, at which point queries filter by the authenticated user id.
class DriftUserRepository implements UserRepository {
  final AppDatabase _db;

  DriftUserRepository(this._db);

  @override
  Future<UserProfile?> getCurrentProfile() async {
    final row = await _db.select(_db.userProfiles).getSingleOrNull();
    if (row == null) return null;

    return UserProfile(
      id: row.id,
      displayName: row.displayName,
      heightCm: row.heightCm,
      weightKg: row.weightKg,
      birthDate: row.birthDate,
      level: TrainingLevel.values.firstWhere(
        (l) => l.name == row.level,
        orElse: () => TrainingLevel.beginner,
      ),
      goals: row.goals
          .split(',')
          .where((g) => g.isNotEmpty)
          .map((g) => TrainingGoal.values.firstWhere((v) => v.name == g))
          .toList(),
      preferredUnits: UnitSystem.values.firstWhere(
        (u) => u.name == row.preferredUnits,
        orElse: () => UnitSystem.metric,
      ),
      weeklyFrequencyTarget: row.weeklyFrequencyTarget,
      createdAt: row.createdAt,
    );
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    await _db.into(_db.userProfiles).insertOnConflictUpdate(
          UserProfilesCompanion.insert(
            id: profile.id,
            displayName: profile.displayName,
            heightCm: Value(profile.heightCm),
            weightKg: Value(profile.weightKg),
            birthDate: Value(profile.birthDate),
            level: Value(profile.level.name),
            goals: Value(profile.goals.map((g) => g.name).join(',')),
            preferredUnits: Value(profile.preferredUnits.name),
            weeklyFrequencyTarget: Value(profile.weeklyFrequencyTarget),
            createdAt: profile.createdAt,
          ),
        );
    return profile;
  }

  @override
  Future<EquipmentProfile?> getEquipmentProfile(String userId) async {
    final row = await (_db.select(_db.equipmentProfiles)
          ..where((e) => e.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return null;

    return EquipmentProfile(
      userId: row.userId,
      availableEquipment:
          row.availableEquipment.split(',').where((e) => e.isNotEmpty).toSet(),
      isHomeGym: row.isHomeGym,
    );
  }

  @override
  Future<EquipmentProfile> saveEquipmentProfile(EquipmentProfile profile) async {
    await _db.into(_db.equipmentProfiles).insertOnConflictUpdate(
          EquipmentProfilesCompanion.insert(
            userId: profile.userId,
            availableEquipment: Value(profile.availableEquipment.join(',')),
            isHomeGym: Value(profile.isHomeGym),
          ),
        );
    return profile;
  }
}
