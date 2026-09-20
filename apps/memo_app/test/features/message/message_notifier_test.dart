import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/message/presentation/message_notifier.dart';

import '../../support/fakes.dart';

void main() {
  late ProviderContainer container;
  MessageNotifier notifier() => container.read(messageProvider.notifier);
  List<String> labels() =>
      container.read(messageProvider).map((p) => p.label).toList();

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test("ajoute dans l'ordre", () {
    notifier()
      ..add(pictogram(1, 'Je veux'))
      ..add(pictogram(2, 'Eau'));
    expect(labels(), ['Je veux', 'Eau']);
  });

  test('supprime un élément par position', () {
    notifier()
      ..add(pictogram(1, 'A'))
      ..add(pictogram(2, 'B'))
      ..removeAt(0);
    expect(labels(), ['B']);
  });

  test('déplace un élément', () {
    notifier()
      ..add(pictogram(1, 'A'))
      ..add(pictogram(2, 'B'))
      ..add(pictogram(3, 'C'))
      ..move(2, 0);
    expect(labels(), ['C', 'A', 'B']);
  });

  test('efface tout', () {
    notifier()
      ..add(pictogram(1, 'A'))
      ..clear();
    expect(labels(), isEmpty);
  });

  test("refuse d'ajouter au-delà de la limite", () {
    for (var i = 0; i < MessageNotifier.maxItems; i++) {
      expect(notifier().add(pictogram(i, 'x$i')), isTrue);
    }
    expect(notifier().add(pictogram(99, 'trop')), isFalse);
    expect(
      container.read(messageProvider),
      hasLength(MessageNotifier.maxItems),
    );
  });
}
