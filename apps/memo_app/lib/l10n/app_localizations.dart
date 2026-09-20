import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Memo'**
  String get appName;

  /// No description provided for @homeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Memo'**
  String get homeTitle;

  /// No description provided for @messageEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Touchez un pictogramme pour commencer'**
  String get messageEmptyHint;

  /// No description provided for @speakButton.
  ///
  /// In fr, this message translates to:
  /// **'Lire le message'**
  String get speakButton;

  /// No description provided for @clearButton.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get clearButton;

  /// No description provided for @removeItem.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {label}'**
  String removeItem(String label);

  /// No description provided for @settingsTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTooltip;

  /// No description provided for @favoritesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes favoris'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez longuement sur un pictogramme pour l\'ajouter à vos favoris'**
  String get favoritesEmpty;

  /// No description provided for @boardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon tableau'**
  String get boardTitle;

  /// No description provided for @boardEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le tableau'**
  String get boardEdit;

  /// No description provided for @boardDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get boardDone;

  /// No description provided for @boardEmptyCell.
  ///
  /// In fr, this message translates to:
  /// **'Case vide'**
  String get boardEmptyCell;

  /// No description provided for @boardClearCell.
  ///
  /// In fr, this message translates to:
  /// **'Vider la case'**
  String get boardClearCell;

  /// No description provided for @noVoiceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Voix française introuvable'**
  String get noVoiceTitle;

  /// No description provided for @noVoiceBody.
  ///
  /// In fr, this message translates to:
  /// **'Installez une voix française dans les réglages de synthèse vocale du téléphone pour entendre les messages sans connexion.'**
  String get noVoiceBody;

  /// No description provided for @onboardingWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans Memo'**
  String get onboardingWelcome;

  /// No description provided for @onboardingWho.
  ///
  /// In fr, this message translates to:
  /// **'Qui va utiliser Memo ?'**
  String get onboardingWho;

  /// No description provided for @profileChild.
  ///
  /// In fr, this message translates to:
  /// **'Enfant'**
  String get profileChild;

  /// No description provided for @profileTeen.
  ///
  /// In fr, this message translates to:
  /// **'Adolescent'**
  String get profileTeen;

  /// No description provided for @profileAdult.
  ///
  /// In fr, this message translates to:
  /// **'Adulte'**
  String get profileAdult;

  /// No description provided for @profileCaregiver.
  ///
  /// In fr, this message translates to:
  /// **'Accompagnant'**
  String get profileCaregiver;

  /// No description provided for @onboardingLevel.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un niveau'**
  String get onboardingLevel;

  /// No description provided for @levelBeginner.
  ///
  /// In fr, this message translates to:
  /// **'Débutant'**
  String get levelBeginner;

  /// No description provided for @levelIntermediate.
  ///
  /// In fr, this message translates to:
  /// **'Intermédiaire'**
  String get levelIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In fr, this message translates to:
  /// **'Avancé'**
  String get levelAdvanced;

  /// No description provided for @onboardingStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingStart;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// No description provided for @levelSetting.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get levelSetting;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
