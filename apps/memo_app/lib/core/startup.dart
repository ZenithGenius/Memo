import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/app.dart';
import 'package:memo/core/bootstrap.dart';
import 'package:memo/core/theme/app_theme.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Construit le widget racine. Si l'ouverture de la base ou l'import du
/// contenu échoue, l'utilisateur voit un message plutôt qu'un écran de
/// chargement sans fin, et l'erreur est rapportée.
Future<Widget> buildRootWidget({
  Future<ProviderContainer> Function()? create,
  void Function(Object error, StackTrace stack)? report,
}) async {
  try {
    final container = await (create ?? createContainer)();
    return UncontrolledProviderScope(
      container: container,
      child: const MemoApp(),
    );
  } on Object catch (error, stack) {
    (report ?? _reportToFlutter)(error, stack);
    return const StartupFailureApp();
  }
}

void _reportToFlutter(Object error, StackTrace stack) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'memo startup',
    ),
  );
}

class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildAppTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.startupFailedTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.startupFailedBody),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: SystemNavigator.pop,
                      child: Text(l10n.startupFailedClose),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
