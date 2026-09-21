import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/ui/adaptive_grid.dart';
import 'package:memo/features/catalog/domain/catalog.dart';

void main() {
  /// Nombre de colonnes obtenues pour une largeur d'écran et un niveau.
  Future<int> columns(WidgetTester tester, Level level, double width) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: width,
            height: 2000,
            child: GridView(
              gridDelegate: adaptiveGridDelegate(level),
              padding: const EdgeInsets.all(16),
              children: [
                for (var i = 0; i < 24; i++) SizedBox(key: ValueKey(i)),
              ],
            ),
          ),
        ),
      ),
    );
    final firstY = tester.getTopLeft(find.byKey(const ValueKey(0))).dy;
    return [
      for (var i = 0; i < 24; i++)
        if (find.byKey(ValueKey(i)).evaluate().isNotEmpty &&
            tester.getTopLeft(find.byKey(ValueKey(i))).dy == firstY)
          i,
    ].length;
  }

  testWidgets(
    'téléphone : moins de colonnes et de plus grandes tuiles au niveau débutant',
    (tester) async {
      final beginner = await columns(tester, Level.beginner, 411);
      final intermediate = await columns(tester, Level.intermediate, 411);
      final advanced = await columns(tester, Level.advanced, 411);
      expect(beginner, 2);
      expect(intermediate, 3);
      expect(advanced, 4);
    },
  );

  testWidgets('tablette : plus de colonnes à niveau égal', (tester) async {
    final phone = await columns(tester, Level.beginner, 411);
    final tablet = await columns(tester, Level.beginner, 800);
    expect(tablet, greaterThan(phone));
  });

  test('les tuiles restent des cibles tactiles de 48 dp minimum', () {
    for (final level in Level.values) {
      expect(maxTileExtent(level), greaterThanOrEqualTo(48));
    }
  });
}
