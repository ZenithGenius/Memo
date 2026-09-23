import 'package:equatable/equatable.dart';

class WordCount extends Equatable {
  const WordCount({required this.label, required this.count});
  final String label;
  final int count;

  @override
  List<Object?> get props => [label, count];
}

class UsageSummary extends Equatable {
  const UsageSummary({
    required this.sentences,
    required this.newWords,
    required this.topWords,
  });

  static const empty = UsageSummary(sentences: 0, newWords: 0, topWords: []);

  /// Phrases prononcées sur la période.
  final int sentences;

  /// Mots utilisés pour la première fois sur la période.
  final int newWords;

  /// Mots les plus utilisés, du plus au moins fréquent.
  final List<WordCount> topWords;

  @override
  List<Object?> get props => [sentences, newWords, topWords];
}

abstract interface class UsageRepository {
  /// Enregistre une phrase prononcée et les mots qu'elle contient
  /// (aucun mot pour une phrase toute faite).
  Future<void> recordSentence({
    required int profileId,
    required List<int> pictogramIds,
    required DateTime at,
  });

  /// Mots qui ont le plus souvent suivi [afterPictogramId] dans les phrases
  /// déjà dites par ce profil, du plus au moins fréquent.
  Stream<List<int>> watchNextWords({
    required int profileId,
    required int afterPictogramId,
    int limit = 4,
  });

  /// Résumé des sept derniers jours jusqu'à [now].
  Stream<UsageSummary> watchWeek({
    required int profileId,
    required String lang,
    required DateTime Function() now,
  });
}
