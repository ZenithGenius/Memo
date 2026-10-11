import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/storage/secure_store.dart';

void main() {
  test('trousseau iOS lié à ce téléphone, jamais migré ni synchronisé', () {
    // Le secret de l'appareil et le jeton de licence ne doivent pas suivre
    // une sauvegarde : le jeton est lié à l'appareil (ADR-008).
    final options = FlutterSecureStore.defaultStorage.iOptions;
    expect(
      options.accessibility,
      KeychainAccessibility.first_unlock_this_device,
    );
    expect(options.synchronizable, isFalse);
  });
}
