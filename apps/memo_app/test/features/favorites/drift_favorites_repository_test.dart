import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/favorites/data/drift_favorites_repository.dart';
import 'package:memo/features/profiles/domain/profile.dart';

import '../../support/seed.dart';

void main() {
  late AppDatabase db;
  late DriftFavoritesRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = DriftFavoritesRepository(db);
  });
  tearDown(() => db.close());

  test('ajoute puis retire un favori', () async {
    final profile = await seedProfile(db);
    final pid = await seedPictogram(db, 'P1');
    await repo.toggle(profile.id, pid);
    expect(await repo.watchIds(profile.id).first, {pid});
    await repo.toggle(profile.id, pid);
    expect(await repo.watchIds(profile.id).first, isEmpty);
  });

  test('les favoris sont propres à chaque profil', () async {
    final a = await seedProfile(db);
    final b = await seedProfile(db, type: ProfileType.adult);
    final pid = await seedPictogram(db, 'P1');
    await repo.toggle(a.id, pid);
    expect(await repo.watchIds(b.id).first, isEmpty);
  });
}
