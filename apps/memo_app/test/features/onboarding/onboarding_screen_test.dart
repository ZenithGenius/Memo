import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/onboarding/presentation/onboarding_screen.dart';
import 'package:memo/features/profiles/data/drift_profile_repository.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/l10n/app_localizations.dart';

import '../../support/seed.dart';

void main() {
  testWidgets('crée le profil choisi puis appelle onDone', (tester) async {
    final db = AppDatabase.forTesting();
    final repo = DriftProfileRepository(db);
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
    );
    var done = false;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(onDone: () => done = true),
        ),
      ),
    );

    // « Suivant » est désactivé tant que rien n'est choisi.
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.text('Enfant'));
    await tester.pump();
    await tester.tap(find.text('Suivant'));
    await tester.pump();
    await tester.tap(find.text('Débutant'));
    await tester.pump();
    await tester.tap(find.text('Suivant'));
    await tester.pump();
    await tester.tap(find.text('Commencer'));
    await tester.pump();

    final profile = await repo.watchActive().first;
    expect(profile?.type, ProfileType.child);
    expect(profile?.level, Level.beginner);
    expect(done, isTrue);

    await disposeWidgetTestDb(tester, container, db);
  });
}
