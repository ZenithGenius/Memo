/// Temps utilisé pour comparer à la fin de période payée (ADR-008, couche 4).
///
/// L'horloge murale seule est réglable par l'utilisateur. On y ajoute le plus
/// grand instant jamais observé, la dernière date de confiance reçue du
/// serveur, et l'horloge monotone du système (non réglable) tant que le
/// démarrage n'a pas changé.
class TrustedTime {
  const TrustedTime({required this.time, required this.tampered});
  final DateTime time;

  /// Vrai si l'horloge murale a reculé de plus de [TrustedClock.tolerance].
  /// Reste vrai jusqu'à la prochaine synchronisation ([TrustedClock.anchor]).
  final bool tampered;
}

class ClockState {
  const ClockState({
    required this.maxObserved,
    required this.tampered,
    this.anchorTime,
    this.anchorElapsedMs,
    this.anchorBootId,
  });

  final DateTime maxObserved;
  final bool tampered;
  final DateTime? anchorTime;
  final int? anchorElapsedMs;
  final String? anchorBootId;
}

/// Stockage protégé de l'état de l'horloge. L'implémentation de production
/// devra le signer avec une clé matérielle (Keystore, Keychain).
abstract interface class ClockStateStore {
  Future<ClockState?> read();
  Future<void> write(ClockState state);
}

class InMemoryClockStateStore implements ClockStateStore {
  ClockState? _state;

  @override
  Future<ClockState?> read() async => _state;

  @override
  Future<void> write(ClockState state) async => _state = state;
}

class TrustedClock {
  TrustedClock({
    required this.store,
    required this.wallNow,
    required this.elapsedMs,
    required this.bootId,
  });

  static const tolerance = Duration(hours: 24);

  final ClockStateStore store;
  final DateTime Function() wallNow;

  /// Horloge monotone : millisecondes écoulées depuis le démarrage.
  final int Function() elapsedMs;

  /// Identifiant du démarrage courant (change à chaque redémarrage).
  final String Function() bootId;

  Future<TrustedTime> now() async {
    final wall = wallNow();
    final state = await store.read();

    var effective = wall;
    var tampered = state?.tampered ?? false;

    if (state != null) {
      if (state.maxObserved.isAfter(effective)) effective = state.maxObserved;
      if (wall.isBefore(state.maxObserved.subtract(tolerance))) {
        tampered = true;
      }
      final anchor = state.anchorTime;
      if (anchor != null) {
        if (anchor.isAfter(effective)) effective = anchor;
        if (state.anchorBootId == bootId() && state.anchorElapsedMs != null) {
          final advanced = anchor.add(
            Duration(milliseconds: elapsedMs() - state.anchorElapsedMs!),
          );
          if (advanced.isAfter(effective)) effective = advanced;
        }
      }
    }

    await store.write(
      ClockState(
        maxObserved: effective,
        tampered: tampered,
        anchorTime: state?.anchorTime,
        anchorElapsedMs: state?.anchorElapsedMs,
        anchorBootId: state?.anchorBootId,
      ),
    );
    return TrustedTime(time: effective, tampered: tampered);
  }

  /// Enregistre une date de confiance reçue du serveur. Elle fait foi : elle
  /// remplace le plus grand instant observé et lève le drapeau de suspicion.
  Future<void> anchor(DateTime serverTime) => store.write(
    ClockState(
      maxObserved: serverTime,
      tampered: false,
      anchorTime: serverTime,
      anchorElapsedMs: elapsedMs(),
      anchorBootId: bootId(),
    ),
  );
}
