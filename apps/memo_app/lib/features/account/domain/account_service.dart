import 'package:memo/core/storage/secure_store.dart';
import 'package:memo/data/content/content_importer.dart';
import 'package:memo/features/account/data/auth_api.dart';
import 'package:memo/features/account/data/premium_pack_api.dart';
import 'package:memo/features/license/domain/device_identity.dart';
import 'package:memo/features/license/domain/entitlement_service.dart';

/// Compte de l'accompagnant : connexion, puis synchronisation qui renouvelle
/// le jeton de licence et télécharge le contenu payant (ADR-008).
/// Tout le reste de l'application fonctionne sans compte et hors ligne.
class AccountService {
  AccountService({
    required this.auth,
    required this.store,
    required this.entitlements,
    required this.packs,
    required this.importer,
    required this.device,
  });

  final AuthApi auth;
  final SecureStore store;
  final EntitlementService entitlements;
  final PremiumPackApi packs;
  final ContentImporter importer;
  final DeviceIdentity device;

  static const _refreshKey = 'auth_refresh_token';
  static const _emailKey = 'auth_email';

  /// E-mail du compte connecté, `null` sans compte.
  Future<String?> get email => store.read(_emailKey);

  Future<Entitlement> signIn(String email, String password) async =>
      _syncWith(await auth.signIn(email.trim(), password));

  Future<Entitlement> signUp(String email, String password) async =>
      _syncWith(await auth.signUp(email.trim(), password));

  /// Renouvelle la session puis les droits. Réseau requis.
  Future<Entitlement> sync() async {
    final refresh = await store.read(_refreshKey);
    if (refresh == null) throw const AuthException(AuthError.sessionExpired);
    try {
      return await _syncWith(await auth.refresh(refresh));
    } on AuthException catch (e) {
      if (e.error == AuthError.sessionExpired) await signOut();
      rethrow;
    }
  }

  /// Oublie la session. Le jeton de licence reste : la période payée sur cet
  /// appareil continue hors ligne jusqu'à son terme.
  Future<void> signOut() async {
    await store.delete(_refreshKey);
    await store.delete(_emailKey);
  }

  Future<Entitlement> _syncWith(AuthSession session) async {
    await store.write(_refreshKey, session.refreshToken);
    await store.write(_emailKey, session.email);
    final entitlement = await entitlements.refresh(session.accessToken);
    if (entitlement.isPremium) {
      final pack = await packs.fetch(
        accessToken: session.accessToken,
        fingerprint: await device.fingerprint(),
        have: await importer.installedVersion(ContentImporter.premiumSlot),
      );
      if (pack != null) {
        await importer.importIfNeeded(pack, slot: ContentImporter.premiumSlot);
      }
    }
    return entitlement;
  }
}
