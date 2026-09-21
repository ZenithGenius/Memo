import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/ui/adaptive_grid.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/catalog/presentation/category_icons.dart';
import 'package:memo/features/catalog/presentation/pictogram_tile.dart';
import 'package:memo/features/message/presentation/message_bar.dart';
import 'package:memo/l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    required this.onOpenCategory,
    required this.onOpenFavorites,
    required this.onOpenBoard,
    this.actions = const [],
    super.key,
  });

  final void Function(String code) onOpenCategory;
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenBoard;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoriesProvider);
    final level = ref.watch(currentLevelProvider);
    final voiceMissing = ref.watch(voiceAvailableProvider).value == false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle), actions: actions),
      body: Column(
        children: [
          if (voiceMissing)
            MaterialBanner(
              leading: const Icon(Icons.volume_off_outlined),
              content: Text('${l10n.noVoiceTitle}. ${l10n.noVoiceBody}'),
              actions: const [SizedBox.shrink()],
            ),
          Expanded(child: _grid(l10n, categories, level)),
        ],
      ),
      bottomNavigationBar: const MessageBar(),
    );
  }

  Widget _grid(
    AppLocalizations l10n,
    AsyncValue<List<Category>> categories,
    Level level,
  ) {
    return categories.when(
      data: (list) => GridView(
        gridDelegate: adaptiveGridDelegate(level),
        padding: const EdgeInsets.all(16),
        children: [
          for (final c in list)
            PictogramTile(
              label: c.label,
              icon: categoryIcon(c.iconName),
              onTap: () => onOpenCategory(c.code),
            ),
          PictogramTile(
            label: l10n.favoritesTitle,
            icon: Icons.star_outline,
            onTap: onOpenFavorites,
          ),
          PictogramTile(
            label: l10n.boardTitle,
            icon: Icons.dashboard_customize_outlined,
            onTap: onOpenBoard,
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}
