import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

class ConfigException implements Exception {
  const ConfigException(this.message);
  final String message;

  @override
  String toString() => 'ConfigException: $message';
}

/// Configuration injectée à la compilation, jamais écrite dans le code :
///
///   flutter run --dart-define-from-file=env/dev.json
///
/// Variables :
/// - `SUPABASE_URL` : adresse du backend (HTTPS hors développement)
/// - `SUPABASE_ANON_KEY` : clé publique (rôle `anon`) ; une clé `service_role`
///   est refusée
/// - `LICENSE_PUBLIC_KEYS` : JSON `{"kid": "<clé Ed25519 en base64>"}`, au plus
///   deux entrées pour permettre la rotation (ADR-008)
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.licensePublicKeys,
  });

  /// Lit les valeurs `--dart-define`. HTTP n'est toléré qu'en dehors d'une
  /// compilation de production.
  factory AppConfig.fromEnvironment() => AppConfig.fromMap(const {
    'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
    'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
    'LICENSE_PUBLIC_KEYS': String.fromEnvironment('LICENSE_PUBLIC_KEYS'),
  }, allowInsecureHttp: !kReleaseMode);

  factory AppConfig.fromMap(
    Map<String, String> env, {
    bool allowInsecureHttp = false,
  }) {
    String required(String key) {
      final value = env[key];
      if (value == null || value.isEmpty) {
        throw ConfigException('Variable manquante : $key');
      }
      return value;
    }

    final url = Uri.tryParse(required('SUPABASE_URL'));
    if (url == null || !url.hasAuthority) {
      throw const ConfigException('SUPABASE_URL invalide');
    }
    if (url.scheme != 'https' && !(allowInsecureHttp && url.scheme == 'http')) {
      throw const ConfigException('SUPABASE_URL doit utiliser HTTPS');
    }

    final anonKey = required('SUPABASE_ANON_KEY');
    if (_jwtRole(anonKey) == 'service_role') {
      throw const ConfigException(
        'SUPABASE_ANON_KEY contient une clé service_role : '
        'elle ne doit jamais être embarquée dans l\'application',
      );
    }

    return AppConfig(
      supabaseUrl: url,
      supabaseAnonKey: anonKey,
      licensePublicKeys: _parsePublicKeys(required('LICENSE_PUBLIC_KEYS')),
    );
  }

  final Uri supabaseUrl;
  final String supabaseAnonKey;

  /// Clés publiques de vérification des licences, par identifiant (`kid`).
  final Map<String, SimplePublicKey> licensePublicKeys;

  static const _maxKeys = 2;
  static const _ed25519KeyLength = 32;

  static Map<String, SimplePublicKey> _parsePublicKeys(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const ConfigException('LICENSE_PUBLIC_KEYS : JSON illisible');
    }
    if (decoded is! Map<String, Object?> || decoded.isEmpty) {
      throw const ConfigException(
        'LICENSE_PUBLIC_KEYS doit être un objet {kid: clé} non vide',
      );
    }
    if (decoded.length > _maxKeys) {
      throw const ConfigException(
        'LICENSE_PUBLIC_KEYS : $_maxKeys clés au plus',
      );
    }
    return decoded.map((kid, value) {
      final List<int> bytes;
      try {
        bytes = base64.decode(value! as String);
      } on Object {
        throw ConfigException('LICENSE_PUBLIC_KEYS : clé "$kid" illisible');
      }
      if (bytes.length != _ed25519KeyLength) {
        throw ConfigException(
          'LICENSE_PUBLIC_KEYS : la clé "$kid" doit faire '
          '$_ed25519KeyLength octets',
        );
      }
      return MapEntry(kid, SimplePublicKey(bytes, type: KeyPairType.ed25519));
    });
  }

  /// Rôle porté par un JWT, sans vérifier la signature (simple garde-fou).
  static String? _jwtRole(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload is Map<String, Object?>
          ? payload['role'] as String?
          : null;
    } on Object {
      return null;
    }
  }
}
