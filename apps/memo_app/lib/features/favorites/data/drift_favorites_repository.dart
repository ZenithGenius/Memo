import 'package:drift/drift.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/favorites/domain/favorites_repository.dart';

class DriftFavoritesRepository implements FavoritesRepository {
  DriftFavoritesRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<Set<int>> watchIds(int profileId) {
    return (_db.select(_db.favorites)
          ..where((f) => f.profileId.equals(profileId)))
        .watch()
        .map((rows) => rows.map((r) => r.pictogramId).toSet());
  }

  @override
  Future<void> toggle(int profileId, int pictogramId) async {
    final match =
        _db.favorites.profileId.equals(profileId) &
        _db.favorites.pictogramId.equals(pictogramId);
    final existing = await (_db.select(
      _db.favorites,
    )..where((_) => match)).getSingleOrNull();
    if (existing == null) {
      await _db
          .into(_db.favorites)
          .insert(
            FavoritesCompanion.insert(
              profileId: profileId,
              pictogramId: pictogramId,
            ),
          );
    } else {
      await (_db.delete(_db.favorites)..where((_) => match)).go();
    }
  }
}
