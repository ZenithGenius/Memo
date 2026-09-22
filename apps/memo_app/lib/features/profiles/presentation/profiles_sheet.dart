import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/caregiver/presentation/caregiver_gate.dart';
import 'package:memo/features/caregiver/presentation/caregiver_providers.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/features/profiles/presentation/new_profile_sheet.dart';
import 'package:memo/features/profiles/presentation/profile_avatar.dart';
import 'package:memo/features/profiles/presentation/profile_labels.dart';
import 'package:memo/features/profiles/presentation/profile_providers.dart';
import 'package:memo/l10n/app_localizations.dart';

/// « Qui parle ? » : un seul appareil, plusieurs personnes. Chaque profil
/// garde son niveau, ses favoris, son tableau, ses phrases et son historique.
/// Changer de profil ou en créer un est réservé à l'accompagnant.
class ProfilesSheet extends ConsumerWidget {
  const ProfilesSheet({super.key});

  Future<void> _switchTo(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    final active = ref.read(activeProfileProvider).asData?.value;
    if (active?.id == profile.id) {
      Navigator.of(context).pop();
      return;
    }
    if (!await requireCaregiver(context, ref)) return;
    // Le message en cours appartient à la personne précédente.
    ref.read(messageProvider.notifier).clear();
    await ref.read(profileRepositoryProvider).setActive(profile.id);
    // L'appareil va être confié à la personne : on reverrouille.
    ref.read(caregiverSessionProvider.notifier).lock();
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    if (!await requireCaregiver(context, ref)) return;
    if (!context.mounted) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const NewProfileSheet(),
    );
    if ((created ?? false) && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profiles = ref.watch(allProfilesProvider).asData?.value ?? const [];
    final activeId = ref.watch(activeProfileProvider).asData?.value?.id;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.profileSwitchTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.profileSwitchHint,
              style: const TextStyle(color: AppColors.mutedText),
            ),
            const SizedBox(height: 12),
            for (final p in profiles)
              ListTile(
                minTileHeight: 64,
                leading: ProfileAvatar(name: p.name),
                title: Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(profileMeta(l10n, p)),
                trailing: p.id == activeId
                    ? Semantics(
                        label: l10n.profileCurrent,
                        child: const Icon(
                          Icons.check_circle,
                          color: AppColors.teal,
                        ),
                      )
                    : const Icon(Icons.lock_outline, size: 18),
                onTap: () => _switchTo(context, ref, p),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _create(context, ref),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
              icon: const Icon(Icons.person_add_alt),
              label: Text(l10n.profileNew),
            ),
          ],
        ),
      ),
    );
  }
}
