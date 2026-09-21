import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/stats/domain/usage.dart';
import 'package:memo/features/stats/presentation/usage_providers.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Ce que la personne a dit cette semaine, pour les proches et les
/// professionnels : phrases, nouveaux mots, mots les plus utilisés.
class WordsScreen extends ConsumerWidget {
  const WordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(usageSummaryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wordsTitle)),
      body: summary.when(
        data: (s) => s.sentences == 0 && s.topWords.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.wordsEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                ),
              )
            : _Content(summary: s),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.summary});
  final UsageSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final max = summary.topWords.isEmpty ? 1 : summary.topWords.first.count;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.wordsThisWeek.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 4),
        Semantics(
          container: true,
          child: Text(
            '${l10n.wordsSentences(summary.sentences)} · '
            '${l10n.wordsNew(summary.newWords)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 20),
        for (final w in summary.topWords)
          Semantics(
            label: l10n.wordsTimes(w.label, w.count),
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      w.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: w.count / max,
                        minHeight: 14,
                        color: AppColors.gold,
                        backgroundColor: AppColors.border,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${w.count}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
