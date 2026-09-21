import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/message/domain/speech_service.dart';

class FakeSpeechService implements SpeechService {
  final List<String> spoken = [];
  final List<String> languages = [];
  bool available = true;

  @override
  Future<bool> isLanguageAvailable(String language) async => available;

  @override
  Future<void> speak(String text, {required String language}) async =>
      _record(text, language);

  void _record(String text, String language) {
    spoken.add(text);
    languages.add(language);
  }

  @override
  Future<void> stop() async {}
}

Pictogram pictogram(int id, String label, {String? spoken}) => Pictogram(
  id: id,
  code: 'P$id',
  categoryId: 1,
  label: label,
  spokenText: spoken ?? label.toLowerCase(),
  minLevel: Level.beginner,
  audience: Audience.all,
  sortOrder: id,
);
