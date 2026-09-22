import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/caregiver/presentation/caregiver_providers.dart';
import 'package:memo/features/caregiver/presentation/pin_pad.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/features/profiles/presentation/profile_button.dart';

import '../../support/fakes.dart';
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

Future<int> addSecondProfile(WidgetTester tester, AppHarness app) async {
  final repo = app.container.read(profileRepositoryProvider);
  final active = app.container.read(activeProfileProvider).value!;
  await tester.runAsync(() async {
    final paul = await repo.create(
      name: 'Paul',
      type: ProfileType.adult,
      level: Level.advanced,
    );
    await repo.setActive(active.id);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return paul;
  });
  await tester.pumpAndSettle();
  return active.id;
}

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.byType(ProfileButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("l'en-tête montre le profil actif : nom, type et niveau", (
    tester,
  ) async {
    final app = await AppHarness.start(tester, name: 'Amina');
    expect(find.text('Amina'), findsOneWidget);
    expect(find.text('A'), findsOneWidget, reason: 'initiale');
    expect(find.text('ENFANT · DÉBUTANT'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('« Qui parle ? » liste les profils et marque le profil actuel', (
    tester,
  ) async {
    final app = await AppHarness.start(tester, name: 'Amina');
    await addSecondProfile(tester, app);
    await openSheet(tester);
    expect(find.text('Qui parle ?'), findsOneWidget);
    expect(find.text('Paul'), findsOneWidget);
    expect(find.text('Adulte · Avancé'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('changer de profil demande le code puis bascule', (tester) async {
    final app = await AppHarness.start(tester, name: 'Amina');
    await addSecondProfile(tester, app);
    await openSheet(tester);

    await tester.tap(find.text('Paul'));
    await tester.pumpAndSettle();
    expect(find.text('Créer un code accompagnant'), findsOneWidget);
    expect(app.container.read(activeProfileProvider).value!.name, 'Amina');

    await pin(tester, '4827');
    await pin(tester, '4827');
    await settleDatabase(tester);

    expect(app.container.read(activeProfileProvider).value!.name, 'Paul');
    expect(find.text('Paul'), findsOneWidget, reason: 'nouvel en-tête');
    expect(find.text('Qui parle ?'), findsNothing, reason: 'feuille fermée');
    expect(
      app.container.read(caregiverSessionProvider),
      isFalse,
      reason: "l'appareil est confié à la personne : reverrouillé",
    );
    await app.dispose(tester);
  });

  testWidgets('le message en cours est vidé au changement de profil', (
    tester,
  ) async {
    final app = await AppHarness.start(tester, name: 'Amina');
    await addSecondProfile(tester, app);
    app.container.read(messageProvider.notifier).add(pictogram(1, 'Oui'));
    app.container.read(caregiverSessionProvider.notifier).unlock();
    await openSheet(tester);
    await tester.tap(find.text('Paul'));
    await settleDatabase(tester);
    expect(app.container.read(messageProvider), isEmpty);
    await app.dispose(tester);
  });

  testWidgets('toucher le profil actuel referme la feuille sans code', (
    tester,
  ) async {
    final app = await AppHarness.start(tester, name: 'Amina');
    await openSheet(tester);
    await tester.tap(find.text('Enfant · Débutant'));
    await tester.pumpAndSettle();
    expect(find.text('Qui parle ?'), findsNothing);
    expect(find.byType(PinPad), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('un nouveau profil demande le code, un nom, puis devient actif', (
    tester,
  ) async {
    final app = await AppHarness.start(tester, name: 'Amina');
    await openSheet(tester);
    await tester.tap(find.text('Nouveau profil'));
    await tester.pumpAndSettle();
    expect(find.byType(PinPad), findsOneWidget);
    await pin(tester, '4827');
    await pin(tester, '4827');

    // Sans nom, la création est impossible.
    final create = find.widgetWithText(FilledButton, 'Créer le profil');
    expect(tester.widget<FilledButton>(create).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Lucie');
    await tester.pump();
    await tester.tap(find.text('Adolescent'));
    await tester.pump();
    await tester.tap(find.text('Intermédiaire'));
    await tester.pump();
    await tester.tap(create);
    await settleDatabase(tester);

    final active = app.container.read(activeProfileProvider).value!;
    expect(active.name, 'Lucie');
    expect(active.type, ProfileType.teen);
    expect(active.level, Level.intermediate);
    expect(app.container.read(caregiverSessionProvider), isFalse);
    expect(find.text('Lucie'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets("le nouveau profil reprend la langue en cours", (tester) async {
    final app = await AppHarness.start(tester, name: 'Amina');
    await tester.tap(find.text('FR'));
    await settleDatabase(tester);
    app.container.read(caregiverSessionProvider.notifier).unlock();

    await tester.tap(find.byType(ProfileButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Grace');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Create profile'));
    await settleDatabase(tester);

    expect(app.container.read(activeProfileProvider).value!.language, 'en');
    await app.dispose(tester);
  });

  testWidgets("un nom composé d'espaces n'est pas accepté", (tester) async {
    final app = await AppHarness.start(tester, name: 'Amina');
    app.container.read(caregiverSessionProvider.notifier).unlock();
    await openSheet(tester);
    await tester.tap(find.text('Nouveau profil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    final create = find.widgetWithText(FilledButton, 'Créer le profil');
    expect(tester.widget<FilledButton>(create).onPressed, isNull);
    await app.dispose(tester);
  });
}
