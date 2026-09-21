import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:memo/data/db/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Categories,
    CategoryTranslations,
    Pictograms,
    PictogramTranslations,
    Profiles,
    Favorites,
    Boards,
    BoardCells,
    Settings,
    ContentMeta,
    QuickPhrases,
    SpokenSentences,
    WordEvents,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.forTesting() : super(NativeDatabase.memory());

  AppDatabase.production() : super(driftDatabase(name: 'memo'));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(categories, categories.colorHex);
        await m.addColumn(pictograms, pictograms.tier);
      }
      if (from < 3) {
        await m.addColumn(pictograms, pictograms.labelInImage);
      }
      if (from < 4) {
        await m.createTable(quickPhrases);
      }
      if (from < 5) {
        await m.createTable(spokenSentences);
        await m.createTable(wordEvents);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
