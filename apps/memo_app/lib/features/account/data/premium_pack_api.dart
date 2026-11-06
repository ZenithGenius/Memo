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
    final response = await _get('premium-pack', accessToken, {
      'fingerprint': fingerprint,
      if (have != null) 'have': '$have',
    });
    if (response.statusCode == 204) return null;
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
    final response = await _get('premium-image', accessToken, {
      'fingerprint': fingerprint,
      'sha256': sha256,
    });
    return response.bodyBytes;
  }

  /// Appel d'une fonction de contenu ; seules les réponses 200 et 204
  /// reviennent, les refus deviennent des erreurs typées.
  Future<http.Response> _get(
    String function,
    String accessToken,
    Map<String, String> query,
  ) async {
    final http.Response response;
    try {
      response = await _client
          .get(
            config.supabaseUrl
                .resolve('/functions/v1/$function')
                .replace(queryParameters: query),
            headers: {
              'Authorization': 'Bearer $accessToken',
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
      401 => throw const LicenseApiException(LicenseApiError.unauthorized),
      402 => throw const LicenseApiException(
        LicenseApiError.noActiveSubscription,
      ),
      403 => throw const LicenseApiException(LicenseApiError.deviceRevoked),
      _ => throw const LicenseApiException(LicenseApiError.server),
    };
  }
}
