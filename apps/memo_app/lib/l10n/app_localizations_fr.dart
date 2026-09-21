// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Memo';

  @override
  String get homeTitle => 'Memo';

  @override
  String get messageEmptyHint => 'Touchez un pictogramme pour commencer';

  @override
  String get speakButton => 'Lire le message';

  @override
  String get clearButton => 'Effacer';

  @override
  String removeItem(String label) {
    return 'Retirer $label';
  }

  @override
  String messageItemAdded(String label) {
    return '$label ajouté';
  }

  @override
  String get messageFull => 'Le message est plein';

  @override
  String get startupFailedTitle => 'Impossible de démarrer Memo';

  @override
  String get startupFailedBody =>
      'Une erreur est survenue au chargement des données. Fermez puis rouvrez l\'application. Si le problème continue, contactez le support.';

  @override
  String get startupFailedClose => 'Fermer';

  @override
  String get phrasesTitle => 'Dis-le maintenant';

  @override
  String get phrasesEmpty => 'Aucune phrase pour le moment';

  @override
  String phraseSpeak(String text) {
    return 'Dire : $text';
  }

  @override
  String get levelNoteBeginner =>
      'Très grandes tuiles, peu de mots à l\'écran, étiquettes agrandies';

  @override
  String get levelNoteIntermediate => 'Tuiles moyennes, vocabulaire élargi';

  @override
  String get levelNoteAdvanced => 'Tuiles denses, tout le vocabulaire';

  @override
  String get settingsSpeech => 'Lecture';

  @override
  String get settingsSpeakEachWord => 'Prononcer chaque mot touché';

  @override
  String get settingsSpeakEachWordNote =>
      'Un retour immédiat, avant même que la phrase soit composée';

  @override
  String get settingsDevice => 'Appareil';

  @override
  String get settingsHaptics => 'Vibrations';

  @override
  String get settingsHapticsNote => 'À couper pour économiser la batterie';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get languageFrench => 'Français';

  @override
  String get wordsTitle => 'Mots';

  @override
  String get wordsThisWeek => 'Cette semaine';

  @override
  String get wordsEmpty => 'Rien n\'a encore été dit cette semaine';

  @override
  String wordsSentences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phrases dites',
      one: '1 phrase dite',
      zero: 'Aucune phrase dite',
    );
    return '$_temp0';
  }

  @override
  String wordsNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux mots',
      one: '1 nouveau mot',
      zero: 'aucun nouveau mot',
    );
    return '$_temp0';
  }

  @override
  String wordsTimes(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fois',
      one: '1 fois',
    );
    return '$label, $_temp0';
  }

  @override
  String get navTalk => 'Parler';

  @override
  String get navPhrases => 'Phrases';

  @override
  String get navWords => 'Mots';

  @override
  String get navSettings => 'Réglages';

  @override
  String get settingsTooltip => 'Réglages';

  @override
  String get favoritesTitle => 'Mes favoris';

  @override
  String get favoritesEmpty =>
      'Appuyez longuement sur un pictogramme pour l\'ajouter à vos favoris';

  @override
  String get boardTitle => 'Mon tableau';

  @override
  String get boardEdit => 'Modifier le tableau';

  @override
  String get boardDone => 'Terminer';

  @override
  String get boardEmptyCell => 'Case vide';

  @override
  String get boardClearCell => 'Vider la case';

  @override
  String noVoiceTitle(String language) {
    return 'Voix $language introuvable';
  }

  @override
  String noVoiceBody(String language) {
    return 'Installez une voix $language dans les réglages de synthèse vocale du téléphone pour entendre les messages sans connexion.';
  }

  @override
  String get onboardingWelcome => 'Bienvenue dans Memo';

  @override
  String get onboardingWho => 'Qui va utiliser Memo ?';

  @override
  String get profileChild => 'Enfant';

  @override
  String get profileTeen => 'Adolescent';

  @override
  String get profileAdult => 'Adulte';

  @override
  String get profileCaregiver => 'Accompagnant';

  @override
  String get onboardingLevel => 'Choisissez un niveau';

  @override
  String get levelBeginner => 'Débutant';

  @override
  String get levelIntermediate => 'Intermédiaire';

  @override
  String get levelAdvanced => 'Avancé';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get next => 'Suivant';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get levelSetting => 'Niveau';

  @override
  String voiceLanguage(String lang) {
    String _temp0 = intl.Intl.selectLogic(lang, {
      'en': 'anglaise',
      'other': 'française',
    });
    return '$_temp0';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String languageSwitchTo(String language) {
    return 'Passer en $language';
  }

  @override
  String languageName(String lang) {
    String _temp0 = intl.Intl.selectLogic(lang, {
      'en': 'anglais',
      'other': 'français',
    });
    return '$_temp0';
  }

  @override
  String get caregiverModeLocked =>
      'Mode accompagnant : verrouillé. Toucher pour le déverrouiller';

  @override
  String get caregiverModeUnlocked =>
      'Mode accompagnant : déverrouillé. Toucher pour verrouiller';

  @override
  String get caregiverProtected =>
      'Réservé à l\'accompagnant : le code sera demandé';

  @override
  String get pinEnterTitle => 'Code accompagnant';

  @override
  String get pinEnterHint => 'Entrez votre code à 4 chiffres';

  @override
  String get pinCreateTitle => 'Créer un code accompagnant';

  @override
  String get pinCreateHint =>
      'Choisissez 4 chiffres. Il protège le niveau, le tableau, les phrases et les profils.';

  @override
  String get pinConfirmTitle => 'Confirmez le code';

  @override
  String get pinConfirmHint => 'Entrez le même code une seconde fois';

  @override
  String get pinMismatch => 'Les deux codes sont différents. Recommencez.';

  @override
  String get pinWeak => 'Ce code est trop simple. Choisissez-en un autre.';

  @override
  String pinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count essais restants',
      one: '1 essai restant',
    );
    return 'Code incorrect. $_temp0';
  }

  @override
  String pinLocked(int seconds) {
    return 'Trop d\'essais. Réessayez dans $seconds s.';
  }

  @override
  String pinDigit(String digit) {
    return 'Chiffre $digit';
  }

  @override
  String get pinDelete => 'Effacer le dernier chiffre';

  @override
  String get pinCancel => 'Annuler';

  @override
  String pinDigitsEntered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chiffres saisis',
      one: '1 chiffre saisi',
      zero: 'Aucun chiffre saisi',
    );
    return '$_temp0';
  }

  @override
  String get phraseAdd => 'Ajouter une phrase';

  @override
  String get phraseAddHint => 'Écrivez la phrase à dire';

  @override
  String get phraseSave => 'Enregistrer';

  @override
  String get phraseDelete => 'Supprimer la phrase';

  @override
  String phraseDeleteConfirm(String text) {
    return 'Supprimer « $text » ?';
  }

  @override
  String get phraseDeleteAction => 'Supprimer';

  @override
  String get cancel => 'Annuler';
}
