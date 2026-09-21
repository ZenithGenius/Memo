import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/phrases/domain/phrase_repository.dart';
import 'package:memo/features/phrases/domain/quick_phrase.dart';
import 'package:memo/features/phrases/presentation/phrase_providers.dart';
import 'package:memo/features/phrases/presentation/phrases_screen.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/features/stats/presentation/usage_providers.dart';
import 'package:memo/l10n/app_localizations.dart';

import '../../support/fake_usage.dart';
import '../../support/fakes.dart';

class _FakePhrases implements PhraseRepository {
  _FakePhrases(this.phrases);
  final List<QuickPhrase> phrases;

  @override
  Stream<List<QuickPhrase>> watch({
    required int? profileId,
    required String lang,
  }) => Stream.value(phrases);

  @override
  Future<QuickPhrase> add({
    required int profileId,
    required String lang,
    required String text,
    List<String> tags = const [],
  }) => throw UnimplementedError();

  @override
  Future<void> remove(int id) => throw UnimplementedError();
}

const _profile = Profile(
  id: 1,
  name: 'T',
  type: ProfileType.child,
  level: Level.beginner,
  language: 'fr',
);

final speech = FakeSpeechService();
final usage = FakeUsageRepository();

Future<void> pump(WidgetTester tester, List<QuickPhrase> phrases) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        phraseRepositoryProvider.overrideWithValue(_FakePhrases(phrases)),
        speechServiceProvider.overrideWithValue(speech),
        usageRepositoryProvider.overrideWithValue(usage),
        activeProfileProvider.overrideWith((ref) => Stream.value(_profile)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PhrasesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    speech.spoken.clear();
    usage.recorded.clear();
  });

  testWidgets('affiche les phrases avec leurs thèmes', (tester) async {
    await pump(tester, const [
      QuickPhrase(
        id: 1,
        text: 'Je dois aller aux toilettes',
        tags: ['école', 'maison'],
        isCustom: false,
      ),
    ]);
    expect(find.text('Dis-le maintenant'), findsOneWidget);
    expect(find.text('Je dois aller aux toilettes'), findsOneWidget);
    expect(find.text('ÉCOLE · MAISON'), findsOneWidget);
  });

  testWidgets('toucher une phrase la prononce en entier', (tester) async {
    await pump(tester, const [
      QuickPhrase(id: 1, text: "C'est à mon tour", tags: [], isCustom: false),
    ]);
    await tester.tap(find.text("C'est à mon tour"));
    await tester.pump();
    expect(speech.spoken, ["C'est à mon tour"]);
    expect(usage.recorded.single.profileId, 1);
    expect(
      usage.recorded.single.ids,
      isEmpty,
      reason: 'phrase toute faite : aucun mot',
    );
  });

  testWidgets('sans phrase : message explicite', (tester) async {
    await pump(tester, const []);
    expect(find.text('Aucune phrase pour le moment'), findsOneWidget);
  });

  testWidgets('la ligne est un bouton lisible par un lecteur d\'écran', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const [
      QuickPhrase(id: 1, text: 'Merci', tags: [], isCustom: false),
    ]);
    expect(find.bySemanticsLabel('Dire : Merci'), findsOneWidget);
    handle.dispose();
  });
}
