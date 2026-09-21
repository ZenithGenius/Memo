import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/settings/data/drift_settings_repository.dart';
import 'package:memo/features/settings/domain/app_settings.dart';

void main() {
  late AppDatabase db;
  late DriftSettingsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = DriftSettingsRepository(db);
  });
  tearDown(() => db.close());

  test('valeurs par défaut : audio par mot et vibrations activés', () async {
    expect(await repo.watch().first, AppSettings.defaults);
    expect(AppSettings.defaults.speakEachWord, isTrue);
    expect(AppSettings.defaults.hapticsEnabled, isTrue);
  });

  test('un réglage modifié est conservé et le reste inchangé', () async {
    await repo.setHapticsEnabled(value: false);
    var s = await repo.watch().first;
    expect(s.hapticsEnabled, isFalse);
    expect(s.speakEachWord, isTrue);

    await repo.setSpeakEachWord(value: false);
    s = await repo.watch().first;
    expect(s, const AppSettings(speakEachWord: false, hapticsEnabled: false));

    await repo.setHapticsEnabled(value: true);
    expect((await repo.watch().first).hapticsEnabled, isTrue);
  });

  test('le flux notifie chaque changement', () async {
    final emitted = <AppSettings>[];
    final sub = repo.watch().listen(emitted.add);
    await Future<void>.delayed(Duration.zero);
    await repo.setSpeakEachWord(value: false);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(emitted.last.speakEachWord, isFalse);
  });
}
