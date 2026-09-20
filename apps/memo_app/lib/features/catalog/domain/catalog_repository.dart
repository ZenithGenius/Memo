import 'package:memo/features/catalog/domain/catalog.dart';

abstract interface class CatalogRepository {
  Stream<List<Category>> watchCategories(String lang);

  Stream<List<Pictogram>> watchPictograms({
    required String categoryCode,
    required String lang,
    required Level maxLevel,
    required Audience audience,
  });

  Stream<List<Pictogram>> watchByIds(List<int> ids, String lang);
}
