import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/storage/secure_store.dart';
import 'package:memo/features/caregiver/domain/caregiver_pin_service.dart';

void main() {
  late InMemorySecureStore store;
  var now = DateTime.utc(2026, 9, 22, 10);

  CaregiverPinService service() =>
      CaregiverPinService(store: store, now: () => now);

  setUp(() {
    store = InMemorySecureStore();
    now = DateTime.utc(2026, 9, 22, 10);
  });

  test("aucun code au départ", () async {
    expect(await service().isSet, isFalse);
  });

  test('un code valide est enregistré puis vérifié', () async {
    final s = service();
    await s.setPin('4827');
    expect(await s.isSet, isTrue);
    expect(await s.verify('4827'), isA<PinAccepted>());
  });

  test('le code n\'est jamais stocké en clair', () async {
    await service().setPin('4827');
    for (final key in ['caregiver_pin_hash', 'caregiver_pin_salt']) {
      final value = await store.read(key);
      expect(value, isNotNull, reason: key);
      expect(value, isNot(contains('4827')), reason: key);
    }
  });

  test(
    'deux enregistrements du même code donnent des empreintes différentes',
    () async {
      await service().setPin('4827');
      final first = await store.read('caregiver_pin_hash');
      await service().setPin('4827');
      expect(await store.read('caregiver_pin_hash'), isNot(first));
    },
  );

  test(
    'un mauvais code est refusé, avec le nombre d\'essais restants',
    () async {
      final s = service();
      await s.setPin('4827');
      final r = await s.verify('1111');
      expect(r, isA<PinRejected>());
      expect(
        (r as PinRejected).attemptsLeft,
        CaregiverPinService.maxAttempts - 1,
      );
    },
  );

  test(
    'un code de forme invalide est refusé sans compter comme essai',
    () async {
      final s = service();
      await s.setPin('4827');
      for (final bad in ['', '12', '12345', 'abcd', '48 7']) {
        expect(await s.verify(bad), isA<PinRejected>(), reason: bad);
      }
      // Aucun blocage : toujours tous les essais disponibles.
      final r = await s.verify('0000') as PinRejected;
      expect(r.attemptsLeft, CaregiverPinService.maxAttempts - 1);
    },
  );

  test('cinq échecs bloquent, même avec le bon code', () async {
    final s = service();
    await s.setPin('4827');
    for (var i = 0; i < CaregiverPinService.maxAttempts; i++) {
      await s.verify('0001');
    }
    final r = await s.verify('4827');
    expect(r, isA<PinLocked>());
    expect((r as PinLocked).remaining, const Duration(seconds: 30));
  });

  test('le blocage se lève avec le temps', () async {
    final s = service();
    await s.setPin('4827');
    for (var i = 0; i < CaregiverPinService.maxAttempts; i++) {
      await s.verify('0001');
    }
    now = now.add(const Duration(seconds: 31));
    expect(await s.verify('4827'), isA<PinAccepted>());
  });

  test('un blocage répété dure plus longtemps, plafonné', () async {
    final s = service();
    await s.setPin('4827');
    Duration? last;
    for (var round = 0; round < 12; round++) {
      for (var i = 0; i < CaregiverPinService.maxAttempts; i++) {
        final r = await s.verify('0001');
        if (r is PinLocked) last = r.remaining;
      }
      final r = await s.verify('0001');
      if (r is PinLocked) last = r.remaining;
      now = now.add(const Duration(hours: 1));
    }
    expect(last, CaregiverPinService.maxLock);
  });

  test('le blocage survit à un redémarrage (état persistant)', () async {
    final s1 = service();
    await s1.setPin('4827');
    for (var i = 0; i < CaregiverPinService.maxAttempts; i++) {
      await s1.verify('0001');
    }
    final r = await service().verify('4827'); // nouvelle instance
    expect(r, isA<PinLocked>());
  });

  test('un succès remet le compteur à zéro', () async {
    final s = service();
    await s.setPin('4827');
    await s.verify('1111');
    await s.verify('1111');
    expect(await s.verify('4827'), isA<PinAccepted>());
    final r = await s.verify('1111') as PinRejected;
    expect(r.attemptsLeft, CaregiverPinService.maxAttempts - 1);
  });

  test('les codes trop simples sont refusés à la création', () async {
    final s = service();
    for (final weak in ['0000', '1111', '1234']) {
      await expectLater(s.setPin(weak), throwsA(isA<WeakPinException>()));
    }
    for (final bad in ['12', 'abcd', '12345']) {
      await expectLater(s.setPin(bad), throwsA(isA<InvalidPinException>()));
    }
    expect(await s.isSet, isFalse);
  });

  test("sans code défini, la vérification échoue proprement", () async {
    expect(await service().verify('4827'), isA<PinRejected>());
  });

  test(
    "changer de code invalide l'ancien et remet le compteur à zéro",
    () async {
      final s = service();
      await s.setPin('4827');
      await s.verify('0001');
      await s.setPin('9153');
      expect(await s.verify('4827'), isA<PinRejected>());
      expect(await s.verify('9153'), isA<PinAccepted>());
    },
  );
}
