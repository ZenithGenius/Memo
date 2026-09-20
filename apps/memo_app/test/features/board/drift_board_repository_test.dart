import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/board/data/drift_board_repository.dart';
import 'package:memo/features/catalog/domain/catalog.dart';

import '../../support/seed.dart';

void main() {
  late AppDatabase db;
  late DriftBoardRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = DriftBoardRepository(db);
  });
  tearDown(() => db.close());

  test('la taille du tableau dépend du niveau', () async {
    final profile = await seedProfile(db);
    final b = await repo.watch(profile.id, Level.beginner).first;
    expect((b.columns, b.rows), (2, 3));
    final a = await repo.watch(profile.id, Level.advanced).first;
    expect((a.columns, a.rows), (4, 5));
  });

  test('place puis vide une case', () async {
    final profile = await seedProfile(db);
    final pid = await seedPictogram(db, 'P1');
    await repo.setCell(profile.id, Level.beginner, 0, pid);
    var layout = await repo.watch(profile.id, Level.beginner).first;
    expect(layout.cells, {0: pid});
    await repo.setCell(profile.id, Level.beginner, 0, null);
    layout = await repo.watch(profile.id, Level.beginner).first;
    expect(layout.cells, isEmpty);
  });
}
