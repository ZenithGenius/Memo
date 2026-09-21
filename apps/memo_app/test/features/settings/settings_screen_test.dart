import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/caregiver/presentation/caregiver_providers.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/profiles/data/drift_profile_repository.dart';
import 'package:memo/features/settings/domain/app_settings.dart';
import 'package:memo/features/settings/presentation/settings_providers.dart';
import 'package:memo/features/settings/presentation/settings_screen.dart';
import 'package:memo/l10n/app_localizations.dart';

import '../../support/fake_settings.dart';
import '../../support/seed.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late FakeSettingsRepository settings;
  late DriftProfileRepository profiles;

  setUp(() async {
    db = AppDatabase.forTesting();
    profiles = DriftProfileRepository(db);
    await seedProfile(db, level: Level.beginner);
    settings = FakeSettingsRepository();
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(profiles),
        settingsRepositoryProvider.overrideWithValue(settings),
      ],
    );
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('affiche le niveau, la lecture, les vibrations et la langue', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Débutant'), findsOneWidget);
    expect(find.text('Intermédiaire'), findsOneWidget);
    expect(find.text('Avancé'), findsOneWidget);
    expect(find.text('Prononcer chaque mot touché'), findsOneWidget);
    expect(find.text('Vibrations'), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);
    expect(find.textContaining('Très grandes tuiles'), findsOneWidget);
    await disposeWidgetTestDb(tester, container, db);
  });

  testWidgets('changer de niveau met à jour le profil et la description', (
    tester,
  ) async {
    // Le niveau est réservé à l'accompagnant : mode déverrouillé.
    container.read(caregiverSessionProvider.notifier).unlock();
    await pump(tester);
    await tester.tap(find.text('Avancé'));
    await tester.pumpAndSettle();
    expect((await profiles.watchActive().first)!.level, Level.advanced);
    expect(find.textContaining('Tuiles denses'), findsOneWidget);
    await disposeWidgetTestDb(tester, container, db);
  });

  testWidgets('les interrupteurs enregistrent les réglages', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Vibrations'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prononcer chaque mot touché'));
    await tester.pumpAndSettle();
    expect(
      await settings.watch().first,
      const AppSettings(speakEachWord: false, hapticsEnabled: false),
    );
    await disposeWidgetTestDb(tester, container, db);
  });

  testWidgets("choisir l'anglais change la langue du profil", (tester) async {
    await pump(tester);
    final english = find.text('English');
    await tester.ensureVisible(english);
    await tester.pumpAndSettle();
    await tester.tap(english);
    await tester.pumpAndSettle();
    expect((await profiles.watchActive().first)!.language, 'en');
    await disposeWidgetTestDb(tester, container, db);
  });
}
