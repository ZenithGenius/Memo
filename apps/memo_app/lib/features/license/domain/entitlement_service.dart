import 'package:memo/features/license/data/license_api.dart';
import 'package:memo/features/license/data/license_token_store.dart';
import 'package:memo/features/license/domain/device_identity.dart';
import 'package:memo/features/license/domain/license_verifier.dart';
import 'package:memo/features/license/domain/trusted_clock.dart';

/// Droits de l'utilisateur. Point d'entrée unique : l'état premium se déduit
/// à chaque appel du jeton vérifié et du temps de confiance, jamais d'un
/// drapeau stocké (ADR-008).
class Entitlement {
  const Entitlement(this.status, {this.plan, this.validUntil});

  final LicenseStatus status;
  final String? plan;
  final DateTime? validUntil;

  bool get isPremium => status.grantsPremium;
}

class EntitlementService {
  EntitlementService({
    required this.verifier,
    required this.clock,
    required this.tokens,
    required this.device,
    required this.api,
    required this.platform,
  });

  final LicenseVerifier verifier;
  final TrustedClock clock;
  final LicenseTokenStore tokens;
  final DeviceIdentity device;
  final LicenseApi api;

  /// `android` ou `ios`.
  final String platform;

  /// Droits actuels, calculés hors ligne à partir du jeton stocké.
  Future<Entitlement> current() async {
    final time = await clock.now();
    final check = await verifier.check(
      await tokens.read(),
      deviceId: await device.fingerprint(),
      now: time.time,
      clockTampered: time.tampered,
    );
    return _toEntitlement(check);
  }

  /// Demande un nouveau jeton au serveur (réseau requis). Le jeton reçu est
  /// vérifié avant d'être stocké ; en cas d'erreur, l'ancien jeton est
  /// conservé et l'erreur est transmise.
  Future<Entitlement> refresh(String accessToken) async {
    final fingerprint = await device.fingerprint();
    final issued = await api.issue(
      accessToken: accessToken,
      fingerprint: fingerprint,
      platform: platform,
    );
    final check = await verifier.check(
      issued.token,
      deviceId: fingerprint,
      now: issued.serverTime,
    );
    if (!check.status.grantsPremium) return _toEntitlement(check);

    await tokens.write(issued.token);
    await clock.anchor(issued.serverTime);
    return current();
  }

  Entitlement _toEntitlement(LicenseCheck check) => Entitlement(
    check.status,
    plan: check.claims?.plan,
    validUntil: check.claims?.validUntil,
  );
}
