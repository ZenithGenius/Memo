import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memo/app.dart';
import 'package:memo/core/bootstrap.dart';
import 'package:memo/data/db/app_database.dart';

import '../test/support/fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('parcours JE VEUX LAIT puis lecture, sans réseau', (
    tester,
  ) async {
    final speech = FakeSpeechService();
    final container = await createContainer(
      db: AppDatabase.forTesting(),
      speech: speech,
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MemoApp()),
    );
    await tester.pumpAndSettle();

    // Première installation : enfant, débutant.
    await tester.tap(find.text('Enfant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Débutant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    // Accueil, Mes besoins, Je veux.
    await tester.tap(find.text('Mes besoins'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Je veux').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Alimentation, Eau.
    await tester.tap(find.text('Alimentation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lait').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lire le message'));
    await tester.pump();

    // Chaque mot est prononcé au toucher, puis la phrase entière à la lecture.
    expect(speech.spoken, ['je veux', 'lait', 'Je veux lait.']);
  });
}
