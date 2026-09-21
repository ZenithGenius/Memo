import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Ajoute un pictogramme au message avec un retour tactile, et une annonce
/// pour les lecteurs d'écran (l'ajout n'est sinon visible qu'à l'écran).
void addToMessage(BuildContext context, WidgetRef ref, Pictogram pictogram) {
  final l10n = AppLocalizations.of(context);
  final added = ref.read(messageProvider.notifier).add(pictogram);
  if (added) {
    HapticFeedback.selectionClick();
  } else {
    HapticFeedback.heavyImpact();
  }
  SemanticsService.sendAnnouncement(
    View.of(context),
    added ? l10n.messageItemAdded(pictogram.label) : l10n.messageFull,
    Directionality.of(context),
  );
}
