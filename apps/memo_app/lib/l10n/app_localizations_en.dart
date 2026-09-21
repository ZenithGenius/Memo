// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Memo';

  @override
  String get homeTitle => 'Memo';

  @override
  String get messageEmptyHint => 'Tap a picture to start';

  @override
  String get speakButton => 'Say the message';

  @override
  String get clearButton => 'Clear';

  @override
  String removeItem(String label) {
    return 'Remove $label';
  }

  @override
  String messageItemAdded(String label) {
    return '$label added';
  }

  @override
  String get messageFull => 'The message is full';

  @override
  String get startupFailedTitle => 'Memo can\'t start';

  @override
  String get startupFailedBody =>
      'An error occurred while loading the data. Close the app and open it again. If the problem continues, contact support.';

  @override
  String get startupFailedClose => 'Close';

  @override
  String get phrasesTitle => 'Say it now';

  @override
  String get phrasesEmpty => 'No phrases yet';

  @override
  String phraseSpeak(String text) {
    return 'Say: $text';
  }

  @override
  String get levelNoteBeginner =>
      'Very large tiles, few words on screen, larger labels';

  @override
  String get levelNoteIntermediate => 'Medium tiles, wider vocabulary';

  @override
  String get levelNoteAdvanced => 'Dense tiles, the full vocabulary';

  @override
  String get settingsSpeech => 'Speech';

  @override
  String get settingsSpeakEachWord => 'Say each word when tapped';

  @override
  String get settingsSpeakEachWordNote =>
      'Instant feedback, before the sentence is built';

  @override
  String get settingsDevice => 'Device';

  @override
  String get settingsHaptics => 'Vibration';

  @override
  String get settingsHapticsNote => 'Turn off to save battery';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageFrench => 'Français';

  @override
  String get wordsTitle => 'Words';

  @override
  String get wordsThisWeek => 'This week';

  @override
  String get wordsEmpty => 'Nothing has been said this week yet';

  @override
  String wordsSentences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sentences spoken',
      one: '1 sentence spoken',
      zero: 'No sentences spoken',
    );
    return '$_temp0';
  }

  @override
  String wordsNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new words',
      one: '1 new word',
      zero: 'no new words',
    );
    return '$_temp0';
  }

  @override
  String wordsTimes(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$label, $_temp0';
  }

  @override
  String get navTalk => 'Talk';

  @override
  String get navPhrases => 'Phrases';

  @override
  String get navWords => 'Words';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get favoritesTitle => 'My favourites';

  @override
  String get favoritesEmpty =>
      'Long-press a picture to add it to your favourites';

  @override
  String get boardTitle => 'My board';

  @override
  String get boardEdit => 'Edit the board';

  @override
  String get boardDone => 'Done';

  @override
  String get boardEmptyCell => 'Empty cell';

  @override
  String get boardClearCell => 'Clear the cell';

  @override
  String noVoiceTitle(String language) {
    return '$language voice not found';
  }

  @override
  String noVoiceBody(String language) {
    return 'Install a $language voice in the phone\'s text-to-speech settings to hear messages without a connection.';
  }

  @override
  String get onboardingWelcome => 'Welcome to Memo';

  @override
  String get onboardingWho => 'Who will use Memo?';

  @override
  String get profileChild => 'Child';

  @override
  String get profileTeen => 'Teenager';

  @override
  String get profileAdult => 'Adult';

  @override
  String get profileCaregiver => 'Caregiver';

  @override
  String get onboardingLevel => 'Choose a level';

  @override
  String get levelBeginner => 'Beginner';

  @override
  String get levelIntermediate => 'Intermediate';

  @override
  String get levelAdvanced => 'Advanced';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get next => 'Next';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get levelSetting => 'Level';

  @override
  String voiceLanguage(String lang) {
    String _temp0 = intl.Intl.selectLogic(lang, {
      'en': 'English',
      'other': 'French',
    });
    return '$_temp0';
  }

  @override
  String get languageEnglish => 'English';
}
