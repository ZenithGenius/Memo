import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('après une phrase dite, le mot suivant est proposé et ajouté', (
    tester,
  ) async {
    final app = await AppHarness.start(tester);
    await tester.tap(find.text('Mes besoins'));
    await tester.pumpAndSettle();

    // Première fois : « Encore » puis « Oui », et on dit la phrase.
    await tester.tap(find.bySemanticsLabel('Encore').first);
    await tester.pumpAndSettle();
    expect(find.text('Ensuite…'), findsNothing, reason: 'pas encore appris');
    await tester.tap(find.bySemanticsLabel('Oui').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lire le message'));
    await settleDatabase(tester);
    await tester.tap(find.text('Effacer'));
    await tester.pumpAndSettle();

    // Deuxième fois : après « Encore », « Oui » est proposé.
    await tester.tap(find.bySemanticsLabel('Encore').first);
    await settleDatabase(tester);
    expect(find.text('Ensuite…'), findsOneWidget);
    final chip = find.widgetWithText(ActionChip, 'Oui');
    expect(chip, findsOneWidget);

    await tester.tap(chip);
    await settleDatabase(tester);
    expect(app.container.read(messageProvider).map((p) => p.label), [
      'Encore',
      'Oui',
    ]);
    await app.dispose(tester);
  });
}
