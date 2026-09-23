import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:memo/core/storage/secure_store.dart';

sealed class PinResult {
  const PinResult();
}

class PinAccepted extends PinResult {
  const PinAccepted();
}

class PinRejected extends PinResult {
  const PinRejected({required this.attemptsLeft});
  final int attemptsLeft;
}

class PinLocked extends PinResult {
  const PinLocked({required this.remaining});
  final Duration remaining;
}

/// Le code n'a pas quatre chiffres.
class InvalidPinException implements Exception {
  const InvalidPinException();
}

/// Le code est trop simple (chiffres identiques, suite évidente).
class WeakPinException implements Exception {
  const WeakPinException();
}

/// Code accompagnant à quatre chiffres (ADR-008 : protège le niveau, le
/// tableau, les phrases personnelles et les profils).
///
/// Le code n'est jamais stocké : seulement une empreinte salée. Un code à
/// quatre chiffres reste devinable par force brute si l'appareil est compromis,
/// c'est une barrière contre l'enfant ou l'entourage, pas contre un attaquant :
/// le vrai frein est le blocage progressif après des essais ratés.
class CaregiverPinService {
  CaregiverPinService({required SecureStore store, required this.now})
    : _store = store;

  static const maxAttempts = 5;
  static const baseLock = Duration(seconds: 30);
  static const maxLock = Duration(minutes: 15);
  static const _iterations = 10000;
  static const _weak = {'1234', '4321', '0123', '3210'};

  static const _hashKey = 'caregiver_pin_hash';
  static const _saltKey = 'caregiver_pin_salt';
  static const _stateKey = 'caregiver_pin_state';

  final SecureStore _store;
  final DateTime Function() now;

  Future<bool> get isSet async => await _store.read(_hashKey) != null;

  Future<void> setPin(String pin) async {
    if (!_isFourDigits(pin)) throw const InvalidPinException();
    if (RegExp(r'^(\d)\1{3}$').hasMatch(pin) || _weak.contains(pin)) {
      throw const WeakPinException();
    }
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    await _store.write(_saltKey, base64.encode(salt));
    await _store.write(_hashKey, base64.encode(await _derive(pin, salt)));
    await _store.delete(_stateKey);
  }

  /// Oubli du code : l'efface avec son compteur d'essais, sans toucher aux
  /// données. À n'appeler qu'après le contrôle adulte ([AdultCheck]).
  Future<void> reset() async {
    await _store.delete(_hashKey);
    await _store.delete(_saltKey);
    await _store.delete(_stateKey);
  }

  Future<PinResult> verify(String pin) async {
    final state = await _readState();
    final until = state.lockedUntil;
    if (until != null && now().isBefore(until)) {
      return PinLocked(remaining: until.difference(now()));
    }

    final hash = await _store.read(_hashKey);
    final salt = await _store.read(_saltKey);
    // Sans code défini, ou de forme invalide : refus qui ne compte pas comme
    // un essai (on n'a rien deviné).
    if (hash == null || salt == null || !_isFourDigits(pin)) {
      return PinRejected(attemptsLeft: maxAttempts - state.failures);
    }

    final derived = await _derive(pin, base64.decode(salt));
    if (_sameBytes(derived, base64.decode(hash))) {
      await _store.delete(_stateKey);
      return const PinAccepted();
    }

    final failures = state.failures + 1;
    if (failures >= maxAttempts) {
      final lock = _lockDuration(failures);
      await _writeState(failures, now().add(lock));
      return PinLocked(remaining: lock);
    }
    await _writeState(failures, null);
    return PinRejected(attemptsLeft: maxAttempts - failures);
  }

  /// 30 s au cinquième échec, puis le double à chaque échec de plus.
  Duration _lockDuration(int failures) {
    final steps = failures - maxAttempts;
    final seconds = baseLock.inSeconds * pow(2, min(steps, 20)).toInt();
    final lock = Duration(seconds: seconds);
    return lock > maxLock ? maxLock : lock;
  }

  bool _isFourDigits(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);

  Future<List<int>> _derive(String pin, List<int> salt) async {
    final key = await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: 256,
    ).deriveKeyFromPassword(password: pin, nonce: salt);
    return key.extractBytes();
  }

  /// Comparaison en temps constant.
  bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  Future<({int failures, DateTime? lockedUntil})> _readState() async {
    final raw = await _store.read(_stateKey);
    if (raw == null) return (failures: 0, lockedUntil: null);
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      final ms = json['lockedUntilMs'] as int?;
      return (
        failures: json['failures']! as int,
        lockedUntil: ms == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
      );
    } on Object {
      // État illisible : on suppose le pire plutôt que d'effacer le compteur.
      return (failures: maxAttempts, lockedUntil: null);
    }
  }

  Future<void> _writeState(int failures, DateTime? lockedUntil) => _store.write(
    _stateKey,
    jsonEncode({
      'failures': failures,
      'lockedUntilMs': lockedUntil?.millisecondsSinceEpoch,
    }),
  );
}
