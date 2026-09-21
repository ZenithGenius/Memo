import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/caregiver/domain/caregiver_pin_service.dart';

final caregiverPinServiceProvider = Provider<CaregiverPinService>(
  (ref) => throw UnimplementedError('à surcharger au démarrage'),
);

/// Session accompagnant : `true` tant que le mode est déverrouillé.
/// Elle se verrouille seule après [idleTimeout] sans action protégée, pour
/// qu'un appareil laissé ouvert ne reste pas modifiable.
class CaregiverSession extends Notifier<bool> {
  static const idleTimeout = Duration(minutes: 5);

  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(() => _timer?.cancel());
    return false;
  }

  void unlock() {
    state = true;
    _restart();
  }

  void lock() {
    _timer?.cancel();
    state = false;
  }

  /// Repousse le verrouillage automatique : à appeler à chaque action protégée.
  void touch() {
    if (state) _restart();
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer(idleTimeout, lock);
  }
}

final caregiverSessionProvider = NotifierProvider<CaregiverSession, bool>(
  CaregiverSession.new,
);
