import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/message/data/flutter_tts_speech_service.dart';

void main() {
  test("l'anglais utilise la voix britannique, plus proche du Cameroun", () {
    expect(ttsLocale('en'), 'en-GB');
    expect(ttsLocale('fr'), 'fr-FR');
  });

  test('une langue inconnue est transmise telle quelle', () {
    expect(ttsLocale('pcm'), 'pcm');
  });
}
