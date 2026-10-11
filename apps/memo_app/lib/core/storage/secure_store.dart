import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage clé-valeur chiffré (Keystore sur Android, Keychain sur iOS).
/// Sert aux secrets et à l'état de sécurité : jeton de licence, état de
/// l'horloge, secret de l'appareil. Jamais aux données de contenu.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore([this._storage = defaultStorage]);
  final FlutterSecureStorage _storage;

  /// iOS : éléments du trousseau liés à ce téléphone (`this_device`), jamais
  /// migrés par une sauvegarde iCloud ou un transfert. Sinon le secret de
  /// l'appareil et le jeton de licence suivraient la copie, et le jeton lié
  /// à l'appareil (ADR-008) serait valide sur un second téléphone. Android :
  /// le stockage est exclu des sauvegardes (res/xml/backup_rules.xml).
  static const defaultStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class InMemorySecureStore implements SecureStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}
