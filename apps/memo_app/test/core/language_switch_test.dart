import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/profiles/presentation/language_actions.dart';

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

  group('pastille FR/EN', () {
    testWidgets("affiche la langue courante et bascule d'un toucher", (
      tester,
    ) async {
      final app = await AppHarness.start(tester);
      expect(find.text('FR'), findsOneWidget);

      await tester.tap(find.text('FR'));
      await settleDatabase(tester);
      expect(find.text('EN'), findsOneWidget);
      expect(find.text('My needs'), findsOneWidget);
      expect(find.text('Talk'), findsWidgets);

      await tester.tap(find.text('EN'));
      await settleDatabase(tester);
      expect(find.text('FR'), findsOneWidget);
      expect(find.text('Mes besoins'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('la pastille annonce la langue vers laquelle elle bascule', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final app = await AppHarness.start(tester);
      expect(find.bySemanticsLabel('Passer en anglais'), findsOneWidget);
      await tester.tap(find.text('FR'));
      await settleDatabase(tester);
      expect(find.bySemanticsLabel('Switch to French'), findsOneWidget);
      handle.dispose();
      await app.dispose(tester);
    });

    testWidgets('la pastille vide aussi le message en cours', (tester) async {
      final app = await AppHarness.start(tester);
      await tester.tap(find.text('Mes besoins'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Je veux').first);
      await tester.pumpAndSettle();
      expect(app.container.read(messageProvider), hasLength(1));

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FR'));
      await settleDatabase(tester);
      expect(app.container.read(messageProvider), isEmpty);
      await app.dispose(tester);
    });
  });

  test('la bascule suit les langues prises en charge, en boucle', () {
    expect(nextLanguage('fr'), 'en');
    expect(nextLanguage('en'), 'fr');
    expect(nextLanguage('autre'), supportedLanguages.first);
  });
}
