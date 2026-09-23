import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:memo/core/config/app_config.dart';

enum AuthError {
  invalidCredentials,
  emailTaken,
  weakPassword,
  confirmationRequired,
  sessionExpired,
  offline,
  server,
}

class AuthException implements Exception {
  const AuthException(this.error);
  final AuthError error;

  @override
  String toString() => 'AuthException(${error.name})';
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.email,
  });

  final String accessToken;
  final String refreshToken;
  final String email;
}

abstract interface class AuthApi {
  Future<AuthSession> signIn(String email, String password);
  Future<AuthSession> signUp(String email, String password);
  Future<AuthSession> refresh(String refreshToken);
}

/// Authentification Supabase (GoTrue) par appels HTTP directs.
class HttpAuthApi implements AuthApi {
  HttpAuthApi({
    required this.config,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  final AppConfig config;
  final Duration timeout;
  final http.Client _client;

  @override
  Future<AuthSession> signIn(String email, String password) => _post(
    '/auth/v1/token?grant_type=password',
    {'email': email, 'password': password},
  );

  @override
  Future<AuthSession> signUp(String email, String password) =>
      _post('/auth/v1/signup', {'email': email, 'password': password});

  @override
  Future<AuthSession> refresh(String refreshToken) => _post(
    '/auth/v1/token?grant_type=refresh_token',
    {'refresh_token': refreshToken},
    refreshing: true,
  );

  Future<AuthSession> _post(
    String path,
    Map<String, String> body, {
    bool refreshing = false,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            config.supabaseUrl.resolve(path),
            headers: {
              'apikey': config.supabaseAnonKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on http.ClientException {
      throw const AuthException(AuthError.offline);
    } on SocketException {
      throw const AuthException(AuthError.offline);
    } on TimeoutException {
      throw const AuthException(AuthError.offline);
    }

    final Map<String, Object?> json;
    try {
      json = jsonDecode(response.body) as Map<String, Object?>;
    } on Object {
      throw const AuthException(AuthError.server);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final access = json['access_token'];
      // Inscription avec confirmation d'e-mail : pas encore de session.
      if (access is! String) {
        throw const AuthException(AuthError.confirmationRequired);
      }
      final user = json['user'] as Map<String, Object?>?;
      return AuthSession(
        accessToken: access,
        refreshToken: json['refresh_token']! as String,
        email: (user?['email'] as String?) ?? body['email'] ?? '',
      );
    }

    final code = '${json['error_code'] ?? json['error'] ?? ''}';
    if (refreshing) throw const AuthException(AuthError.sessionExpired);
    if (code.contains('already') || code == 'email_exists') {
      throw const AuthException(AuthError.emailTaken);
    }
    if (code.contains('weak_password')) {
      throw const AuthException(AuthError.weakPassword);
    }
    if (response.statusCode == 400 || code == 'invalid_credentials') {
      throw const AuthException(AuthError.invalidCredentials);
    }
    throw const AuthException(AuthError.server);
  }
}
