import 'package:drift/drift.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/domain/catalog_repository.dart';

class DriftCatalogRepository implements CatalogRepository {
  DriftCatalogRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<Category>> watchCategories(
    String lang, {
    bool includePremium = false,
  }) {
    // Une catégorie n'apparaît que si elle contient au moins un pictogramme
    // accessible : sans droits payants, les catégories payantes disparaissent.
    final hasVisible = existsQuery(
      _db.select(_db.pictograms)..where(
        (p) =>
            p.categoryId.equalsExp(_db.categories.id) &
            _tierFilter(p.tier, includePremium),
      ),
    );
    final query =
        _db.select(_db.categories).join([
            innerJoin(
              _db.categoryTranslations,
              _db.categoryTranslations.categoryId.equalsExp(_db.categories.id) &
                  _db.categoryTranslations.lang.equals(lang),
            ),
          ])
          ..where(hasVisible)
          ..orderBy([OrderingTerm.asc(_db.categories.sortOrder)]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          Category(
            id: r.readTable(_db.categories).id,
            code: r.readTable(_db.categories).code,
            sortOrder: r.readTable(_db.categories).sortOrder,
            iconName: r.readTable(_db.categories).iconName,
            colorArgb: parseHexColor(r.readTable(_db.categories).colorHex),
            label: r.readTable(_db.categoryTranslations).label,
          ),
      ],
    );
  }

  @override
  Stream<List<Pictogram>> watchPictograms({
    required String categoryCode,
    required String lang,
    required Level maxLevel,
    required Audience audience,
    bool includePremium = false,
  }) {
    final query = _pictogramJoin(lang)
      ..where(
        _db.categories.code.equals(categoryCode) &
            _db.pictograms.minLevel.isSmallerOrEqualValue(maxLevel.index) &
            _audienceFilter(audience) &
            _tierFilter(_db.pictograms.tier, includePremium),
      )
      ..orderBy([OrderingTerm.asc(_db.pictograms.sortOrder)]);
    return query.watch().map(_mapRows);
  }

  @override
  Stream<List<Pictogram>> watchByIds(
    List<int> ids,
    String lang, {
    bool includePremium = false,
  }) {
    final query = _pictogramJoin(lang)
      ..where(
        _db.pictograms.id.isIn(ids) &
            _tierFilter(_db.pictograms.tier, includePremium),
      );
    return query.watch().map(_mapRows);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _pictogramJoin(String lang) {
    return _db.select(_db.pictograms).join([
      innerJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.pictograms.categoryId),
      ),
      innerJoin(
        _db.pictogramTranslations,
        _db.pictogramTranslations.pictogramId.equalsExp(_db.pictograms.id) &
            _db.pictogramTranslations.lang.equals(lang),
      ),
    ]);
  }

  /// Le profil accompagnant (`Audience.all`) voit tous les contenus.
  Expression<bool> _audienceFilter(Audience audience) {
    if (audience == Audience.all) return const Constant(true);
    return _db.pictograms.audience.isIn(['all', audience.name]);
  }

  /// Sans droits payants, seul le contenu gratuit est visible.
  Expression<bool> _tierFilter(GeneratedColumn<String> tier, bool premium) {
    if (premium) return const Constant(true);
    return tier.equals(Tier.free.name);
  }

  List<Pictogram> _mapRows(List<TypedResult> rows) => [
    for (final r in rows)
      Pictogram(
        id: r.readTable(_db.pictograms).id,
        code: r.readTable(_db.pictograms).code,
        categoryId: r.readTable(_db.pictograms).categoryId,
        imageAsset: r.readTable(_db.pictograms).imageAsset,
        minLevel: Level.values[r.readTable(_db.pictograms).minLevel],
        audience: Audience.values.byName(r.readTable(_db.pictograms).audience),
        sortOrder: r.readTable(_db.pictograms).sortOrder,
        tier: Tier.values.byName(r.readTable(_db.pictograms).tier),
        colorArgb: parseHexColor(r.readTable(_db.categories).colorHex),
        labelInImage: r.readTable(_db.pictograms).labelInImage,
        label: r.readTable(_db.pictogramTranslations).label,
        spokenText: r.readTable(_db.pictogramTranslations).spokenText,
      ),
  ];
}

/// `#RRGGBB` vers ARGB opaque, ou `null` si absent ou invalide.
int? parseHexColor(String? hex) {
  if (hex == null) return null;
  final m = RegExp(r'^#([0-9A-Fa-f]{6})$').firstMatch(hex);
  return m == null ? null : 0xFF000000 | int.parse(m.group(1)!, radix: 16);
}
