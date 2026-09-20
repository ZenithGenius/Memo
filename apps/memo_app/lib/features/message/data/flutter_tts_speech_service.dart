import 'package:flutter_tts/flutter_tts.dart';
import 'package:memo/features/message/domain/speech_service.dart';

class FlutterTtsSpeechService implements SpeechService {
  FlutterTtsSpeechService() : _tts = FlutterTts();
  final FlutterTts _tts;

  static String _locale(String language) => switch (language) {
        'fr' => 'fr-FR',
        'en' => 'en-US',
        _ => language,
      };

  @override
  Future<bool> isLanguageAvailable(String language) async {
    final result = await _tts.isLanguageAvailable(_locale(language));
    return result == true || result == 1;
  }

  @override
  Future<void> speak(String text, {required String language}) async {
    await _tts.setLanguage(_locale(language));
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
