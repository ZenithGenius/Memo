import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/theme/contrast.dart';
import 'package:memo/data/content/content_pack.dart';
import 'package:memo/data/content/content_pack_source.dart';

import '../../support/pump_app.dart';

/// Tout le contenu : paquet embarqué et paquet payant servi par le serveur.
Future<ContentPack> allContent() async {
  final bundled = await const AssetContentPackSource().load();
  final premium = await loadPremiumPack();
  return ContentPack(
    version: bundled.version,
    categories: [...bundled.categories, ...premium.categories],
    pictograms: [...bundled.pictograms, ...premium.pictograms],
    phrases: bundled.phrases,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'embarqué : seulement le gratuit ; payant : le reste, sans doublon',
    () async {
      final bundled = await const AssetContentPackSource().load();
      final premium = await loadPremiumPack();
      expect(bundled.version, premium.version, reason: 'versions alignées');
      expect(bundled.pictograms, hasLength(20));
      expect(bundled.pictograms.every((p) => p.tier == 'free'), isTrue);
      expect(premium.pictograms, hasLength(131));
      expect(premium.pictograms.every((p) => p.tier == 'premium'), isTrue);
      expect(premium.phrases, isEmpty, reason: 'les phrases sont gratuites');

      final all = await allContent();
      expect(all.pictograms.map((p) => p.code).toSet(), hasLength(151));
      expect(
        bundled.categories
            .map((c) => c.code)
            .toSet()
            .intersection(premium.categories.map((c) => c.code).toSet()),
        isEmpty,
      );
      final categoryCodes = all.categories.map((c) => c.code).toSet();
      for (final p in all.pictograms) {
        expect(categoryCodes, contains(p.categoryCode));
        expect(p.labels['fr'], isNotNull, reason: p.code);
      }
    },
  );

  test(
    'position stable : monter de niveau ajoute des mots sans déplacer les autres',
    () async {
      // Les pictogrammes sont affichés par ordre croissant de `sortOrder`.
      // Si le niveau ne décroît jamais avec `sortOrder`, un niveau supérieur
      // ne fait qu'ajouter des mots à la fin : les mots déjà connus gardent
      // leur place (mémoire motrice, bonnes pratiques CAA).
      final pack = await allContent();
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

  test('chaque catégorie a une couleur lisible sur fond blanc (3:1)', () async {
    final pack = await allContent();
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
      final pack = await allContent();
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
    final pack = await allContent();
    expect(pack.phrases, hasLength(8));
    expect(pack.phrases.map((p) => p.code).toSet(), hasLength(8));
    for (final p in pack.phrases) {
      expect(p.texts['fr']!.text.trim(), isNotEmpty, reason: p.code);
    }
  });

  test('tout le contenu existe en anglais', () async {
    final pack = await allContent();
    // Mots identiques en français et en anglais (noms propres, emprunts).
    const same = {
      'Stop',
      'Orange',
      'Couscous',
      'Beignet',
      'Plantain',
      'Ndolé',
      'Eru',
      'Biscuit',
      'Actions',
      'Hygiène',
    };
    for (final c in pack.categories) {
      expect(c.labels['en'], isNotNull, reason: c.code);
    }
    for (final p in pack.pictograms) {
      final en = p.labels['en'];
      final fr = p.labels['fr']!;
      expect(en, isNotNull, reason: p.code);
      expect(en!.label.trim(), isNotEmpty, reason: p.code);
      expect(en.spoken.trim(), isNotEmpty, reason: p.code);
      if (en.label == fr.label) {
        expect(same, contains(en.label), reason: '${p.code} non traduit ?');
      }
    }
    for (final ph in pack.phrases) {
      expect(ph.texts['en'], isNotNull, reason: ph.code);
      expect(
        ph.texts['en']!.text,
        isNot(ph.texts['fr']!.text),
        reason: ph.code,
      );
      expect(
        ph.texts['en']!.tags.length,
        ph.texts['fr']!.tags.length,
        reason: 'thèmes de ${ph.code}',
      );
    }
  });

  test(
    "le texte prononcé anglais garde le pronom « I » en majuscule",
    () async {
      final pack = await allContent();
      for (final p in pack.pictograms) {
        final spoken = p.labels['en']!.spoken;
        if (p.labels['en']!.label.startsWith('I ')) {
          expect(spoken, startsWith('I '), reason: p.code);
        }
      }
    },
  );
}
