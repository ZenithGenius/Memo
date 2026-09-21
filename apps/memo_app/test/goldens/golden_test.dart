import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/theme/app_theme.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/onboarding/presentation/onboarding_screen.dart';
import 'package:memo/features/profiles/data/drift_profile_repository.dart';
import 'package:memo/l10n/app_localizations.dart';

import '../support/pump_app.dart';
import '../support/seed.dart';

/// Captures de référence des écrans clés, avec la vraie police Manrope.
/// Régénérer après un changement visuel voulu :
///   flutter test test/goldens --update-goldens
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final manrope = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await manrope.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  /// Charge les images avant la capture : sans cela elles restent vides.
  Future<void> loadImages(WidgetTester tester) async {
    final context = tester.element(find.byType(MaterialApp));
    await tester.runAsync(() async {
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(image.image, context);
      }
    });
    await tester.pumpAndSettle();
  }

  void phone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
  }

  Future<void> shot(String name) =>
      expectLater(find.byType(MaterialApp), matchesGoldenFile(name));

  testWidgets('parler : accueil', (tester) async {
    phone(tester);
    final app = await AppHarness.start(tester);
    await shot('home.png');
    await app.dispose(tester);
  });

  testWidgets('parler : catégorie avec un message composé', (tester) async {
    phone(tester);
    final app = await AppHarness.start(tester);
    await tester.tap(find.text('Mes besoins'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Je veux').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fini').first);
    await tester.pumpAndSettle();
    await loadImages(tester);
    await shot('category_with_message.png');
    await app.dispose(tester);
  });

  testWidgets('phrases toutes faites', (tester) async {
    phone(tester);
    final app = await AppHarness.start(tester);
    await tester.tap(find.text('Phrases'));
    await tester.pumpAndSettle();
    await shot('phrases.png');
    await app.dispose(tester);
  });

  testWidgets('mots : statistiques', (tester) async {
    phone(tester);
    final app = await AppHarness.start(tester);
    await tester.tap(find.text('Mes besoins'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Je veux').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lire le message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mots'));
    await tester.pumpAndSettle();
    await shot('words.png');
    await app.dispose(tester);
  });

  testWidgets('réglages', (tester) async {
    phone(tester);
    final app = await AppHarness.start(tester);
    await tester.tap(find.text('Réglages'));
    await tester.pumpAndSettle();
    await shot('settings.png');
    await app.dispose(tester);
  });

  testWidgets('première installation', (tester) async {
    phone(tester);
    final db = AppDatabase.forTesting();
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(DriftProfileRepository(db)),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enfant'));
    await tester.pumpAndSettle();
    await shot('onboarding.png');
    await disposeWidgetTestDb(tester, container, db);
  });
}
