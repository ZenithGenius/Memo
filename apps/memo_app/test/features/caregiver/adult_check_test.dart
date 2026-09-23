import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/caregiver/domain/adult_check.dart';

void main() {
  test('les nombres sont écrits en lettres et la somme est acceptée', () {
    for (var seed = 0; seed < 200; seed++) {
      final c = AdultCheck.random(Random(seed));
      expect(c.a, inInclusiveRange(11, 30));
      expect(c.b, inInclusiveRange(11, 30));
      expect(c.question('fr'), isNot(contains(RegExp(r'\d'))));
      expect(c.question('en'), isNot(contains(RegExp(r'\d'))));
      expect(c.accepts(' ${c.a + c.b} '), isTrue);
      expect(c.accepts('${c.a + c.b + 1}'), isFalse);
      expect(c.accepts('abc'), isFalse);
    }
  });

  test('les bornes des tables de mots sont correctes', () {
    // Parcourt assez de tirages pour couvrir 11 et 30.
    final seen = <int>{};
    for (var seed = 0; seed < 2000; seed++) {
      final c = AdultCheck.random(Random(seed));
      seen
        ..add(c.a)
        ..add(c.b);
      if (c.a == 11) expect(c.question('fr'), startsWith('onze plus'));
      if (c.a == 30) expect(c.question('en'), startsWith('thirty plus'));
    }
    expect(seen, containsAll([11, 30]));
  });
}
