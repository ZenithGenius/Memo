import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/caregiver/presentation/caregiver_gate.dart';
import 'package:memo/features/caregiver/presentation/caregiver_providers.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/phrases/domain/quick_phrase.dart';
import 'package:memo/features/phrases/presentation/phrase_providers.dart';
import 'package:memo/features/stats/presentation/usage_providers.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Phrases toutes faites : un toucher les prononce en entier. L'accompagnant
/// peut ajouter les siennes et supprimer celles qu'il a ajoutées.
class PhrasesScreen extends ConsumerWidget {
  const PhrasesScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(activeProfileProvider).asData?.value;
    if (profile == null) return;
    if (!await requireCaregiver(context, ref)) return;
    if (!context.mounted) return;
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _AddPhraseDialog(),
    );
    if (text == null || text.trim().isEmpty) return;
    await ref
        .read(phraseRepositoryProvider)
        .add(profileId: profile.id, lang: profile.language, text: text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final phrases = ref.watch(quickPhrasesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.phrasesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.phraseAdd),
      ),
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
                // Laisse la place du bouton flottant sous la dernière ligne.
                padding: const EdgeInsets.only(top: 8, bottom: 96),
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

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.phraseDeleteConfirm(phrase.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.phraseDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(phraseRepositoryProvider).remove(phrase.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final caregiver = ref.watch(caregiverSessionProvider);
    return Row(
      children: [
        Expanded(
          child: Semantics(
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
                recordSpoken(ref);
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
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
                      const Icon(
                        Icons.volume_up_outlined,
                        color: AppColors.teal,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (caregiver && phrase.isCustom)
          IconButton(
            tooltip: l10n.phraseDelete,
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
          )
        else
          const SizedBox(width: 8),
      ],
    );
  }
}

class _AddPhraseDialog extends StatefulWidget {
  const _AddPhraseDialog();

  @override
  State<_AddPhraseDialog> createState() => _AddPhraseDialogState();
}

class _AddPhraseDialogState extends State<_AddPhraseDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.phraseAdd),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 80,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.phraseAddHint),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.phraseSave),
        ),
      ],
    );
  }
}
