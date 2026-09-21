import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/settings/domain/app_settings.dart';
import 'package:memo/features/settings/presentation/settings_providers.dart';
import 'package:memo/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(activeProfileProvider).value;
    final settings =
        ref.watch(appSettingsProvider).asData?.value ?? AppSettings.defaults;
    final repo = ref.read(settingsRepositoryProvider);

    String levelName(Level l) => switch (l) {
      Level.beginner => l10n.levelBeginner,
      Level.intermediate => l10n.levelIntermediate,
      Level.advanced => l10n.levelAdvanced,
    };
    String levelNote(Level l) => switch (l) {
      Level.beginner => l10n.levelNoteBeginner,
      Level.intermediate => l10n.levelNoteIntermediate,
      Level.advanced => l10n.levelNoteAdvanced,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (profile != null) ...[
            _Section(l10n.levelSetting),
            SegmentedButton<Level>(
              segments: [
                for (final l in Level.values)
                  ButtonSegment(value: l, label: Text(levelName(l))),
              ],
              selected: {profile.level},
              showSelectedIcon: false,
              onSelectionChanged: (s) => ref
                  .read(profileRepositoryProvider)
                  .setLevel(profile.id, s.single),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                levelNote(profile.level),
                style: const TextStyle(color: AppColors.mutedText),
              ),
            ),
          ],
          _Section(l10n.settingsSpeech),
          SwitchListTile(
            value: settings.speakEachWord,
            onChanged: (v) => repo.setSpeakEachWord(value: v),
            title: Text(l10n.settingsSpeakEachWord),
            subtitle: Text(l10n.settingsSpeakEachWordNote),
          ),
          _Section(l10n.settingsDevice),
          SwitchListTile(
            value: settings.hapticsEnabled,
            onChanged: (v) => repo.setHapticsEnabled(value: v),
            title: Text(l10n.settingsHaptics),
            subtitle: Text(l10n.settingsHapticsNote),
          ),
          _Section(l10n.settingsLanguage),
          if (profile != null)
            RadioGroup<String>(
              groupValue: profile.language,
              onChanged: (language) {
                if (language == null || language == profile.language) return;
                // Un message composé dans l'autre langue n'aurait plus de sens.
                ref.read(messageProvider.notifier).clear();
                ref
                    .read(profileRepositoryProvider)
                    .setLanguage(profile.id, language);
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'fr',
                    title: Text(l10n.languageFrench),
                  ),
                  RadioListTile<String>(
                    value: 'en',
                    title: Text(l10n.languageEnglish),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.mutedText,
      ),
    ),
  );
}
