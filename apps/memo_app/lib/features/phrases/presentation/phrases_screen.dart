import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/phrases/domain/quick_phrase.dart';
import 'package:memo/features/phrases/presentation/phrase_providers.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Phrases toutes faites : un toucher les prononce en entier.
class PhrasesScreen extends ConsumerWidget {
  const PhrasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final phrases = ref.watch(quickPhrasesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.phrasesTitle)),
      body: phrases.when(
        data: (list) => list.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.phrasesEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, i) => _PhraseRow(phrase: list[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _PhraseRow extends ConsumerWidget {
  const _PhraseRow({required this.phrase});
  final QuickPhrase phrase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.phraseSpeak(phrase.text),
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          final language =
              ref.read(activeProfileProvider).value?.language ?? 'fr';
          ref
              .read(speechServiceProvider)
              .speak(phrase.text, language: language);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phrase.text,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (phrase.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            phrase.tags.join(' · ').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              letterSpacing: 0.6,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.volume_up_outlined, color: AppColors.teal),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
