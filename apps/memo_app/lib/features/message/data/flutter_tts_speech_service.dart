import 'package:flutter_tts/flutter_tts.dart';
import 'package:memo/features/message/domain/speech_service.dart';

/// Code de langue utilisé par la synthèse vocale. L'anglais est britannique,
/// plus proche de l'anglais du Cameroun que l'américain.
String ttsLocale(String language) => switch (language) {
  'fr' => 'fr-FR',
  'en' => 'en-GB',
  _ => language,
};

class FlutterTtsSpeechService implements SpeechService {
  FlutterTtsSpeechService() : _tts = FlutterTts();
  final FlutterTts _tts;

  @override
  Future<bool> isLanguageAvailable(String language) async {
    final result = await _tts.isLanguageAvailable(ttsLocale(language));
    return result == true || result == 1;
  }

  @override
  Future<void> speak(String text, {required String language}) async {
    await _tts.setLanguage(ttsLocale(language));
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
