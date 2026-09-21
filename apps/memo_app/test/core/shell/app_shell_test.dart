import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

const _hint = 'Touchez un pictogramme pour commencer';

void main() {
  testWidgets('quatre onglets, Parler affiché avec la barre de phrase', (
    tester,
  ) async {
    final app = await AppHarness.start(tester);
    for (final label in ['Parler', 'Phrases', 'Mots', 'Réglages']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Mes besoins'), findsOneWidget);
    expect(find.text(_hint), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('la barre de phrase disparaît hors de l\'onglet Parler', (
    tester,
  ) async {
    final app = await AppHarness.start(tester);
    await tester.tap(find.text('Phrases'));
    await tester.pumpAndSettle();
    expect(find.text('Dis-le maintenant'), findsOneWidget);
    expect(find.text(_hint), findsNothing);

    await tester.tap(find.text('Parler'));
    await tester.pumpAndSettle();
    expect(find.text(_hint), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('chaque onglet ouvre son écran', (tester) async {
    final app = await AppHarness.start(tester);
    await tester.tap(find.text('Mots'));
    await tester.pumpAndSettle();
    expect(find.text("Rien n'a encore été dit cette semaine"), findsOneWidget);

    await tester.tap(find.text('Réglages'));
    await tester.pumpAndSettle();
    expect(find.text('Vibrations'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets("un onglet garde sa position quand on le quitte", (tester) async {
    final app = await AppHarness.start(tester);
    await tester.tap(find.text('Mes besoins'));
    await tester.pumpAndSettle();
    expect(find.text('Je veux'), findsWidgets);

    await tester.tap(find.text('Phrases'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parler'));
    await tester.pumpAndSettle();
    expect(
      find.byType(BackButton),
      findsOneWidget,
      reason: 'toujours dans la catégorie',
    );
    await app.dispose(tester);
  });

  testWidgets("toucher l'onglet actif revient à sa racine", (tester) async {
    final app = await AppHarness.start(tester);
    await tester.tap(find.text('Mes besoins'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.text('Parler'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsNothing);
    expect(find.text('Mes besoins'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('le message composé survit au changement d\'onglet', (
    tester,
  ) async {
    final app = await AppHarness.start(tester);
    await tester.tap(find.text('Mes besoins'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Je veux').first);
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsOneWidget);

    await tester.tap(find.text('Réglages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parler'));
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('parcours complet : choisir des mots puis lire le message', (
    tester,
  ) async {
    final app = await AppHarness.start(tester);
    await tester.tap(find.text('Mes besoins'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Je veux').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lire le message'));
    await tester.pump();
    expect(app.speech.spoken, contains('Je veux.'));
    await app.dispose(tester);
  });
}
