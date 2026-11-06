import 'package:drift/drift.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/board/domain/routine.dart';

class DriftRoutineRepository implements RoutineRepository {
  DriftRoutineRepository(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final AppDatabase _db;
  final DateTime Function() _now;

  @override
  Stream<List<Routine>> watch(int profileId) {
    final query =
        _db.select(_db.routines).join([
            leftOuterJoin(
              _db.routineSteps,
              _db.routineSteps.routineId.equalsExp(_db.routines.id),
            ),
          ])
          ..where(_db.routines.profileId.equals(profileId))
          ..orderBy([
            OrderingTerm.asc(_db.routines.id),
            OrderingTerm.asc(_db.routineSteps.position),
          ]);
    return query.watch().map((rows) {
      final byId = <int, (RoutineRow, List<RoutineStep>)>{};
      for (final row in rows) {
        final r = row.readTable(_db.routines);
        final entry = byId.putIfAbsent(r.id, () => (r, []));
        final s = row.readTableOrNull(_db.routineSteps);
        if (s != null) {
          entry.$2.add(
            RoutineStep(pictogramId: s.pictogramId, doneOn: s.doneOn),
          );
        }
      }
      return [
        for (final (r, steps) in byId.values)
          Routine(id: r.id, name: r.name, steps: steps),
      ];
    });
  }

  @override
  Future<int> create(int profileId, String name) => _db
      .into(_db.routines)
      .insert(RoutinesCompanion.insert(profileId: profileId, name: name));

  @override
  Future<void> rename(int routineId, String name) =>
      (_db.update(_db.routines)..where((r) => r.id.equals(routineId))).write(
        RoutinesCompanion(name: Value(name)),
      );

  @override
  Future<void> delete(int routineId) =>
      (_db.delete(_db.routines)..where((r) => r.id.equals(routineId))).go();

  SimpleSelectStatement<$RoutineStepsTable, RoutineStepRow> _steps(int id) =>
      _db.select(_db.routineSteps)..where((s) => s.routineId.equals(id));

  @override
  Future<void> setSteps(int routineId, List<int> pictogramIds) =>
      _db.transaction(() async {
        final today = dayKey(_now());
        final doneToday = {
          for (final s in await _steps(routineId).get())
            if (s.doneOn == today) s.pictogramId,
        };
        await (_db.delete(
          _db.routineSteps,
        )..where((s) => s.routineId.equals(routineId))).go();
        await _db.batch(
          (b) => b.insertAll(_db.routineSteps, [
            for (final (i, id) in pictogramIds.indexed)
              RoutineStepsCompanion.insert(
                routineId: routineId,
                position: i,
                pictogramId: id,
                doneOn: Value(doneToday.contains(id) ? today : null),
              ),
          ]),
        );
      });

  @override
  Future<void> toggleStep(int routineId, int position) async {
    final today = dayKey(_now());
    await _db.customUpdate(
      'UPDATE routine_steps SET done_on = '
      'CASE WHEN done_on = ?1 THEN NULL ELSE ?1 END '
      'WHERE routine_id = ?2 AND position = ?3',
      variables: [
        Variable.withString(today),
        Variable.withInt(routineId),
        Variable.withInt(position),
      ],
      updates: {_db.routineSteps},
    );
  }

  @override
  Future<void> reset(int routineId) =>
      (_db.update(_db.routineSteps)
            ..where((s) => s.routineId.equals(routineId)))
          .write(const RoutineStepsCompanion(doneOn: Value(null)));
}
