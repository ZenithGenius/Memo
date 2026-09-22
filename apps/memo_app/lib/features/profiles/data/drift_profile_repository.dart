import 'package:drift/drift.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/features/profiles/domain/profile_repository.dart';

class DriftProfileRepository implements ProfileRepository {
  DriftProfileRepository(this._db);
  final AppDatabase _db;

  static const _activeKey = 'active_profile_id';

  @override
  Stream<Profile?> watchActive() {
    // Une seule requête réactive qui joint le réglage « profil actif » et la
    // table des profils : elle se met à jour quand l'un ou l'autre change.
    // (Enchaîner deux flux avec asyncExpand ne suivait pas un changement de
    // profil actif : le flux interne ne se termine jamais.)
    final query = _db.select(_db.profiles).join([
      innerJoin(
        _db.settings,
        _db.settings.key.equals(_activeKey) &
            _db.settings.value.equalsExp(_db.profiles.id.cast<String>()),
      ),
    ]);
    return query.watchSingleOrNull().map((row) {
      final profile = row?.readTableOrNull(_db.profiles);
      return profile == null ? null : _toDomain(profile);
    });
  }

  @override
  Future<Profile> create({
    required String name,
    required ProfileType type,
    required Level level,
    String language = 'fr',
  }) async {
    final id = await _db
        .into(_db.profiles)
        .insert(
          ProfilesCompanion.insert(
            name: name,
            type: type.name,
            level: level.index,
            language: Value(language),
          ),
        );
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(key: _activeKey, value: '$id'),
        );
    final row = await (_db.select(
      _db.profiles,
    )..where((p) => p.id.equals(id))).getSingle();
    return _toDomain(row);
  }

  @override
  Stream<List<Profile>> watchAll() {
    final query = _db.select(_db.profiles)
      ..orderBy([(p) => OrderingTerm.asc(p.id)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> setActive(int profileId) async {
    final exists = await (_db.select(
      _db.profiles,
    )..where((p) => p.id.equals(profileId))).getSingleOrNull();
    if (exists == null) return;
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(key: _activeKey, value: '$profileId'),
        );
  }

  @override
  Future<void> setLevel(int profileId, Level level) async {
    await (_db.update(_db.profiles)..where((p) => p.id.equals(profileId)))
        .write(ProfilesCompanion(level: Value(level.index)));
  }

  @override
  Future<void> setLanguage(int profileId, String language) async {
    await (_db.update(_db.profiles)..where((p) => p.id.equals(profileId)))
        .write(ProfilesCompanion(language: Value(language)));
  }

  Profile _toDomain(ProfileRow row) => Profile(
    id: row.id,
    name: row.name,
    type: ProfileType.values.byName(row.type),
    level: Level.values[row.level],
    language: row.language,
  );
}
