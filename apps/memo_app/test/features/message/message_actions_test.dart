import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/message/presentation/message_actions.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/l10n/app_localizations.dart';

import '../../support/fakes.dart';

void main() {
  final haptics = <Object?>[];

  setUp(() {
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        });
  });

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    late BuildContext ctx;
    late WidgetRef widgetRef;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) {
              ctx = context;
              widgetRef = ref;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    addToMessageForTest = (p) => addToMessage(ctx, widgetRef, p);
    return container;
  }

  testWidgets('un ajout donne un retour tactile léger', (tester) async {
    final container = await pump(tester);
    addToMessageForTest(pictogram(1, 'Eau'));
    expect(container.read(messageProvider), hasLength(1));
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });

  testWidgets('message plein : retour tactile fort et pas d\'ajout', (
    tester,
  ) async {
    final container = await pump(tester);
    for (var i = 0; i < MessageNotifier.maxItems; i++) {
      container.read(messageProvider.notifier).add(pictogram(i, 'x$i'));
    }
    addToMessageForTest(pictogram(99, 'trop'));
    expect(
      container.read(messageProvider),
      hasLength(MessageNotifier.maxItems),
    );
    expect(haptics, ['HapticFeedbackType.heavyImpact']);
  });
}

// Renseigné par `pump` : appelle `addToMessage` dans le contexte du widget.
late void Function(Pictogram) addToMessageForTest;
