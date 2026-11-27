import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Images téléchargées depuis le serveur, rangées sous leur empreinte SHA-256
/// (ADR-012). Une image n'est enregistrée que si son contenu correspond à son
/// nom : un fichier altéré en route n'est jamais affiché.
class ImageStore {
  ImageStore(this.directory);

  final Directory directory;

  File fileFor(String sha256) => File('${directory.path}/$sha256');

  Future<bool> has(String sha256) => fileFor(sha256).exists();

  /// Enregistre [bytes] sous [sha256]. Retourne `false` si le contenu ne
  /// correspond pas à l'empreinte annoncée.
  Future<bool> save(String sha256, Uint8List bytes) async {
    final digest = await Sha256().hash(bytes);
    final hex = digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    if (hex != sha256) return false;
    await directory.create(recursive: true);
    // Écrit à côté puis renomme : jamais de fichier à moitié écrit.
    final partial = File('${fileFor(sha256).path}.part');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(fileFor(sha256).path);
    return true;
  }
}
