import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/storage/secure_store.dart';
import 'package:memo/data/content/content_importer.dart';
import 'package:memo/data/content/content_pack_source.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/board/data/drift_board_repository.dart';
import 'package:memo/features/caregiver/domain/caregiver_pin_service.dart';
import 'package:memo/features/caregiver/presentation/caregiver_providers.dart';
import 'package:memo/features/catalog/data/drift_catalog_repository.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/favorites/data/drift_favorites_repository.dart';
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
}) async {
  final database = db ?? AppDatabase.production();
  final pack = await (source ?? const AssetContentPackSource()).load();
  await ContentImporter(database).importIfNeeded(pack);
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
        CaregiverPinService(
          store: secureStore ?? const FlutterSecureStore(),
          now: now ?? DateTime.now,
        ),
      ),
      settingsRepositoryProvider.overrideWithValue(
        DriftSettingsRepository(database),
      ),
      if (speech != null) speechServiceProvider.overrideWithValue(speech),
    ],
  );
  // Chargés avant la première image : le premier toucher doit déjà respecter
  // les réglages de l'utilisateur.
  await container.read(activeProfileProvider.future);
  await container.read(appSettingsProvider.future);
  return container;
}
