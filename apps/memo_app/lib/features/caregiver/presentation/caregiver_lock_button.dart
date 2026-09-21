import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/caregiver/presentation/caregiver_gate.dart';
import 'package:memo/features/caregiver/presentation/caregiver_providers.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Verrou de l'en-tête : toujours visible (jamais un geste caché), il montre
/// si le mode accompagnant est actif et permet de le verrouiller.
class CaregiverLockButton extends ConsumerWidget {
  const CaregiverLockButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unlocked = ref.watch(caregiverSessionProvider);
    return IconButton(
      tooltip: unlocked ? l10n.caregiverModeUnlocked : l10n.caregiverModeLocked,
      isSelected: unlocked,
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: AppColors.charcoal,
        backgroundColor: unlocked ? AppColors.terracotta : null,
        side: const BorderSide(color: AppColors.charcoal, width: 2),
      ),
      icon: const Icon(Icons.lock_outline),
      selectedIcon: const Icon(Icons.lock_open, color: Colors.white),
      onPressed: () {
        if (unlocked) {
          ref.read(caregiverSessionProvider.notifier).lock();
        } else {
          requireCaregiver(context, ref);
        }
      },
    );
  }
}
