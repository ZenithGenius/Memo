import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/bootstrap.dart';
import 'package:memo/data/content/content_pack.dart';
import 'package:memo/data/content/content_pack_source.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';

import '../support/fakes.dart';

void main() {
  test('le démarrage importe le contenu et fournit les dépôts', () async {
    final db = AppDatabase.forTesting();
    final container = await createContainer(
      db: db,
      source: InMemoryContentPackSource(
        ContentPack.fromJson({
          'version': 1,
          'categories': [
            {
              'code': 'CBE',
              'sortOrder': 1,
              'icon': 'bubble',
              'labels': {'fr': 'Mes besoins'},
            },
          ],
          'pictograms': [
            {
              'code': 'A1',
              'category': 'CBE',
              'level': 0,
              'audience': 'all',
              'sortOrder': 1,
              'image': null,
              'labels': {
                'fr': {'label': 'Je veux', 'spoken': 'je veux'},
              },
            },
          ],
        }),
      ),
      speech: FakeSpeechService(),
    );
    final cats = await container
        .read(catalogRepositoryProvider)
        .watchCategories('fr')
        .first;
    expect(cats.map((c) => c.code), ['CBE']);
    expect(container.read(activeProfileProvider).value, isNull);
    container.dispose();
    await db.close();
  });

  test('variante dev : le contenu payant embarqué est importé', () async {
    final db = AppDatabase.forTesting();
    Map<String, Object?> pack(String category, String code, String tier) => {
      'version': 1,
      'categories': [
        {
          'code': category,
          'sortOrder': 1,
          'icon': 'bubble',
          'labels': {'fr': category},
        },
      ],
      'pictograms': [
        {
          'code': code,
          'category': category,
          'level': 0,
          'audience': 'all',
          'sortOrder': 1,
          'tier': tier,
          'image': null,
          'labels': {
            'fr': {'label': code, 'spoken': code},
          },
        },
      ],
    };
    final container = await createContainer(
      db: db,
      source: InMemoryContentPackSource(
        ContentPack.fromJson(pack('CBE', 'A1', 'free')),
      ),
      devPremiumSource: InMemoryContentPackSource(
        ContentPack.fromJson(pack('ALI', 'B1', 'premium')),
      ),
      speech: FakeSpeechService(),
    );
    final cats = await container
        .read(catalogRepositoryProvider)
        .watchCategories('fr', includePremium: true)
        .first;
    expect(cats.map((c) => c.code), containsAll(['CBE', 'ALI']));
    container.dispose();
    await db.close();
  });
}
