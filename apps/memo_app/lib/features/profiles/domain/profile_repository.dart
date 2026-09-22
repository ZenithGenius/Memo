import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/profiles/domain/profile.dart';

abstract interface class ProfileRepository {
  Stream<Profile?> watchActive();

  /// Tous les profils de l'appareil, dans l'ordre de création.
  Stream<List<Profile>> watchAll();

  /// Crée un profil et le rend actif.
  Future<Profile> create({
    required String name,
    required ProfileType type,
    required Level level,
    String language = 'fr',
  });

  /// Change le profil actif. Sans effet si le profil n'existe pas.
  Future<void> setActive(int profileId);

  Future<void> setLevel(int profileId, Level level);

  /// Langue du profil : interface, libellés, phrases et voix (`fr`, `en`).
  Future<void> setLanguage(int profileId, String language);
}
