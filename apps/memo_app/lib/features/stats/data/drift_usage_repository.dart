import 'dart:async';

import 'package:drift/drift.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/stats/domain/usage.dart';

class DriftUsageRepository implements UsageRepository {
  DriftUsageRepository(this._db);
  final AppDatabase _db;

  static const _topLimit = 8;
  static const _window = Duration(days: 7);

  @override
  Future<void> recordSentence({
    required int profileId,
    required List<int> pictogramIds,
    required DateTime at,
  }) => _db.transaction(() async {
    await _db
        .into(_db.spokenSentences)
        .insert(
          SpokenSentencesCompanion.insert(profileId: profileId, spokenAt: at),
        );
    await _db.batch((b) {
      b.insertAll(_db.wordEvents, [
        for (final id in pictogramIds)
          WordEventsCompanion.insert(
            profileId: profileId,
            pictogramId: id,
            usedAt: at,
          ),
      ]);
    });
  });

  @override
  Stream<UsageSummary> watchWeek({
    required int profileId,
    required String lang,
    required DateTime Function() now,
  }) {
    late final StreamController<UsageSummary> controller;
    StreamSubscription<Set<TableUpdate>>? updates;

    Future<void> emit() async {
      try {
        final summary = await _load(profileId, lang, now());
        if (!controller.isClosed) controller.add(summary);
      } on Object catch (error, stack) {
        if (!controller.isClosed) controller.addError(error, stack);
      }
    }

    controller = StreamController<UsageSummary>(
      onListen: () {
        emit();
        updates = _db
            .tableUpdates(
              TableUpdateQuery.onAllTables([
                _db.spokenSentences,
                _db.wordEvents,
              ]),
            )
            .listen((_) => emit());
      },
      // Annulation sans attendre : celle de drift peut se faire attendre.
      onCancel: () {
        updates?.cancel();
      },
    );
    return controller.stream;
  }

  Future<UsageSummary> _load(int profileId, String lang, DateTime now) async {
    final since = now.subtract(_window);
    final sinceVar = Variable.withDateTime(since);

    final sentences = await _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM spoken_sentences '
          'WHERE profile_id = ?1 AND spoken_at >= ?2',
          variables: [Variable.withInt(profileId), sinceVar],
          readsFrom: {_db.spokenSentences},
        )
        .getSingle();

    final newWords = await _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM ('
          'SELECT pictogram_id FROM word_events WHERE profile_id = ?1 '
          'GROUP BY pictogram_id HAVING MIN(used_at) >= ?2)',
          variables: [Variable.withInt(profileId), sinceVar],
          readsFrom: {_db.wordEvents},
        )
        .getSingle();

    final top = await _db
        .customSelect(
          'SELECT t.label AS label, COUNT(*) AS n FROM word_events e '
          'JOIN pictogram_translations t '
          'ON t.pictogram_id = e.pictogram_id AND t.lang = ?1 '
          'WHERE e.profile_id = ?2 AND e.used_at >= ?3 '
          'GROUP BY e.pictogram_id ORDER BY n DESC, t.label LIMIT $_topLimit',
          variables: [
            Variable.withString(lang),
            Variable.withInt(profileId),
            sinceVar,
          ],
          readsFrom: {_db.wordEvents, _db.pictogramTranslations},
        )
        .get();

    return UsageSummary(
      sentences: sentences.read<int>('n'),
      newWords: newWords.read<int>('n'),
      topWords: [
        for (final r in top)
          WordCount(label: r.read<String>('label'), count: r.read<int>('n')),
      ],
    );
  }
}
