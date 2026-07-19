abstract class FavoritesRepository {
  Future<Set<String>> getFavoriteExerciseIds(String userId);
  Future<void> toggleFavorite(String userId, String exerciseId);
}
