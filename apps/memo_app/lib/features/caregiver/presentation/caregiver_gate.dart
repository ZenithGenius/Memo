import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/caregiver/presentation/caregiver_providers.dart';
import 'package:memo/features/caregiver/presentation/pin_sheet.dart';

/// À appeler avant toute action réservée à l'accompagnant (niveau, tableau,
/// phrases personnelles, profils). Retourne `true` si l'action peut se faire :
/// mode déjà déverrouillé, ou code saisi avec succès.
Future<bool> requireCaregiver(BuildContext context, WidgetRef ref) async {
  final session = ref.read(caregiverSessionProvider.notifier);
  if (ref.read(caregiverSessionProvider)) {
    session.touch();
    return true;
  }
  final unlocked = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const PinSheet(),
  );
  return unlocked ?? false;
}
