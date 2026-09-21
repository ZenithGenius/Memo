import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/core/ui/adaptive_grid.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/catalog/presentation/pictogram_tile.dart';
import 'package:memo/features/message/presentation/message_actions.dart';
import 'package:memo/l10n/app_localizations.dart';

class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  bool _editing = false;

  Future<void> _pickForCell(int position) async {
    final profile = ref.read(activeProfileProvider).value;
    if (profile == null) return;
    final repo = ref.read(boardRepositoryProvider);
    final picked = await showModalBottomSheet<_PickResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _PictogramPicker(),
    );
    if (picked == null) return;
    await repo.setCell(profile.id, profile.level, position, picked.pictogramId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final board = ref.watch(boardProvider).value;
    final pictograms = ref.watch(boardPictogramsProvider).value ?? const {};
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.boardTitle),
        actions: [
          IconButton(
            tooltip: _editing ? l10n.boardDone : l10n.boardEdit,
            icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
            onPressed: () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: board == null
          ? const Center(child: CircularProgressIndicator())
          : GridView.count(
              crossAxisCount: board.columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              padding: const EdgeInsets.all(16),
              children: [
                for (var i = 0; i < board.size; i++)
                  _cell(board.cells[i], pictograms, i, l10n),
              ],
            ),
    );
  }

  Widget _cell(
    int? pictogramId,
    Map<int, Pictogram> pictograms,
    int position,
    AppLocalizations l10n,
  ) {
    final p = pictogramId == null ? null : pictograms[pictogramId];
    if (p == null) {
      return Semantics(
        button: _editing,
        label: l10n.boardEmptyCell,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _editing ? () => _pickForCell(position) : null,
            child: _editing
                ? const Center(
                    child: Icon(Icons.add, color: AppColors.mutedText),
                  )
                : null,
          ),
        ),
      );
    }
    return PictogramTile(
      label: p.label,
      imageAsset: p.imageAsset,
      labelInImage: p.labelInImage,
      labelSize: labelSize(ref.watch(currentLevelProvider)),
      accent: p.colorArgb == null ? null : Color(p.colorArgb!),
      icon: Icons.chat_bubble_outline,
      selected: _editing,
      onTap: _editing
          ? () => _pickForCell(position)
          : () => addToMessage(context, ref, p),
    );
  }
}

class _PickResult {
  const _PickResult(this.pictogramId);
  final int? pictogramId;
}

class _PictogramPicker extends ConsumerWidget {
  const _PictogramPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(const _PickResult(null)),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.boardClearCell),
          ),
          for (final c in categories) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                c.label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p
                    in ref.watch(pictogramsProvider(c.code)).value ??
                        const <Pictogram>[])
                  ActionChip(
                    label: Text(p.label),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onPressed: () =>
                        Navigator.of(context).pop(_PickResult(p.id)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
