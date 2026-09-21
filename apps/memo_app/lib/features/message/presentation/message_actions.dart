import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/features/settings/domain/app_settings.dart';
import 'package:memo/features/settings/presentation/settings_providers.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Ajoute un pictogramme au message.
///
/// Selon les réglages : le mot est prononcé aussitôt (retour immédiat avant
/// que la phrase existe) et l'appareil vibre. Une annonce est envoyée aux
/// lecteurs d'écran, l'ajout n'étant sinon visible qu'à l'écran.
void addToMessage(BuildContext context, WidgetRef ref, Pictogram pictogram) {
  final l10n = AppLocalizations.of(context);
  final settings =
      ref.read(appSettingsProvider).asData?.value ?? AppSettings.defaults;
  final added = ref.read(messageProvider.notifier).add(pictogram);

  if (settings.hapticsEnabled) {
    if (added) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.heavyImpact();
    }
  }
  if (added && settings.speakEachWord) {
    final language =
        ref.read(activeProfileProvider).asData?.value?.language ?? 'fr';
    ref
        .read(speechServiceProvider)
        .speak(pictogram.spokenText, language: language);
  }
  SemanticsService.sendAnnouncement(
    View.of(context),
    added ? l10n.messageItemAdded(pictogram.label) : l10n.messageFull,
    Directionality.of(context),
  );
}
