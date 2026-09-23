import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/stats/domain/usage.dart';

final usageRepositoryProvider = Provider<UsageRepository>(
  (ref) => throw UnimplementedError('à surcharger au démarrage'),
);

final usageSummaryProvider = StreamProvider<UsageSummary>((ref) {
  final profile = ref.watch(activeProfileProvider).asData?.value;
  if (profile == null) return Stream.value(UsageSummary.empty);
  return ref
      .watch(usageRepositoryProvider)
      .watchWeek(
        profileId: profile.id,
        lang: profile.language,
        now: DateTime.now,
      );
});

/// Enregistre une phrase prononcée par le profil actif (statistiques).
/// Sans profil actif, ne fait rien. Une erreur d'enregistrement est rapportée
/// mais ne perturbe jamais la parole.
void recordSpoken(WidgetRef ref, {List<int> pictogramIds = const []}) {
  final profile = ref.read(activeProfileProvider).asData?.value;
  if (profile == null) return;
  unawaited(
    ref
        .read(usageRepositoryProvider)
        .recordSentence(
          profileId: profile.id,
          pictogramIds: pictogramIds,
          at: DateTime.now(),
        )
        .catchError((Object error, StackTrace stack) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'memo usage',
            ),
          );
        }),
  );
}

/// Identifiants des mots qui suivent souvent le dernier mot du message.
final _nextWordIdsProvider = StreamProvider<List<int>>((ref) {
  final profile = ref.watch(activeProfileProvider).asData?.value;
  final message = ref.watch(messageProvider);
  if (profile == null || message.isEmpty) return Stream.value(const []);
  return ref
      .watch(usageRepositoryProvider)
      .watchNextWords(profileId: profile.id, afterPictogramId: message.last.id);
});

/// Suggestions de mot suivant, apprises des phrases déjà dites (hors ligne).
final nextWordSuggestionsProvider = StreamProvider<List<Pictogram>>((ref) {
  final profile = ref.watch(activeProfileProvider).asData?.value;
  final ids = ref.watch(_nextWordIdsProvider).asData?.value ?? const [];
  if (profile == null || ids.isEmpty) return Stream.value(const []);
  return ref
      .watch(catalogRepositoryProvider)
      .watchByIds(
        ids,
        profile.language,
        includePremium: ref.watch(premiumUnlockedProvider),
      )
      // watchByIds ne garde pas l'ordre : on rétablit celui de la fréquence.
      .map((list) => [for (final id in ids) ...list.where((p) => p.id == id)]);
});
