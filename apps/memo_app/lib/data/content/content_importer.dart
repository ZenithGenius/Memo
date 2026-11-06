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

  /// Emplacement du paquet embarqué (gratuit).
  static const baseSlot = 1;

  /// Emplacement du paquet payant téléchargé (ADR-008).
  static const premiumSlot = 2;

  /// Emplacement du paquet gratuit téléchargé sans compte (#41) : il fait
  /// foi pour la liste des mots gratuits.
  static const freeSlot = 3;

  /// Version installée d'un emplacement, `null` si rien n'est installé.
  Future<int?> installedVersion(int slot) async => (await (_db.select(
    _db.contentMeta,
  )..where((m) => m.id.equals(slot))).getSingleOrNull())?.version;

  /// Retourne `true` si un import a eu lieu. Chaque emplacement a sa propre
  /// version : le paquet payant ne remplace pas le paquet embarqué.
  Future<bool> importIfNeeded(ContentPack pack, {int slot = baseSlot}) async {
    final installed = await (_db.select(
      _db.contentMeta,
    )..where((m) => m.id.equals(slot))).getSingleOrNull();
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
          imageFeminine: Value(p.imageFeminine),
          imageMasculine: Value(p.imageMasculine),
          imageSha256: Value(p.imageSha256),
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
      for (final phrase in pack.phrases) {
        for (final e in phrase.texts.entries) {
          final row = QuickPhrasesCompanion.insert(
            code: Value(phrase.code),
            lang: e.key,
            body: e.value.text,
            tags: Value(e.value.tags.join(',')),
            sortOrder: phrase.sortOrder,
          );
          await _db
              .into(_db.quickPhrases)
              .insert(
                row,
                onConflict: DoUpdate(
                  (_) => row,
                  target: [_db.quickPhrases.code, _db.quickPhrases.lang],
                ),
              );
        }
      }
      if (slot == freeSlot) {
        // Un mot sorti de l'offre gratuite redevient réservé aux abonnés
        // (un abonné le retrouve par son paquet payant).
        await (_db.update(_db.pictograms)..where(
              (p) =>
                  p.tier.equals('free') &
                  p.code.isNotIn([for (final p in pack.pictograms) p.code]),
            ))
            .write(const PictogramsCompanion(tier: Value('premium')));
      }
      if (slot == baseSlot) {
        // Nouveau paquet embarqué (mise à jour de l'application) : le paquet
        // gratuit du serveur sera réappliqué par-dessus.
        await (_db.delete(
          _db.contentMeta,
        )..where((m) => m.id.equals(freeSlot))).go();
      }
      await _db
          .into(_db.contentMeta)
          .insertOnConflictUpdate(
            ContentMetaCompanion.insert(
              id: Value(slot),
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

  /// Empreintes des images envoyées depuis le back-office, à télécharger ;
  /// celles des mots gratuits seulement si [freeOnly].
  Future<List<String>> imageHashes({bool freeOnly = false}) async {
    final query = _db.selectOnly(_db.pictograms, distinct: true)
      ..addColumns([_db.pictograms.imageSha256])
      ..where(
        _db.pictograms.imageSha256.isNotNull() &
            (freeOnly
                ? _db.pictograms.tier.equals('free')
                : const Constant(true)),
      );
    return [
      for (final row in await query.get())
        row.read(_db.pictograms.imageSha256)!,
    ];
  }
}
