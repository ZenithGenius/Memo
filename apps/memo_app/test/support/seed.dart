import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/profiles/data/drift_profile_repository.dart';
import 'package:memo/features/profiles/domain/profile.dart';

/// Insère un pictogramme minimal (avec traduction française) et retourne son id.
Future<int> seedPictogram(
  AppDatabase db,
  String code, {
  String label = 'Test',
}) async {
  await db
      .into(db.categories)
      .insert(
        CategoriesCompanion.insert(code: 'C', sortOrder: 1),
        mode: InsertMode.insertOrIgnore,
      );
  final cat = await (db.select(
    db.categories,
  )..where((c) => c.code.equals('C'))).getSingle();
  final id = await db
      .into(db.pictograms)
      .insert(
        PictogramsCompanion.insert(
          code: code,
          categoryId: cat.id,
          minLevel: 0,
          audience: 'all',
          sortOrder: 1,
        ),
      );
  await db
      .into(db.pictogramTranslations)
      .insert(
        PictogramTranslationsCompanion.insert(
          pictogramId: id,
          lang: 'fr',
          label: label,
          spokenText: label.toLowerCase(),
        ),
      );
  return id;
}

Future<Profile> seedProfile(
  AppDatabase db, {
  ProfileType type = ProfileType.child,
  Level level = Level.beginner,
}) => DriftProfileRepository(db).create(name: 'T', type: type, level: level);

/// Démonte l'arbre, laisse s'écouler les minuteurs des flux drift, puis ferme
/// la base en temps réel : `db.close()` bloque dans le temps simulé.
Future<void> disposeWidgetTestDb(
  WidgetTester tester,
  ProviderContainer container,
  AppDatabase db,
) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
  await tester.pump(const Duration(seconds: 1));
  await tester.runAsync(db.close);
}
