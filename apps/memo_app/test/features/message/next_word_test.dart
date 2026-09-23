import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('après une phrase dite, le mot suivant est proposé et ajouté', (
    tester,
  ) async {
    final app = await AppHarness.start(tester);
    await tester.tap(find.text('Mes besoins'));
    await tester.pumpAndSettle();

    // Première fois : « Je veux » puis « Fini », et on dit la phrase.
    await tester.tap(find.text('Je veux').first);
    await tester.pumpAndSettle();
    expect(find.text('Ensuite…'), findsNothing, reason: 'pas encore appris');
    await tester.tap(find.text('Fini').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lire le message'));
    await settleDatabase(tester);
    await tester.tap(find.text('Effacer'));
    await tester.pumpAndSettle();

    // Deuxième fois : après « Je veux », « Fini » est proposé.
    await tester.tap(find.text('Je veux').first);
    await settleDatabase(tester);
    expect(find.text('Ensuite…'), findsOneWidget);
    final chip = find.widgetWithText(ActionChip, 'Fini');
    expect(chip, findsOneWidget);

    await tester.tap(chip);
    await settleDatabase(tester);
    expect(app.container.read(messageProvider).map((p) => p.label), [
      'Je veux',
      'Fini',
    ]);
    await app.dispose(tester);
  });
}
