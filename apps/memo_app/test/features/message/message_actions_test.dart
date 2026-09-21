import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/message/presentation/message_actions.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/settings/domain/app_settings.dart';
import 'package:memo/features/settings/presentation/settings_providers.dart';
import 'package:memo/l10n/app_localizations.dart';

import '../../support/fake_settings.dart';
import '../../support/fakes.dart';

void main() {
  final haptics = <Object?>[];
  late FakeSpeechService speech;
  late void Function(Pictogram) add;

  setUp(() {
    haptics.clear();
    speech = FakeSpeechService();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        });
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    AppSettings settings = AppSettings.defaults,
  }) async {
    final container = ProviderContainer(
      overrides: [
        speechServiceProvider.overrideWithValue(speech),
        settingsRepositoryProvider.overrideWithValue(
          FakeSettingsRepository(settings),
        ),
      ],
    );
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
    await container.read(appSettingsProvider.future);
    add = (p) => addToMessage(ctx, widgetRef, p);
    return container;
  }

  testWidgets('un ajout vibre légèrement et prononce le mot', (tester) async {
    final container = await pump(tester);
    add(pictogram(1, 'Eau'));
    expect(container.read(messageProvider), hasLength(1));
    expect(haptics, ['HapticFeedbackType.selectionClick']);
    expect(speech.spoken, ['eau']);
  });

  testWidgets("c'est le texte parlé qui est prononcé, pas le libellé", (
    tester,
  ) async {
    await pump(tester);
    add(pictogram(1, 'EAU', spoken: "de l'eau"));
    expect(speech.spoken, ["de l'eau"]);
  });

  testWidgets('sans « prononcer chaque mot » : aucun son', (tester) async {
    await pump(tester, settings: const AppSettings(speakEachWord: false));
    add(pictogram(1, 'Eau'));
    expect(speech.spoken, isEmpty);
  });

  testWidgets('vibrations coupées : aucune vibration, le mot est ajouté', (
    tester,
  ) async {
    final container = await pump(
      tester,
      settings: const AppSettings(hapticsEnabled: false),
    );
    add(pictogram(1, 'Eau'));
    expect(container.read(messageProvider), hasLength(1));
    expect(haptics, isEmpty);
  });

  testWidgets('message plein : vibration forte, pas d\'ajout ni de son', (
    tester,
  ) async {
    final container = await pump(tester);
    for (var i = 0; i < MessageNotifier.maxItems; i++) {
      container.read(messageProvider.notifier).add(pictogram(i, 'x$i'));
    }
    add(pictogram(99, 'trop'));
    expect(
      container.read(messageProvider),
      hasLength(MessageNotifier.maxItems),
    );
    expect(haptics, ['HapticFeedbackType.heavyImpact']);
    expect(speech.spoken, isEmpty);
  });
}
