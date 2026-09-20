import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/content/content_importer.dart';
import 'package:memo/data/content/content_pack.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/catalog/data/drift_catalog_repository.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/catalog/presentation/category_screen.dart';
import 'package:memo/features/catalog/presentation/home_screen.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/profiles/data/drift_profile_repository.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/l10n/app_localizations.dart';

import '../../../support/fakes.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late FakeSpeechService speech;

  setUp(() async {
    speech = FakeSpeechService();
    db = AppDatabase.forTesting();
    await ContentImporter(db).importIfNeeded(
      ContentPack.fromJson({
        'version': 1,
        'categories': [
          {
            'code': 'CBE',
            'sortOrder': 1,
            'icon': 'bubble',
            'labels': {'fr': 'Mes besoins'},
          },
          {
            'code': 'ALI',
            'sortOrder': 2,
            'icon': 'plate',
            'labels': {'fr': 'Alimentation'},
          },
        ],
        'pictograms': [
          {
            'code': 'A1',
            'category': 'CBE',
            'level': 0,
            'audience': 'all',
            'sortOrder': 1,
            'image': null,
            'labels': {
              'fr': {'label': 'Je veux', 'spoken': 'je veux'},
            },
          },
        ],
      }),
    );
    final profiles = DriftProfileRepository(db);
    await profiles.create(
      name: 'T',
      type: ProfileType.child,
      level: Level.beginner,
    );
    container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(DriftCatalogRepository(db)),
        profileRepositoryProvider.overrideWithValue(profiles),
        speechServiceProvider.overrideWithValue(speech),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Widget host(Widget child) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );

  testWidgets("l'accueil affiche les catégories et les raccourcis", (
    tester,
  ) async {
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
    expect(find.text('Mes besoins'), findsOneWidget);
    expect(find.text('Alimentation'), findsOneWidget);
    expect(find.text('Mes favoris'), findsOneWidget);
    expect(find.text('Mon tableau'), findsOneWidget);
  });

  testWidgets("toucher un pictogramme l'ajoute au message", (tester) async {
    await tester.pumpWidget(host(const CategoryScreen(code: 'CBE')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Je veux').first);
    await tester.pump();
    expect(container.read(messageProvider).map((p) => p.code), ['A1']);
  });

  testWidgets("l'accueil avertit quand la voix française est absente", (
    tester,
  ) async {
    speech.available = false;
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
    expect(find.textContaining('Voix française introuvable'), findsOneWidget);
  });

  testWidgets("pas d'avertissement quand la voix est disponible", (
    tester,
  ) async {
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
    expect(find.textContaining('Voix française introuvable'), findsNothing);
  });
}
