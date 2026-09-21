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
}
