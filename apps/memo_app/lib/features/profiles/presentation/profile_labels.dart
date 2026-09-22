import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/l10n/app_localizations.dart';

String profileTypeLabel(AppLocalizations l10n, ProfileType type) =>
    switch (type) {
      ProfileType.child => l10n.profileChild,
      ProfileType.teen => l10n.profileTeen,
      ProfileType.adult => l10n.profileAdult,
      ProfileType.caregiver => l10n.profileCaregiver,
    };

String levelLabel(AppLocalizations l10n, Level level) => switch (level) {
  Level.beginner => l10n.levelBeginner,
  Level.intermediate => l10n.levelIntermediate,
  Level.advanced => l10n.levelAdvanced,
};

/// « Enfant · Débutant » : ce qui distingue les profils de même nom.
String profileMeta(AppLocalizations l10n, Profile profile) =>
    '${profileTypeLabel(l10n, profile.type)} · '
    '${levelLabel(l10n, profile.level)}';
