import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/catalog/presentation/pictogram_tile.dart';
import 'package:memo/features/message/presentation/message_bar.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final title =
        categories.where((c) => c.code == code).map((c) => c.label).firstOrNull;
    final pictograms = ref.watch(pictogramsProvider(code));
    return Scaffold(
      appBar: AppBar(title: Text(title ?? '')),
      body: pictograms.when(
        data: (list) => GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          padding: const EdgeInsets.all(16),
          children: [
            for (final p in list)
              PictogramTile(
                label: p.label,
                imageAsset: p.imageAsset,
                icon: Icons.chat_bubble_outline,
                onTap: () => ref.read(messageProvider.notifier).add(p),
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
