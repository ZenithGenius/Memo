import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/phrases/domain/phrase_repository.dart';
import 'package:memo/features/phrases/domain/quick_phrase.dart';

final phraseRepositoryProvider = Provider<PhraseRepository>(
  (ref) => throw UnimplementedError('à surcharger au démarrage'),
);

final quickPhrasesProvider = StreamProvider<List<QuickPhrase>>((ref) {
  final profile = ref.watch(activeProfileProvider).value;
  return ref
      .watch(phraseRepositoryProvider)
      .watch(profileId: profile?.id, lang: profile?.language ?? 'fr');
});
