import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/core/ui/adaptive_grid.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/catalog/presentation/pictogram_tile.dart';
import 'package:memo/features/message/presentation/message_actions.dart';
import 'package:memo/features/message/presentation/message_bar.dart';
import 'package:memo/l10n/app_localizations.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorites = ref.watch(favoritePictogramsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoritesTitle)),
      body: favorites.when(
        data: (list) => list.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.favoritesEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                ),
              )
            : GridView(
                gridDelegate: adaptiveGridDelegate(
                  ref.watch(currentLevelProvider),
                ),
                padding: const EdgeInsets.all(16),
                children: [
                  for (final p in list)
                    PictogramTile(
                      label: p.label,
                      imageAsset: p.imageAsset,
                      labelInImage: p.labelInImage,
                      labelSize: labelSize(ref.watch(currentLevelProvider)),
                      accent: p.colorArgb == null ? null : Color(p.colorArgb!),
                      icon: Icons.chat_bubble_outline,
                      onTap: () => addToMessage(context, ref, p),
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
