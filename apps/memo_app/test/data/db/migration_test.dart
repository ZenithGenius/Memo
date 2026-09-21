import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/db/app_database.dart';

void main() {
  test(
    'migration v1 vers v2 : les données restent, les colonnes arrivent',
    () async {
      // Base telle qu'elle existait en version 1 (sans palier ni couleur).
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute('''
            CREATE TABLE categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              code TEXT NOT NULL UNIQUE,
              sort_order INTEGER NOT NULL,
              icon_name TEXT NULL
            )''');
            raw.execute('''
            CREATE TABLE pictograms (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              code TEXT NOT NULL UNIQUE,
              category_id INTEGER NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
              image_asset TEXT NULL,
              image_version INTEGER NOT NULL DEFAULT 1,
              min_level INTEGER NOT NULL,
              audience TEXT NOT NULL,
              sort_order INTEGER NOT NULL
            )''');
            raw.execute(
              "INSERT INTO categories (code, sort_order) VALUES ('CBE', 1)",
            );
            raw.execute(
              "INSERT INTO pictograms (code, category_id, min_level, audience, sort_order) "
              "VALUES ('CAA-CR-CBE-001', 1, 0, 'all', 1)",
            );
            raw.execute('PRAGMA user_version = 1');
          },
        ),
      );
      addTearDown(db.close);

      final p = await db.select(db.pictograms).getSingle();
      expect(p.code, 'CAA-CR-CBE-001');
      expect(
        p.tier,
        'free',
        reason: 'valeur par défaut pour les lignes existantes',
      );
      expect(p.labelInImage, isFalse);

      final c = await db.select(db.categories).getSingle();
      expect(c.colorHex, isNull);

      await (db.update(db.categories)..where((t) => t.id.equals(c.id))).write(
        const CategoriesCompanion(colorHex: Value('#C1502E')),
      );
      expect((await db.select(db.categories).getSingle()).colorHex, '#C1502E');
    },
  );

  test(
    'migration v2 vers v3 : ajoute « mot dans l\'image » sans perdre le reste',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute('''
            CREATE TABLE categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              code TEXT NOT NULL UNIQUE,
              sort_order INTEGER NOT NULL,
              icon_name TEXT NULL,
              color_hex TEXT NULL
            )''');
            raw.execute('''
            CREATE TABLE pictograms (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              code TEXT NOT NULL UNIQUE,
              category_id INTEGER NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
              image_asset TEXT NULL,
              image_version INTEGER NOT NULL DEFAULT 1,
              min_level INTEGER NOT NULL,
              audience TEXT NOT NULL,
              sort_order INTEGER NOT NULL,
              tier TEXT NOT NULL DEFAULT 'free'
            )''');
            raw.execute(
              "INSERT INTO categories (code, sort_order, color_hex) VALUES ('ACT', 1, '#2F7D4F')",
            );
            raw.execute(
              "INSERT INTO pictograms (code, category_id, min_level, audience, sort_order, tier) "
              "VALUES ('CAA-CR-ACT-001', 1, 0, 'all', 1, 'premium')",
            );
            raw.execute('PRAGMA user_version = 2');
          },
        ),
      );
      addTearDown(db.close);

      final p = await db.select(db.pictograms).getSingle();
      expect(p.tier, 'premium', reason: 'les données de la v2 sont conservées');
      expect(p.labelInImage, isFalse);
      expect((await db.select(db.categories).getSingle()).colorHex, '#2F7D4F');
    },
  );

  test('migration v3 vers v4 : la table des phrases est créée', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE profiles (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL, type TEXT NOT NULL, level INTEGER NOT NULL,
              language TEXT NOT NULL DEFAULT 'fr',
              created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
            )''');
          raw.execute(
            "INSERT INTO profiles (name, type, level) VALUES ('T','child',0)",
          );
          raw.execute('PRAGMA user_version = 3');
        },
      ),
    );
    addTearDown(db.close);

    await db
        .into(db.quickPhrases)
        .insert(
          QuickPhrasesCompanion.insert(
            lang: 'fr',
            body: 'Bonjour',
            sortOrder: 1,
            code: const Value('PH-001'),
          ),
        );
    expect((await db.select(db.quickPhrases).getSingle()).body, 'Bonjour');
    expect((await db.select(db.profiles).getSingle()).name, 'T');
  });

  test('migration v4 vers v5 : les tables d\'usage sont créées', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE profiles (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL, type TEXT NOT NULL, level INTEGER NOT NULL,
              language TEXT NOT NULL DEFAULT 'fr',
              created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
            )''');
          raw.execute(
            "INSERT INTO profiles (name, type, level) VALUES ('T','child',0)",
          );
          raw.execute('PRAGMA user_version = 4');
        },
      ),
    );
    addTearDown(db.close);

    await db
        .into(db.spokenSentences)
        .insert(
          SpokenSentencesCompanion.insert(
            profileId: 1,
            spokenAt: DateTime.utc(2026, 9, 21),
          ),
        );
    expect(await db.select(db.spokenSentences).get(), hasLength(1));
  });
}
