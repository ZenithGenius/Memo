import 'package:memo/features/catalog/domain/catalog.dart';

abstract interface class PhraseComposer {
  String compose(List<Pictogram> items);
}

/// M1 : concatène les textes parlés. Les règles de grammaire arriveront
/// derrière cette même interface.
class SimplePhraseComposer implements PhraseComposer {
  const SimplePhraseComposer();

  @override
  String compose(List<Pictogram> items) {
    if (items.isEmpty) return '';
    final joined = items.map((p) => p.spokenText.trim()).join(' ');
    return '${joined[0].toUpperCase()}${joined.substring(1)}.';
  }
}
