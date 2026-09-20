import 'package:drift/drift.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/board/domain/board_repository.dart';
import 'package:memo/features/catalog/domain/catalog.dart';

class DriftBoardRepository implements BoardRepository {
  DriftBoardRepository(this._db);
  final AppDatabase _db;

  static (int, int) _dimensions(Level level) => switch (level) {
    Level.beginner => (2, 3),
    Level.intermediate => (3, 4),
    Level.advanced => (4, 5),
  };

  Future<int> _boardId(int profileId, Level level) async {
    final (columns, rows) = _dimensions(level);
    final existing =
        await (_db.select(_db.boards)..where(
              (b) =>
                  b.profileId.equals(profileId) &
                  b.columns.equals(columns) &
                  b.rows.equals(rows),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    return _db
        .into(_db.boards)
        .insert(
          BoardsCompanion.insert(
            profileId: profileId,
            columns: columns,
            rows: rows,
          ),
        );
  }

  @override
  Stream<BoardLayout> watch(int profileId, Level level) async* {
    final boardId = await _boardId(profileId, level);
    final (columns, rows) = _dimensions(level);
    yield* (_db.select(
      _db.boardCells,
    )..where((c) => c.boardId.equals(boardId))).watch().map(
      (cells) => BoardLayout(
        columns: columns,
        rows: rows,
        cells: {for (final c in cells) c.position: c.pictogramId},
      ),
    );
  }

  @override
  Future<void> setCell(
    int profileId,
    Level level,
    int position,
    int? pictogramId,
  ) async {
    final boardId = await _boardId(profileId, level);
    if (pictogramId == null) {
      await (_db.delete(_db.boardCells)..where(
            (c) => c.boardId.equals(boardId) & c.position.equals(position),
          ))
          .go();
    } else {
      await _db
          .into(_db.boardCells)
          .insertOnConflictUpdate(
            BoardCellsCompanion.insert(
              boardId: boardId,
              position: position,
              pictogramId: pictogramId,
            ),
          );
    }
  }
}
