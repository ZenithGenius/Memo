import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/content/content_importer.dart';
import 'package:memo/data/content/content_pack.dart';
import 'package:memo/data/db/app_database.dart';

ContentPack samplePack({int version = 1}) => ContentPack.fromJson({
      'version': version,
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
          'code': 'CAA-CR-CBE-001',
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
    });

void main() {
  late AppDatabase db;
  late ContentImporter importer;

  setUp(() {
    db = AppDatabase.forTesting();
    importer = ContentImporter(db);
  });
  tearDown(() => db.close());

  test('importe catégories, pictogrammes et traductions', () async {
    final imported = await importer.importIfNeeded(samplePack());
    expect(imported, isTrue);
    expect(await db.select(db.categories).get(), hasLength(1));
    expect(await db.select(db.pictograms).get(), hasLength(1));
    final tr = await db.select(db.pictogramTranslations).getSingle();
    expect(tr.label, 'Je veux');
    expect(tr.spokenText, 'je veux');
  });

  test('ne réimporte pas une version déjà installée', () async {
    await importer.importIfNeeded(samplePack());
    final again = await importer.importIfNeeded(samplePack());
    expect(again, isFalse);
    expect(await db.select(db.pictograms).get(), hasLength(1));
  });

  test('une version plus récente met à jour sans dupliquer', () async {
    await importer.importIfNeeded(samplePack());
    final firstId = (await db.select(db.pictograms).getSingle()).id;
    final updated = await importer.importIfNeeded(samplePack(version: 2));
    expect(updated, isTrue);
    final rows = await db.select(db.pictograms).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, firstId);
    final meta = await db.select(db.contentMeta).getSingle();
    expect(meta.version, 2);
  });
}
