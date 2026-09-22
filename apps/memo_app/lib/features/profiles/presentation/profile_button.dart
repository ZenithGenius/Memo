import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/profiles/presentation/profile_avatar.dart';
import 'package:memo/features/profiles/presentation/profile_labels.dart';
import 'package:memo/features/profiles/presentation/profiles_sheet.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Profil actif dans l'en-tête : un toucher ouvre « Qui parle ? ».
class ProfileButton extends ConsumerWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider).asData?.value;
    final l10n = AppLocalizations.of(context);
    if (profile == null) return Text(l10n.homeTitle);
    return Semantics(
      button: true,
      label: l10n.profileButtonSemantics(profile.name),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const ProfilesSheet(),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              ProfileAvatar(name: profile.name),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      profileMeta(l10n, profile).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.5,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
