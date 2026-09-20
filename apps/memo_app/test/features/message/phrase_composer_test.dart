import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/message/domain/phrase_composer.dart';

import '../../support/fakes.dart';

void main() {
  const composer = SimplePhraseComposer();

  test('une liste vide donne une phrase vide', () {
    expect(composer.compose([]), '');
  });

  test('assemble les textes parlés, majuscule initiale et point final', () {
    final text = composer.compose([
      pictogram(1, 'Je veux'),
      pictogram(2, 'Boire'),
    ]);
    expect(text, 'Je veux boire.');
  });

  test('utilise le texte parlé et non le libellé', () {
    final text = composer.compose([pictogram(1, 'EAU', spoken: "de l'eau")]);
    expect(text, "De l'eau.");
  });
}
