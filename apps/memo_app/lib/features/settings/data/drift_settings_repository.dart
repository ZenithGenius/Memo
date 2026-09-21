import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/settings/domain/app_settings.dart';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);
  final AppDatabase _db;

  static const _speakEachWord = 'speak_each_word';
  static const _haptics = 'haptics_enabled';

  @override
  Stream<AppSettings> watch() {
    return _db.select(_db.settings).watch().map((rows) {
      final values = {for (final r in rows) r.key: r.value};
      bool read(String key, bool fallback) =>
          values.containsKey(key) ? values[key] == 'true' : fallback;
      return AppSettings(
        speakEachWord: read(_speakEachWord, AppSettings.defaults.speakEachWord),
        hapticsEnabled: read(_haptics, AppSettings.defaults.hapticsEnabled),
      );
    });
  }

  @override
  Future<void> setSpeakEachWord({required bool value}) =>
      _write(_speakEachWord, value);

  @override
  Future<void> setHapticsEnabled({required bool value}) =>
      _write(_haptics, value);

  Future<void> _write(String key, bool value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, value: '$value'),
      );
}
