import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:memo/core/storage/secure_store.dart';

/// Identité de l'appareil présentée au serveur et liée au jeton (ADR-008).
abstract interface class DeviceIdentity {
  /// Empreinte stable, sans lien avec l'identifiant matériel de l'appareil.
  Future<String> fingerprint();
}

/// Secret aléatoire généré au premier usage, gardé dans le stockage chiffré ;
/// seule son empreinte quitte l'appareil. Remplaçable par une clé matérielle
/// attestée (Keystore, Secure Enclave) derrière la même interface.
class SecureStoreDeviceIdentity implements DeviceIdentity {
  SecureStoreDeviceIdentity(this._store);
  final SecureStore _store;

  static const _secretKey = 'device_secret';
  static const _context = 'memo-device-v1:';
  String? _cached;

  @override
  Future<String> fingerprint() async {
    if (_cached != null) return _cached!;
    var secret = await _store.read(_secretKey);
    if (secret == null) {
      final random = Random.secure();
      secret = base64Url.encode(List.generate(32, (_) => random.nextInt(256)));
      await _store.write(_secretKey, secret);
    }
    final digest = await Sha256().hash(utf8.encode('$_context$secret'));
    return _cached = base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
