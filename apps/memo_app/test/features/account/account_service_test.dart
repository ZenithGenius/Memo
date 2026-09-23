import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/storage/secure_store.dart';
import 'package:memo/data/content/content_importer.dart';
import 'package:memo/data/content/content_pack.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/account/data/auth_api.dart';
import 'package:memo/features/account/data/premium_pack_api.dart';
import 'package:memo/features/account/domain/account_service.dart';
import 'package:memo/features/license/data/license_api.dart';
import 'package:memo/features/license/data/license_token_store.dart';
import 'package:memo/features/license/data/secure_clock_state_store.dart';
import 'package:memo/features/license/domain/device_identity.dart';
import 'package:memo/features/license/domain/entitlement_service.dart';
import 'package:memo/features/license/domain/license_verifier.dart';
import 'package:memo/features/license/domain/trusted_clock.dart';

import '../../support/license_fixtures.dart';

class FakeAuth implements AuthApi {
  AuthError? failWith;
  int refreshes = 0;

  AuthSession _session(String email) => AuthSession(
    accessToken: 'jwt',
    refreshToken: 'refresh-${++refreshes}',
    email: email,
  );

  @override
  Future<AuthSession> signIn(String email, String password) async {
    if (failWith != null) throw AuthException(failWith!);
    return _session(email);
  }

  @override
  Future<AuthSession> signUp(String email, String password) =>
      signIn(email, password);

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    if (failWith != null) throw AuthException(failWith!);
    return _session('amina@example.org');
  }
}

class FakeLicenseApi implements LicenseApi {
  FakeLicenseApi(this.issue_);
  Future<IssuedLicense> Function(String fingerprint) issue_;

  @override
  Future<IssuedLicense> issue({
    required String accessToken,
    required String fingerprint,
    required String platform,
    String? label,
  }) => issue_(fingerprint);
}

class FakePacks implements PremiumPackApi {
  int version = 7;
  final requestedHave = <int?>[];

  @override
  Future<ContentPack?> fetch({
    required String accessToken,
    required String fingerprint,
    int? have,
  }) async {
    requestedHave.add(have);
    if (have != null && have >= version) return null;
    return ContentPack.fromJson({
      'version': version,
      'categories': [
        {
          'code': 'ALI',
          'sortOrder': 3,
          'labels': {'fr': 'Alimentation'},
        },
      ],
      'pictograms': [
        {
          'code': 'CAA-CR-ALI-001',
          'category': 'ALI',
          'level': 0,
          'audience': 'all',
          'sortOrder': 1,
          'tier': 'premium',
          'labels': {
            'fr': {'label': 'Eau', 'spoken': 'eau'},
          },
        },
      ],
    });
  }
}

void main() {
  final now = DateTime.utc(2026, 9, 23, 10);
  late SimpleKeyPair serverKey;
  late InMemorySecureStore store;
  late AppDatabase db;
  late FakeAuth auth;
  late FakePacks packs;
  late bool subscribed;

  Future<AccountService> service() async {
    final device = SecureStoreDeviceIdentity(store);
    return AccountService(
      auth: auth,
      store: store,
      packs: packs,
      importer: ContentImporter(db),
      device: device,
      entitlements: EntitlementService(
        verifier: LicenseVerifier(
          publicKeys: {'k1': await serverKey.extractPublicKey()},
        ),
        clock: TrustedClock(
          store: SecureClockStateStore(store),
          wallNow: () => now,
          elapsedMs: () => 0,
          bootId: () => 'b',
        ),
        tokens: LicenseTokenStore(store),
        device: device,
        platform: 'android',
        api: FakeLicenseApi((fp) async {
          if (!subscribed) {
            throw const LicenseApiException(
              LicenseApiError.noActiveSubscription,
            );
          }
          final until = now.add(const Duration(days: 30));
          return IssuedLicense(
            token: await signToken(
              serverKey,
              device: fp,
              issuedAt: now,
              validUntil: until,
            ),
            serverTime: now,
            validUntil: until,
            plan: 'essentiel',
          );
        }),
      ),
    );
  }

  setUp(() async {
    serverKey = await Ed25519().newKeyPair();
    store = InMemorySecureStore();
    db = AppDatabase.forTesting();
    auth = FakeAuth();
    packs = FakePacks();
    subscribed = true;
  });
  tearDown(() => db.close());

  Future<int> premiumCount() async =>
      (await db.select(db.pictograms).get()).length;

  test('connexion abonnée : droits actifs et contenu payant importé', () async {
    final s = await service();
    final e = await s.signIn(' amina@example.org ', 'secret');
    expect(e.isPremium, isTrue);
    expect(await s.email, 'amina@example.org');
    expect(await premiumCount(), 1);
    expect(
      await ContentImporter(db).installedVersion(ContentImporter.premiumSlot),
      7,
    );
  });

  test('déjà à jour : le paquet n\'est pas retéléchargé', () async {
    final s = await service();
    await s.signIn('a@b.org', 'x');
    await s.sync();
    expect(packs.requestedHave, [null, 7]);
  });

  test('nouvelle version publiée : importée à la synchronisation', () async {
    final s = await service();
    await s.signIn('a@b.org', 'x');
    packs.version = 8;
    await s.sync();
    expect(
      await ContentImporter(db).installedVersion(ContentImporter.premiumSlot),
      8,
    );
  });

  test(
    'sans abonnement : connecté, erreur explicite, rien d\'importé',
    () async {
      subscribed = false;
      final s = await service();
      await expectLater(
        s.signIn('a@b.org', 'x'),
        throwsA(
          isA<LicenseApiException>().having(
            (e) => e.error,
            'error',
            LicenseApiError.noActiveSubscription,
          ),
        ),
      );
      expect(await s.email, 'a@b.org', reason: 'la session est gardée');
      expect(await premiumCount(), 0);
      expect(packs.requestedHave, isEmpty);
    },
  );

  test('identifiants refusés : aucune session enregistrée', () async {
    auth.failWith = AuthError.invalidCredentials;
    final s = await service();
    await expectLater(s.signIn('a@b.org', 'x'), throwsA(isA<AuthException>()));
    expect(await s.email, isNull);
  });

  test('session expirée à la synchronisation : déconnexion', () async {
    final s = await service();
    await s.signIn('a@b.org', 'x');
    auth.failWith = AuthError.sessionExpired;
    await expectLater(s.sync(), throwsA(isA<AuthException>()));
    expect(await s.email, isNull);
  });

  test('synchroniser sans compte : session expirée', () async {
    final s = await service();
    await expectLater(
      s.sync(),
      throwsA(
        isA<AuthException>().having(
          (e) => e.error,
          'error',
          AuthError.sessionExpired,
        ),
      ),
    );
  });

  test('se déconnecter garde les droits de la période payée', () async {
    final s = await service();
    await s.signIn('a@b.org', 'x');
    await s.signOut();
    expect(await s.email, isNull);
    expect((await s.entitlements.current()).isPremium, isTrue);
  });

  test('la session tournante est mémorisée à chaque synchronisation', () async {
    final s = await service();
    await s.signIn('a@b.org', 'x');
    await s.sync();
    expect(await store.read('auth_refresh_token'), 'refresh-2');
  });
}
