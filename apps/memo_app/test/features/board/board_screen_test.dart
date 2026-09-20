import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/board/data/drift_board_repository.dart';
import 'package:memo/features/board/presentation/board_screen.dart';
import 'package:memo/features/catalog/data/drift_catalog_repository.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/profiles/data/drift_profile_repository.dart';
import 'package:memo/l10n/app_localizations.dart';

import '../../support/fakes.dart';
import '../../support/seed.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late DriftBoardRepository boards;
  late int profileId;
  late int pictogramId;

  setUp(() async {
    db = AppDatabase.forTesting();
    final profile = await seedProfile(db);
    profileId = profile.id;
    pictogramId = await seedPictogram(db, 'P1', label: 'Eau');
    boards = DriftBoardRepository(db);
    await boards.setCell(profileId, Level.beginner, 0, pictogramId);
    container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(DriftCatalogRepository(db)),
        profileRepositoryProvider.overrideWithValue(DriftProfileRepository(db)),
        boardRepositoryProvider.overrideWithValue(boards),
        speechServiceProvider.overrideWithValue(FakeSpeechService()),
      ],
    );
  });

  Widget host() => UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BoardScreen(),
    ),
  );

  testWidgets('toucher une case remplie ajoute le pictogramme au message', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eau'));
    await tester.pump();
    expect(container.read(messageProvider).map((p) => p.id), [pictogramId]);
    await disposeWidgetTestDb(tester, container, db);
  });

  testWidgets('la grille du niveau débutant compte 6 cases', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    await disposeWidgetTestDb(tester, container, db);
  });
}
