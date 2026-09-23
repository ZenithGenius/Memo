import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/storage/secure_store.dart';
import 'package:memo/data/content/content_importer.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/account/domain/account_service.dart';
import 'package:memo/features/account/presentation/account_providers.dart';
import 'package:memo/features/caregiver/presentation/caregiver_providers.dart';
import 'package:memo/features/license/data/license_api.dart';
import 'package:memo/features/license/data/license_token_store.dart';
import 'package:memo/features/license/data/secure_clock_state_store.dart';
import 'package:memo/features/license/domain/device_identity.dart';
import 'package:memo/features/license/domain/entitlement_service.dart';
import 'package:memo/features/license/domain/license_verifier.dart';
import 'package:memo/features/license/domain/trusted_clock.dart';

import '../../support/pump_app.dart';
import 'account_service_test.dart' show FakeAuth, FakeLicenseApi, FakePacks;

AccountService unsubscribedService(AppDatabase db, SecureStore store) {
  final device = SecureStoreDeviceIdentity(store);
  return AccountService(
    auth: FakeAuth(),
    store: store,
    packs: FakePacks(),
    importer: ContentImporter(db),
    device: device,
    entitlements: EntitlementService(
      verifier: LicenseVerifier(publicKeys: const {}),
      clock: TrustedClock(
        store: SecureClockStateStore(store),
        wallNow: DateTime.now,
        elapsedMs: () => 0,
        bootId: () => 'b',
      ),
      tokens: LicenseTokenStore(store),
      device: device,
      platform: 'android',
      api: FakeLicenseApi(
        (_) => throw const LicenseApiException(
          LicenseApiError.noActiveSubscription,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'connexion depuis les réglages : e-mail, message, synchronisation',
    (tester) async {
      final app = await AppHarness.start(
        tester,
        overrides: (db, store) => [
          accountServiceProvider.overrideWithValue(
            unsubscribedService(db, store),
          ),
        ],
      );
      app.container.read(caregiverSessionProvider.notifier).unlock();
      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();

      final signIn = find.widgetWithText(FilledButton, 'Se connecter');
      await tester.ensureVisible(signIn);
      await tester.pumpAndSettle();
      await tester.tap(signIn);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'amina@example.org');
      await tester.enterText(find.byType(TextField).last, 'motdepasse');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Se connecter').last);
      await settleDatabase(tester);

      expect(find.text('amina@example.org'), findsOneWidget);
      expect(find.textContaining('aucun abonnement actif'), findsOneWidget);
      expect(find.text('Synchroniser'), findsOneWidget);
      await app.dispose(tester);
    },
  );

  testWidgets('sans serveur configuré, pas de section Compte', (tester) async {
    final app = await AppHarness.start(tester);
    await tester.tap(find.text('Réglages'));
    await tester.pumpAndSettle();
    expect(find.text('COMPTE'), findsNothing);
    await app.dispose(tester);
  });
}
