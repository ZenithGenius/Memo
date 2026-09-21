import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/app.dart';
import 'package:memo/core/startup.dart';

void main() {
  testWidgets("un échec de démarrage affiche un message, pas un écran vide", (
    tester,
  ) async {
    final reported = <Object>[];
    final root = await buildRootWidget(
      create: () async => throw StateError('base illisible'),
      report: (error, stack) => reported.add(error),
    );
    await tester.pumpWidget(root);
    await tester.pumpAndSettle();

    expect(find.text('Impossible de démarrer Memo'), findsOneWidget);
    expect(find.textContaining('rouvrez'), findsOneWidget);
    expect(reported.single, isA<StateError>());
    expect(find.byType(MemoApp), findsNothing);
  });

  test("un démarrage réussi construit l'application", () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final root = await buildRootWidget(create: () async => container);
    expect(root, isA<UncontrolledProviderScope>());
  });
}
