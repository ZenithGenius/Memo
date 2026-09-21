import 'package:flutter/widgets.dart';
import 'package:memo/features/catalog/domain/catalog.dart';

/// Grille des pictogrammes selon le niveau de l'utilisateur.
///
/// Débutant : peu de symboles, grands. Avancé : plus de symboles, plus
/// petits. La largeur maximale d'une tuile fait aussi adapter le nombre de
/// colonnes à la taille de l'écran (téléphone, tablette).
SliverGridDelegate adaptiveGridDelegate(Level level) =>
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxTileExtent(level),
      mainAxisSpacing: gridSpacing,
      crossAxisSpacing: gridSpacing,
    );

const double gridSpacing = 12;

double maxTileExtent(Level level) => switch (level) {
  Level.beginner => 220,
  Level.intermediate => 150,
  Level.advanced => 110,
};
