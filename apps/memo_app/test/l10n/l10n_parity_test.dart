import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde-fou : chaque texte de l'interface existe dans toutes les langues,
/// avec les mêmes paramètres. Une clé oubliée afficherait le français (ou
/// planterait) chez un utilisateur anglophone.
Map<String, Object?> load(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
        as Map<String, Object?>;

Iterable<String> keys(Map<String, Object?> arb) =>
    arb.keys.where((k) => !k.startsWith('@'));

/// Paramètres de premier niveau d'un message ICU : `{nom}` et `{nom, plural...}`.
/// Les accolades imbriquées (branches de pluriel ou de sélection) sont ignorées.
Set<String> placeholders(String message) {
  final found = <String>{};
  var depth = 0;
  for (var i = 0; i < message.length; i++) {
    final c = message[i];
    if (c == '{') {
      if (depth == 0) {
        final m = RegExp(r'^(\w+)').firstMatch(message.substring(i + 1));
        if (m != null) found.add(m.group(1)!);
      }
      depth++;
    } else if (c == '}') {
      depth--;
    }
  }
  return found;
}

void main() {
  final fr = load('fr');
  final en = load('en');

  test('les deux langues ont exactement les mêmes clés', () {
    expect(keys(en).toSet(), keys(fr).toSet());
  });

  test('aucun texte vide', () {
    for (final arb in [fr, en]) {
      for (final k in keys(arb)) {
        expect((arb[k]! as String).trim(), isNotEmpty, reason: k);
      }
    }
  });

  test('les paramètres sont identiques dans les deux langues', () {
    for (final k in keys(fr)) {
      expect(
        placeholders(en[k]! as String),
        placeholders(fr[k]! as String),
        reason: 'paramètres de « $k »',
      );
    }
  });

  test("aucun tiret cadratin dans les textes de l'interface", () {
    for (final arb in [fr, en]) {
      for (final k in keys(arb)) {
        expect(arb[k]! as String, isNot(contains('—')), reason: k);
      }
    }
  });

  test('les textes anglais ne sont pas de simples copies du français', () {
    // Noms propres ou identiques dans les deux langues.
    const same = {
      'appName',
      'homeTitle',
      'navPhrases',
      'languageFrench',
      'languageEnglish',
    };
    for (final k in keys(fr)) {
      if (same.contains(k)) continue;
      expect(en[k], isNot(fr[k]), reason: '« $k » semble non traduit');
    }
  });
}
