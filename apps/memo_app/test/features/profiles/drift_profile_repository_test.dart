import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/profiles/data/drift_profile_repository.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import '../../support/seed.dart';

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

  group('plusieurs profils', () {
    test('la liste suit l\'ordre de création', () async {
      await repo.create(
        name: 'Amina',
        type: ProfileType.child,
        level: Level.beginner,
      );
      await repo.create(
        name: 'Paul',
        type: ProfileType.adult,
        level: Level.advanced,
      );
      final all = await repo.watchAll().first;
      expect(all.map((p) => p.name), ['Amina', 'Paul']);
    });

    test('créer un profil le rend actif, dans la langue demandée', () async {
      await repo.create(
        name: 'Amina',
        type: ProfileType.child,
        level: Level.beginner,
      );
      final paul = await repo.create(
        name: 'Paul',
        type: ProfileType.adult,
        level: Level.advanced,
        language: 'en',
      );
      final active = (await repo.watchActive().first)!;
      expect(active.id, paul.id);
      expect(active.language, 'en');
    });

    test('changer de profil actif est persistant', () async {
      final amina = await repo.create(
        name: 'Amina',
        type: ProfileType.child,
        level: Level.beginner,
      );
      await repo.create(
        name: 'Paul',
        type: ProfileType.adult,
        level: Level.advanced,
      );
      await repo.setActive(amina.id);
      expect((await repo.watchActive().first)!.name, 'Amina');
    });

    test(
      'le flux du profil actif suit les changements de profil actif',
      () async {
        final amina = await repo.create(
          name: 'Amina',
          type: ProfileType.child,
          level: Level.beginner,
        );
        final paul = await repo.create(
          name: 'Paul',
          type: ProfileType.adult,
          level: Level.advanced,
        );
        final names = <String?>[];
        final sub = repo.watchActive().listen((p) => names.add(p?.name));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await repo.setActive(amina.id);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await repo.setActive(paul.id);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();
        // Régression : un flux interne sans fin bloquait tout changement.
        expect(names, ['Paul', 'Amina', 'Paul']);
      },
    );

    test('activer un profil inexistant ne change rien', () async {
      final amina = await repo.create(
        name: 'Amina',
        type: ProfileType.child,
        level: Level.beginner,
      );
      await repo.setActive(9999);
      expect((await repo.watchActive().first)!.id, amina.id);
    });

    test('le niveau et la langue sont propres à chaque profil', () async {
      final a = await repo.create(
        name: 'A',
        type: ProfileType.child,
        level: Level.beginner,
      );
      final b = await repo.create(
        name: 'B',
        type: ProfileType.adult,
        level: Level.beginner,
      );
      await repo.setLevel(a.id, Level.advanced);
      await repo.setLanguage(b.id, 'en');
      final all = await repo.watchAll().first;
      expect(all.firstWhere((p) => p.id == a.id).level, Level.advanced);
      expect(all.firstWhere((p) => p.id == b.id).level, Level.beginner);
      expect(all.firstWhere((p) => p.id == a.id).language, 'fr');
      expect(all.firstWhere((p) => p.id == b.id).language, 'en');
    });
  });

  test('supprimer un profil efface ses données, les autres restent', () async {
    final a = await repo.create(
      name: 'A',
      type: ProfileType.child,
      level: Level.beginner,
    );
    final b = await repo.create(
      name: 'B',
      type: ProfileType.adult,
      level: Level.beginner,
    );
    final pid = await seedPictogram(db, 'P1', label: 'Eau');
    await db
        .into(db.favorites)
        .insert(FavoritesCompanion.insert(profileId: a.id, pictogramId: pid));
    await db
        .into(db.favorites)
        .insert(FavoritesCompanion.insert(profileId: b.id, pictogramId: pid));

    await repo.delete(a.id); // B est actif
    expect((await repo.watchAll().first).map((p) => p.name), ['B']);
    final favs = await db.select(db.favorites).get();
    expect(favs.map((f) => f.profileId), [b.id]);
  });

  test('le profil actif ne peut pas être supprimé', () async {
    final a = await repo.create(
      name: 'A',
      type: ProfileType.child,
      level: Level.beginner,
    );
    await expectLater(repo.delete(a.id), throwsStateError);
    expect(await repo.watchAll().first, hasLength(1));
  });
}
