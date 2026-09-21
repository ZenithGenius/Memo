import 'package:memo/core/storage/secure_store.dart';

class LicenseTokenStore {
  LicenseTokenStore(this._store);
  final SecureStore _store;

  static const _key = 'license_token';

  Future<String?> read() => _store.read(_key);
  Future<void> write(String token) => _store.write(_key, token);
  Future<void> clear() => _store.delete(_key);
}
