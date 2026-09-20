import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(activeProfileProvider).value;
    String label(Level l) => switch (l) {
      Level.beginner => l10n.levelBeginner,
      Level.intermediate => l10n.levelIntermediate,
      Level.advanced => l10n.levelAdvanced,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: profile == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.levelSetting,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                RadioGroup<Level>(
                  groupValue: profile.level,
                  onChanged: (l) {
                    if (l == null) return;
                    ref.read(profileRepositoryProvider).setLevel(profile.id, l);
                  },
                  child: Column(
                    children: [
                      for (final l in Level.values)
                        RadioListTile<Level>(value: l, title: Text(label(l))),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
