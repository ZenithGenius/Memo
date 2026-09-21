import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Signe un jeton comme le fera le serveur : `base64url(charge).base64url(signature)`.
Future<String> signToken(
  SimpleKeyPair key, {
  String kid = 'k1',
  String device = 'dev-A',
  required DateTime issuedAt,
  required DateTime validUntil,
  String sub = 'user-1',
  String plan = 'essentiel',
}) async {
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'sub': sub,
        'plan': plan,
        'iat': issuedAt.millisecondsSinceEpoch ~/ 1000,
        'exp': validUntil.millisecondsSinceEpoch ~/ 1000,
        'dev': device,
        'kid': kid,
      }),
    ),
  );
  final sig = await Ed25519().sign(utf8.encode(payload), keyPair: key);
  return '$payload.${base64Url.encode(sig.bytes)}';
}
