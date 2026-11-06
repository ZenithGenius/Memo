import 'package:memo/core/storage/secure_store.dart';
import 'package:memo/data/content/content_importer.dart';
import 'package:memo/data/content/image_store.dart';
import 'package:memo/features/account/data/auth_api.dart';
import 'package:memo/features/account/data/premium_pack_api.dart';
import 'package:memo/features/license/data/license_api.dart';
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
    this.images,
  });

  final AuthApi auth;
  final SecureStore store;
  final EntitlementService entitlements;
  final PremiumPackApi packs;
  final ContentImporter importer;
  final DeviceIdentity device;

  /// Images envoyées depuis le back-office ; `null` sans stockage local.
  final ImageStore? images;

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

  /// Lien de réinitialisation envoyé par e-mail ; le nouveau mot de passe se
  /// choisit sur la page du lien, puis on se reconnecte ici.
  Future<void> requestPasswordReset(String email) =>
      auth.requestPasswordReset(email.trim());

  /// Supprime le compte sur le serveur (réseau requis), puis oublie la session
  /// et le jeton de licence : l'appareil repasse en gratuit. Les profils, les
  /// favoris et les tableaux restent sur l'appareil.
  Future<void> deleteAccount() async {
    final refresh = await store.read(_refreshKey);
    if (refresh == null) throw const AuthException(AuthError.sessionExpired);
    final session = await auth.refresh(refresh);
    await auth.deleteAccount(session.accessToken);
    await entitlements.forget();
    await signOut();
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
      await _downloadImages(session.accessToken);
    }
    return entitlement;
  }

  /// Télécharge les images qui manquent, à chaque synchronisation : une image
  /// non reçue (réseau coupé, erreur ponctuelle) est retentée la fois
  /// suivante, sans faire échouer la synchronisation du reste.
  Future<void> _downloadImages(String accessToken) async {
    final store = images;
    if (store == null) return;
    final fingerprint = await device.fingerprint();
    for (final sha256 in await importer.imageHashes()) {
      if (await store.has(sha256)) continue;
      try {
        final bytes = await packs.fetchImage(
          accessToken: accessToken,
          fingerprint: fingerprint,
          sha256: sha256,
        );
        await store.save(sha256, bytes);
      } on LicenseApiException catch (e) {
        if (e.error == LicenseApiError.offline) return;
      }
    }
  }
}
