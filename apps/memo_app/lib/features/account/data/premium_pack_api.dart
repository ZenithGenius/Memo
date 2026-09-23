import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
    final http.Response response;
    try {
      response = await _client
          .get(
            config.supabaseUrl
                .resolve('/functions/v1/premium-pack')
                .replace(
                  queryParameters: {
                    'fingerprint': fingerprint,
                    if (have != null) 'have': '$have',
                  },
                ),
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

    switch (response.statusCode) {
      case 204:
        return null;
      case 200:
        try {
          return ContentPack.fromJson(
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>,
          );
        } on Object {
          throw const LicenseApiException(LicenseApiError.server);
        }
      case 401:
        throw const LicenseApiException(LicenseApiError.unauthorized);
      case 402:
        throw const LicenseApiException(LicenseApiError.noActiveSubscription);
      case 403:
        throw const LicenseApiException(LicenseApiError.deviceRevoked);
      default:
        throw const LicenseApiException(LicenseApiError.server);
    }
  }
}
