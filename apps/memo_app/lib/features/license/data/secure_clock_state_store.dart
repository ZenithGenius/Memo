import 'dart:convert';

import 'package:memo/core/storage/secure_store.dart';
import 'package:memo/features/license/domain/trusted_clock.dart';

/// État de l'horloge de confiance dans le stockage chiffré : le modifier
/// suppose un appareil compromis.
class SecureClockStateStore implements ClockStateStore {
  SecureClockStateStore(this._store);
  final SecureStore _store;

  static const _key = 'clock_state';

  @override
  Future<ClockState?> read() async {
    final raw = await _store.read(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      DateTime? time(String key) => json[key] == null
          ? null
          : DateTime.parse(json[key]! as String).toUtc();
      return ClockState(
        maxObserved: time('maxObserved')!,
        tampered: json['tampered']! as bool,
        anchorTime: time('anchorTime'),
        anchorElapsedMs: json['anchorElapsedMs'] as int?,
        anchorBootId: json['anchorBootId'] as String?,
      );
    } on Object {
      // Contenu illisible : prudence, l'horloge est considérée manipulée
      // jusqu'à la prochaine synchronisation.
      return ClockState(
        maxObserved: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        tampered: true,
      );
    }
  }

  @override
  Future<void> write(ClockState state) => _store.write(
    _key,
    jsonEncode({
      'maxObserved': state.maxObserved.toUtc().toIso8601String(),
      'tampered': state.tampered,
      'anchorTime': state.anchorTime?.toUtc().toIso8601String(),
      'anchorElapsedMs': state.anchorElapsedMs,
      'anchorBootId': state.anchorBootId,
    }),
  );
}
