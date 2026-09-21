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
  String get noVoiceTitle => 'Voix française introuvable';

  @override
  String get noVoiceBody =>
      'Installez une voix française dans les réglages de synthèse vocale du téléphone pour entendre les messages sans connexion.';

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
}
