import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/catalog/domain/catalog.dart';

void main() {
  const base = Pictogram(
    id: 1,
    code: 'P1',
    categoryId: 1,
    label: 'Enfant',
    spokenText: 'enfant',
    minLevel: Level.beginner,
    audience: Audience.all,
    sortOrder: 1,
    imageAsset: 'commun.png',
    imageFeminine: 'fille.png',
    imageMasculine: 'garcon.png',
  );

  test("l'image suit le genre du profil", () {
    expect(base.forGender(Gender.feminine).imageAsset, 'fille.png');
    expect(base.forGender(Gender.masculine).imageAsset, 'garcon.png');
    expect(base.forGender(Gender.unspecified).imageAsset, 'commun.png');
  });

  test('sans variante, image commune pour tous', () {
    const plain = Pictogram(
      id: 2,
      code: 'P2',
      categoryId: 1,
      label: 'Eau',
      spokenText: 'eau',
      minLevel: Level.beginner,
      audience: Audience.all,
      sortOrder: 1,
      imageAsset: 'eau.png',
    );
    expect(plain.forGender(Gender.feminine).imageAsset, 'eau.png');
    expect(plain.forGender(Gender.masculine), same(plain));
  });
}
