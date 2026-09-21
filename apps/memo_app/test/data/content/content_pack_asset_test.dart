import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/theme/contrast.dart';
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

  test(
    'palier gratuit : exactement les 20 concepts prioritaires (ADR-008)',
    () async {
      final pack = await const AssetContentPackSource().load();
      final free = pack.pictograms.where((p) => p.tier == 'free').toList();
      expect(free, hasLength(20));
      expect(free.every((p) => p.categoryCode == 'CBE'), isTrue);
      expect(
        pack.pictograms
            .where((p) => p.tier != 'free')
            .every((p) => p.tier == 'premium'),
        isTrue,
      );
    },
  );

  test('chaque catégorie a une couleur lisible sur fond blanc (3:1)', () async {
    final pack = await const AssetContentPackSource().load();
    for (final c in pack.categories) {
      expect(c.color, matches(RegExp(r'^#[0-9A-Fa-f]{6}$')), reason: c.code);
      final color = Color(
        0xFF000000 | int.parse(c.color!.substring(1), radix: 16),
      );
      expect(
        contrastRatio(color, const Color(0xFFFFFFFF)),
        greaterThanOrEqualTo(3.0),
        reason: 'couleur de ${c.code}',
      );
    }
    final colors = pack.categories.map((c) => c.color).toSet();
    expect(
      colors,
      hasLength(pack.categories.length),
      reason: 'une couleur par catégorie, sans doublon',
    );
  });

  test(
    'les images référencées existent et sont déclarées comme assets',
    () async {
      final pack = await const AssetContentPackSource().load();
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final p in pack.pictograms.where((p) => p.imageAsset != null)) {
        expect(File(p.imageAsset!).existsSync(), isTrue, reason: p.imageAsset);
        final dir = p.imageAsset!.substring(
          0,
          p.imageAsset!.lastIndexOf('/') + 1,
        );
        expect(pubspec, contains(dir), reason: 'dossier non déclaré : $dir');
        expect(
          p.labelInImage,
          isTrue,
          reason: 'les images de démonstration portent le mot',
        );
      }
    },
  );

  test('phrases toutes faites : codes uniques, texte non vide', () async {
    final pack = await const AssetContentPackSource().load();
    expect(pack.phrases, hasLength(8));
    expect(pack.phrases.map((p) => p.code).toSet(), hasLength(8));
    for (final p in pack.phrases) {
      expect(p.texts['fr']!.text.trim(), isNotEmpty, reason: p.code);
    }
  });
}
