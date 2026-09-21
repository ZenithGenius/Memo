import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';

import '../support/pump_app.dart';

Future<void> switchToEnglish(WidgetTester tester) async {
  await tester.tap(find.text('Réglages'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('English'));
  await settleDatabase(tester);
}

void main() {
  testWidgets("choisir l'anglais traduit l'interface et le contenu", (
    tester,
  ) async {
    final app = await AppHarness.start(tester);
    expect(find.text('Mes besoins'), findsOneWidget); // accueil en français
    await switchToEnglish(tester);

    // Interface : onglets, titre, réglages.
    for (final label in ['Talk', 'Phrases', 'Words', 'Settings']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.text('Say each word when tapped'), findsOneWidget);

    // Contenu : catégories et phrases.
    await tester.tap(find.text('Talk'));
    await tester.pumpAndSettle();
    expect(find.text('My needs'), findsOneWidget);
    expect(find.text('Mes besoins'), findsNothing);

    await tester.tap(find.text('Phrases'));
    await tester.pumpAndSettle();
    expect(find.text('Say it now'), findsOneWidget);
    expect(find.text('I need to go to the toilet'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets("en anglais, la voix et les mots sont anglais", (tester) async {
    final app = await AppHarness.start(tester);
    await switchToEnglish(tester);
    await tester.tap(find.text('Talk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My needs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I want').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Say the message'));
    await tester.pump();

    expect(app.speech.spoken, ['I want', 'I want.']);
    expect(app.speech.languages.toSet(), {'en'});
    await app.dispose(tester);
  });

  testWidgets('changer de langue vide le message en cours', (tester) async {
    final app = await AppHarness.start(tester);
    await tester.tap(find.text('Mes besoins'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Je veux').first);
    await tester.pumpAndSettle();
    expect(app.container.read(messageProvider), hasLength(1));

    await switchToEnglish(tester);
    expect(app.container.read(messageProvider), isEmpty);
    await app.dispose(tester);
  });

  testWidgets('la langue est celle du profil et revient en français', (
    tester,
  ) async {
    final app = await AppHarness.start(tester);
    await switchToEnglish(tester);
    expect(app.container.read(activeProfileProvider).value!.language, 'en');

    await tester.tap(find.text('Français'));
    await settleDatabase(tester);
    expect(find.text('Réglages'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    await app.dispose(tester);
  });
}
