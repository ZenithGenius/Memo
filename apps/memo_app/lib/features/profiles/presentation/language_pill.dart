import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/profiles/presentation/language_actions.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Pastille FR/EN de l'en-tête : bascule toute l'interface et la voix.
class LanguagePill extends ConsumerWidget {
  const LanguagePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider).asData?.value;
    if (profile == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final next = nextLanguage(profile.language);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        label: l10n.languageSwitchTo(l10n.languageName(next)),
        excludeSemantics: true,
        child: OutlinedButton(
          onPressed: () => setProfileLanguage(ref, profile, next),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(56, 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            side: const BorderSide(color: AppColors.charcoal, width: 2),
            foregroundColor: AppColors.charcoal,
            textStyle: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          child: Text(profile.language.toUpperCase()),
        ),
      ),
    );
  }
}
