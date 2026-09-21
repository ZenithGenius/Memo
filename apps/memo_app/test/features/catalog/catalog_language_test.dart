import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/content/content_importer.dart';
import 'package:memo/data/content/content_pack.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/catalog/data/drift_catalog_repository.dart';
import 'package:memo/features/catalog/domain/catalog.dart';

Map<String, Object?> pict(
  String code,
  String fr,
  String en, {
  String? image,
  bool labelInImage = false,
  String category = 'CBE',
}) => {
  'code': code,
  'category': category,
  'level': 0,
  'audience': 'all',
  'sortOrder': 1,
  'image': image,
  'labelInImage': labelInImage,
  'labels': {
    'fr': {'label': fr, 'spoken': fr.toLowerCase()},
    'en': {'label': en, 'spoken': "I'd like $en"},
  },
};

void main() {
  late AppDatabase db;
  late DriftCatalogRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting();
    repo = DriftCatalogRepository(db);
    await ContentImporter(db).importIfNeeded(
      ContentPack.fromJson({
        'version': 1,
        'categories': [
          {
            'code': 'CBE',
            'sortOrder': 1,
            'labels': {'fr': 'Mes besoins', 'en': 'My needs'},
          },
          {
            'code': 'ACT',
            'sortOrder': 2,
            'labels': {'fr': 'Actions'},
          },
        ],
        'pictograms': [
          pict(
            'A1',
            'Oui',
            'Yes',
            image: 'assets/demo/oui.png',
            labelInImage: true,
          ),
          pict('A2', 'Eau', 'Water', image: 'assets/demo/eau.png'),
          pict('B1', 'Manger', 'Eat', category: 'ACT'),
        ],
      }),
    );
  });
  tearDown(() => db.close());

  Stream<List<Pictogram>> watch(String lang) => repo.watchPictograms(
    categoryCode: 'CBE',
    lang: lang,
    maxLevel: Level.advanced,
    audience: Audience.all,
  );

  test("les catégories s'affichent dans la langue demandée", () async {
    expect((await repo.watchCategories('fr').first).map((c) => c.label), [
      'Mes besoins',
      'Actions',
    ]);
    // « Actions » n'a pas de traduction anglaise : elle ne s'affiche pas
    // plutôt que d'apparaître vide.
    expect((await repo.watchCategories('en').first).map((c) => c.label), [
      'My needs',
    ]);
  });

  test('libellé et texte prononcé suivent la langue', () async {
    final en = (await watch('en').first).firstWhere((p) => p.code == 'A2');
    expect(en.label, 'Water');
    expect(en.spokenText, "I'd like Water");
    final fr = (await watch('fr').first).firstWhere((p) => p.code == 'A2');
    expect(fr.label, 'Eau');
  });

  test(
    'image de démonstration avec mot français : masquée en anglais',
    () async {
      final fr = (await watch('fr').first).firstWhere((p) => p.code == 'A1');
      expect(fr.imageAsset, 'assets/demo/oui.png');
      expect(fr.labelInImage, isTrue);

      final en = (await watch('en').first).firstWhere((p) => p.code == 'A1');
      expect(en.imageAsset, isNull, reason: 'le mot incrusté est en français');
      expect(
        en.labelInImage,
        isFalse,
        reason: 'la légende anglaise est affichée',
      );
    },
  );

  test(
    "une image sans texte incrusté reste affichée dans toutes les langues",
    () async {
      for (final lang in ['fr', 'en']) {
        final p = (await watch(lang).first).firstWhere((p) => p.code == 'A2');
        expect(p.imageAsset, 'assets/demo/eau.png', reason: lang);
      }
    },
  );
}
