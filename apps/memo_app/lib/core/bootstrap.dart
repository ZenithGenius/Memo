import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/config/app_config.dart';
import 'package:memo/core/storage/secure_store.dart';
import 'package:memo/data/content/content_importer.dart';
import 'package:memo/data/content/content_pack_source.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/account/data/auth_api.dart';
import 'package:memo/features/account/data/premium_pack_api.dart';
import 'package:memo/features/account/domain/account_service.dart';
import 'package:memo/features/account/presentation/account_providers.dart';
import 'package:memo/features/board/data/drift_board_repository.dart';
import 'package:memo/features/caregiver/domain/caregiver_pin_service.dart';
import 'package:memo/features/caregiver/presentation/caregiver_providers.dart';
import 'package:memo/features/catalog/data/drift_catalog_repository.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/favorites/data/drift_favorites_repository.dart';
import 'package:memo/features/license/data/license_api.dart';
import 'package:memo/features/license/data/license_token_store.dart';
import 'package:memo/features/license/data/secure_clock_state_store.dart';
import 'package:memo/features/license/domain/device_identity.dart';
import 'package:memo/features/license/domain/entitlement_service.dart';
import 'package:memo/features/license/domain/license_verifier.dart';
import 'package:memo/features/license/domain/trusted_clock.dart';
import 'package:memo/features/message/domain/speech_service.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/phrases/data/drift_phrase_repository.dart';
import 'package:memo/features/phrases/presentation/phrase_providers.dart';
import 'package:memo/features/profiles/data/drift_profile_repository.dart';
import 'package:memo/features/settings/data/drift_settings_repository.dart';
import 'package:memo/features/settings/presentation/settings_providers.dart';
import 'package:memo/features/stats/data/drift_usage_repository.dart';
import 'package:memo/features/stats/presentation/usage_providers.dart';

/// Ouvre la base, importe le contenu embarqué et câble les dépôts.
/// Attend le premier état du profil actif et des réglages : le routeur décide
/// immédiatement entre première installation et accueil.
Future<ProviderContainer> createContainer({
  AppDatabase? db,
  ContentPackSource? source,
  SpeechService? speech,
  SecureStore? secureStore,
  DateTime Function()? now,
  AppConfig? config,
  List<Override> overrides = const [],
}) async {
  final database = db ?? AppDatabase.production();
  final store = secureStore ?? const FlutterSecureStore();
  final clock = now ?? DateTime.now;
  final serverConfig = config ?? _configFromEnvironment();
  final pack = await (source ?? const AssetContentPackSource()).load();
  final importer = ContentImporter(database);
  await importer.importIfNeeded(pack);
  final container = ProviderContainer(
    overrides: [
      catalogRepositoryProvider.overrideWithValue(
        DriftCatalogRepository(database),
      ),
      profileRepositoryProvider.overrideWithValue(
        DriftProfileRepository(database),
      ),
      favoritesRepositoryProvider.overrideWithValue(
        DriftFavoritesRepository(database),
      ),
      boardRepositoryProvider.overrideWithValue(DriftBoardRepository(database)),
      phraseRepositoryProvider.overrideWithValue(
        DriftPhraseRepository(database),
      ),
      usageRepositoryProvider.overrideWithValue(DriftUsageRepository(database)),
      caregiverPinServiceProvider.overrideWithValue(
        CaregiverPinService(store: store, now: clock),
      ),
      settingsRepositoryProvider.overrideWithValue(
        DriftSettingsRepository(database),
      ),
      if (speech != null) speechServiceProvider.overrideWithValue(speech),
      if (serverConfig != null)
        accountServiceProvider.overrideWithValue(
          _accountService(serverConfig, store, importer, clock),
        ),
      ...overrides,
    ],
  );
  // Chargés avant la première image : le premier toucher doit déjà respecter
  // les réglages de l'utilisateur.
  await container.read(activeProfileProvider.future);
  await container.read(appSettingsProvider.future);
  return container;
}

AppConfig? _configFromEnvironment() {
  try {
    return AppConfig.fromEnvironment();
  } on ConfigException {
    // Compilée sans serveur : hors ligne, contenu gratuit, sans compte.
    return null;
  }
}

/// Horloge monotone du processus (non réglable par l'utilisateur).
/// ponytail: repart à zéro à chaque lancement, d'où un identifiant de
/// démarrage par lancement ; l'horloge de confiance retombe alors sur le plus
/// grand instant observé. Passer à elapsedRealtime (canal natif) si besoin.
final _monotonic = Stopwatch()..start();
final _launchId = DateTime.now().microsecondsSinceEpoch.toString();

AccountService _accountService(
  AppConfig config,
  SecureStore store,
  ContentImporter importer,
  DateTime Function() now,
) {
  final device = SecureStoreDeviceIdentity(store);
  return AccountService(
    auth: HttpAuthApi(config: config),
    store: store,
    packs: HttpPremiumPackApi(config: config),
    importer: importer,
    device: device,
    entitlements: EntitlementService(
      verifier: LicenseVerifier(publicKeys: config.licensePublicKeys),
      clock: TrustedClock(
        store: SecureClockStateStore(store),
        wallNow: now,
        elapsedMs: () => _monotonic.elapsedMilliseconds,
        bootId: () => _launchId,
      ),
      tokens: LicenseTokenStore(store),
      device: device,
      api: HttpLicenseApi(config: config),
      platform: Platform.isIOS ? 'ios' : 'android',
    ),
  );
}
