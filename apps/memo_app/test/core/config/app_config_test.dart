import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/config/app_config.dart';

import '../../support/fake_jwt.dart';

final key32 = base64.encode(List.filled(32, 7));

Map<String, String> valid({Map<String, String> override = const {}}) => {
  'SUPABASE_URL': 'https://api.example.org',
  'SUPABASE_ANON_KEY': fakeJwt('anon'),
  'LICENSE_PUBLIC_KEYS': jsonEncode({'k1': key32}),
  ...override,
};

void main() {
  test('configuration valide', () {
    final c = AppConfig.fromMap(valid());
    expect(c.supabaseUrl.host, 'api.example.org');
    expect(c.licensePublicKeys.keys, ['k1']);
  });

  test('variable manquante : message qui nomme la variable', () {
    final m = valid()..remove('SUPABASE_URL');
    expect(
      () => AppConfig.fromMap(m),
      throwsA(
        isA<ConfigException>().having(
          (e) => e.message,
          'message',
          contains('SUPABASE_URL'),
        ),
      ),
    );
  });

  test(
    'HTTP refusé par défaut, autorisé explicitement pour le développement',
    () {
      final m = valid(override: {'SUPABASE_URL': 'http://10.0.2.2:54321'});
      expect(() => AppConfig.fromMap(m), throwsA(isA<ConfigException>()));
      expect(
        AppConfig.fromMap(m, allowInsecureHttp: true).supabaseUrl.scheme,
        'http',
      );
    },
  );

  test("une clé service_role n'a rien à faire dans l'application", () {
    final m = valid(override: {'SUPABASE_ANON_KEY': fakeJwt('service_role')});
    expect(
      () => AppConfig.fromMap(m),
      throwsA(
        isA<ConfigException>().having(
          (e) => e.message,
          'message',
          contains('service_role'),
        ),
      ),
    );
  });

  test('clé publique de licence : 32 octets exactement', () {
    final short = base64.encode(List.filled(16, 1));
    final m = valid(
      override: {
        'LICENSE_PUBLIC_KEYS': jsonEncode({'k1': short}),
      },
    );
    expect(() => AppConfig.fromMap(m), throwsA(isA<ConfigException>()));
  });

  test('au plus deux clés publiques (rotation)', () {
    final m = valid(
      override: {
        'LICENSE_PUBLIC_KEYS': jsonEncode({
          'k1': key32,
          'k2': key32,
          'k3': key32,
        }),
      },
    );
    expect(() => AppConfig.fromMap(m), throwsA(isA<ConfigException>()));
  });

  test('JSON de clés illisible', () {
    final m = valid(override: {'LICENSE_PUBLIC_KEYS': '{pas du json'});
    expect(() => AppConfig.fromMap(m), throwsA(isA<ConfigException>()));
  });

  test("le message d'erreur ne révèle pas les valeurs", () {
    final secret = fakeJwt('service_role');
    try {
      AppConfig.fromMap(valid(override: {'SUPABASE_ANON_KEY': secret}));
      fail('aurait dû échouer');
    } on ConfigException catch (e) {
      expect(e.message.contains(secret), isFalse);
    }
  });
}
