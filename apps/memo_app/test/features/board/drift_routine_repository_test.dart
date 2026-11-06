import 'package:flutter_test/flutter_test.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/board/data/drift_routine_repository.dart';
import 'package:memo/features/board/domain/routine.dart';

import '../../support/seed.dart';

void main() {
  late AppDatabase db;
  late DriftRoutineRepository repo;
  var now = DateTime(2026, 11, 6, 7, 30);

  setUp(() {
    db = AppDatabase.forTesting();
    now = DateTime(2026, 11, 6, 7, 30);
    repo = DriftRoutineRepository(db, now: () => now);
  });
  tearDown(() => db.close());

  test('crée une routine, ses étapes dans l\'ordre, puis la renomme', () async {
    final profile = await seedProfile(db);
    final a = await seedPictogram(db, 'P1');
    final b = await seedPictogram(db, 'P2');
    final id = await repo.create(profile.id, 'Le matin');
    await repo.setSteps(id, [b, a, b]);
    await repo.rename(id, 'Matin');

    final routines = await repo.watch(profile.id).first;
    expect(routines.single.name, 'Matin');
    expect(routines.single.steps.map((s) => s.pictogramId), [b, a, b]);
  });

  test('une étape cochée ne l\'est plus le lendemain', () async {
    final profile = await seedProfile(db);
    final a = await seedPictogram(db, 'P1');
    final id = await repo.create(profile.id, 'Le matin');
    await repo.setSteps(id, [a]);
    await repo.toggleStep(id, 0);

    final step = (await repo.watch(profile.id).first).single.steps.single;
    expect(step.doneOnDay(now), isTrue);
    expect(step.doneOnDay(now.add(const Duration(days: 1))), isFalse);

    // Le lendemain, la cocher la marque faite pour ce jour-là.
    now = now.add(const Duration(days: 1));
    await repo.toggleStep(id, 0);
    final again = (await repo.watch(profile.id).first).single.steps.single;
    expect(again.doneOnDay(now), isTrue);
  });

  test('décocher, recommencer, et garder les coches en modifiant', () async {
    final profile = await seedProfile(db);
    final a = await seedPictogram(db, 'P1');
    final b = await seedPictogram(db, 'P2');
    final id = await repo.create(profile.id, 'Le soir');
    await repo.setSteps(id, [a, b]);
    await repo.toggleStep(id, 0);
    await repo.toggleStep(id, 1);
    await repo.toggleStep(id, 1);

    Future<List<bool>> state() async => [
      for (final s in (await repo.watch(profile.id).first).single.steps)
        s.doneOnDay(now),
    ];
    expect(await state(), [true, false]);

    // Réordonner garde l'étape faite.
    await repo.setSteps(id, [b, a]);
    expect(await state(), [false, true]);

    await repo.reset(id);
    expect(await state(), [false, false]);
  });

  test('supprimer une routine ou son profil supprime ses étapes', () async {
    final profile = await seedProfile(db);
    final a = await seedPictogram(db, 'P1');
    final first = await repo.create(profile.id, 'A');
    final second = await repo.create(profile.id, 'B');
    await repo.setSteps(first, [a]);
    await repo.setSteps(second, [a]);

    await repo.delete(first);
    expect((await repo.watch(profile.id).first).map((r) => r.name), ['B']);

    await (db.delete(db.profiles)..where((p) => p.id.equals(profile.id))).go();
    expect(await db.select(db.routines).get(), isEmpty);
    expect(await db.select(db.routineSteps).get(), isEmpty);
  });

  test('dayKey compte les jours en heure locale', () {
    expect(dayKey(DateTime(2026, 1, 2, 23, 59)), '2026-01-02');
  });
}
