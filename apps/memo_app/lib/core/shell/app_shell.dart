import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memo/features/message/presentation/message_bar.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Coque de l'application : quatre onglets, chacun avec son propre historique
/// de navigation. La barre de phrase n'existe que sur l'onglet Parler.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  static const talkIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (shell.currentIndex == talkIndex) const MessageBar(),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            // Toucher l'onglet déjà actif revient à sa racine.
            onDestinationSelected: (i) =>
                shell.goBranch(i, initialLocation: i == shell.currentIndex),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.chat_bubble_outline),
                selectedIcon: const Icon(Icons.chat_bubble),
                label: l10n.navTalk,
              ),
              NavigationDestination(
                icon: const Icon(Icons.format_quote_outlined),
                selectedIcon: const Icon(Icons.format_quote),
                label: l10n.navPhrases,
              ),
              NavigationDestination(
                icon: const Icon(Icons.bar_chart_outlined),
                selectedIcon: const Icon(Icons.bar_chart),
                label: l10n.navWords,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: l10n.navSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
