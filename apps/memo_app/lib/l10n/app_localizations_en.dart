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

  @override
  String languageSwitchTo(String language) {
    return 'Switch to $language';
  }

  @override
  String languageName(String lang) {
    String _temp0 = intl.Intl.selectLogic(lang, {
      'en': 'English',
      'other': 'French',
    });
    return '$_temp0';
  }

  @override
  String get caregiverModeLocked => 'Caregiver mode: locked. Tap to unlock';

  @override
  String get caregiverModeUnlocked => 'Caregiver mode: unlocked. Tap to lock';

  @override
  String get caregiverProtected => 'Caregiver only: the code will be asked';

  @override
  String get pinEnterTitle => 'Caregiver code';

  @override
  String get pinEnterHint => 'Enter your 4-digit code';

  @override
  String get pinCreateTitle => 'Create a caregiver code';

  @override
  String get pinCreateHint =>
      'Choose 4 digits. It protects the level, the board, phrases and profiles.';

  @override
  String get pinConfirmTitle => 'Confirm the code';

  @override
  String get pinConfirmHint => 'Enter the same code a second time';

  @override
  String get pinMismatch => 'The two codes are different. Try again.';

  @override
  String get pinWeak => 'This code is too simple. Choose another one.';

  @override
  String pinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts left',
      one: '1 attempt left',
    );
    return 'Wrong code. $_temp0';
  }

  @override
  String pinLocked(int seconds) {
    return 'Too many attempts. Try again in $seconds s.';
  }

  @override
  String pinDigit(String digit) {
    return 'Digit $digit';
  }

  @override
  String get pinDelete => 'Delete the last digit';

  @override
  String get pinCancel => 'Cancel';

  @override
  String pinDigitsEntered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count digits entered',
      one: '1 digit entered',
      zero: 'No digits entered',
    );
    return '$_temp0';
  }

  @override
  String get phraseAdd => 'Add a phrase';

  @override
  String get phraseAddHint => 'Write the phrase to say';

  @override
  String get phraseSave => 'Save';

  @override
  String get phraseDelete => 'Delete the phrase';

  @override
  String phraseDeleteConfirm(String text) {
    return 'Delete \"$text\"?';
  }

  @override
  String get phraseDeleteAction => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get profileSwitchTitle => 'Who is talking?';

  @override
  String get profileSwitchHint =>
      'Each person keeps their own level, favourites, board, phrases and history.';

  @override
  String get profileNew => 'New profile';

  @override
  String get profileNameLabel => 'First name or nickname';

  @override
  String get profileCreate => 'Create profile';

  @override
  String get profileCurrent => 'Current profile';

  @override
  String profileButtonSemantics(String name) {
    return '$name\'s profile. Tap to switch person';
  }

  @override
  String get onboardingName => 'What is the person\'s name?';

  @override
  String get onboardingNameHint => 'Optional';

  @override
  String get pinForgot => 'Forgot the code?';

  @override
  String get adultCheckTitle => 'Adult check';

  @override
  String get adultCheckHint => 'Write the result in digits:';

  @override
  String get adultCheckAnswer => 'Result';

  @override
  String get adultCheckWrong => 'That\'s not the right result. New question.';

  @override
  String get adultCheckContinue => 'Continue';

  @override
  String profileDelete(String name) {
    return 'Delete $name';
  }

  @override
  String get profileDeleteAction => 'Delete';

  @override
  String get profileDeleteWarning =>
      'Their favourites, board, phrases and history will be erased. This cannot be undone.';
}
