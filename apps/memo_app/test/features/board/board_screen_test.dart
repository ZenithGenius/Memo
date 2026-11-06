import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/storage/secure_store.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/board/data/drift_board_repository.dart';
import 'package:memo/features/board/data/drift_routine_repository.dart';
import 'package:memo/features/board/presentation/board_screen.dart';
import 'package:memo/features/caregiver/domain/caregiver_pin_service.dart';
import 'package:memo/features/caregiver/presentation/caregiver_providers.dart';
import 'package:memo/features/caregiver/presentation/pin_sheet.dart';
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
  late FakeSpeechService speech;

  setUp(() async {
    db = AppDatabase.forTesting();
    final profile = await seedProfile(db);
    profileId = profile.id;
    pictogramId = await seedPictogram(db, 'P1', label: 'Eau');
    boards = DriftBoardRepository(db);
    await boards.setCell(profileId, Level.beginner, 0, pictogramId);
    speech = FakeSpeechService();
    final routines = DriftRoutineRepository(db);
    final routine = await routines.create(profileId, 'Le matin');
    final wash = await seedPictogram(db, 'P2', label: 'Se laver');
    await routines.setSteps(routine, [pictogramId, wash]);
    container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(DriftCatalogRepository(db)),
        profileRepositoryProvider.overrideWithValue(DriftProfileRepository(db)),
        boardRepositoryProvider.overrideWithValue(boards),
        routineRepositoryProvider.overrideWithValue(routines),
        caregiverPinServiceProvider.overrideWithValue(
          CaregiverPinService(store: InMemorySecureStore(), now: DateTime.now),
        ),
        speechServiceProvider.overrideWithValue(speech),
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

  testWidgets('routine : toucher une étape la prononce, « Fait » la coche', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    expect(find.text('Le matin'), findsOneWidget);
    expect(find.text('0 sur 2'), findsOneWidget);

    await tester.tap(find.text('Se laver'));
    await tester.pump();
    expect(speech.spoken, ['se laver']);
    expect(container.read(messageProvider), isEmpty);

    await tester.tap(find.text('Fait').first);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('1 sur 2'), findsOneWidget);

    await tester.tap(find.text('Fait').last);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Routine terminée, bravo !'), findsOneWidget);

    await tester.tap(find.byTooltip('Recommencer'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('0 sur 2'), findsOneWidget);
    await disposeWidgetTestDb(tester, container, db);
  });

  testWidgets('créer une routine demande le code de l\'accompagnant', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouvelle routine'));
    // La feuille du code attend son service : pas de pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PinSheet), findsOneWidget);
    expect(
      await tester.runAsync(() => db.select(db.routines).get()),
      hasLength(1),
    );
    await disposeWidgetTestDb(tester, container, db);
  });

  testWidgets("l'accompagnant crée une routine puis ouvre ses étapes", (
    tester,
  ) async {
    container.read(caregiverSessionProvider.notifier).unlock();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Routines'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouvelle routine'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Le soir ');
    await tester.tap(find.text('Enregistrer'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Étapes de « Le soir »'), findsOneWidget);

    final rows = await tester.runAsync(() => db.select(db.routines).get());
    expect(rows!.map((r) => r.name), ['Le matin', 'Le soir']);
    container.read(caregiverSessionProvider.notifier).lock();
    await disposeWidgetTestDb(tester, container, db);
  });
}
