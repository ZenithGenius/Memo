import 'package:flutter/material.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Genre de la personne, facultatif : il choisit l'image des pictogrammes
/// qui représentent une personne (#19). Fille ou garçon pour un enfant ou un
/// adolescent, femme ou homme sinon.
class GenderChoice extends StatelessWidget {
  const GenderChoice({
    required this.type,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ProfileType? type;
  final Gender value;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final young = type == ProfileType.child || type == ProfileType.teen;
    final labels = {
      Gender.feminine: young ? l10n.genderGirl : l10n.genderWoman,
      Gender.masculine: young ? l10n.genderBoy : l10n.genderMan,
      Gender.unspecified: l10n.genderUnspecified,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.genderLabel.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final MapEntry(key: gender, value: label) in labels.entries)
              ChoiceChip(
                label: Text(label),
                selected: value == gender,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) => onChanged(gender),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.genderHint,
          style: const TextStyle(color: AppColors.mutedText),
        ),
      ],
    );
  }
}
