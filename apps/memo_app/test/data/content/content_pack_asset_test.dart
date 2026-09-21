import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/content/content_pack_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le paquet embarqué est complet et cohérent', () async {
    final pack = await const AssetContentPackSource().load();
    expect(pack.pictograms, hasLength(151));
    expect(pack.pictograms.map((p) => p.code).toSet(), hasLength(151));
    final categoryCodes = pack.categories.map((c) => c.code).toSet();
    for (final p in pack.pictograms) {
      expect(categoryCodes, contains(p.categoryCode));
      expect(p.labels['fr'], isNotNull, reason: p.code);
    }
    final beginners = pack.pictograms.where((p) => p.minLevel == 0).length;
    expect(beginners, greaterThanOrEqualTo(20));
  });

  test(
    'position stable : monter de niveau ajoute des mots sans déplacer les autres',
    () async {
      // Les pictogrammes sont affichés par ordre croissant de `sortOrder`.
      // Si le niveau ne décroît jamais avec `sortOrder`, un niveau supérieur
      // ne fait qu'ajouter des mots à la fin : les mots déjà connus gardent
      // leur place (mémoire motrice, bonnes pratiques CAA).
      final pack = await const AssetContentPackSource().load();
      for (final category in pack.categories) {
        final items =
            pack.pictograms
                .where((p) => p.categoryCode == category.code)
                .toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        var level = 0;
        for (final p in items) {
          expect(
            p.minLevel,
            greaterThanOrEqualTo(level),
            reason: '${p.code} passerait devant un mot de niveau inférieur',
          );
          level = p.minLevel;
        }
        final orders = items.map((p) => p.sortOrder).toList();
        expect(
          orders.toSet(),
          hasLength(orders.length),
          reason: 'sortOrder dupliqué dans ${category.code}',
        );
      }
    },
  );
}
