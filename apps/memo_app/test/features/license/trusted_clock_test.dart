import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/license/domain/trusted_clock.dart';

void main() {
  late InMemoryClockStateStore store;
  var wall = DateTime.utc(2026, 9, 10, 12);
  var elapsed = 0; // ms depuis le démarrage
  var boot = 'boot-1';

  TrustedClock clock() => TrustedClock(
    store: store,
    wallNow: () => wall,
    elapsedMs: () => elapsed,
    bootId: () => boot,
  );

  setUp(() {
    store = InMemoryClockStateStore();
    wall = DateTime.utc(2026, 9, 10, 12);
    elapsed = 0;
    boot = 'boot-1';
  });

  test("l'horloge qui avance normalement n'est pas suspecte", () async {
    final c = clock();
    await c.now();
    wall = wall.add(const Duration(days: 3));
    final t = await c.now();
    expect(t.time, wall);
    expect(t.tampered, isFalse);
  });

  test(
    'un recul de moins de 24 h est toléré (changement de fuseau, dérive)',
    () async {
      final c = clock();
      await c.now();
      wall = wall.subtract(const Duration(hours: 5));
      expect((await c.now()).tampered, isFalse);
    },
  );

  test(
    'un recul de plus de 24 h est détecté et le temps ne recule pas',
    () async {
      final c = clock();
      final before = (await c.now()).time;
      wall = wall.subtract(const Duration(days: 20));
      final t = await c.now();
      expect(t.tampered, isTrue);
      expect(t.time, before);
    },
  );

  test("le drapeau persiste jusqu'à une synchronisation", () async {
    final c = clock();
    await c.now();
    wall = wall.subtract(const Duration(days: 5));
    await c.now();
    wall = DateTime.utc(2026, 9, 12); // revient à une valeur plausible
    expect((await c.now()).tampered, isTrue);
    await c.anchor(DateTime.utc(2026, 9, 12));
    expect((await c.now()).tampered, isFalse);
  });

  test("l'ancre de confiance avance avec l'horloge monotone", () async {
    final c = clock();
    final anchor = DateTime.utc(2026, 9, 10, 12);
    await c.anchor(anchor);
    // L'utilisateur recule l'horloge de 5 jours, une heure s'écoule réellement.
    wall = anchor.subtract(const Duration(days: 5));
    elapsed = const Duration(hours: 1).inMilliseconds;
    final t = await c.now();
    expect(t.time, anchor.add(const Duration(hours: 1)));
    expect(t.tampered, isTrue);
  });

  test("après un redémarrage l'ancre reste un plancher", () async {
    final c = clock();
    final anchor = DateTime.utc(2026, 9, 10, 12);
    await c.anchor(anchor);
    boot = 'boot-2';
    elapsed = 5000;
    wall = anchor.subtract(const Duration(days: 30));
    final t = await c.now();
    expect(t.time.isBefore(anchor), isFalse);
    expect(t.tampered, isTrue);
  });

  test(
    "la date serveur fait foi : une horloge trop avancée est corrigée",
    () async {
      final c = clock();
      wall = DateTime.utc(2026, 12, 1); // téléphone en avance par erreur
      await c.now();
      await c.anchor(DateTime.utc(2026, 9, 10, 12));
      wall = DateTime.utc(2026, 9, 10, 13); // remis à l'heure
      final t = await c.now();
      expect(t.tampered, isFalse);
      expect(t.time, DateTime.utc(2026, 9, 10, 13));
    },
  );
}
