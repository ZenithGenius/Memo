import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/theme/app_theme.dart';
import 'package:memo/features/phrases/presentation/phrase_providers.dart';
import 'package:memo/features/phrases/presentation/phrases_screen.dart';
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
  home: child,
);

void main() {
  testWidgets(
    'PhrasesScreen affiche ErrorState, pas le texte brut de l\'exception',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quickPhrasesProvider.overrideWith(
              (ref) => Stream.error(Exception('SqliteException boom')),
            ),
          ],
          child: _wrap(const PhrasesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Cet écran n'a pas pu s'afficher"), findsOneWidget);
      expect(find.textContaining('SqliteException'), findsNothing);
    },
  );
}
