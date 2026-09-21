import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/router/app_router.dart';
import 'package:memo/core/theme/app_theme.dart';
import 'package:memo/core/ui/app_scroll_behavior.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/l10n/app_localizations.dart';

class MemoApp extends ConsumerWidget {
  const MemoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: buildAppTheme(),
      // La langue de l'interface suit celle du profil, pas celle du téléphone.
      locale: Locale(
        ref.watch(activeProfileProvider).asData?.value?.language ?? 'fr',
      ),
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: ref.watch(appRouterProvider),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
