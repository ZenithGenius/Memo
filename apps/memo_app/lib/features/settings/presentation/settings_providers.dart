import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/settings/domain/app_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError('à surcharger au démarrage'),
);

final appSettingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);
