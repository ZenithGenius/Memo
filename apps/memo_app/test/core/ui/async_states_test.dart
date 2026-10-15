import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/theme/app_theme.dart';
import 'package:memo/core/ui/async_states.dart';
import 'package:memo/l10n/app_localizations.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('fr')}) => MaterialApp(
  theme: buildAppTheme(),
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'le chargement reste invisible pendant le délai, puis montre les emplacements',
    (tester) async {
      await tester.pumpWidget(_wrap(const LoadingTiles()));
      expect(find.byType(GridView), findsNothing);

      await tester.pump(loadingRevealDelay);
      expect(find.byType(GridView), findsOneWidget);
    },
  );

  testWidgets('le chargement est annoncé aux lecteurs d\'écran dès le départ', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(const LoadingTiles()));
    expect(find.bySemanticsLabel('Chargement…'), findsOneWidget);
    await tester.pump(loadingRevealDelay);
    handle.dispose();
  });

  testWidgets(
    'l\'erreur affiche un message compréhensible, jamais l\'erreur technique',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ErrorState(
            error: Exception('SqliteException(1): no such table'),
            onRetry: () {},
          ),
        ),
      );
      expect(find.text("Cet écran n'a pas pu s'afficher"), findsOneWidget);
      expect(find.textContaining('Sqlite'), findsNothing);
    },
  );

  testWidgets(
    'réessayer relance le chargement, avec une cible tactile d\'au moins 48 dp',
    (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        _wrap(ErrorState(error: 'x', onRetry: () => retried++)),
      );
      final button = find.widgetWithText(FilledButton, 'Réessayer');
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      await tester.tap(button);
      expect(retried, 1);
    },
  );

  testWidgets('sans relance possible, pas de bouton', (tester) async {
    await tester.pumpWidget(_wrap(const ErrorState(error: 'x')));
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('traduit en anglais', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ErrorState(error: 'x', onRetry: () {}),
        locale: const Locale('en'),
      ),
    );
    expect(find.text("This screen couldn't be shown"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('la variante en lignes affiche des emplacements en liste', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const LoadingTiles.rows()));
    await tester.pump(loadingRevealDelay);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
  });
}
