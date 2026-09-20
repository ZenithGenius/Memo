abstract interface class SpeechService {
  Future<bool> isLanguageAvailable(String language);
  Future<void> speak(String text, {required String language});
  Future<void> stop();
}
