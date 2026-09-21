import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/features/stats/domain/usage.dart';
import 'package:memo/features/stats/presentation/usage_providers.dart';
import 'package:memo/features/stats/presentation/words_screen.dart';
import 'package:memo/l10n/app_localizations.dart';

import '../../support/fake_usage.dart';

const _profile = Profile(
  id: 1,
  name: 'T',
  type: ProfileType.child,
  level: Level.beginner,
  language: 'fr',
);

Future<void> pump(WidgetTester tester, UsageSummary summary) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        usageRepositoryProvider.overrideWithValue(
          FakeUsageRepository(summary: summary),
        ),
        activeProfileProvider.overrideWith((ref) => Stream.value(_profile)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WordsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sans usage : message explicite', (tester) async {
    await pump(tester, UsageSummary.empty);
    expect(find.text("Rien n'a encore été dit cette semaine"), findsOneWidget);
  });

  testWidgets('affiche phrases, nouveaux mots et classement', (tester) async {
    await pump(
      tester,
      const UsageSummary(
        sentences: 12,
        newWords: 4,
        topWords: [
          WordCount(label: 'Je veux', count: 41),
          WordCount(label: 'Eau', count: 1),
        ],
      ),
    );
    expect(find.text('12 phrases dites · 4 nouveaux mots'), findsOneWidget);
    expect(find.text('Je veux'), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
    expect(find.text('Eau'), findsOneWidget);
  });

  testWidgets('accord au singulier', (tester) async {
    await pump(
      tester,
      const UsageSummary(sentences: 1, newWords: 1, topWords: []),
    );
    expect(find.text('1 phrase dite · 1 nouveau mot'), findsOneWidget);
  });

  testWidgets(
    "la barre du mot le plus utilisé est pleine, les autres proportionnelles",
    (tester) async {
      await pump(
        tester,
        const UsageSummary(
          sentences: 3,
          newWords: 0,
          topWords: [
            WordCount(label: 'A', count: 4),
            WordCount(label: 'B', count: 1),
          ],
        ),
      );
      final bars = tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .map((b) => b.value)
          .toList();
      expect(bars, [1.0, 0.25]);
    },
  );

  testWidgets("chaque ligne est annoncée avec son nombre d'utilisations", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const UsageSummary(
        sentences: 2,
        newWords: 0,
        topWords: [WordCount(label: 'Eau', count: 2)],
      ),
    );
    expect(find.bySemanticsLabel('Eau, 2 fois'), findsOneWidget);
    handle.dispose();
  });
}
