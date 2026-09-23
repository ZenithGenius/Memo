import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/caregiver/domain/adult_check.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Se ferme avec `true` si la personne résout l'addition.
class AdultCheckDialog extends StatefulWidget {
  const AdultCheckDialog({this.check, super.key});

  /// Question imposée (tests) ; sinon tirée au hasard.
  final AdultCheck? check;

  @override
  State<AdultCheckDialog> createState() => _AdultCheckDialogState();
}

class _AdultCheckDialogState extends State<AdultCheckDialog> {
  late AdultCheck _check = widget.check ?? AdultCheck.random();
  final _answer = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _submit() {
    if (_check.accepts(_answer.text)) {
      Navigator.of(context).pop(true);
      return;
    }
    // Nouvelle question à chaque erreur : pas d'essais au hasard sur la même.
    setState(() {
      _check = AdultCheck.random();
      _answer.clear();
      _wrong = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return AlertDialog(
      title: Text(l10n.adultCheckTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.adultCheckHint),
          const SizedBox(height: 8),
          Text(
            _check.question(lang),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          TextField(
            controller: _answer,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 3,
            decoration: InputDecoration(labelText: l10n.adultCheckAnswer),
            onSubmitted: (_) => _submit(),
          ),
          if (_wrong)
            Text(
              l10n.adultCheckWrong,
              style: const TextStyle(color: Color(0xFFB3261E)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.charcoal),
          onPressed: _submit,
          child: Text(l10n.adultCheckContinue),
        ),
      ],
    );
  }
}
