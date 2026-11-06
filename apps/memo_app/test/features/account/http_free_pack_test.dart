import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memo/core/config/app_config.dart';
import 'package:memo/features/account/data/premium_pack_api.dart';
import 'package:memo/features/license/data/license_api.dart';

import '../../support/fake_jwt.dart';

void main() {
  final anon = fakeJwt('anon');
  final config = AppConfig.fromMap({
    'SUPABASE_URL': 'https://api.example.org',
    'SUPABASE_ANON_KEY': anon,
    'LICENSE_PUBLIC_KEYS': jsonEncode({
      'k1': base64.encode(List.filled(32, 1)),
    }),
  });

  HttpPremiumPackApi api(MockClientHandler h) =>
      HttpPremiumPackApi(config: config, client: MockClient(h));

  test('paquet gratuit : appel anonyme, version transmise', () async {
    late http.Request seen;
    final pack = await api((r) async {
      seen = r;
      return http.Response(
        jsonEncode({
          'version': 9,
          'categories': <Object>[],
          'pictograms': <Object>[],
        }),
        200,
      );
    }).fetchFree(have: 8);
    expect(pack!.version, 9);
    expect(seen.url.path, '/functions/v1/free-pack');
    expect(seen.url.queryParameters, {'have': '8'});
    expect(seen.headers['Authorization'], 'Bearer $anon');
  });

  test('paquet gratuit : à jour (204) ou absent (404) donne null', () async {
    expect(await api((_) async => http.Response('', 204)).fetchFree(), isNull);
    expect(
      await api((_) async => http.Response('{}', 404)).fetchFree(),
      isNull,
    );
  });

  test("image gratuite introuvable : erreur, pas d'octets vides", () async {
    await expectLater(
      api((_) async => http.Response('{}', 404)).fetchFreeImage('a' * 64),
      throwsA(
        isA<LicenseApiException>().having(
          (e) => e.error,
          'error',
          LicenseApiError.server,
        ),
      ),
    );
  });
}
