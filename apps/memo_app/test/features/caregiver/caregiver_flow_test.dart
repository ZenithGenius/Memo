import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/router/app_router.dart';
import 'package:memo/features/caregiver/domain/caregiver_pin_service.dart';
import 'package:memo/features/caregiver/presentation/caregiver_providers.dart';
import 'package:memo/features/caregiver/presentation/pin_pad.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';

import '../../support/pump_app.dart';

Future<void> pin(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(
      find.descendant(of: find.byType(PinPad), matching: find.text(d)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Réglages'));
  await tester.pumpAndSettle();
}

Future<Level> currentLevel(AppHarness app) async =>
    app.container.read(activeProfileProvider).value!.level;

/// Crée le code 4827 et déverrouille, depuis le verrou de l'en-tête.
Future<void> createCodeAndUnlock(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.lock_outline));
  await tester.pumpAndSettle();
  await pin(tester, '4827');
  await pin(tester, '4827');
}

void main() {
  group('verrou de l\'en-tête', () {
    testWidgets('premier usage : création du code avec confirmation', (
      tester,
    ) async {
      final app = await AppHarness.start(tester);
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();
      expect(find.text('Créer un code accompagnant'), findsOneWidget);

      await pin(tester, '4827');
      expect(find.text('Confirmez le code'), findsOneWidget);
      await pin(tester, '4827');

      expect(app.container.read(caregiverSessionProvider), isTrue);
      expect(find.byIcon(Icons.lock_open), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('un code trop simple est refusé à la création', (tester) async {
      final app = await AppHarness.start(tester);
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();
      await pin(tester, '1111');
      expect(
        find.text('Ce code est trop simple. Choisissez-en un autre.'),
        findsOneWidget,
      );
      expect(find.text('Créer un code accompagnant'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('deux saisies différentes : on recommence', (tester) async {
      final app = await AppHarness.start(tester);
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();
      await pin(tester, '4827');
      await pin(tester, '9153');
      expect(
        find.text('Les deux codes sont différents. Recommencez.'),
        findsOneWidget,
      );
      expect(find.text('Créer un code accompagnant'), findsOneWidget);
      expect(app.container.read(caregiverSessionProvider), isFalse);
      await app.dispose(tester);
    });

    testWidgets('le verrou reverrouille sur demande', (tester) async {
      final app = await AppHarness.start(tester);
      await createCodeAndUnlock(tester);
      await tester.tap(find.byIcon(Icons.lock_open));
      await tester.pumpAndSettle();
      expect(app.container.read(caregiverSessionProvider), isFalse);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('code existant : saisie, mauvais code puis bon code', (
      tester,
    ) async {
      final app = await AppHarness.start(tester);
      await createCodeAndUnlock(tester);
      app.container.read(caregiverSessionProvider.notifier).lock();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();
      expect(find.text('Code accompagnant'), findsOneWidget);

      await pin(tester, '0001');
      expect(find.text('Code incorrect. 4 essais restants'), findsOneWidget);
      expect(app.container.read(caregiverSessionProvider), isFalse);

      await pin(tester, '4827');
      expect(app.container.read(caregiverSessionProvider), isTrue);
      await app.dispose(tester);
    });

    testWidgets('après cinq échecs le pavé annonce le blocage', (tester) async {
      final app = await AppHarness.start(tester);
      await createCodeAndUnlock(tester);
      app.container.read(caregiverSessionProvider.notifier).lock();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();

      for (var i = 0; i < CaregiverPinService.maxAttempts; i++) {
        await pin(tester, '0001');
      }
      expect(find.textContaining('Trop d\'essais'), findsOneWidget);

      // Même le bon code est refusé pendant le blocage.
      await pin(tester, '4827');
      expect(app.container.read(caregiverSessionProvider), isFalse);

      // Le blocage passé, le bon code fonctionne.
      AppHarness.clock = AppHarness.clock.add(const Duration(seconds: 31));
      await pin(tester, '4827');
      expect(app.container.read(caregiverSessionProvider), isTrue);
      await app.dispose(tester);
    });

    testWidgets("annuler ferme la saisie sans déverrouiller", (tester) async {
      final app = await AppHarness.start(tester);
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.byType(PinPad), findsNothing);
      expect(app.container.read(caregiverSessionProvider), isFalse);
      await app.dispose(tester);
    });

    testWidgets('effacer retire le dernier chiffre saisi', (tester) async {
      final app = await AppHarness.start(tester);
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(PinPad), matching: find.text('4')),
      );
      await tester.tap(
        find.descendant(of: find.byType(PinPad), matching: find.text('8')),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
      final dots = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(PinDots),
              matching: find.byType(Container),
            ),
          )
          .map(
            (c) => (c.decoration! as BoxDecoration).color != Colors.transparent,
          )
          .toList();
      expect(dots, [true, false, false, false]);
      await app.dispose(tester);
    });
  });

  group('actions protégées', () {
    testWidgets('changer de niveau demande le code', (tester) async {
      final app = await AppHarness.start(tester, level: Level.beginner);
      await openSettings(tester);
      expect(
        find.text("Réservé à l'accompagnant : le code sera demandé"),
        findsOneWidget,
      );

      await tester.tap(find.text('Avancé'));
      await tester.pumpAndSettle();
      expect(find.text('Créer un code accompagnant'), findsOneWidget);
      expect(await currentLevel(app), Level.beginner, reason: 'pas encore');

      await pin(tester, '4827');
      await pin(tester, '4827');
      await settleDatabase(tester);
      // Le code vient d'être créé : l'action demandée n'est pas rejouée, mais
      // l'utilisateur peut maintenant changer le niveau.
      await tester.tap(find.text('Avancé'));
      await settleDatabase(tester);
      expect(await currentLevel(app), Level.advanced);
      await app.dispose(tester);
    });

    testWidgets("annuler la saisie laisse le niveau inchangé", (tester) async {
      final app = await AppHarness.start(tester, level: Level.beginner);
      await openSettings(tester);
      await tester.tap(find.text('Avancé'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await settleDatabase(tester);
      expect(await currentLevel(app), Level.beginner);
      await app.dispose(tester);
    });

    testWidgets('mode déverrouillé : plus de code demandé, note masquée', (
      tester,
    ) async {
      final app = await AppHarness.start(tester, level: Level.beginner);
      await createCodeAndUnlock(tester);
      await openSettings(tester);
      expect(
        find.text("Réservé à l'accompagnant : le code sera demandé"),
        findsNothing,
      );
      await tester.tap(find.text('Intermédiaire'));
      await settleDatabase(tester);
      expect(find.byType(PinPad), findsNothing);
      expect(await currentLevel(app), Level.intermediate);
      await app.dispose(tester);
    });

    testWidgets('modifier le tableau demande le code', (tester) async {
      final app = await AppHarness.start(tester);
      app.container.read(appRouterProvider).go('/board');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Créer un code accompagnant'), findsOneWidget);
      expect(
        find.byIcon(Icons.check),
        findsNothing,
        reason: 'pas en modification',
      );
      await app.dispose(tester);
    });

    testWidgets('ajouter une phrase demande le code puis l\'enregistre', (
      tester,
    ) async {
      final app = await AppHarness.start(tester);
      await tester.tap(find.text('Phrases'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajouter une phrase'));
      await tester.pumpAndSettle();
      expect(find.text('Créer un code accompagnant'), findsOneWidget);
      await pin(tester, '4827');
      await pin(tester, '4827');

      // Le code créé, l'ajout demandé se poursuit : le dialogue s'ouvre.
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Il fait très chaud');
      await tester.pump();
      await tester.tap(find.text('Enregistrer'));
      await settleDatabase(tester);
      expect(find.text('Il fait très chaud'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('supprimer sa phrase demande confirmation', (tester) async {
      final app = await AppHarness.start(tester);
      await createCodeAndUnlock(tester);
      await tester.tap(find.text('Phrases'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajouter une phrase'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'À supprimer');
      await tester.pump();
      await tester.tap(find.text('Enregistrer'));
      await settleDatabase(tester);

      // La phrase ajoutée est en bas de la liste : on y fait défiler.
      await tester.ensureVisible(find.byTooltip('Supprimer la phrase'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Supprimer la phrase'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer « À supprimer » ?'), findsOneWidget);
      await tester.tap(find.text('Supprimer'));
      await settleDatabase(tester);
      expect(find.text('À supprimer'), findsNothing);
      await app.dispose(tester);
    });

    testWidgets("les phrases livrées ne sont jamais supprimables", (
      tester,
    ) async {
      final app = await AppHarness.start(tester);
      await createCodeAndUnlock(tester);
      await tester.tap(find.text('Phrases'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Supprimer la phrase'), findsNothing);
      await app.dispose(tester);
    });
  });
}
