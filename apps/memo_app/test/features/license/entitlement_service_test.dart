import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/storage/secure_store.dart';
import 'package:memo/features/license/data/license_api.dart';
import 'package:memo/features/license/data/license_token_store.dart';
import 'package:memo/features/license/data/secure_clock_state_store.dart';
import 'package:memo/features/license/domain/device_identity.dart';
import 'package:memo/features/license/domain/entitlement_service.dart';
import 'package:memo/features/license/domain/license_verifier.dart';
import 'package:memo/features/license/domain/trusted_clock.dart';

import '../../support/license_fixtures.dart';

class FakeApi implements LicenseApi {
  FakeApi(this.respond);
  Future<IssuedLicense> Function(String fingerprint) respond;
  int calls = 0;

  @override
  Future<IssuedLicense> issue({
    required String accessToken,
    required String fingerprint,
    required String platform,
    String? label,
  }) {
    calls++;
    return respond(fingerprint);
  }
}

void main() {
  late SimpleKeyPair serverKey;
  late InMemorySecureStore store;
  late DeviceIdentity device;
  var wall = DateTime.utc(2026, 9, 21, 10);
  var elapsed = 0;

  Future<EntitlementService> service(FakeApi api) async => EntitlementService(
    verifier: LicenseVerifier(
      publicKeys: {'k1': await serverKey.extractPublicKey()},
    ),
    clock: TrustedClock(
      store: SecureClockStateStore(store),
      wallNow: () => wall,
      elapsedMs: () => elapsed,
      bootId: () => 'boot-1',
    ),
    tokens: LicenseTokenStore(store),
    device: device,
    api: api,
    platform: 'android',
  );

  Future<FakeApi> issuing({
    Duration validity = const Duration(days: 30),
  }) async {
    final fingerprint = await device.fingerprint();
    return FakeApi((_) async {
      return IssuedLicense(
        token: await signToken(
          serverKey,
          device: fingerprint,
          issuedAt: wall,
          validUntil: wall.add(validity),
        ),
        serverTime: wall,
        validUntil: wall.add(validity),
        plan: 'essentiel',
      );
    });
  }

  setUp(() async {
    serverKey = await Ed25519().newKeyPair();
    store = InMemorySecureStore();
    device = SecureStoreDeviceIdentity(store);
    wall = DateTime.utc(2026, 9, 21, 10);
    elapsed = 0;
  });

  test('sans jeton : contenu gratuit uniquement', () async {
    final s = await service(FakeApi((_) => throw StateError('pas d\'appel')));
    final e = await s.current();
    expect(e.status, LicenseStatus.none);
    expect(e.isPremium, isFalse);
  });

  test(
    'actualisation : jeton stocké, droits actifs, y compris hors ligne',
    () async {
      final api = await issuing();
      final s = await service(api);
      final e = await s.refresh('jwt');
      expect(e.status, LicenseStatus.active);
      expect(e.plan, 'essentiel');
      expect(e.isPremium, isTrue);

      // Nouvelle instance, plus de réseau : le jeton stocké suffit.
      final offline = await service(
        FakeApi(
          (_) => throw const LicenseApiException(LicenseApiError.offline),
        ),
      );
      wall = wall.add(const Duration(days: 10));
      expect((await offline.current()).isPremium, isTrue);
    },
  );

  test(
    "l'empreinte de l'appareil est stable et n'est pas l'identifiant brut",
    () async {
      final a = await device.fingerprint();
      final b = await SecureStoreDeviceIdentity(store).fingerprint();
      expect(a, b);
      expect(a.length, greaterThanOrEqualTo(16));
      expect(await store.read('device_secret'), isNot(a));
    },
  );

  test('un jeton signé pour un autre appareil est refusé', () async {
    final stolen = await signToken(
      serverKey,
      device: 'empreinte-d-un-autre-appareil',
      issuedAt: wall,
      validUntil: wall.add(const Duration(days: 30)),
    );
    await LicenseTokenStore(store).write(stolen);
    final s = await service(FakeApi((_) => throw StateError('non appelé')));
    expect((await s.current()).status, LicenseStatus.deviceMismatch);
  });

  test(
    'retour en arrière de l\'horloge : payant suspendu jusqu\'à la synchro',
    () async {
      final api = await issuing();
      final s = await service(api);
      await s.refresh('jwt');
      wall = wall.add(const Duration(days: 3));
      await s.current();

      // L'utilisateur recule l'horloge de 20 jours.
      wall = wall.subtract(const Duration(days: 20));
      final tampered = await s.current();
      expect(tampered.status, LicenseStatus.clockTampered);
      expect(tampered.isPremium, isFalse);

      // Une synchronisation rétablit la situation.
      wall = DateTime.utc(2026, 9, 24, 10);
      final api2 = await issuing();
      final s2 = await service(api2);
      expect((await s2.refresh('jwt')).status, LicenseStatus.active);
    },
  );

  test('abonnement expiré : jeton refusé après la tolérance', () async {
    final api = await issuing(validity: const Duration(days: 5));
    final s = await service(api);
    await s.refresh('jwt');
    wall = wall.add(const Duration(days: 7)); // 2 jours après : tolérance
    expect((await s.current()).status, LicenseStatus.grace);
    wall = wall.add(const Duration(days: 3)); // 5 jours après : plus rien
    expect((await s.current()).status, LicenseStatus.expired);
  });

  test(
    'échec d\'actualisation : erreur transmise, ancien jeton conservé',
    () async {
      final api = await issuing();
      final s = await service(api);
      await s.refresh('jwt');

      final failing = await service(
        FakeApi(
          (_) => throw const LicenseApiException(
            LicenseApiError.noActiveSubscription,
          ),
        ),
      );
      await expectLater(
        failing.refresh('jwt'),
        throwsA(isA<LicenseApiException>()),
      );
      expect((await failing.current()).isPremium, isTrue);
    },
  );

  test(
    'un jeton renvoyé pour un autre appareil est rejeté et non stocké',
    () async {
      final s = await service(
        FakeApi(
          (_) async => IssuedLicense(
            token: await signToken(
              serverKey,
              device: 'quelqu-un-d-autre',
              issuedAt: wall,
              validUntil: wall.add(const Duration(days: 30)),
            ),
            serverTime: wall,
            validUntil: wall.add(const Duration(days: 30)),
            plan: 'essentiel',
          ),
        ),
      );
      final e = await s.refresh('jwt');
      expect(e.isPremium, isFalse);
      expect(await LicenseTokenStore(store).read(), isNull);
    },
  );
}
