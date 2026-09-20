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
import 'package:memo/features/profiles/data/drift_profile_repository.dart';

/// Ouvre la base, importe le contenu embarqué et câble les dépôts.
/// Attend le premier état du profil actif pour que le routeur décide
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
      if (speech != null) speechServiceProvider.overrideWithValue(speech),
    ],
  );
  await container.read(activeProfileProvider.future);
  return container;
}
