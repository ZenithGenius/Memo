import 'package:equatable/equatable.dart';

/// Jour au format AAAA-MM-JJ, heure locale.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class RoutineStep extends Equatable {
  const RoutineStep({required this.pictogramId, this.doneOn});

  final int pictogramId;

  /// Jour où l'étape a été cochée (voir [dayKey]).
  final String? doneOn;

  bool doneOnDay(DateTime now) => doneOn == dayKey(now);

  @override
  List<Object?> get props => [pictogramId, doneOn];
}

class Routine extends Equatable {
  const Routine({required this.id, required this.name, required this.steps});

  final int id;
  final String name;

  /// Étapes dans l'ordre.
  final List<RoutineStep> steps;

  @override
  List<Object?> get props => [id, name, steps];
}

abstract interface class RoutineRepository {
  Stream<List<Routine>> watch(int profileId);
  Future<int> create(int profileId, String name);
  Future<void> rename(int routineId, String name);
  Future<void> delete(int routineId);

  /// Remplace les étapes ; celles déjà cochées aujourd'hui le restent.
  Future<void> setSteps(int routineId, List<int> pictogramIds);

  /// Coche ou décoche l'étape pour aujourd'hui.
  Future<void> toggleStep(int routineId, int position);

  /// Décoche toutes les étapes.
  Future<void> reset(int routineId);
}
