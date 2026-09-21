import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/profiles/domain/profile.dart';

/// Langues proposées, dans l'ordre de bascule de la pastille.
const supportedLanguages = ['fr', 'en'];

/// Change la langue du profil : interface, libellés, phrases et voix.
/// Le message en cours est vidé, il n'aurait plus de sens dans l'autre langue.
Future<void> setProfileLanguage(
  WidgetRef ref,
  Profile profile,
  String language,
) async {
  if (language == profile.language) return;
  ref.read(messageProvider.notifier).clear();
  await ref.read(profileRepositoryProvider).setLanguage(profile.id, language);
}

/// Langue suivante dans [supportedLanguages].
String nextLanguage(String current) {
  final i = supportedLanguages.indexOf(current);
  return supportedLanguages[(i + 1) % supportedLanguages.length];
}
