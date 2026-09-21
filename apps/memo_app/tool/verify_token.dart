// Vérifie un jeton de licence avec le vérificateur de l'application.
// Usage : dart run tool/verify_token.dart <jeton> <clé publique base64> <empreinte appareil> [kid]
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:memo/features/license/domain/license_verifier.dart';

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln(
      'usage: verify_token.dart <jeton> <clé publique b64> <appareil> [kid]',
    );
    exit(64);
  }
  final kid = args.length > 3 ? args[3] : 'k1';
  final verifier = LicenseVerifier(
    publicKeys: {
      kid: SimplePublicKey(base64.decode(args[1]), type: KeyPairType.ed25519),
    },
  );
  final result = await verifier.check(
    args[0],
    deviceId: args[2],
    now: DateTime.now().toUtc(),
  );
  stdout.writeln('statut : ${result.status.name}');
  final c = result.claims;
  if (c != null) {
    stdout.writeln(
      'offre : ${c.plan}, valide jusqu\'au ${c.validUntil.toIso8601String()}',
    );
  }
  exit(result.status.grantsPremium ? 0 : 1);
}
