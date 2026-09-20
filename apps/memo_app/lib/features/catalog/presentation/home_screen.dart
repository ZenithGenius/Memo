import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle), actions: actions),
      body: categories.when(
        data: (list) => GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
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
      ),
      bottomNavigationBar: const MessageBar(),
    );
  }
}
