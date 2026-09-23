import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/caregiver/domain/adult_check.dart';
import 'package:memo/features/caregiver/presentation/adult_check_dialog.dart';
import 'package:memo/features/caregiver/presentation/caregiver_providers.dart';
import 'package:memo/features/caregiver/presentation/pin_pad.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/features/profiles/presentation/profile_button.dart';

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

/// Lit l'addition affichée (en lettres) et en calcule le résultat.
String answerShown(WidgetTester tester) {
  final question = tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(AdultCheckDialog),
          matching: find.byType(Text),
        ),
      )
      .map((t) => t.data ?? '')
      .firstWhere((s) => s.contains(' plus '));
  final parts = question.split(' plus ');
  int value(String w) => AdultCheck.frWords.indexOf(w) + 11;
  return '${value(parts[0]) + value(parts[1])}';
}

Future<void> lockedWithCode(WidgetTester tester, AppHarness app) async {
  await tester.tap(find.byIcon(Icons.lock_outline));
  await tester.pumpAndSettle();
  await pin(tester, '4827');
  await pin(tester, '4827');
  app.container.read(caregiverSessionProvider.notifier).lock();
  await tester.pumpAndSettle();
}

void main() {
  group('code oublié', () {
    testWidgets('contrôle adulte réussi : nouveau code, données intactes', (
      tester,
    ) async {
      final app = await AppHarness.start(tester, name: 'Amina');
      await lockedWithCode(tester, app);

      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Code oublié ?'));
      await tester.pumpAndSettle();
      expect(find.text('Vérification adulte'), findsOneWidget);

      await tester.enterText(find.byType(TextField), answerShown(tester));
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(find.text('Créer un code accompagnant'), findsOneWidget);
      await pin(tester, '9153');
      await pin(tester, '9153');
      expect(app.container.read(caregiverSessionProvider), isTrue);
      expect(
        app.container.read(activeProfileProvider).value!.name,
        'Amina',
        reason: 'le profil et ses données sont conservés',
      );
      await app.dispose(tester);
    });

    testWidgets('mauvaise réponse : nouvelle question, code inchangé', (
      tester,
    ) async {
      final app = await AppHarness.start(tester);
      await lockedWithCode(tester, app);
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Code oublié ?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '999');
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(
        find.text("Ce n'est pas le bon résultat. Nouvelle question."),
        findsOneWidget,
      );

      await tester.tap(find.text('Annuler').last);
      await tester.pumpAndSettle();
      await pin(tester, '4827');
      expect(
        app.container.read(caregiverSessionProvider),
        isTrue,
        reason: "l'ancien code fonctionne toujours",
      );
      await app.dispose(tester);
    });

    testWidgets("pas de « code oublié » à la création d'un code", (
      tester,
    ) async {
      final app = await AppHarness.start(tester);
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();
      expect(find.text('Code oublié ?'), findsNothing);
      await app.dispose(tester);
    });
  });

  group('suppression de profil', () {
    Future<void> addPaulAndOpenSheet(
      WidgetTester tester,
      AppHarness app,
    ) async {
      await tester.runAsync(() async {
        final repo = app.container.read(profileRepositoryProvider);
        final amina = (await repo.watchActive().first)!;
        await repo.create(
          name: 'Paul',
          type: ProfileType.adult,
          level: Level.advanced,
        );
        await repo.setActive(amina.id);
      });
      await settleDatabase(tester);
      await tester.tap(find.byType(ProfileButton));
      await tester.pumpAndSettle();
    }

    testWidgets('mode verrouillé : aucune suppression possible', (
      tester,
    ) async {
      final app = await AppHarness.start(tester, name: 'Amina');
      await addPaulAndOpenSheet(tester, app);
      expect(find.byTooltip('Supprimer Paul'), findsNothing);
      await app.dispose(tester);
    });

    testWidgets('accompagnant : supprime un autre profil après confirmation', (
      tester,
    ) async {
      final app = await AppHarness.start(tester, name: 'Amina');
      app.container.read(caregiverSessionProvider.notifier).unlock();
      await addPaulAndOpenSheet(tester, app);

      expect(
        find.byTooltip('Supprimer Amina'),
        findsNothing,
        reason: 'le profil actif ne se supprime pas',
      );
      await tester.tap(find.byTooltip('Supprimer Paul'));
      await tester.pumpAndSettle();
      expect(find.textContaining('définitive'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
      await settleDatabase(tester);

      final all = await tester.runAsync(
        () => app.container.read(profileRepositoryProvider).watchAll().first,
      );
      expect(all!.map((p) => p.name), ['Amina']);
      expect(find.text('Paul'), findsNothing);
      await app.dispose(tester);
    });

    testWidgets('annuler la confirmation garde le profil', (tester) async {
      final app = await AppHarness.start(tester, name: 'Amina');
      app.container.read(caregiverSessionProvider.notifier).unlock();
      await addPaulAndOpenSheet(tester, app);
      await tester.tap(find.byTooltip('Supprimer Paul'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await settleDatabase(tester);
      expect(find.text('Paul'), findsOneWidget);
      await app.dispose(tester);
    });
  });
}
