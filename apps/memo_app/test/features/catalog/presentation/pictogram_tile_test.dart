import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/ui/adaptive_grid.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/pictogram_tile.dart';

Widget tile({
  double labelSize = 14,
  bool labelInImage = false,
  String? imageAsset,
}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 200,
      height: 200,
      child: PictogramTile(
        label: 'Eau',
        onTap: () {},
        labelSize: labelSize,
        labelInImage: labelInImage,
        imageAsset: imageAsset,
      ),
    ),
  ),
);

void main() {
  testWidgets("l'étiquette suit la taille demandée", (tester) async {
    await tester.pumpWidget(tile(labelSize: 16));
    expect(tester.widget<Text>(find.text('Eau')).style?.fontSize, 16);
  });

  test('les enfants ont les plus grandes étiquettes, jamais sous 14', () {
    expect(labelSize(Level.beginner), 16);
    expect(labelSize(Level.beginner), greaterThan(labelSize(Level.advanced)));
    for (final level in Level.values) {
      expect(labelSize(level), greaterThanOrEqualTo(14));
    }
  });

  testWidgets("mot déjà dans l'image : pas de légende en double", (
    tester,
  ) async {
    await tester.pumpWidget(tile(labelInImage: true));
    expect(find.text('Eau'), findsNothing);
  });

  testWidgets("une image introuvable retombe sur l'icône, sans erreur", (
    tester,
  ) async {
    await tester.pumpWidget(tile(imageAsset: 'assets/inexistant.png'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets("l'étiquette reste accessible au lecteur d'écran même masquée", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(tile(labelInImage: true));
    expect(find.bySemanticsLabel('Eau'), findsOneWidget);
    handle.dispose();
  });
}
