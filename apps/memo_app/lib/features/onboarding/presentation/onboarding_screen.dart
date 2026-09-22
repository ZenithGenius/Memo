import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/features/profiles/presentation/profile_labels.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Première installation : type de profil, niveau, puis démarrage.
/// La navigation vers l'accueil est assurée par la garde du routeur
/// dès que le profil actif existe.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({this.onDone, super.key});

  final VoidCallback? onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  ProfileType? _type;
  Level? _level;
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _finish(AppLocalizations l10n) async {
    await ref
        .read(profileRepositoryProvider)
        .create(
          // Sans prénom saisi, le profil porte le nom de son type.
          name: _name.text.trim().isEmpty
              ? profileTypeLabel(l10n, _type!)
              : _name.text.trim(),
          type: _type!,
          level: _level!,
        );
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canContinue = switch (_step) {
      0 => _type != null,
      1 => _level != null,
      _ => true,
    };
    final title = switch (_step) {
      0 => l10n.onboardingWho,
      1 => l10n.onboardingLevel,
      _ => l10n.onboardingWelcome,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingWelcome)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    if (_step == 0)
                      for (final t in ProfileType.values)
                        _ChoiceCard(
                          label: profileTypeLabel(l10n, t),
                          selected: _type == t,
                          onTap: () => setState(() => _type = t),
                        ),
                    if (_step == 2)
                      TextField(
                        controller: _name,
                        maxLength: 30,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.onboardingName,
                          hintText: l10n.onboardingNameHint,
                        ),
                      ),
                    if (_step == 1)
                      for (final l in Level.values)
                        _ChoiceCard(
                          label: levelLabel(l10n, l),
                          selected: _level == l,
                          onTap: () => setState(() => _level = l),
                        ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: !canContinue
                    ? null
                    : _step < 2
                    ? () => setState(() => _step++)
                    : () => _finish(l10n),
                child: Text(_step < 2 ? l10n.next : l10n.onboardingStart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? AppColors.terracotta : AppColors.border,
              width: 2,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
