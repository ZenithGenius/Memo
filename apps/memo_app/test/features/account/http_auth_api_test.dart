import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memo/core/config/app_config.dart';
import 'package:memo/features/account/data/auth_api.dart';

import '../../support/fake_jwt.dart';

void main() {
  final config = AppConfig.fromMap({
    'SUPABASE_URL': 'https://api.example.org',
    'SUPABASE_ANON_KEY': fakeJwt('anon'),
    'LICENSE_PUBLIC_KEYS': jsonEncode({
      'k1': base64.encode(List.filled(32, 1)),
    }),
  });

  HttpAuthApi api(MockClientHandler h) =>
      HttpAuthApi(config: config, client: MockClient(h));

  Future<AuthError> errorOf(Future<void> f) async {
    try {
      await f;
    } on AuthException catch (e) {
      return e.error;
    }
    fail('aucune erreur');
  }

  test('connexion : bonne route, clé publique, session lue', () async {
    late http.Request seen;
    final s = await api((r) async {
      seen = r;
      return http.Response(
        jsonEncode({
          'access_token': 'a',
          'refresh_token': 'r',
          'user': {'email': 'amina@example.org'},
        }),
        200,
      );
    }).signIn('amina@example.org', 'pw');
    expect(seen.url.path, '/auth/v1/token');
    expect(seen.url.queryParameters['grant_type'], 'password');
    expect(seen.headers['apikey'], config.supabaseAnonKey);
    expect(s.accessToken, 'a');
    expect(s.refreshToken, 'r');
    expect(s.email, 'amina@example.org');
  });

  test('erreurs de connexion et d\'inscription typées', () async {
    http.Response r(int code, Map<String, Object?> b) =>
        http.Response(jsonEncode(b), code);
    expect(
      await errorOf(
        api(
          (_) async => r(400, {'error_code': 'invalid_credentials'}),
        ).signIn('a@b', 'x'),
      ),
      AuthError.invalidCredentials,
    );
    expect(
      await errorOf(
        api(
          (_) async => r(422, {'error_code': 'user_already_exists'}),
        ).signUp('a@b', 'x'),
      ),
      AuthError.emailTaken,
    );
    expect(
      await errorOf(
        api(
          (_) async => r(422, {'error_code': 'weak_password'}),
        ).signUp('a@b', 'x'),
      ),
      AuthError.weakPassword,
    );
    expect(
      await errorOf(
        api(
          (_) async => r(200, {'id': 'u', 'email': 'a@b'}),
        ).signUp('a@b', 'x'),
      ),
      AuthError.confirmationRequired,
    );
    expect(
      await errorOf(
        api((_) async => r(400, {'error': 'invalid_grant'})).refresh('old'),
      ),
      AuthError.sessionExpired,
    );
    expect(
      await errorOf(
        api((_) async => http.Response('<html>', 502)).signIn('a@b', 'x'),
      ),
      AuthError.server,
    );
    expect(
      await errorOf(
        api((_) async => throw http.ClientException('x')).signIn('a@b', 'x'),
      ),
      AuthError.offline,
    );
  });
}
