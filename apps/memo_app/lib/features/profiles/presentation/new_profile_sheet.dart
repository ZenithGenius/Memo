import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/caregiver/presentation/caregiver_providers.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/profiles/domain/profile.dart';
import 'package:memo/features/profiles/presentation/profile_labels.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Nouvelle personne : prénom, type de profil et niveau de départ.
class NewProfileSheet extends ConsumerStatefulWidget {
  const NewProfileSheet({super.key});

  @override
  ConsumerState<NewProfileSheet> createState() => _NewProfileSheetState();
}

class _NewProfileSheetState extends ConsumerState<NewProfileSheet> {
  static const _maxName = 30;

  final _name = TextEditingController();
  ProfileType _type = ProfileType.child;
  Level _level = Level.beginner;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty;

  Future<void> _create() async {
    setState(() => _saving = true);
    final language =
        ref.read(activeProfileProvider).asData?.value?.language ?? 'fr';
    ref.read(messageProvider.notifier).clear();
    await ref
        .read(profileRepositoryProvider)
        .create(
          name: _name.text.trim(),
          type: _type,
          level: _level,
          language: language,
        );
    ref.read(caregiverSessionProvider.notifier).lock();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.profileNew,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: _maxName,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.profileNameLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in ProfileType.values)
                  ChoiceChip(
                    label: Text(profileTypeLabel(l10n, t)),
                    selected: _type == t,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.levelSetting.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<Level>(
              segments: [
                for (final l in Level.values)
                  ButtonSegment(value: l, label: Text(levelLabel(l10n, l))),
              ],
              selected: {_level},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _level = s.single),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _valid && !_saving ? _create : null,
              child: Text(l10n.profileCreate),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
