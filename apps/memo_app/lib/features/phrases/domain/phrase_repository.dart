import 'package:memo/features/phrases/domain/quick_phrase.dart';

abstract interface class PhraseRepository {
  /// Phrases livrées puis celles du profil, dans l'ordre d'affichage.
  Stream<List<QuickPhrase>> watch({
    required int? profileId,
    required String lang,
  });

  Future<QuickPhrase> add({
    required int profileId,
    required String lang,
    required String text,
    List<String> tags = const [],
  });

  /// Ne supprime que les phrases créées par l'utilisateur.
  Future<void> remove(int id);
}
