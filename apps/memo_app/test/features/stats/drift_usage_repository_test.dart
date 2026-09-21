import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/features/stats/data/drift_usage_repository.dart';
import 'package:memo/features/stats/domain/usage.dart';

import '../../support/seed.dart';

void main() {
  final now = DateTime.utc(2026, 9, 21, 12);
  late AppDatabase db;
  late DriftUsageRepository repo;
  late int profile;
  late int eau, veux, manger;

  setUp(() async {
    db = AppDatabase.forTesting();
    repo = DriftUsageRepository(db);
    profile = (await seedProfile(db)).id;
    veux = await seedPictogram(db, 'P1', label: 'Je veux');
    eau = await seedPictogram(db, 'P2', label: 'Eau');
    manger = await seedPictogram(db, 'P3', label: 'Manger');
  });
  tearDown(() => db.close());

  Future<UsageSummary> week({int? p, String lang = 'fr'}) =>
      repo.watchWeek(profileId: p ?? profile, lang: lang, now: () => now).first;

  Future<void> say(List<int> ids, {Duration ago = Duration.zero, int? p}) =>
      repo.recordSentence(
        profileId: p ?? profile,
        pictogramIds: ids,
        at: now.subtract(ago),
      );

  test('sans usage : tout à zéro', () async {
    expect(await week(), UsageSummary.empty);
  });

  test('compte les phrases des sept derniers jours seulement', () async {
    await say([veux, eau]);
    await say([veux], ago: const Duration(days: 6));
    await say([veux], ago: const Duration(days: 8));
    expect((await week()).sentences, 2);
  });

  test('une phrase toute faite compte comme phrase, sans mot', () async {
    await say([]);
    final s = await week();
    expect(s.sentences, 1);
    expect(s.topWords, isEmpty);
    expect(s.newWords, 0);
  });

  test('classe les mots par fréquence puis par ordre alphabétique', () async {
    await say([veux, eau]);
    await say([veux, manger]);
    await say([veux, eau]);
    final s = await week();
    expect(s.topWords, const [
      WordCount(label: 'Je veux', count: 3),
      WordCount(label: 'Eau', count: 2),
      WordCount(label: 'Manger', count: 1),
    ]);
  });

  test("les mots hors période ne comptent pas dans le classement", () async {
    await say([manger], ago: const Duration(days: 20));
    await say([eau]);
    expect((await week()).topWords.map((w) => w.label), ['Eau']);
  });

  test(
    'un mot est nouveau seulement si sa première utilisation est récente',
    () async {
      await say([veux], ago: const Duration(days: 30)); // connu de longue date
      await say([veux, eau]); // eau est nouveau, veux ne l'est pas
      expect((await week()).newWords, 1);
    },
  );

  test('le classement est limité aux huit premiers mots', () async {
    final ids = <int>[];
    for (var i = 0; i < 10; i++) {
      ids.add(await seedPictogram(db, 'X$i', label: 'Mot $i'));
    }
    await say(ids);
    expect((await week()).topWords, hasLength(8));
  });

  test('les statistiques sont propres à chaque profil', () async {
    final other = (await seedProfile(db, type: ProfileType.adult)).id;
    await say([veux]);
    await say([eau], p: other);
    expect((await week()).topWords.map((w) => w.label), ['Je veux']);
    expect((await week(p: other)).topWords.map((w) => w.label), ['Eau']);
  });

  test('une langue sans traduction ne donne pas de libellé', () async {
    await say([veux]);
    expect((await week(lang: 'en')).topWords, isEmpty);
  });

  test('le flux se met à jour après un nouvel enregistrement', () async {
    final emitted = <UsageSummary>[];
    final sub = repo
        .watchWeek(profileId: profile, lang: 'fr', now: () => now)
        .listen(emitted.add);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await say([eau]);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await sub.cancel();
    expect(emitted.first.sentences, 0);
    expect(emitted.last.sentences, 1);
    expect(emitted.last.topWords.single.label, 'Eau');
  });
}
