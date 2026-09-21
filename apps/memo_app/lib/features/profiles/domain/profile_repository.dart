import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/profiles/domain/profile.dart';

abstract interface class ProfileRepository {
  Stream<Profile?> watchActive();

  /// Crée un profil et le rend actif.
  Future<Profile> create({
    required String name,
    required ProfileType type,
    required Level level,
  });

  Future<void> setLevel(int profileId, Level level);

  /// Langue du profil : interface, libellés, phrases et voix (`fr`, `en`).
  Future<void> setLanguage(int profileId, String language);
}
