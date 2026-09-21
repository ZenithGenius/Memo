import 'package:drift/drift.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  IntColumn get sortOrder => integer()();
  TextColumn get iconName => text().nullable()();
  TextColumn get colorHex => text().nullable()();
}

class CategoryTranslations extends Table {
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  TextColumn get lang => text()();
  TextColumn get label => text()();

  @override
  Set<Column<Object>> get primaryKey => {categoryId, lang};
}

@DataClassName('PictogramRow')
class Pictograms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  TextColumn get imageAsset => text().nullable()();
  IntColumn get imageVersion => integer().withDefault(const Constant(1))();
  IntColumn get minLevel => integer()();
  TextColumn get audience => text()();
  IntColumn get sortOrder => integer()();
  TextColumn get tier => text().withDefault(const Constant('free'))();
  BoolColumn get labelInImage => boolean().withDefault(const Constant(false))();
}

class PictogramTranslations extends Table {
  IntColumn get pictogramId =>
      integer().references(Pictograms, #id, onDelete: KeyAction.cascade)();
  TextColumn get lang => text()();
  TextColumn get label => text()();
  TextColumn get spokenText => text()();

  @override
  Set<Column<Object>> get primaryKey => {pictogramId, lang};
}

@DataClassName('ProfileRow')
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  IntColumn get level => integer()();
  TextColumn get language => text().withDefault(const Constant('fr'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Favorites extends Table {
  IntColumn get profileId =>
      integer().references(Profiles, #id, onDelete: KeyAction.cascade)();
  IntColumn get pictogramId =>
      integer().references(Pictograms, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {profileId, pictogramId};
}

class Boards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId =>
      integer().references(Profiles, #id, onDelete: KeyAction.cascade)();
  IntColumn get columns => integer()();
  IntColumn get rows => integer()();
}

class BoardCells extends Table {
  IntColumn get boardId =>
      integer().references(Boards, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  IntColumn get pictogramId =>
      integer().references(Pictograms, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {boardId, position};
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class ContentMeta extends Table {
  IntColumn get id => integer()();
  IntColumn get version => integer()();
  DateTimeColumn get installedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Phrases toutes faites : livrées avec le contenu (`profileId` nul) ou
/// créées par un profil.
@DataClassName('QuickPhraseRow')
class QuickPhrases extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().nullable().references(
    Profiles,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Code stable des phrases livrées, nul pour les phrases de l'utilisateur.
  TextColumn get code => text().nullable()();
  TextColumn get lang => text()();
  TextColumn get body => text()();

  /// Thèmes séparés par des virgules (maison, école...).
  TextColumn get tags => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {code, lang},
  ];
}

/// Une phrase prononcée par un profil : sert aux statistiques d'usage.
class SpokenSentences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId =>
      integer().references(Profiles, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get spokenAt => dateTime()();
}

/// Un mot utilisé dans une phrase prononcée (une ligne par mot et par phrase).
class WordEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId =>
      integer().references(Profiles, #id, onDelete: KeyAction.cascade)();
  IntColumn get pictogramId =>
      integer().references(Pictograms, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get usedAt => dateTime()();
}
