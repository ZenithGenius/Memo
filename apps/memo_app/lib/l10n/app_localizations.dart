import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

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

  /// No description provided for @messageItemAdded.
  ///
  /// In fr, this message translates to:
  /// **'{label} ajouté'**
  String messageItemAdded(String label);

  /// No description provided for @messageFull.
  ///
  /// In fr, this message translates to:
  /// **'Le message est plein'**
  String get messageFull;

  /// No description provided for @startupFailedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de démarrer Memo'**
  String get startupFailedTitle;

  /// No description provided for @startupFailedBody.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue au chargement des données. Fermez puis rouvrez l\'application. Si le problème continue, contactez le support.'**
  String get startupFailedBody;

  /// No description provided for @startupFailedClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get startupFailedClose;

  /// No description provided for @phrasesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dis-le maintenant'**
  String get phrasesTitle;

  /// No description provided for @phrasesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune phrase pour le moment'**
  String get phrasesEmpty;

  /// No description provided for @phraseSpeak.
  ///
  /// In fr, this message translates to:
  /// **'Dire : {text}'**
  String phraseSpeak(String text);

  /// No description provided for @levelNoteBeginner.
  ///
  /// In fr, this message translates to:
  /// **'Très grandes tuiles, peu de mots à l\'écran, étiquettes agrandies'**
  String get levelNoteBeginner;

  /// No description provided for @levelNoteIntermediate.
  ///
  /// In fr, this message translates to:
  /// **'Tuiles moyennes, vocabulaire élargi'**
  String get levelNoteIntermediate;

  /// No description provided for @levelNoteAdvanced.
  ///
  /// In fr, this message translates to:
  /// **'Tuiles denses, tout le vocabulaire'**
  String get levelNoteAdvanced;

  /// No description provided for @settingsSpeech.
  ///
  /// In fr, this message translates to:
  /// **'Lecture'**
  String get settingsSpeech;

  /// No description provided for @settingsSpeakEachWord.
  ///
  /// In fr, this message translates to:
  /// **'Prononcer chaque mot touché'**
  String get settingsSpeakEachWord;

  /// No description provided for @settingsSpeakEachWordNote.
  ///
  /// In fr, this message translates to:
  /// **'Un retour immédiat, avant même que la phrase soit composée'**
  String get settingsSpeakEachWordNote;

  /// No description provided for @settingsDevice.
  ///
  /// In fr, this message translates to:
  /// **'Appareil'**
  String get settingsDevice;

  /// No description provided for @settingsHaptics.
  ///
  /// In fr, this message translates to:
  /// **'Vibrations'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsNote.
  ///
  /// In fr, this message translates to:
  /// **'À couper pour économiser la batterie'**
  String get settingsHapticsNote;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @wordsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mots'**
  String get wordsTitle;

  /// No description provided for @wordsThisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get wordsThisWeek;

  /// No description provided for @wordsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'a encore été dit cette semaine'**
  String get wordsEmpty;

  /// No description provided for @wordsSentences.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune phrase dite} =1{1 phrase dite} other{{count} phrases dites}}'**
  String wordsSentences(int count);

  /// No description provided for @wordsNew.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{aucun nouveau mot} =1{1 nouveau mot} other{{count} nouveaux mots}}'**
  String wordsNew(int count);

  /// No description provided for @wordsTimes.
  ///
  /// In fr, this message translates to:
  /// **'{label}, {count, plural, =1{1 fois} other{{count} fois}}'**
  String wordsTimes(String label, int count);

  /// No description provided for @navTalk.
  ///
  /// In fr, this message translates to:
  /// **'Parler'**
  String get navTalk;

  /// No description provided for @navPhrases.
  ///
  /// In fr, this message translates to:
  /// **'Phrases'**
  String get navPhrases;

  /// No description provided for @navWords.
  ///
  /// In fr, this message translates to:
  /// **'Mots'**
  String get navWords;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get navSettings;

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
  /// **'Voix {language} introuvable'**
  String noVoiceTitle(String language);

  /// No description provided for @noVoiceBody.
  ///
  /// In fr, this message translates to:
  /// **'Installez une voix {language} dans les réglages de synthèse vocale du téléphone pour entendre les messages sans connexion.'**
  String noVoiceBody(String language);

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

  /// No description provided for @voiceLanguage.
  ///
  /// In fr, this message translates to:
  /// **'{lang, select, en{anglaise} other{française}}'**
  String voiceLanguage(String lang);

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSwitchTo.
  ///
  /// In fr, this message translates to:
  /// **'Passer en {language}'**
  String languageSwitchTo(String language);

  /// No description provided for @languageName.
  ///
  /// In fr, this message translates to:
  /// **'{lang, select, en{anglais} other{français}}'**
  String languageName(String lang);
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
