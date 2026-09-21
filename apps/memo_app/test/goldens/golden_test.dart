import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/theme/app_theme.dart';
import 'package:memo/data/content/content_importer.dart';
import 'package:memo/data/content/content_pack_source.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/board/data/drift_board_repository.dart';
import 'package:memo/features/catalog/data/drift_catalog_repository.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/catalog/presentation/category_screen.dart';
import 'package:memo/features/catalog/presentation/home_screen.dart';
import 'package:memo/features/favorites/data/drift_favorites_repository.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/onboarding/presentation/onboarding_screen.dart';
import 'package:memo/features/profiles/data/drift_profile_repository.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/l10n/app_localizations.dart';

import '../support/fakes.dart';
import '../support/seed.dart';

/// Captures de référence des écrans clés, avec la vraie police Manrope.
/// Régénérer après un changement visuel voulu :
///   flutter test test/goldens --update-goldens
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUpAll(() async {
    final loader = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  setUp(() async {
    db = AppDatabase.forTesting();
    await ContentImporter(
      db,
    ).importIfNeeded(await const AssetContentPackSource().load());
    final profiles = DriftProfileRepository(db);
    await profiles.create(
      name: 'Enfant',
      type: ProfileType.child,
      level: Level.beginner,
    );
    container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(DriftCatalogRepository(db)),
        profileRepositoryProvider.overrideWithValue(profiles),
        favoritesRepositoryProvider.overrideWithValue(
          DriftFavoritesRepository(db),
        ),
        boardRepositoryProvider.overrideWithValue(DriftBoardRepository(db)),
        speechServiceProvider.overrideWithValue(FakeSpeechService()),
      ],
    );
  });

  Widget host(Widget child) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );

  void phone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
  }

  testWidgets('accueil', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      host(
        HomeScreen(
          onOpenCategory: (_) {},
          onOpenFavorites: () {},
          onOpenBoard: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('home.png'));
    await disposeWidgetTestDb(tester, container, db);
  });

  testWidgets('catégorie avec un message composé', (tester) async {
    phone(tester);
    final catalog = DriftCatalogRepository(db);
    final besoins = (await tester.runAsync(
      () => catalog
          .watchPictograms(
            categoryCode: 'CBE',
            lang: 'fr',
            maxLevel: Level.beginner,
            audience: Audience.child,
          )
          .first,
    ))!;
    container.read(messageProvider.notifier)
      ..add(besoins.first)
      ..add(besoins[2]);
    await tester.pumpWidget(host(const CategoryScreen(code: 'CBE')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('category_with_message.png'),
    );
    await disposeWidgetTestDb(tester, container, db);
  });

  testWidgets('première installation', (tester) async {
    phone(tester);
    await tester.pumpWidget(host(const OnboardingScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enfant'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('onboarding.png'),
    );
    await disposeWidgetTestDb(tester, container, db);
  });
}
