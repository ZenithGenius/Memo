import 'package:equatable/equatable.dart';
import 'package:memo/features/catalog/domain/catalog.dart';

class BoardLayout extends Equatable {
  const BoardLayout({
    required this.columns,
    required this.rows,
    required this.cells,
  });

  final int columns;
  final int rows;

  /// position -> identifiant du pictogramme
  final Map<int, int> cells;

  int get size => columns * rows;

  @override
  List<Object?> get props => [columns, rows, cells];
}

abstract interface class BoardRepository {
  Stream<BoardLayout> watch(int profileId, Level level);

  /// Place un pictogramme dans une case, ou vide la case si [pictogramId] est nul.
  Future<void> setCell(
    int profileId,
    Level level,
    int position,
    int? pictogramId,
  );
}
