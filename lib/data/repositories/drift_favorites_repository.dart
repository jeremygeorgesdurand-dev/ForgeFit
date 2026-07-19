import 'package:drift/drift.dart';

import '../../domain/repositories/favorites_repository.dart';
import '../datasources/local/app_database.dart';

class DriftFavoritesRepository implements FavoritesRepository {
  final AppDatabase _db;
  DriftFavoritesRepository(this._db);

  @override
  Future<Set<String>> getFavoriteExerciseIds(String userId) async {
    final rows = await (_db.select(_db.favoriteExercises)
          ..where((f) => f.userId.equals(userId)))
        .get();
    return rows.map((r) => r.exerciseId).toSet();
  }

  @override
  Future<void> toggleFavorite(String userId, String exerciseId) async {
    final existing = await (_db.select(_db.favoriteExercises)
          ..where((f) => f.userId.equals(userId) & f.exerciseId.equals(exerciseId)))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.delete(_db.favoriteExercises)
            ..where((f) => f.userId.equals(userId) & f.exerciseId.equals(exerciseId)))
          .go();
    } else {
      await _db.into(_db.favoriteExercises).insert(
            FavoriteExercisesCompanion.insert(userId: userId, exerciseId: exerciseId),
          );
    }
  }
}
