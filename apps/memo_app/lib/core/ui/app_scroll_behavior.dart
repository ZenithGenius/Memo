import 'package:flutter/material.dart';

/// Défilement sans effet élastique : ni étirement (Material 3 sur Android),
/// ni halo, ni rebond. Pour une grille de symboles, les tuiles déformées au
/// dépassement gênent le repérage et le ciblage.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
