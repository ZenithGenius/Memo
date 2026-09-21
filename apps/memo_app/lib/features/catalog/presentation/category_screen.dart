import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/ui/adaptive_grid.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/catalog/presentation/pictogram_tile.dart';
import 'package:memo/features/message/presentation/message_actions.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final title = categories
        .where((c) => c.code == code)
        .map((c) => c.label)
        .firstOrNull;
    final pictograms = ref.watch(pictogramsProvider(code));
    final favoriteIds = ref.watch(favoriteIdsProvider).value ?? const <int>{};
    return Scaffold(
      appBar: AppBar(title: Text(title ?? '')),
      body: pictograms.when(
        data: (list) => GridView(
          gridDelegate: adaptiveGridDelegate(ref.watch(currentLevelProvider)),
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
                selected: favoriteIds.contains(p.id),
                onTap: () => addToMessage(context, ref, p),
                onLongPress: () {
                  final profile = ref.read(activeProfileProvider).value;
                  if (profile == null) return;
                  ref
                      .read(favoritesRepositoryProvider)
                      .toggle(profile.id, p.id);
                },
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
