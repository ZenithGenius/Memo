import 'dart:math';

/// Contrôle adulte pour le code oublié : une addition dont les nombres sont
/// écrits en toutes lettres, réponse en chiffres. Un jeune enfant ne sait pas
/// la résoudre, un adulte si (principe des « parental gates » des boutiques).
/// ponytail: barrière contre l'enfant, pas contre un adulte malveillant.
class AdultCheck {
  AdultCheck._(this.a, this.b);

  factory AdultCheck.random([Random? random]) {
    final r = random ?? Random();
    return AdultCheck._(11 + r.nextInt(20), 11 + r.nextInt(20));
  }

  final int a;
  final int b;

  bool accepts(String answer) => int.tryParse(answer.trim()) == a + b;

  String question(String lang) => lang == 'en'
      ? '${enWords[a - 11]} plus ${enWords[b - 11]}'
      : '${frWords[a - 11]} plus ${frWords[b - 11]}';

  static const frWords = [
    'onze',
    'douze',
    'treize',
    'quatorze',
    'quinze',
    'seize',
    'dix-sept',
    'dix-huit',
    'dix-neuf',
    'vingt',
    'vingt et un',
    'vingt-deux',
    'vingt-trois',
    'vingt-quatre',
    'vingt-cinq',
    'vingt-six',
    'vingt-sept',
    'vingt-huit',
    'vingt-neuf',
    'trente',
  ];
  static const enWords = [
    'eleven',
    'twelve',
    'thirteen',
    'fourteen',
    'fifteen',
    'sixteen',
    'seventeen',
    'eighteen',
    'nineteen',
    'twenty',
    'twenty-one',
    'twenty-two',
    'twenty-three',
    'twenty-four',
    'twenty-five',
    'twenty-six',
    'twenty-seven',
    'twenty-eight',
    'twenty-nine',
    'thirty',
  ];
}
