import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/message/presentation/message_bar.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/l10n/app_localizations.dart';

import '../../../support/fakes.dart';

Widget host(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(bottomNavigationBar: MessageBar()),
  ),
);

void main() {
  late FakeSpeechService speech;
  late ProviderContainer container;

  setUp(() {
    speech = FakeSpeechService();
    container = ProviderContainer(
      overrides: [
        speechServiceProvider.overrideWithValue(speech),
        activeProfileProvider.overrideWith(
          (ref) => Stream<Profile?>.value(null),
        ),
      ],
    );
  });
  tearDown(() => container.dispose());

  testWidgets('affiche une invite quand le message est vide', (tester) async {
    await tester.pumpWidget(host(container));
    expect(find.text('Touchez un pictogramme pour commencer'), findsOneWidget);
  });

  testWidgets('affiche les éléments et les retire au toucher', (tester) async {
    container.read(messageProvider.notifier)
      ..add(pictogram(1, 'Je veux'))
      ..add(pictogram(2, 'Eau'));
    await tester.pumpWidget(host(container));
    expect(find.text('Je veux'), findsOneWidget);
    await tester.tap(find.widgetWithText(InputChip, 'Eau'));
    await tester.pump();
    expect(container.read(messageProvider).map((p) => p.label), ['Je veux']);
  });

  testWidgets('le bouton lire prononce la phrase composée', (tester) async {
    container.read(messageProvider.notifier)
      ..add(pictogram(1, 'Je veux'))
      ..add(pictogram(2, 'Boire'));
    await tester.pumpWidget(host(container));
    await tester.tap(find.text('Lire le message'));
    await tester.pump();
    expect(speech.spoken, ['Je veux boire.']);
  });

  testWidgets('effacer vide le message', (tester) async {
    container.read(messageProvider.notifier).add(pictogram(1, 'Oui'));
    await tester.pumpWidget(host(container));
    await tester.tap(find.text('Effacer'));
    await tester.pump();
    expect(container.read(messageProvider), isEmpty);
  });
}
