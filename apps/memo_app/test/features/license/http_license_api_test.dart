import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memo/core/config/app_config.dart';
import 'package:memo/features/license/data/license_api.dart';

import '../../support/fake_jwt.dart';

void main() {
  final config = AppConfig.fromMap({
    'SUPABASE_URL': 'https://api.example.org',
    'SUPABASE_ANON_KEY': fakeJwt('anon'),
    'LICENSE_PUBLIC_KEYS': jsonEncode({
      'k1': base64.encode(List.filled(32, 1)),
    }),
  });

  HttpLicenseApi api(MockClientHandler handler) =>
      HttpLicenseApi(config: config, client: MockClient(handler));

  Future<IssuedLicense> issue(HttpLicenseApi a) => a.issue(
    accessToken: 'jwt-utilisateur',
    fingerprint: 'abcdefghijklmnop1234',
    platform: 'android',
  );

  test('envoie la requête attendue et lit la réponse', () async {
    late http.Request seen;
    final result = await issue(
      api((request) async {
        seen = request;
        return http.Response(
          jsonEncode({
            'token': 'a.b',
            'server_time': '2026-09-21T10:00:00.000Z',
            'valid_until': '2026-10-21T10:00:00.000Z',
            'plan': 'essentiel',
          }),
          200,
        );
      }),
    );
    expect(
      seen.url.toString(),
      'https://api.example.org/functions/v1/issue-license',
    );
    expect(seen.method, 'POST');
    expect(seen.headers['Authorization'], 'Bearer jwt-utilisateur');
    expect(seen.headers['apikey'], config.supabaseAnonKey);
    expect(jsonDecode(seen.body), {
      'fingerprint': 'abcdefghijklmnop1234',
      'platform': 'android',
    });
    expect(result.token, 'a.b');
    expect(result.serverTime, DateTime.utc(2026, 9, 21, 10));
    expect(result.plan, 'essentiel');
  });

  test('codes métier du serveur transformés en erreurs typées', () async {
    for (final (status, code) in [
      (402, LicenseApiError.noActiveSubscription),
      (409, LicenseApiError.deviceLimitReached),
      (403, LicenseApiError.deviceRevoked),
      (401, LicenseApiError.unauthorized),
    ]) {
      await expectLater(
        issue(api((_) async => http.Response('{"error":"x"}', status))),
        throwsA(
          isA<LicenseApiException>().having((e) => e.error, 'error', code),
        ),
        reason: 'HTTP $status',
      );
    }
  });

  test('erreur serveur ou réponse illisible : erreur générique', () async {
    await expectLater(
      issue(api((_) async => http.Response('boom', 500))),
      throwsA(
        isA<LicenseApiException>().having(
          (e) => e.error,
          'error',
          LicenseApiError.server,
        ),
      ),
    );
    await expectLater(
      issue(api((_) async => http.Response('pas du json', 200))),
      throwsA(
        isA<LicenseApiException>().having(
          (e) => e.error,
          'error',
          LicenseApiError.server,
        ),
      ),
    );
  });

  test('réseau indisponible : erreur dédiée, sans détail technique', () async {
    await expectLater(
      issue(api((_) async => throw http.ClientException('no route'))),
      throwsA(
        isA<LicenseApiException>().having(
          (e) => e.error,
          'error',
          LicenseApiError.offline,
        ),
      ),
    );
  });
}
