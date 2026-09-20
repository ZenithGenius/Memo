import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting());
  tearDown(() => db.close());

  test('insère et relit un profil', () async {
    final id = await db
        .into(db.profiles)
        .insert(
          ProfilesCompanion.insert(name: 'Test', type: 'child', level: 0),
        );
    final row = await (db.select(
      db.profiles,
    )..where((p) => p.id.equals(id))).getSingle();
    expect(row.name, 'Test');
    expect(row.language, 'fr');
  });

  test("le code d'un pictogramme est unique", () async {
    final catId = await db
        .into(db.categories)
        .insert(CategoriesCompanion.insert(code: 'CBE', sortOrder: 1));
    Future<int> insert() => db
        .into(db.pictograms)
        .insert(
          PictogramsCompanion.insert(
            code: 'CAA-CR-CBE-001',
            categoryId: catId,
            minLevel: 0,
            audience: 'all',
            sortOrder: 1,
          ),
        );
    await insert();
    expect(insert, throwsA(isA<Exception>()));
  });

  test(
    'supprimer une catégorie supprime ses pictogrammes (clé étrangère)',
    () async {
      final catId = await db
          .into(db.categories)
          .insert(CategoriesCompanion.insert(code: 'ACT', sortOrder: 2));
      await db
          .into(db.pictograms)
          .insert(
            PictogramsCompanion.insert(
              code: 'CAA-CR-ACT-001',
              categoryId: catId,
              minLevel: 0,
              audience: 'all',
              sortOrder: 1,
            ),
          );
      await (db.delete(db.categories)..where((c) => c.id.equals(catId))).go();
      expect(await db.select(db.pictograms).get(), isEmpty);
    },
  );
}
