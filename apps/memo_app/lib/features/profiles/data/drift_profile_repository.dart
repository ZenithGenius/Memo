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
    final setting = _db.select(_db.settings)
      ..where((s) => s.key.equals(_activeKey));
    return setting.watchSingleOrNull().asyncExpand((s) {
      if (s == null) return Stream<Profile?>.value(null);
      final id = int.parse(s.value);
      return (_db.select(_db.profiles)..where((p) => p.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _toDomain(row));
    });
  }

  @override
  Future<Profile> create({
    required String name,
    required ProfileType type,
    required Level level,
  }) async {
    final id = await _db
        .into(_db.profiles)
        .insert(
          ProfilesCompanion.insert(
            name: name,
            type: type.name,
            level: level.index,
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
  Future<void> setLevel(int profileId, Level level) async {
    await (_db.update(_db.profiles)..where((p) => p.id.equals(profileId)))
        .write(ProfilesCompanion(level: Value(level.index)));
  }

  Profile _toDomain(ProfileRow row) => Profile(
    id: row.id,
    name: row.name,
    type: ProfileType.values.byName(row.type),
    level: Level.values[row.level],
    language: row.language,
  );
}
