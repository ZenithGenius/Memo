import 'package:drift/drift.dart';
import 'package:memo/data/content/content_pack.dart';
import 'package:memo/data/db/app_database.dart';

/// Importe un paquet de contenu dans la base locale, de façon idempotente.
///
/// Les lignes sont mises à jour par code (clé unique) : les identifiants
/// restent stables, ce qui préserve favoris et tableaux lors d'une mise à jour.
class ContentImporter {
  ContentImporter(this._db);
  final AppDatabase _db;

  /// Retourne `true` si un import a eu lieu.
  Future<bool> importIfNeeded(ContentPack pack) async {
    final installed = await (_db.select(
      _db.contentMeta,
    )..where((m) => m.id.equals(1))).getSingleOrNull();
    if (installed != null && installed.version >= pack.version) return false;

    await _db.transaction(() async {
      final categoryIds = <String, int>{};
      for (final c in pack.categories) {
        final category = CategoriesCompanion.insert(
          code: c.code,
          sortOrder: c.sortOrder,
          iconName: Value(c.iconName),
          colorHex: Value(c.color),
        );
        await _db
            .into(_db.categories)
            .insert(
              category,
              onConflict: DoUpdate(
                (_) => category,
                target: [_db.categories.code],
              ),
            );
        final id = await _categoryId(c.code);
        categoryIds[c.code] = id;
        for (final e in c.labels.entries) {
          await _db
              .into(_db.categoryTranslations)
              .insertOnConflictUpdate(
                CategoryTranslationsCompanion.insert(
                  categoryId: id,
                  lang: e.key,
                  label: e.value,
                ),
              );
        }
      }
      for (final p in pack.pictograms) {
        final pictogram = PictogramsCompanion.insert(
          code: p.code,
          categoryId: categoryIds[p.categoryCode]!,
          minLevel: p.minLevel,
          audience: p.audience,
          sortOrder: p.sortOrder,
          imageAsset: Value(p.imageAsset),
          tier: Value(p.tier),
          labelInImage: Value(p.labelInImage),
        );
        await _db
            .into(_db.pictograms)
            .insert(
              pictogram,
              onConflict: DoUpdate(
                (_) => pictogram,
                target: [_db.pictograms.code],
              ),
            );
        final id = await _pictogramId(p.code);
        for (final e in p.labels.entries) {
          await _db
              .into(_db.pictogramTranslations)
              .insertOnConflictUpdate(
                PictogramTranslationsCompanion.insert(
                  pictogramId: id,
                  lang: e.key,
                  label: e.value.label,
                  spokenText: e.value.spoken,
                ),
              );
        }
      }
      await _db
          .into(_db.contentMeta)
          .insertOnConflictUpdate(
            ContentMetaCompanion.insert(
              id: const Value(1),
              version: pack.version,
              installedAt: DateTime.now(),
            ),
          );
    });
    return true;
  }

  Future<int> _categoryId(String code) async => (await (_db.select(
    _db.categories,
  )..where((c) => c.code.equals(code))).getSingle()).id;

  Future<int> _pictogramId(String code) async => (await (_db.select(
    _db.pictograms,
  )..where((p) => p.code.equals(code))).getSingle()).id;
}
