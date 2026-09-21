import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/stats/presentation/usage_providers.dart';
import 'package:memo/l10n/app_localizations.dart';

class MessageBar extends ConsumerWidget {
  const MessageBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(messageProvider);
    final notifier = ref.read(messageProvider.notifier);
    final language = ref.watch(activeProfileProvider).value?.language ?? 'fr';

    return Material(
      color: const Color(0xFFFFF9F0),
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: items.isEmpty
                      ? Text(
                          l10n.messageEmptyHint,
                          style: const TextStyle(color: AppColors.mutedText),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < items.length; i++)
                              Semantics(
                                button: true,
                                label: l10n.removeItem(items[i].label),
                                excludeSemantics: true,
                                child: InputChip(
                                  label: Text(items[i].label),
                                  onDeleted: () => notifier.removeAt(i),
                                  onPressed: () => notifier.removeAt(i),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: items.isEmpty ? null : notifier.clear,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 52),
                    ),
                    child: Text(l10n.clearButton),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: items.isEmpty
                          ? null
                          : () {
                              ref
                                  .read(speechServiceProvider)
                                  .speak(
                                    ref
                                        .read(phraseComposerProvider)
                                        .compose(items),
                                    language: language,
                                  );
                              recordSpoken(
                                ref,
                                pictogramIds: [for (final p in items) p.id],
                              );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                      ),
                      icon: const Icon(Icons.volume_up),
                      label: Text(l10n.speakButton),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
