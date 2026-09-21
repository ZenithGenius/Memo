import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/content/content_importer.dart';
import 'package:memo/data/content/content_pack.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/catalog/data/drift_catalog_repository.dart';
import 'package:memo/features/catalog/domain/catalog.dart';

Map<String, Object?> pict(
  String code,
  String label,
  int level, {
  String audience = 'all',
  int order = 1,
  String category = 'CBE',
  String tier = 'free',
}) => {
  'code': code,
  'category': category,
  'tier': tier,
  'level': level,
  'audience': audience,
  'sortOrder': order,
  'image': null,
  'labels': {
    'fr': {'label': label, 'spoken': label.toLowerCase()},
  },
};

void main() {
  late AppDatabase db;
  late DriftCatalogRepository repo;

  Stream<List<Pictogram>> watch(Level maxLevel, Audience audience) =>
      repo.watchPictograms(
        categoryCode: 'CBE',
        lang: 'fr',
        maxLevel: maxLevel,
        audience: audience,
      );

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
            'icon': 'bubble',
            'color': '#C1502E',
            'labels': {'fr': 'Mes besoins'},
          },
          {
            'code': 'ACT',
            'sortOrder': 2,
            'icon': 'hand',
            'labels': {'fr': 'Actions'},
          },
        ],
        'pictograms': [
          pict('A1', 'Je veux', 0),
          pict('A2', 'Merci', 1, order: 2),
          pict('A3', 'Avancé', 2, order: 3),
          pict('A4', 'Enfant seul', 0, audience: 'child', order: 4),
          pict('B1', 'Manger', 0, category: 'ACT', tier: 'premium'),
        ],
      }),
    );
  });
  tearDown(() => db.close());

  test(
    'sans droits payants, seules les catégories gratuites apparaissent',
    () async {
      final cats = await repo.watchCategories('fr').first;
      expect(cats.map((c) => c.code), ['CBE']);
      expect(cats.first.label, 'Mes besoins');
      expect(cats.first.iconName, 'bubble');
    },
  );

  test(
    'avec droits payants, toutes les catégories apparaissent triées',
    () async {
      final cats = await repo.watchCategories('fr', includePremium: true).first;
      expect(cats.map((c) => c.code), ['CBE', 'ACT']);
    },
  );

  test('la couleur de la catégorie est lue (ARGB opaque)', () async {
    final cats = await repo.watchCategories('fr').first;
    expect(cats.first.colorArgb, 0xFFC1502E);
    final list = await watch(Level.beginner, Audience.all).first;
    expect(list.first.colorArgb, 0xFFC1502E);
  });

  test('un pictogramme payant est masqué sans droits, visible avec', () async {
    Stream<List<Pictogram>> actions({required bool premium}) =>
        repo.watchPictograms(
          categoryCode: 'ACT',
          lang: 'fr',
          maxLevel: Level.advanced,
          audience: Audience.all,
          includePremium: premium,
        );
    expect(await actions(premium: false).first, isEmpty);
    final visible = await actions(premium: true).first;
    expect(visible.map((p) => p.code), ['B1']);
    expect(visible.single.tier, Tier.premium);
  });

  test('favoris et tableau : le contenu payant est aussi masqué', () async {
    final all = await repo
        .watchPictograms(
          categoryCode: 'ACT',
          lang: 'fr',
          maxLevel: Level.advanced,
          audience: Audience.all,
          includePremium: true,
        )
        .first;
    final id = all.single.id;
    expect(await repo.watchByIds([id], 'fr').first, isEmpty);
    expect(
      await repo.watchByIds([id], 'fr', includePremium: true).first,
      hasLength(1),
    );
  });

  test('filtre par niveau maximal', () async {
    final list = await watch(Level.beginner, Audience.all).first;
    expect(list.map((p) => p.code), ['A1', 'A4']);
  });

  test("un profil adulte ne voit pas le contenu réservé aux enfants", () async {
    final list = await watch(Level.advanced, Audience.adult).first;
    expect(list.map((p) => p.code), ['A1', 'A2', 'A3']);
  });

  test('le libellé et le texte parlé viennent de la traduction', () async {
    final list = await watch(Level.advanced, Audience.all).first;
    final p = list.firstWhere((p) => p.code == 'A1');
    expect(p.label, 'Je veux');
    expect(p.spokenText, 'je veux');
  });

  test('watchByIds renvoie les pictogrammes demandés', () async {
    final all = await watch(Level.advanced, Audience.all).first;
    final found = await repo.watchByIds([all[1].id, all[0].id], 'fr').first;
    expect(found.map((p) => p.code).toSet(), {'A1', 'A2'});
  });
}
