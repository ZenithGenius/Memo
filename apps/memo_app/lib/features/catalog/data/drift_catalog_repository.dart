import 'package:drift/drift.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/domain/catalog_repository.dart';

class DriftCatalogRepository implements CatalogRepository {
  DriftCatalogRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<Category>> watchCategories(String lang) {
    final query = _db.select(_db.categories).join([
      innerJoin(
        _db.categoryTranslations,
        _db.categoryTranslations.categoryId.equalsExp(_db.categories.id) &
            _db.categoryTranslations.lang.equals(lang),
      ),
    ])
      ..orderBy([OrderingTerm.asc(_db.categories.sortOrder)]);
    return query.watch().map(
          (rows) => [
            for (final r in rows)
              Category(
                id: r.readTable(_db.categories).id,
                code: r.readTable(_db.categories).code,
                sortOrder: r.readTable(_db.categories).sortOrder,
                iconName: r.readTable(_db.categories).iconName,
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
  }) {
    final query = _pictogramJoin(lang)
      ..where(
        _db.categories.code.equals(categoryCode) &
            _db.pictograms.minLevel.isSmallerOrEqualValue(maxLevel.index) &
            _audienceFilter(audience),
      )
      ..orderBy([OrderingTerm.asc(_db.pictograms.sortOrder)]);
    return query.watch().map(_mapRows);
  }

  @override
  Stream<List<Pictogram>> watchByIds(List<int> ids, String lang) {
    final query = _pictogramJoin(lang)..where(_db.pictograms.id.isIn(ids));
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

  List<Pictogram> _mapRows(List<TypedResult> rows) => [
        for (final r in rows)
          Pictogram(
            id: r.readTable(_db.pictograms).id,
            code: r.readTable(_db.pictograms).code,
            categoryId: r.readTable(_db.pictograms).categoryId,
            imageAsset: r.readTable(_db.pictograms).imageAsset,
            minLevel: Level.values[r.readTable(_db.pictograms).minLevel],
            audience:
                Audience.values.byName(r.readTable(_db.pictograms).audience),
            sortOrder: r.readTable(_db.pictograms).sortOrder,
            label: r.readTable(_db.pictogramTranslations).label,
            spokenText: r.readTable(_db.pictogramTranslations).spokenText,
          ),
      ];
}
