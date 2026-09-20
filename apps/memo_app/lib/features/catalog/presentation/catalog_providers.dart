import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/domain/catalog_repository.dart';
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

final pictogramsProvider =
    StreamProvider.family<List<Pictogram>, String>((ref, categoryCode) {
  final profile = ref.watch(activeProfileProvider).value;
  return ref.watch(catalogRepositoryProvider).watchPictograms(
        categoryCode: categoryCode,
        lang: profile?.language ?? 'fr',
        maxLevel: profile?.level ?? Level.beginner,
        audience: profile?.type.audience ?? Audience.all,
      );
});
