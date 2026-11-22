import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:memo/l10n/app_localizations.dart';

/// Traductions de l'application et des composants Material et Cupertino.
///
/// Les composants viennent de `material_ui` : leurs traductions aussi. La
/// liste générée par `flutter gen-l10n` (`AppLocalizations.localizationsDelegates`)
/// cite encore celles de `flutter_localizations`, d'un autre type : avec elle,
/// le français paraît non pris en charge.
const appLocalizationsDelegates = <LocalizationsDelegate<Object>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
