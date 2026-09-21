import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/content/content_importer.dart';
import 'package:memo/data/content/content_pack.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/phrases/data/drift_phrase_repository.dart';
import 'package:memo/features/profiles/domain/profile.dart';

import '../../support/seed.dart';

ContentPack packWithPhrases({int version = 1, String firstText = 'Bonjour'}) =>
    ContentPack.fromJson({
      'version': version,
      'categories': <Object?>[],
      'pictograms': <Object?>[],
      'phrases': [
        {
          'code': 'PH-001',
          'sortOrder': 1,
          'texts': {
            'fr': {
              'text': firstText,
              'tags': ['maison'],
            },
            'en': {
              'text': 'Hello',
              'tags': ['home'],
            },
          },
        },
        {
          'code': 'PH-002',
          'sortOrder': 2,
          'texts': {
            'fr': {'text': "C'est à mon tour"},
          },
        },
      ],
    });

void main() {
  late AppDatabase db;
  late DriftPhraseRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting();
    repo = DriftPhraseRepository(db);
    await ContentImporter(db).importIfNeeded(packWithPhrases());
  });
  tearDown(() => db.close());

  test('les phrases livrées sont triées et filtrées par langue', () async {
    final fr = await repo.watch(profileId: null, lang: 'fr').first;
    expect(fr.map((p) => p.text), ['Bonjour', "C'est à mon tour"]);
    expect(fr.first.tags, ['maison']);
    expect(fr.last.tags, isEmpty);
    expect(fr.every((p) => !p.isCustom), isTrue);

    final en = await repo.watch(profileId: null, lang: 'en').first;
    expect(en.map((p) => p.text), ['Hello']);
  });

  test('une mise à jour du contenu remplace le texte sans dupliquer', () async {
    await ContentImporter(
      db,
    ).importIfNeeded(packWithPhrases(version: 2, firstText: 'Salut'));
    final fr = await repo.watch(profileId: null, lang: 'fr').first;
    expect(fr.map((p) => p.text), ['Salut', "C'est à mon tour"]);
  });

  test(
    "les phrases d'un profil viennent après les livrées, sans fuite",
    () async {
      final a = await seedProfile(db);
      final b = await seedProfile(db, type: ProfileType.adult);
      await repo.add(profileId: a.id, lang: 'fr', text: '  Il fait chaud  ');

      final forA = await repo.watch(profileId: a.id, lang: 'fr').first;
      expect(forA.map((p) => p.text), [
        'Bonjour',
        "C'est à mon tour",
        'Il fait chaud',
      ]);
      expect(forA.last.isCustom, isTrue);

      final forB = await repo.watch(profileId: b.id, lang: 'fr').first;
      expect(forB.map((p) => p.text), ['Bonjour', "C'est à mon tour"]);
    },
  );

  test("les phrases ajoutées gardent l'ordre d'ajout", () async {
    final a = await seedProfile(db);
    await repo.add(profileId: a.id, lang: 'fr', text: 'Une');
    await repo.add(profileId: a.id, lang: 'fr', text: 'Deux');
    final list = await repo.watch(profileId: a.id, lang: 'fr').first;
    expect(list.skip(2).map((p) => p.text), ['Une', 'Deux']);
  });

  test('une phrase vide est refusée', () async {
    final a = await seedProfile(db);
    await expectLater(
      repo.add(profileId: a.id, lang: 'fr', text: '   '),
      throwsArgumentError,
    );
  });

  test("seules les phrases de l'utilisateur sont supprimables", () async {
    final a = await seedProfile(db);
    final mine = await repo.add(profileId: a.id, lang: 'fr', text: 'Ma phrase');
    final shipped = (await repo.watch(profileId: a.id, lang: 'fr').first).first;

    await repo.remove(shipped.id);
    await repo.remove(mine.id);

    final list = await repo.watch(profileId: a.id, lang: 'fr').first;
    expect(list.map((p) => p.text), ['Bonjour', "C'est à mon tour"]);
  });
}
