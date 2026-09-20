import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/board/domain/board_repository.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/domain/catalog_repository.dart';
import 'package:memo/features/favorites/domain/favorites_repository.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/features/profiles/domain/profile_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => throw UnimplementedError('à surcharger au démarrage'),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => throw UnimplementedError('à surcharger au démarrage'),
);

final activeProfileProvider = StreamProvider<Profile?>(
  (ref) => ref.watch(profileRepositoryProvider).watchActive(),
);

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final lang = ref.watch(activeProfileProvider).value?.language ?? 'fr';
  return ref.watch(catalogRepositoryProvider).watchCategories(lang);
});

final pictogramsProvider = StreamProvider.family<List<Pictogram>, String>((
  ref,
  categoryCode,
) {
  final profile = ref.watch(activeProfileProvider).value;
  return ref
      .watch(catalogRepositoryProvider)
      .watchPictograms(
        categoryCode: categoryCode,
        lang: profile?.language ?? 'fr',
        maxLevel: profile?.level ?? Level.beginner,
        audience: profile?.type.audience ?? Audience.all,
      );
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => throw UnimplementedError('à surcharger au démarrage'),
);

final boardRepositoryProvider = Provider<BoardRepository>(
  (ref) => throw UnimplementedError('à surcharger au démarrage'),
);

final favoriteIdsProvider = StreamProvider<Set<int>>((ref) {
  final profile = ref.watch(activeProfileProvider).value;
  if (profile == null) return Stream.value(<int>{});
  return ref.watch(favoritesRepositoryProvider).watchIds(profile.id);
});

final favoritePictogramsProvider = StreamProvider<List<Pictogram>>((ref) {
  final profile = ref.watch(activeProfileProvider).value;
  final ids = ref.watch(favoriteIdsProvider).value ?? <int>{};
  if (profile == null || ids.isEmpty) return Stream.value(const <Pictogram>[]);
  return ref
      .watch(catalogRepositoryProvider)
      .watchByIds(ids.toList(), profile.language);
});

final boardProvider = StreamProvider<BoardLayout?>((ref) {
  final profile = ref.watch(activeProfileProvider).value;
  if (profile == null) return Stream.value(null);
  return ref.watch(boardRepositoryProvider).watch(profile.id, profile.level);
});

final boardPictogramsProvider = StreamProvider<Map<int, Pictogram>>((ref) {
  final profile = ref.watch(activeProfileProvider).value;
  final board = ref.watch(boardProvider).value;
  if (profile == null || board == null || board.cells.isEmpty) {
    return Stream.value(const <int, Pictogram>{});
  }
  return ref
      .watch(catalogRepositoryProvider)
      .watchByIds(board.cells.values.toList(), profile.language)
      .map((list) => {for (final p in list) p.id: p});
});
