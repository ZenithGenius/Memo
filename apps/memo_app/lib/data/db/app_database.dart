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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.forTesting() : super(NativeDatabase.memory());

  AppDatabase.production() : super(driftDatabase(name: 'memo'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
