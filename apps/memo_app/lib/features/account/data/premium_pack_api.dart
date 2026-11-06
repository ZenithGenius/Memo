import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:memo/core/config/app_config.dart';
import 'package:memo/data/content/content_pack.dart';
import 'package:memo/features/license/data/license_api.dart';

abstract interface class PremiumPackApi {
  /// Paquet payant, ou `null` si la version [have] est déjà la dernière.
  Future<ContentPack?> fetch({
    required String accessToken,
    required String fingerprint,
    int? have,
  });

  /// Octets d'une image publiée, désignée par son empreinte (ADR-012).
  Future<Uint8List> fetchImage({
    required String accessToken,
    required String fingerprint,
    required String sha256,
  });

  /// Paquet des mots gratuits (#41), sans compte ; `null` si la version
  /// [have] est déjà la dernière ou si le serveur n'en publie aucun.
  Future<ContentPack?> fetchFree({int? have});

  /// Image d'un mot gratuit, sans compte.
  Future<Uint8List> fetchFreeImage(String sha256);
}

class HttpPremiumPackApi implements PremiumPackApi {
  HttpPremiumPackApi({
    required this.config,
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  }) : _client = client ?? http.Client();

  final AppConfig config;
  final Duration timeout;
  final http.Client _client;

  @override
  Future<ContentPack?> fetch({
    required String accessToken,
    required String fingerprint,
    int? have,
  }) async {
    final response = await _get('premium-pack', {
      'fingerprint': fingerprint,
      if (have != null) 'have': '$have',
    }, accessToken: accessToken);
    return _pack(response);
  }

  @override
  Future<ContentPack?> fetchFree({int? have}) async {
    final response = await _get('free-pack', {
      if (have != null) 'have': '$have',
    }, notFoundIsEmpty: true);
    return _pack(response);
  }

  @override
  Future<Uint8List> fetchFreeImage(String sha256) async =>
      (await _get('free-pack', {'sha256': sha256})).bodyBytes;

  ContentPack? _pack(http.Response response) {
    if (response.statusCode == 204 || response.statusCode == 404) return null;
    try {
      return ContentPack.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>,
      );
    } on Object {
      throw const LicenseApiException(LicenseApiError.server);
    }
  }

  @override
  Future<Uint8List> fetchImage({
    required String accessToken,
    required String fingerprint,
    required String sha256,
  }) async {
    final response = await _get('premium-image', {
      'fingerprint': fingerprint,
      'sha256': sha256,
    }, accessToken: accessToken);
    return response.bodyBytes;
  }

  /// Appel d'une fonction de contenu ; seules les réponses 200 et 204 (et
  /// 404 si [notFoundIsEmpty]) reviennent, les refus deviennent des erreurs
  /// typées. Sans [accessToken], l'appel est anonyme (contenu gratuit).
  Future<http.Response> _get(
    String function,
    Map<String, String> query, {
    String? accessToken,
    bool notFoundIsEmpty = false,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .get(
            config.supabaseUrl
                .resolve('/functions/v1/$function')
                .replace(queryParameters: query),
            headers: {
              'Authorization':
                  'Bearer ${accessToken ?? config.supabaseAnonKey}',
              'apikey': config.supabaseAnonKey,
            },
          )
          .timeout(timeout);
    } on http.ClientException {
      throw const LicenseApiException(LicenseApiError.offline);
    } on SocketException {
      throw const LicenseApiException(LicenseApiError.offline);
    } on TimeoutException {
      throw const LicenseApiException(LicenseApiError.offline);
    }
    return switch (response.statusCode) {
      200 || 204 => response,
      404 when notFoundIsEmpty => response,
      401 => throw const LicenseApiException(LicenseApiError.unauthorized),
      402 => throw const LicenseApiException(
        LicenseApiError.noActiveSubscription,
      ),
      403 => throw const LicenseApiException(LicenseApiError.deviceRevoked),
      _ => throw const LicenseApiException(LicenseApiError.server),
    };
  }
}
