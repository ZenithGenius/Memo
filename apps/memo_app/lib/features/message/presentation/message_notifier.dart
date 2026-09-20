import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memo/features/catalog/domain/catalog.dart';
import 'package:memo/features/message/data/flutter_tts_speech_service.dart';
import 'package:memo/features/message/domain/phrase_composer.dart';
import 'package:memo/features/message/domain/speech_service.dart';

class MessageNotifier extends Notifier<List<Pictogram>> {
  static const maxItems = 12;

  @override
  List<Pictogram> build() => const [];

  /// Retourne `false` si le message est plein.
  bool add(Pictogram p) {
    if (state.length >= maxItems) return false;
    state = [...state, p];
    return true;
  }

  void removeAt(int index) {
    if (index < 0 || index >= state.length) return;
    state = [...state]..removeAt(index);
  }

  void move(int from, int to) {
    if (from < 0 || from >= state.length || to < 0 || to >= state.length) {
      return;
    }
    final list = [...state];
    list.insert(to, list.removeAt(from));
    state = list;
  }

  void clear() => state = const [];
}

final messageProvider =
    NotifierProvider<MessageNotifier, List<Pictogram>>(MessageNotifier.new);

final phraseComposerProvider =
    Provider<PhraseComposer>((ref) => const SimplePhraseComposer());

final speechServiceProvider =
    Provider<SpeechService>((ref) => FlutterTtsSpeechService());
