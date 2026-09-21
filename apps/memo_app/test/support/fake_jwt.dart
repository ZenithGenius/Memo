import 'dart:convert';

/// Faux JWT construit à l'exécution pour les tests : rien de secret n'est
/// écrit dans le dépôt, ce qui évite aussi les faux positifs du scan de secrets.
String fakeJwt(String role) {
  String enc(Map<String, Object?> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${enc({'alg': 'HS256'})}.${enc({'role': role})}.signature';
}
