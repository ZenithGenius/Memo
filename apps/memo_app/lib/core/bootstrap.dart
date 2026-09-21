import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/data/content/content_importer.dart';
import 'package:memo/data/content/content_pack_source.dart';
import 'package:memo/data/db/app_database.dart';
import 'package:memo/features/board/data/drift_board_repository.dart';
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

/// Ouvre la base, importe le contenu embarqué et câble les dépôts.
/// Attend le premier état du profil actif et des réglages : le routeur décide
/// immédiatement entre première installation et accueil.
Future<ProviderContainer> createContainer({
  AppDatabase? db,
  ContentPackSource? source,
  SpeechService? speech,
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
