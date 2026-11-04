import 'package:flutter/services.dart' show appFlavor;

/// Variante `dev` (`flutter run --flavor dev`) : tout le contenu embarqué,
/// sans serveur ni compte. La variante `prod` est celle publiée.
const isDevFlavor = appFlavor == 'dev';

/// Contenu payant embarqué dans la seule variante dev (voir pubspec.yaml).
const devPremiumAsset = 'assets/content/dev/premium_pack.json';
