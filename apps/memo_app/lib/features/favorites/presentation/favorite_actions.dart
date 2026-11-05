import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/core/ui/action_feedback.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Ajoute ou retire un favori du profil actif, avec un retour visible et une
/// vibration légère : sans eux, l'appui long ne semble rien faire. Le message
/// propose d'annuler, un appui long accidentel étant fréquent.
Future<void> toggleFavorite(
  BuildContext context,
  WidgetRef ref,
  Pictogram pictogram, {
  required bool isFavorite,
}) async {
  final profile = ref.read(activeProfileProvider).value;
  if (profile == null) return;
  final l10n = AppLocalizations.of(context);
  final repository = ref.read(favoritesRepositoryProvider);

  await repository.toggle(profile.id, pictogram.id);
  if (!context.mounted) return;
  confirmAction(
    context,
    ref,
    isFavorite
        ? l10n.favoriteRemoved(pictogram.label)
        : l10n.favoriteAdded(pictogram.label),
    action: SnackBarAction(
      label: l10n.cancel,
      onPressed: () => repository.toggle(profile.id, pictogram.id),
    ),
  );
}
