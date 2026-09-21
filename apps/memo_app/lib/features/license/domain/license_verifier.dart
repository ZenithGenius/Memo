import 'dart:convert';

import 'package:cryptography/cryptography.dart';

enum LicenseStatus {
  none,
  active,
  grace,
  expired,
  stale,
  deviceMismatch,
  invalidSignature,
  unknownKey,
  malformed,
  clockTampered;

  /// Seuls ces états donnent accès au contenu payant.
  bool get grantsPremium => this == active || this == grace;
}

class LicenseClaims {
  const LicenseClaims({
    required this.subject,
    required this.plan,
    required this.issuedAt,
    required this.validUntil,
    required this.device,
    required this.keyId,
  });

  final String subject;
  final String plan;
  final DateTime issuedAt;
  final DateTime validUntil;
  final String device;
  final String keyId;
}

class LicenseCheck {
  const LicenseCheck(this.status, [this.claims]);
  final LicenseStatus status;
  final LicenseClaims? claims;
}

/// Vérifie un jeton `base64url(charge).base64url(signature)` signé en Ed25519
/// (ADR-004 et ADR-008). Ne contient que des clés publiques.
class LicenseVerifier {
  LicenseVerifier({required this.publicKeys});

  /// Clés publiques embarquées par identifiant (deux au plus, pour la rotation).
  final Map<String, SimplePublicKey> publicKeys;

  /// Durée de vie maximale d'un jeton, quelle que soit la période payée.
  static const maxTokenAge = Duration(days: 45);

  /// Tolérance après la fin de la période payée.
  static const grace = Duration(days: 3);

  Future<LicenseCheck> check(
    String? token, {
    required String deviceId,
    required DateTime now,
    bool clockTampered = false,
  }) async {
    if (token == null) return const LicenseCheck(LicenseStatus.none);

    final parts = token.split('.');
    if (parts.length != 2) return const LicenseCheck(LicenseStatus.malformed);

    final LicenseClaims claims;
    final List<int> signature;
    try {
      final json =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
              )
              as Map<String, Object?>;
      claims = LicenseClaims(
        subject: json['sub']! as String,
        plan: json['plan']! as String,
        issuedAt: _fromSeconds(json['iat']! as int),
        validUntil: _fromSeconds(json['exp']! as int),
        device: json['dev']! as String,
        keyId: json['kid']! as String,
      );
      signature = base64Url.decode(base64Url.normalize(parts[1]));
    } on Object {
      return const LicenseCheck(LicenseStatus.malformed);
    }

    final key = publicKeys[claims.keyId];
    if (key == null) return const LicenseCheck(LicenseStatus.unknownKey);

    final valid = await Ed25519().verify(
      utf8.encode(parts[0]),
      signature: Signature(signature, publicKey: key),
    );
    if (!valid) return const LicenseCheck(LicenseStatus.invalidSignature);

    if (claims.device != deviceId) {
      return LicenseCheck(LicenseStatus.deviceMismatch, claims);
    }
    if (clockTampered) return LicenseCheck(LicenseStatus.clockTampered, claims);
    if (now.isAfter(claims.issuedAt.add(maxTokenAge))) {
      return LicenseCheck(LicenseStatus.stale, claims);
    }
    if (!now.isAfter(claims.validUntil)) {
      return LicenseCheck(LicenseStatus.active, claims);
    }
    if (!now.isAfter(claims.validUntil.add(grace))) {
      return LicenseCheck(LicenseStatus.grace, claims);
    }
    return LicenseCheck(LicenseStatus.expired, claims);
  }

  static DateTime _fromSeconds(int s) =>
      DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: true);
}
