import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/caregiver/presentation/caregiver_providers.dart';

void main() {
  test('verrouillée au départ', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(caregiverSessionProvider), isFalse);
  });

  test('se déverrouille puis se verrouille à la demande', () {
    fakeAsync((async) {
      final c = ProviderContainer();
      c.read(caregiverSessionProvider.notifier).unlock();
      expect(c.read(caregiverSessionProvider), isTrue);
      c.read(caregiverSessionProvider.notifier).lock();
      expect(c.read(caregiverSessionProvider), isFalse);
      c.dispose();
    });
  });

  test('se verrouille seule après cinq minutes sans action', () {
    fakeAsync((async) {
      final c = ProviderContainer();
      c.read(caregiverSessionProvider.notifier).unlock();
      async.elapse(CaregiverSession.idleTimeout - const Duration(seconds: 1));
      expect(c.read(caregiverSessionProvider), isTrue);
      async.elapse(const Duration(seconds: 2));
      expect(c.read(caregiverSessionProvider), isFalse);
      c.dispose();
    });
  });

  test('chaque action protégée repousse le verrouillage', () {
    fakeAsync((async) {
      final c = ProviderContainer();
      final session = c.read(caregiverSessionProvider.notifier)..unlock();
      async.elapse(const Duration(minutes: 4));
      session.touch();
      async.elapse(const Duration(minutes: 4));
      expect(c.read(caregiverSessionProvider), isTrue);
      async.elapse(const Duration(minutes: 2));
      expect(c.read(caregiverSessionProvider), isFalse);
      c.dispose();
    });
  });

  test("toucher une session verrouillée ne la déverrouille pas", () {
    fakeAsync((async) {
      final c = ProviderContainer();
      c.read(caregiverSessionProvider.notifier).touch();
      async.elapse(const Duration(minutes: 10));
      expect(c.read(caregiverSessionProvider), isFalse);
      c.dispose();
    });
  });
}
