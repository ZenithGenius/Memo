import 'package:drift/drift.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/phrases/domain/phrase_repository.dart';
import 'package:memo/features/phrases/domain/quick_phrase.dart';

class DriftPhraseRepository implements PhraseRepository {
  DriftPhraseRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<QuickPhrase>> watch({
    required int? profileId,
    required String lang,
  }) {
    final query = _db.select(_db.quickPhrases)
      ..where(
        (p) =>
            p.lang.equals(lang) &
            (profileId == null
                ? p.profileId.isNull()
                : p.profileId.isNull() | p.profileId.equals(profileId)),
      )
      // Livrées d'abord (profileId nul), puis celles de l'utilisateur.
      ..orderBy([
        (p) => OrderingTerm.asc(p.profileId.isNull().not()),
        (p) => OrderingTerm.asc(p.sortOrder),
        (p) => OrderingTerm.asc(p.id),
      ]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<QuickPhrase> add({
    required int profileId,
    required String lang,
    required String text,
    List<String> tags = const [],
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'La phrase est vide');
    }
    final last =
        await (_db.selectOnly(_db.quickPhrases)
              ..addColumns([_db.quickPhrases.sortOrder.max()])
              ..where(_db.quickPhrases.profileId.equals(profileId)))
            .map((r) => r.read(_db.quickPhrases.sortOrder.max()))
            .getSingle();
    final id = await _db
        .into(_db.quickPhrases)
        .insert(
          QuickPhrasesCompanion.insert(
            profileId: Value(profileId),
            lang: lang,
            body: trimmed,
            tags: Value(tags.join(',')),
            sortOrder: (last ?? 0) + 1,
          ),
        );
    return _toDomain(
      await (_db.select(
        _db.quickPhrases,
      )..where((p) => p.id.equals(id))).getSingle(),
    );
  }

  @override
  Future<void> remove(int id) async {
    await (_db.delete(
      _db.quickPhrases,
    )..where((p) => p.id.equals(id) & p.profileId.isNotNull())).go();
  }

  QuickPhrase _toDomain(QuickPhraseRow row) => QuickPhrase(
    id: row.id,
    text: row.body,
    tags: row.tags.isEmpty ? const [] : row.tags.split(','),
    isCustom: row.profileId != null,
  );
}
