import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/profiles/domain/profile.dart';

final allProfilesProvider = StreamProvider<List<Profile>>(
  (ref) => ref.watch(profileRepositoryProvider).watchAll(),
);
