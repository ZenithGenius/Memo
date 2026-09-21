import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/ui/app_scroll_behavior.dart';

Widget list({ScrollBehavior? behavior}) => MaterialApp(
  scrollBehavior: behavior,
  home: Scaffold(
    body: GridView.count(
      crossAxisCount: 2,
      children: [for (var i = 0; i < 40; i++) Text('$i')],
    ),
  ),
);

void main() {
  testWidgets('sans réglage, Android étire le contenu au dépassement', (
    tester,
  ) async {
    await tester.pumpWidget(list());
    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
  });

  testWidgets("le comportement de l'application n'étire jamais le contenu", (
    tester,
  ) async {
    await tester.pumpWidget(list(behavior: const AppScrollBehavior()));
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);

    // Tirer vers le bas au sommet ne déplace rien.
    final before = tester.getTopLeft(find.text('0'));
    await tester.drag(find.text('0'), const Offset(0, 300));
    await tester.pump();
    expect(tester.getTopLeft(find.text('0')), before);
  });
}
