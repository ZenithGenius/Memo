import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:memo/core/config/app_config.dart';

enum LicenseApiError {
  noActiveSubscription,
  deviceLimitReached,
  deviceRevoked,
  unauthorized,
  offline,
  server,
}

class LicenseApiException implements Exception {
  const LicenseApiException(this.error);
  final LicenseApiError error;

  @override
  String toString() => 'LicenseApiException(${error.name})';
}

class IssuedLicense {
  const IssuedLicense({
    required this.token,
    required this.serverTime,
    required this.validUntil,
    required this.plan,
  });

  final String token;

  /// Date du serveur : sert d'ancre à l'horloge de confiance.
  final DateTime serverTime;
  final DateTime validUntil;
  final String plan;
}

abstract interface class LicenseApi {
  Future<IssuedLicense> issue({
    required String accessToken,
    required String fingerprint,
    required String platform,
    String? label,
  });
}

class HttpLicenseApi implements LicenseApi {
  HttpLicenseApi({
    required this.config,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  final AppConfig config;
  final Duration timeout;
  final http.Client _client;

  @override
  Future<IssuedLicense> issue({
    required String accessToken,
    required String fingerprint,
    required String platform,
    String? label,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            config.supabaseUrl.resolve('/functions/v1/issue-license'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'apikey': config.supabaseAnonKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'fingerprint': fingerprint,
              'platform': platform,
              'label': ?label,
            }),
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
      case 200:
        return _parse(response.body);
      case 401:
        throw const LicenseApiException(LicenseApiError.unauthorized);
      case 402:
        throw const LicenseApiException(LicenseApiError.noActiveSubscription);
      case 403:
        throw const LicenseApiException(LicenseApiError.deviceRevoked);
      case 409:
        throw const LicenseApiException(LicenseApiError.deviceLimitReached);
      default:
        throw const LicenseApiException(LicenseApiError.server);
    }
  }

  IssuedLicense _parse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, Object?>;
      return IssuedLicense(
        token: json['token']! as String,
        serverTime: DateTime.parse(json['server_time']! as String).toUtc(),
        validUntil: DateTime.parse(json['valid_until']! as String).toUtc(),
        plan: json['plan']! as String,
      );
    } on Object {
      throw const LicenseApiException(LicenseApiError.server);
    }
  }
}
