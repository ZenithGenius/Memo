abstract interface class FavoritesRepository {
  Stream<Set<int>> watchIds(int profileId);
  Future<void> toggle(int profileId, int pictogramId);
}
