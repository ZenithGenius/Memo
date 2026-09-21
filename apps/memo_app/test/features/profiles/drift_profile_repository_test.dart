import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/profiles/data/drift_profile_repository.dart';
import 'package:memo/features/profiles/domain/profile.dart';

void main() {
  late AppDatabase db;
  late DriftProfileRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = DriftProfileRepository(db);
  });
  tearDown(() => db.close());

  test('aucun profil actif au départ', () async {
    expect(await repo.watchActive().first, isNull);
  });

  test('créer un profil le rend actif', () async {
    final p = await repo.create(
      name: 'Amina',
      type: ProfileType.child,
      level: Level.beginner,
    );
    final active = await repo.watchActive().first;
    expect(active, p);
    expect(active!.type.audience, Audience.child);
  });

  test('changer le niveau est persistant et réactif', () async {
    final p = await repo.create(
      name: 'Paul',
      type: ProfileType.adult,
      level: Level.beginner,
    );
    await repo.setLevel(p.id, Level.advanced);
    final active = await repo.watchActive().first;
    expect(active!.level, Level.advanced);
  });

  test('le profil accompagnant voit tous les publics', () {
    expect(ProfileType.caregiver.audience, Audience.all);
  });

  test('changer la langue du profil est persistant et réactif', () async {
    final p = await repo.create(
      name: 'Amina',
      type: ProfileType.child,
      level: Level.beginner,
    );
    expect(p.language, 'fr');
    await repo.setLanguage(p.id, 'en');
    expect((await repo.watchActive().first)!.language, 'en');
  });
}
