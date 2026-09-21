import 'package:flutter/material.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Quatre pastilles : remplies pour chaque chiffre saisi.
class PinDots extends StatelessWidget {
  const PinDots({required this.filled, super.key});

  final int filled;

  static const length = 4;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < length; i++)
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? AppColors.charcoal : Colors.transparent,
              border: Border.all(color: AppColors.charcoal, width: 2),
            ),
          ),
      ],
    );
  }
}

/// Pavé numérique aux grandes touches (au moins 64 sur 64).
class PinPad extends StatelessWidget {
  const PinPad({
    required this.onDigit,
    required this.onDelete,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget key(String digit) => _Key(
      label: digit,
      semanticLabel: l10n.pinDigit(digit),
      onTap: enabled ? () => onDigit(digit) : null,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in row) key(d)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: _Key.size + 8),
            key('0'),
            _Key(
              icon: Icons.backspace_outlined,
              semanticLabel: l10n.pinDelete,
              onTap: enabled ? onDelete : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, required this.semanticLabel, this.onTap});

  static const size = 64.0;

  final String? label;
  final IconData? icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: semanticLabel,
        excludeSemantics: true,
        child: Material(
          color: AppColors.card,
          shape: CircleBorder(
            side: BorderSide(
              color: onTap == null
                  ? AppColors.border
                  : AppColors.charcoal.withValues(alpha: 0.4),
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: label != null
                    ? Text(
                        label!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Icon(icon, size: 26),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
