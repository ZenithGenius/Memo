import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/license/domain/license_verifier.dart';

import '../../support/license_fixtures.dart';

void main() {
  final issued = DateTime.utc(2026, 9, 1);
  final validUntil = DateTime.utc(2026, 10, 1);
  late SimpleKeyPair serverKey;
  late LicenseVerifier verifier;

  setUp(() async {
    serverKey = await Ed25519().newKeyPair();
    verifier = LicenseVerifier(
      publicKeys: {'k1': await serverKey.extractPublicKey()},
    );
  });

  Future<String> token({String device = 'dev-A', String kid = 'k1'}) =>
      signToken(
        serverKey,
        device: device,
        kid: kid,
        issuedAt: issued,
        validUntil: validUntil,
      );

  Future<LicenseStatus> check(
    String? t, {
    DateTime? now,
    bool tampered = false,
  }) async => (await verifier.check(
    t,
    deviceId: 'dev-A',
    now: now ?? DateTime.utc(2026, 9, 15),
    clockTampered: tampered,
  )).status;

  test('sans jeton : aucune licence', () async {
    expect(await check(null), LicenseStatus.none);
  });

  test('jeton valide pendant la période payée', () async {
    final status = await check(await token());
    expect(status, LicenseStatus.active);
    expect(status.grantsPremium, isTrue);
  });

  test('tolérance de 3 jours après la fin de période', () async {
    expect(
      await check(await token(), now: DateTime.utc(2026, 10, 3)),
      LicenseStatus.grace,
    );
    expect(
      await check(await token(), now: DateTime.utc(2026, 10, 5)),
      LicenseStatus.expired,
    );
  });

  test(
    'un jeton de plus de 45 jours est périmé même si la période court',
    () async {
      final long = await signToken(
        serverKey,
        issuedAt: issued,
        validUntil: DateTime.utc(2027, 9, 1),
      );
      expect(
        await check(long, now: DateTime.utc(2026, 10, 20)),
        LicenseStatus.stale,
      );
      expect(
        await check(long, now: DateTime.utc(2026, 10, 10)),
        LicenseStatus.active,
      );
    },
  );

  test('charge modifiée : signature invalide', () async {
    final t = await token();
    final parts = t.split('.');
    final forged =
        jsonDecode(utf8.decode(base64Url.decode(parts[0])))
            as Map<String, Object?>;
    forged['exp'] = DateTime.utc(2030).millisecondsSinceEpoch ~/ 1000;
    final payload = base64Url.encode(utf8.encode(jsonEncode(forged)));
    expect(await check('$payload.${parts[1]}'), LicenseStatus.invalidSignature);
  });

  test("signé par une autre clé : signature invalide", () async {
    final other = await Ed25519().newKeyPair();
    final t = await signToken(other, issuedAt: issued, validUntil: validUntil);
    expect(await check(t), LicenseStatus.invalidSignature);
  });

  test('identifiant de clé inconnu', () async {
    expect(await check(await token(kid: 'k9')), LicenseStatus.unknownKey);
  });

  test("jeton copié d'un autre appareil", () async {
    expect(
      await check(await token(device: 'dev-B')),
      LicenseStatus.deviceMismatch,
    );
  });

  test('horloge manipulée : contenu payant suspendu', () async {
    final status = await check(await token(), tampered: true);
    expect(status, LicenseStatus.clockTampered);
    expect(status.grantsPremium, isFalse);
  });

  test('jeton illisible', () async {
    expect(await check('nimportequoi'), LicenseStatus.malformed);
    expect(await check('a.b'), LicenseStatus.malformed);
  });

  test('rotation : la seconde clé embarquée est acceptée', () async {
    final k2 = await Ed25519().newKeyPair();
    final rotating = LicenseVerifier(
      publicKeys: {
        'k1': await serverKey.extractPublicKey(),
        'k2': await k2.extractPublicKey(),
      },
    );
    final t = await signToken(
      k2,
      kid: 'k2',
      issuedAt: issued,
      validUntil: validUntil,
    );
    final r = await rotating.check(
      t,
      deviceId: 'dev-A',
      now: DateTime.utc(2026, 9, 15),
    );
    expect(r.status, LicenseStatus.active);
  });
}
